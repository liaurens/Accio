classdef ShellBendingOpening < UsainUtils.ShellBending
    % Models shell bending stresses due to flange opening.
    % This class captures flange opening effects. Under meridional tensile
    % stresses, the flange is opening, which induces a curvature at the tower
    % wall, and hence bending stresses in the shells. Such a flange opening
    % occurs even when the flange bolts are preloaded.
    %
    % The local origin x=0 is at the top of the flange surface (i.e. where
    % x_global = t_flange), see method calc_local_origin.
    %
    % Reference:
    %   Seidel, Marc. (2020). Analytical calculation of stress concentrations at
    %   welded flange necks. [Stahlbau]
    %

    properties
        % NOTE: A note on property sizes is given in parent class
        % UsainUtils.ShellBending

        diamBolt double % Nominal diameter of bolt
        preload double % Preload in bolt
        bcd double % Bolt circle diameter
        nBolts double % Number of bolts

        a double % Inner width "a", distance bolt axis to flange inner edge
        b double % [1*2] Outer width "b", distance bolt axis to shell mid
        c double % [1*2] Distance between bolts "c"
        aEff double % [1*2] Effective width "a", distance bolt axis to reaction point

        stiffnBolt double % Stiffness of bolt
        loadFactor double = 0.06 % Bolt load carrying factor (0.06 is reasonable estimate)
        intpExp double = 2 % Power factor for interpolation of opening rotations
    end
    properties (Dependent)
        omega double % [1*2] Shortcut "Omega" for flange gapping force calculations
    end

    methods

        function Obj = ShellBendingOpening(varargin)
            if nargin
                Obj = assign_varargin_2_classprop(Obj, varargin{:});
            end
        end

        function load_model(Obj, Mdl)
            % Extends parent method:
            %   UsainUtils.ShellBending/load_model

            % First call parent method and then extend
            load_model@UsainUtils.ShellBending(Obj, Mdl);

            % Grab more inputs
            Obj.diamBolt = Mdl.Bolt.diam;
            Obj.bcd = Mdl.Inputs.diamBoltCircle;
            Obj.nBolts = Mdl.Space.nBolts;
            % TODO: check that FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS is same as one of BoltFls.PRELOAD_LOSS_FACTOR_FLS
            % TODO: document behavior of FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS
            Obj.preload = usain.fastener.get_preload(Mdl.Tool.defaultPreload, ...
                Mdl.Inputs.FlangeNeckScf.CUSTOM_PRELOAD, Mdl.Inputs.FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS);

            % Assume load factor of 0.06, following  Marc's PhD thesis (page 173
            % -> Vereinfachung -> stark). This is acceptable as it has little
            % effect on the results
            % NOTE: The load factor used for the Schmidt-Neuper model is not
            % applicable to this gapping model (Schmidt-Neuper considers the
            % entire connection, this model only half).
            Obj.loadFactor = 0.06;

            % Determine bolt stiffness. In contrast to Schmidt-Neuper, this
            % model considers half of the flange. Hence, take half of the
            % resilience (= twice the stiffness)
            Obj.stiffnBolt = 2 ./ Mdl.Segment.resilBolt;

            % Compute segment model properties. Explicitly calculated because
            % Mdl.Segment only stores the properties for the most flexible
            % flange in the connection. Here, both upper and lower flanges need
            % to be evaluated.
            Obj.a = Mdl.Segment.distRim;
            Obj.b = Mdl.Segment.calc_outer_width( ...
                Mdl.flangeType, Mdl.diameterOutNeck, Obj.bcd, Obj.thkNose, Obj.thkNose);
            Obj.c = Mdl.Segment.calc_segment_width(Mdl.diameterOutNeck - Obj.thkNose, Obj.nBolts);

            % Compute "effective width", again for upper and lower flange
            % separately
            React = UsainUtils.ReactionDistance(Obj.a, Obj.b, Mdl.Space.thickness);
            switch Mdl.Inputs.REACTION_DISTANCE_METHOD
                case 'seidel'
                    Obj.aEff = React.calc_aeff_seidel_fls();
                case 'tobinaga'
                    Obj.aEff = React.calc_aeff_tobinaga();
                otherwise
                    error('Effective width method "%s" not supported.', ...
                        Mdl.Inputs.REACTION_DISTANCE_METHOD);
            end
        end

        function [q0, m0] = calc_bending_coefficients(Obj, stress)
            % See parent method:
            %   UsainUtils.ShellBending/calc_bending_coefficients

            Obj.validate_stress_input(stress);

            % Shortcuts (common literature symbols are used)
            k = Obj.flexRigdty;
            beta = Obj.geomParam;

            % Compute rotations in flange due to tensile and/or compressive
            % loading. Using just the rotations, the shear and moment constants
            % can be determined
            rot = Obj.calc_rotations(stress);
            q0 = -2 * k .* beta.^3 .* rot .* (Obj.thk + (1 ./ beta));
            m0 = k .* beta.^2 .* rot .* (Obj.thk + (2 ./ beta));
        end

        function x0 = calc_local_origin(Obj)
            % See parent method:
            %   UsainUtils.ShellBending/calc_local_origin

            x0 = ones(1, 2) .* Obj.thk;
        end

        function rot = calc_rotations(Obj, stress)
            % Computes flange rotations due to applied loading
            %
            % INPUT (* = optional)
            %   stress: See UsainUtils.ShellBending/solve
            %
            % OUTPUT
            %   rot: [double, N*2] Rotations for (1) upper and (2) lower flange

            % Compute segment force
            fSeg = pi .* (Obj.diamOutNeck - Obj.thkNose(1)) ./ ...
                Obj.nBolts .* Obj.thkNose(1) .* stress;

            % Compute rotations if loading was purely compressive
            rotComprUnit = Obj.calc_unit_rotations_compression();
            rotCompr = fSeg .* rotComprUnit;

            % Compute rotations if loading was purely tensile, with load level
            % high enough for flange gapping to occur
            fGap = Obj.calc_gapping_force();
            rotOpenUnit = Obj.calc_unit_rotations_tension();
            rotOpen = rotOpenUnit .* (fSeg ./ fGap).^Obj.intpExp;

            % Compute rotations if loading is tensile, but flange is not opening
            % up to the bolts yet
            rotTrans = rotOpen + ...
                rotCompr .* ((fGap - fSeg) ./ fGap).^Obj.intpExp;

            % Return actual rotations based on opening state of connection. For
            % this, compate fGap to fSeg where the latter is repeated to a [N*2]
            % array (segment force upper == lower due to force equilibrium)
            rot = rotTrans;
            isCompr = [fSeg, fSeg] <= 0;
            rot(isCompr) = rotCompr(isCompr);
            isOpen = [fSeg, fSeg] >= fGap;
            rot(isOpen) = rotOpen(isOpen);
        end

        function fGap = calc_gapping_force(Obj)
            % Computes segment force at which flange opens up to bolts
            fGap = 2 * Obj.preload .* Obj.aEff.^2 .* Obj.c ./ Obj.omega;
        end

        function rot = calc_unit_rotations_cantilever(Obj)
            % Computes rotations per unit load due to flange's cantilever behavior
            inertia = Obj.c * Obj.thk^3 / 12;
            fGap = Obj.calc_gapping_force();
            rot = (fGap .* Obj.b.^2) ./ (2 * Obj.eMod * inertia);
        end

        function rot = calc_unit_rotations_gapping(Obj)
            % Computes rotations per unit load due to flange gapping
            rot = (6 * Obj.preload * Obj.b * Obj.thk) ./ ...
                (Obj.eMod * Obj.omega .* Obj.aEff);
        end

        function rot = calc_unit_rotations_tension(Obj)
            % Combines gapping and cantilever rotations
            rot1 = Obj.calc_unit_rotations_cantilever();
            rot2 = Obj.calc_unit_rotations_gapping();
            rot = rot1 + rot2;
        end

        function rot = calc_unit_rotations_compression(Obj)
            % Computes rotations per unit load due to compression
            bEff = Obj.aEff + Obj.b + Obj.thkNose / 2;
            inertia = Obj.c .* bEff.^3 / 12;
            eccBolt = (Obj.aEff - (Obj.b + Obj.thkNose ./ 2)) / 2;
            rot = (Obj.b + eccBolt * (1 - Obj.loadFactor)) * Obj.thk ./ ...
                (Obj.eMod * inertia);
        end

        function value = get.omega(Obj)
            value = 3 * Obj.b .* ...
                (Obj.aEff .* Obj.c - Obj.stiffnBolt * Obj.thk / Obj.eMod) + ...
                2 * Obj.aEff.^2 .* Obj.c * (1 - Obj.loadFactor);
        end

    end
end
