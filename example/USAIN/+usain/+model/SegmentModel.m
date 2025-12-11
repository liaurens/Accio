classdef SegmentModel
    % Datamodel for L- and T-flange segment

    properties
        FlangeType (1, 1) usain.inputs.FlangeType

        % geometrical parameters
        diameterOutNeck (:, 1) double  % outer diameter of flange neck
        diameterBoltCircle (:, 1) double  % diameter of L-flange bolt circle (inside)
        diameterIn (:, 1) double  % inner diameter of flange
        flangeWidth (:, 1) double  % physical width, inside to outside flange
        flangeThickness (:, 1) double
        neckThicknessUp (:, 1) double
        neckThicknessLo (:, 1) double
        nSegments (:, 1) double {mustBeInteger}

        % material parameters
        eModulus (1, 1) double = 210e9
        gModulus (1, 1) double = 81e9

        % derived geometrical parameters
        a (:, 1) double  % "inner width"; distance from inside flange to bolt hole center
        aEffective (:, 1) double  % effective `a`, where prying reaction force is assumed
        b (:, 1) double  % "outer width"; distance from bolt hole center to the middle of the flange neck

        % fastener parameters
        ftRd (:, 1) double  % design value of bolt's tension resistance

        % coupled flange/fastener parameters
        resilienceFlanges (:, 1) double
        resilienceClampedParts (:, 1) double
        resilienceBoltAxial (:, 1) double
        resilienceBoltBending (:, 1) double
        loadFactor (:, 1) double
    end
    properties (Dependent)
        areaCircumferential (:, 1) double  % cross-section area in circumferential direction, excluding flange neck
        areaTangential (:, 1) double  % cross-section area in tangential direction
        boltDistance (:, 1) double  % center-to-center distance
        inertiaGapClosing (:, 1) double
        inertiaFlangeRotation (:, 1) double
        neckThickness (1, 1) double  % average from upper and lower flange
        segmentWidth (:, 1) double  % measured at center of neck (average neck thickness)
    end

    methods

        function Obj = SegmentModel(FlangeType)
            Obj.FlangeType = FlangeType;
        end

        function aMod = calc_a_modified(Obj)
            % Computes empirical factor `a*` (modified parameter `a`, used for L-flange bolt moment calculations)

            if Obj.FlangeType == usain.inputs.FlangeType.T
                aMod = nan;
                return
            end

            aMod = Obj.aEffective .* max(0.4, ...
                min(1,  ...
                (Obj.flangeThickness ./ (Obj.aEffective + Obj.b)).^2));
        end

        function value = get.areaCircumferential(Obj)
            % Cross-sectional area of flange in circumferential direction (i.e. physical width times thickness)
            value = Obj.flangeWidth .* Obj.flangeThickness;
        end

        function value = get.areaTangential(Obj)
            value = Obj.flangeThickness .* Obj.segmentWidth;
        end

        function value = get.boltDistance(Obj)
            value = pi * Obj.diameterBoltCircle ./ Obj.nSegments;
        end

        function value = get.inertiaGapClosing(Obj)
            % Area moment of inertia for bending axis in flange width direction (from inside to outside of flange).
            % This moment of inertia is relevant when modelling flange gap opening/closing.
            value = Obj.flangeWidth .* Obj.flangeThickness.^3 / 12;
        end

        function value = get.inertiaFlangeRotation(Obj)
            % Area moment of inertia for bending axis in flange segment width (circumferential) direction.
            % This moment of inertia is relevant when modelling flange/stud rotation due to an applied segment tension.
            value = Obj.segmentWidth .* Obj.flangeThickness.^3 / 12;
        end

        function value = get.neckThickness(Obj)
            value = (Obj.neckThicknessLo + Obj.neckThicknessUp) / 2;
        end

        function value = get.segmentWidth(Obj)
            value = pi * (Obj.diameterOutNeck - Obj.neckThickness) ./ Obj.nSegments;
        end

    end

    methods (Static)

        function Obj = create(FlangeModel)
            % Builds SegmentModel from input args
            Obj = usain.model.SegmentModel(FlangeModel.flangeType);

            % Extract geometrical flange parameters
            Obj.diameterOutNeck = FlangeModel.diameterOutNeck;
            Obj.diameterBoltCircle = FlangeModel.diameterBoltCircle;
            Obj.diameterIn = Obj.calc_inner_diameter(FlangeModel.diamOutFlange, FlangeModel.Space.width);
            Obj.flangeWidth = FlangeModel.Space.width;
            Obj.flangeThickness = FlangeModel.Space.thickness;
            Obj.neckThicknessUp = FlangeModel.Inputs.thicknNoseUp;
            Obj.neckThicknessLo = FlangeModel.Inputs.thicknNoseLo;
            Obj.nSegments = FlangeModel.Space.nBolts;

            % Extract material parameters
            Obj.eModulus = FlangeModel.Inputs.E_FLANGE;
            POISSONS_RATIO = 0.3;  % TODO: Move to expert inputs
            Obj.gModulus = FlangeModel.Inputs.E_FLANGE / (2 * (1 + POISSONS_RATIO));

            % Derive parameters from physical flange geometry
            Obj.a = Obj.calc_parameter_a(Obj.diameterIn, Obj.diameterBoltCircle);
            Obj.b = ones(size(Obj.a)) .* Obj.calc_parameter_b(Obj.FlangeType, Obj.diameterOutNeck, ...
                Obj.diameterBoltCircle, Obj.neckThicknessUp, Obj.neckThicknessLo);
            Obj.aEffective = UsainUtils.ReactionDistance(Obj.a, Obj.b, Obj.flangeThickness).calc_aeff_tobinaga();

            Obj.ftRd = 0.9 * FlangeModel.Bolt.ftRc ./ FlangeModel.Inputs.PSF_BOLT_RESISTANCE;
            % TODO: `ftRd` should not be part of this class. Move to BoltLoadModel?
            % TODO: `ftRd` always includes a PSF. This would be overly conservative for robustness cases

            % Compute and store resiliences and load factor
            ResilienceModel = usain.model.ResilienceModel.from_flange_model(FlangeModel);
            Obj.resilienceFlanges = ResilienceModel.resilienceFlanges;
            Obj.resilienceClampedParts = ResilienceModel.resilienceClampedParts;
            Obj.resilienceBoltAxial = ResilienceModel.resilienceBolt;
            Obj.resilienceBoltBending = ResilienceModel.bendingResilienceBolt;
            Obj.loadFactor = ResilienceModel.loadFactor;
        end

        function diam = calc_inner_diameter(diameterOutFlange, flangeWidth)
            % Compute inner diameter
            % diameterOutFlange: Outer diameter of flange
            % flangeWidth: Physical width of flange

            diam = diameterOutFlange - 2 .* flangeWidth;
        end

        function a = calc_parameter_a(diameterIn, diameterBoltCircle)
            % Computes parameter 'a' (distance inner edge to bolt axis)
            a = (diameterBoltCircle - diameterIn) ./ 2;
        end

        function b = calc_parameter_b(FlangeType, diameterOutNeck, diameterBoltCircle, neckThicknessUp, neckThicknessLo)
            % Computes parameter 'b' (distance bolt axis to flange neck center)
            % NOTE: Difference between L- and T-flanges in case of asymmetrical neck thicknesses

            if FlangeType == usain.inputs.FlangeType.L
                % L-flanges are outside aligned -> use minimum neck thickness
                minNeckThickness = min(neckThicknessUp, neckThicknessLo);
                b = (diameterOutNeck - diameterBoltCircle - minNeckThickness) ./ 2;
            elseif FlangeType == usain.inputs.FlangeType.T
                % T-flanges are center aligned -> use neck thickness that corresponds to the outer neck diameter
                % of the upper flange
                b = (diameterOutNeck - diameterBoltCircle - neckThicknessUp) ./ 2;
            end
        end

    end

end
