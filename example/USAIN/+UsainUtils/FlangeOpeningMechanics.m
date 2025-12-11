classdef FlangeOpeningMechanics < matlab.mixin.SetGet
    % Models forces and stresses for flange opening up to the bolt axis (bolt circle diameter)

    % The following properties block contains inputs to calculations
    properties
        preload double  % Preload to be used for the calculations in this class
        paramA double  % "Inner width", i.e. parameter a from literature
        paramB double  % "Outer width", i.e. parameter b from literature
        paramC double  % Segment width at BCD, i.e. parameter c from literature, or bolt distance
        thickness double  % Flange thickness
        bendingResilienceBolt double  % Bending resilience of bolt/stud
        axialResilienceBolt double  % Axial resilience of bolt/stud
        eModulus double  % Young's modulus of bolt material
        loadFactor double  % Load factor, i.e. parameter p from literature
        reactionDistanceMethod char = 'tobinaga'  % Toggle to use 'seidel' or 'tobinaga' for "effective a"

        stressAreaBolt double  % Stress area of bolt
        loadIntroductionFactor double = 1.0  % Load introduction factor (correction of load factor for omega)
    end

    methods

        function Obj = FlangeOpeningMechanics(varargin)
            Obj = assign_varargin_2_classprop(Obj, varargin{:});
        end

        function omega = calc_omega_parameter(Obj)
            % Computes magical omega parameter (just a helper value that simplifies equations)
            % Omega is computed according to eq. 107 in Seidel's thesis

            % Shortcut notations to make the formula for omega look like the one from literature
            t = Obj.thickness;
            b = Obj.paramB;
            c = Obj.paramC;
            aEffective = Obj.calc_effective_a_parameter();

            % For the fastener stiffness (denoted by C_S in Marc's dissertation), use half of the resilience:
            %   stiffness = 1 / (resilience / 2) = 2 / resilience
            % Note that the bending resilience is not halved; for this the full stud is used. This is
            % confusing, but that's how Marc originally derived these equations.
            stiffnHalfBolt = 2 ./ Obj.axialResilienceBolt;

            % If loadIntroductionFactor is not unity, correct the load factor by this load introduction factor
            phi = Obj.loadIntroductionFactor .* Obj.loadFactor;

            % Derive properties required to computed opening force
            omega = 3 * b .* ...
                (aEffective .* c - stiffnHalfBolt .* t ./ Obj.eModulus) + ...
                2 .* aEffective.^2 .* c .* (1 - phi);
        end

        function aEff = calc_effective_a_parameter(Obj)
            % Helper method to get "effective a"

            React = UsainUtils.ReactionDistance(Obj.paramA, Obj.paramB, Obj.thickness);
            switch Obj.reactionDistanceMethod
                case 'tobinaga'
                    aEff = React.calc_aeff_tobinaga();
                case 'seidel'
                    aEff = React.calc_aeff_seidel_fls();
                otherwise
                    error('FlangeOpeningMechanics:UnsupportedReactionDistanceMethod', ...
                        'Reaction distance method "%s" is not supported.', Obj.reactionDistanceMethod);
            end
        end

        function force = calc_bolt_force_at_bcd_opening(Obj)

            % Shortcut notations using symbols from literature
            b = Obj.paramB;
            c = Obj.paramC;
            aEffective = Obj.calc_effective_a_parameter();
            omega = Obj.calc_omega_parameter();

            % Compute bolt force according to eq. 105 in Seidel's thesis
            force = Obj.preload .* aEffective .* c .* (3 * b + 2 * aEffective) ./ omega;
        end

        function moment = calc_bolt_moment_at_bcd_opening(Obj)

            % Shortcut notations using symbols from literature
            t = Obj.thickness;
            b = Obj.paramB;
            aEffective = Obj.calc_effective_a_parameter();
            omega = Obj.calc_omega_parameter();
            beta = Obj.bendingResilienceBolt;

            % Compute bending moment according to eq. 106 in Seidel's thesis
            moment = 12 * Obj.preload .* b .* t ./ (omega .* aEffective .* Obj.eModulus .* beta);
        end

        function stress = calc_bolt_axial_stress_at_bcd_opening(Obj, fPreload)
            % Computes axial bolt stress when subjected to force that opens flange up to the BCD
            %
            % fPreload: Optional preload value that will be subtracted from the bolt force

            if nargin < 2
                fPreload = 0;
            end

            force = Obj.calc_bolt_force_at_bcd_opening();
            stress = (force - fPreload) ./ Obj.stressAreaBolt;
        end

        function stress = calc_bolt_bending_stress_at_bcd_opening(Obj)

            % Derived the "stress diameter" based on the bolt's stress area
            d = sqrt(4 * Obj.stressAreaBolt / pi);
            moment = Obj.calc_bolt_moment_at_bcd_opening();
            sectionModulus = (pi / 32) .* d.^3;  % = arm / inertia = r / (pi*r^4/4)
            stress = moment ./ sectionModulus;
        end

        function n = calc_load_introduction_factor(Obj, diamContact)
            % Computes load introduction factor (= correction on load factor)
            % This method follows the "medium simplified" path from section 13.1.3 in Seidel's thesis
            %
            % Symbols from literature are used:
            %   ak: distance between the edge of the preloading area and the load introduction point
            %   ar: distance of the joint between the preloading area and the lateral edge of the joint
            %   h: joint thickness
            %   n2d: calibrated load introduction factor based on the joint from figure 17 in VDI2230/1 2015
            %   kar: parameter for the effect of the component height on the load introduction factor
            %
            % diamContact: diameter of fastener component in contact with flange (round nut or washer)
            % n: load introduction factor

            ak = Obj.paramB - (diamContact / 2);
            ar = (Obj.paramC - diamContact) / 2;
            h = Obj.thickness;
            n2d = 0.52 - 0.703 * (ak ./ h);
            kar = 1 - 1.74 * (ar ./ h) + 1.24 * (ar ./ h).^2;
            n = 0.85 * n2d .* kar;
        end

    end

    methods (Static)

        function Obj = from_flange_model(FlangeModel)

            SegmentModel = FlangeModel.Segment;
            bendingResilience = SegmentModel.calc_bending_resilience_fastener();

            Obj = UsainUtils.FlangeOpeningMechanics( ...
                'paramA', SegmentModel.distRim, ...
                'paramB', SegmentModel.distForce, ...
                'paramC', SegmentModel.distBolt, ...
                'thickness', FlangeModel.Space.thickness, ...
                'bendingResilienceBolt', bendingResilience, ...
                'axialResilienceBolt', SegmentModel.resilBolt, ...
                'eModulus', FlangeModel.Inputs.E_BOLT, ...
                'loadFactor', SegmentModel.loadFactor, ...
                'reactionDistanceMethod', FlangeModel.Inputs.REACTION_DISTANCE_METHOD, ...
                'stressAreaBolt', FlangeModel.Bolt.areaStress);
        end

    end
end
