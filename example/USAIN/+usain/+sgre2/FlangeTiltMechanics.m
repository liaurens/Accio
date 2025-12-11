classdef FlangeTiltMechanics
    % Closing behavior of tilted L- or T-flanges
    % Shell theory is used, similar to the flange neck bending stress calculation, to find the preload force needed to
    % close a tilted flange.
    %
    % NOTE: The calculations are done using mean/average geometry of the flange pair, which is not entirely correct for
    % asymmetric flange connections.

    properties
        FlangeType (1, 1) usain.inputs.FlangeType
        eModulus (1, 1) double
        flangeThickness (:, 1) double
        neckThickness (1, 1) double  % neck thickness, mean value of upper and lower flange
        parameterB (:, 1) double  % "outer width", mean value of upper and lower flange
        flangeWidth (:, 1) double
        radiusMidNeck (:, 1) double  % radius at middle of flange neck, mean value of upper and lower flange
        segmentWidth (:, 1) double
    end
    properties (Constant)
        POISSONS_RATIO = 0.3
    end

    methods

        function Obj = FlangeTiltMechanics(FlangeType)
            Obj.FlangeType = FlangeType;
        end

        function radius = calc_flange_mid_radius(Obj)
            % Compute radius of middle of flange body

            if Obj.FlangeType == usain.inputs.FlangeType.L
                radius = Obj.radiusMidNeck + Obj.neckThickness ./ 2 - Obj.flangeWidth ./ 2;
            else
                radius = Obj.radiusMidNeck;
            end
        end

        function arm = calc_lever_arm(Obj)
            % Compute lever arm of a closing tilted flange

            if Obj.FlangeType == usain.inputs.FlangeType.L
                % For an L-flange, the lever arm is the distance from outer edge to fastener
                arm = Obj.parameterB + Obj.neckThickness ./ 2;
            else
                % For a T-flange, the lever arm is the distance from the outer bolt to the inner edge
                arm = Obj.parameterB + Obj.flangeWidth ./ 2;
            end
        end

        function [n, k] = calc_shell_parameters(Obj)
            % Compute shell parameters `n` (sometimes `lambda`) and `K`
            n = (3 * (1 - Obj.POISSONS_RATIO^2))^0.25 ./ (Obj.radiusMidNeck .* Obj.neckThickness).^0.5;
            k = Obj.eModulus * Obj.neckThickness^3 / (12 * (1 - Obj.POISSONS_RATIO^2));
        end

        function force = calc_tilt_closing_force(Obj, tiltAngle)
            % Compute force required to close
            % tiltAngle: target flange tilt angle in [rad]

            [n, k] = Obj.calc_shell_parameters();

            % Compute generalized matrix entries that are needed to compute the tilt angle (in [rad]) that is being
            % closed by a unity preload force (1 [N])
            % NOTE: Symbols used in this method are explained in ./USAIN/docs/explanation/developer-documentation.md
            leverArm = Obj.calc_lever_arm();
            radiusFlangeMid = Obj.calc_flange_mid_radius();
            gapClosingForce = 1;
            tiltClosingMoment = gapClosingForce .* leverArm ./ Obj.segmentWidth;  % Nm/m
            radiusSquaredTerm = Obj.radiusMidNeck .* radiusFlangeMid;

            c12 = 1 ./ (2 * k * n.^2);
            c22 = 1 ./ (k * n);
            d02 = 12 * tiltClosingMoment .* radiusFlangeMid.^2 ./ (Obj.eModulus * Obj.flangeWidth .* Obj.flangeThickness.^3);  % mh:ignore_style
            d11 = 1 ./ (2 * k * n.^3) + radiusSquaredTerm ./ (Obj.eModulus * Obj.flangeWidth .* Obj.flangeThickness);
            d22 = 1 ./ (k * n) + 12 * radiusSquaredTerm ./ (Obj.eModulus * Obj.flangeWidth .* Obj.flangeThickness.^3);

            % Compute the tilt angle (in [rad]) that is being closed by a unity preload force (1 [N])
            unitAngle = d02 .* (c22 .* d11 - c12.^2) ./ (d11 .* d22 - c12.^2);

            % Compute force required to close the input tilt angle
            force = tiltAngle * gapClosingForce ./ unitAngle;
        end

    end

    methods (Static)

        function Obj  = create(Segment)
            Obj = usain.sgre2.FlangeTiltMechanics(Segment.FlangeType);

            Obj.eModulus = Segment.eModulus;
            Obj.flangeThickness = Segment.flangeThickness;
            Obj.neckThickness = Segment.neckThickness;
            Obj.flangeWidth = Segment.flangeWidth;
            Obj.segmentWidth = Segment.segmentWidth;
            Obj.radiusMidNeck = (Segment.diameterOutNeck - Obj.neckThickness) ./ 2;
            Obj.parameterB = Obj.radiusMidNeck - (Segment.diameterBoltCircle ./ 2);
        end

    end

end
