classdef ShellBending < matlab.mixin.SetGet
    % Abstract class for flange neck shell bending modelling
    %
    % Shell bending theory for "long" (semi-infinite) shells is applied. It is
    % assumed that this is always applicable for support structure flange
    % connections. The condition L >= 2.3 * sqrt(R*h) is not checked.
    %
    % For speed reasons, the calculations are vectorised. Therefore, the
    % dimensions of properties and temporary variables in this class (and
    % subclasses) are reserved as follows:
    % - Dimension #1: Stress/load ranges
    % - Dimension #2: Upper/lower flange. Hence, dim #2 is either 1 (in case
    %   upper and lower flange share the same value, like bolt diameter) or 2
    %   (in case upper and lower flange may have different values, like nose
    %   thickness)
    %

    properties
        % NOTE: Properties are either scalar or [1*2] vectors. In case of the
        % latter, the elements pertain to the upper and lower flange in the
        % connection, respectively.
        eMod double % Young's modulus of flange material
        nu double = 0.3 % Poisson ratio of flange material
        thk double % Thickness of flange
        wid double % Width of flange
        diamOutNeck double % Outer diameter at flange neck
        thkNose double % [1*2] Flange nose thickness
        xWeldToe double % [1*2] Distance weld toe from flange mating surface
        shiftShell double = 0 % Radius shift due to shell misalignment
        shiftFlange double = 0 % Radius shift due to flange misalignment
    end
    properties (Dependent)
        rNose double % [1*2] Radius (mid) of flange nose, including radius shift due to tolerances
        flexRigdty double % [1*2] Flexural rigidity (K or D in literature)
        geomParam double % [1*2] Geometric shell bending parameter (n or beta in literature)
    end

    methods

        function load_model(Obj, Mdl)
            % Construct shell bending object from USAIN's FlangeModel instance
            %

            assert(Mdl.Space.nPoints == 1, ...
                'Bending stresses can only be computed for a single design point.');

            Obj.eMod = Mdl.Inputs.E_FLANGE;
            Obj.thk = Mdl.Space.thickness;
            Obj.wid = Mdl.Space.width;
            Obj.diamOutNeck = Mdl.diameterOutNeck;
            Obj.thkNose = [Mdl.Inputs.thicknNoseUp, Mdl.Inputs.thicknNoseLo];
            Obj.shiftShell = Mdl.Inputs.RADIUS_SHIFT_SHELL;
            Obj.shiftFlange = Mdl.Inputs.RADIUS_SHIFT_FLANGE;

            % Compute distance of weld toe from flange mating surface. Assume
            % the weld toe starts at the weld prep (bevel)
            heightWeldPrep = Mdl.calc_bevel_triangle_sides(Obj.thkNose);
            heightNose = [Mdl.Inputs.heightNoseUp, Mdl.Inputs.heightNoseLo];
            Obj.xWeldToe = Obj.thk + heightNose - heightWeldPrep;
        end

        function [stressIn, stressOut] = solve(Obj, stress, x)
            % Returns bending stresses in flange neck / shell.
            %
            % INPUT (* = optional)
            %   stress: [double, N*1] Nominal stress on top flange nose
            %   *x:     [double, M*2] Axial location(s) at which to evaluate
            %           stresses, in local coordinate system. If no "x' is
            %           input, the stresses at both upper and lower weld toe
            %           will be evaluated.
            %
            % OUTPUT
            %   stressIn, : [double, N*2*M] Bending stress in flange neck. First
            %   stressOut   column is for stresses in upper flange, second
            %               column for lower flange
            %

            if nargin < 3
                x0 = Obj.calc_local_origin();
                x = Obj.xWeldToe - x0;
            end

            % Make sure input stress is a column vector
            Obj.validate_stress_input(stress);

            % Force x to [1*2*M] array for uniform processing
            x = Obj.process_position_x(x);

            % Compute shell bending moments according to shell bending theory
            % for "long" shells
            [q0, m0] = Obj.calc_bending_coefficients(stress);
            beta = Obj.geomParam;
            beta_x = beta .* x;
            moment = q0 ./ beta .* exp(-beta_x) .* sin(beta_x) + ...
                m0 .* exp(-beta_x) .* (cos(beta_x) + sin(beta_x));

            % Compute stresses in flange neck
            secMod = Obj.thkNose.^2 / 6;
            stressIn = moment ./ secMod;
            stressOut = -stressIn;
        end

        function validate_stress_input(~, stress)
            % Stress must be a column vector otherwise we cannot solve the
            % system of equations for shell bending theory
            assert(size(stress, 2) == 1, ...
                'ShellBending:StressNotColumnVector', ...
                'Input "stress" must be scalar or a column vector');
        end

        function x = process_position_x(~, x)
            % Makes sure position x is [1*2*M] array

            assert(size(x, 2) == 2, 'ShellBending:WrongPositionSize', ...
                'Position x must be N-by-2, N >= 1.');

            % Swap dimensions to return [1*2*M] array. That is, move dim #1 to
            % dim #3
            szM = size(x, 1);
            x = reshape(x', 1, 2, szM);
        end

        function value = get.rNose(Obj)
            % Nominal value
            rNoseNom = (Obj.diamOutNeck - Obj.thkNose) / 2;
            % Add radius shifts
            shiftUp = Obj.shiftShell + Obj.shiftFlange;
            shiftLo = -Obj.shiftShell - Obj.shiftFlange;
            value = rNoseNom + [shiftUp, shiftLo];
        end

        function value = get.flexRigdty(Obj)
            value = (Obj.eMod * Obj.thkNose.^3) / (12 * (1 - Obj.nu^2));
        end

        function value = get.geomParam(Obj)
            value = (3 * (1 - Obj.nu^2))^0.25 ./ ...
                sqrt(Obj.rNose .* Obj.thkNose);
        end

    end

    methods (Abstract)
        % Computes bending moment coefficients q0, m0 for given stress level(s).
        % The coefficients are needed to solve for bending stresses in "long
        % shells", according the shell bending theory. In literature, these
        % coefficients may also be given symbols A1 and A2 (constants of
        % integration, determined from the boundary conditions at x=0).
        %
        % INPUT
        %   stress: [double, N*1] Stress on top flange nose
        %
        % OUTPUT
        %   q0, m0: [double, N*2] Bending moment coefficients at upper (column
        %           1) and lower (column 2) flange
        %
        [q0, m0] = calc_bending_coefficients(Obj, stress)

        % Returns axial origin x=0 relative to flange mating surface.
        % Different shell bending effects have different origins. This origin,
        % x=0, is defined relativ to the flange mating surface and has positive
        % direction away from the mating surface.
        %
        % OUTPUT
        %   x0: [double, scalar] Distance of origin to flange mating surface
        %
        x0 = calc_local_origin(Obj)
    end
end
