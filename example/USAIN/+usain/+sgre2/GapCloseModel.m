classdef GapCloseModel < logging.Loggable

    properties
        Gap usain.sgre2.GapData
        Tilt usain.sgre2.TiltData

        forceGapClose (:, 1) double  % Force needed to close the gap ("DeltaZ_gap,tot")
        forceParallelGapClose (:, 1) double  % Force needed to close the initial/parallel gap ("DeltaZ_gap")
        forcePrying (:, 1) double  % Force "lost" due to prying of T-flange on outer edge ("DeltaZ_gap,c")
        forceTiltClose (:, 1) double  % Force needed to close the flange tilt ("DeltaZ_gap,inclination")

        gapCloseFactor (1, 1) double  % Compensation factor on linear assumptions
        gapCloseStiffnessRatio (1, 1) double  % Assumed gap closing ratio between the upper and lower flange
        stiffnessFlange (:, 1) double  % Flange stiffness ("k_fl")
        stiffnessShell (:, 1) double  % Shell stiffness ("k_shell")
        stiffnessGapTotal (:, 1) double  % Total 'gap' stiffness ("k_gap,tot")
        stiffnessSegment (:, 1) double  % Flange segment stiffness ("k_seg")
        stiffnessCorrectionFactor (:, 1) double  % Stiffness correction factor ("alpha_k")
    end

    methods

        function force = calc_gap_closing_force(Obj)
            % Compute force required to, theoretically, close flange gap
            force = max(1000, Obj.forceParallelGapClose) + Obj.forcePrying + Obj.forceTiltClose;

            % Add limitation >= 1kN, to avoid negative gap closing forces
            force = max(1000, force);
        end

        function force = calc_parallel_gap_closing_force(Obj, Segment, gapHeight)
            % Compute force needed to close the initial gap

            force = Obj.gapCloseStiffnessRatio .* Obj.stiffnessGapTotal .* gapHeight .* Segment.segmentWidth;
        end

        function force = calc_prying_force(Obj, Segment, gapHeight, preload)
            % Compute reduced efficiency of gap closing force due to prying at the outer edges of a T-flange connection.
            %
            % The efficiency of the applied preload is reduced when prying starts (i.e. when the outer edge(s) of the
            % T-flanges are in contact).

            % For L-flanges, this effect is not present and therefore `force=0` will be returned.
            if Segment.FlangeType == usain.inputs.FlangeType.L
                force = zeros(size(preload));
                return
            end

            % Compute force at which edge contact occurs
            forceEdgeContact = 0.5 .* gapHeight ./ ( ...
                (Segment.b.^3) ./ (3 * Segment.eModulus .* Segment.inertiaFlangeRotation) + ...
                (Segment.b.^2 .* Segment.a) ./ (2 * Segment.eModulus .* Segment.inertiaFlangeRotation) + ...
                (1.2 * Segment.b) ./ (Segment.gModulus .* Segment.areaTangential) + ...
                1 ./ (Segment.segmentWidth .* (Obj.stiffnessShell + Obj.stiffnessFlange)));

            % Percentage of preload NOT going into tower wall
            deficiencyFactor = ((3 .* Segment.a + 2 .* Segment.b) .* Segment.b.^2) ./ ...
                (2 .* (Segment.a + Segment.b).^3);

            force = max(0, (preload - forceEdgeContact) .* deficiencyFactor);
        end

        function force = calc_tilt_closing_force(Obj, Segment)
            % Compute force required to close flange tilt (=surface inclination)

            TiltModel = usain.sgre2.FlangeTiltMechanics.create(Segment);
            force = TiltModel.calc_tilt_closing_force(Obj.Tilt.angle);

            % For L-flanges, this force is contributing favorably to fatigue capacity
            if Segment.FlangeType == usain.inputs.FlangeType.L
                force = -1 .* force;
            end
        end

        function k = calc_segment_stiffness(Obj, Segment, preload)
            % Computes flange segment stiffness
            %
            % k: N*1 array with segment stiffness, expressed as "line stiffness" [N/m/m]
            % Segment: `usain.model.SegmentModel` instance, with N*1 array properties
            % preload: N*1 array with design preload values

            % Compute theoretical prying force (Z_0), shifted by gap closing force (Z~_2)
            fictitiousResistance = max(Segment.ftRd, 1.25 * preload);
            if Segment.FlangeType == usain.inputs.FlangeType.L
                z0 = fictitiousResistance .* Segment.aEffective ./ (Segment.aEffective + Segment.b);
            else
                z0 = 2 * fictitiousResistance;
            end
            if any(Obj.forceParallelGapClose > z0)
                Obj.Logger.warning('USAIN:GapCloseModel:ExcessiveGapClosingForce', ...
                    ['Force needed to close the %.0fdeg gap exceeds the theoretical prying force (Z_0). ', ...
                    'This is non-physical and hints at an unsound flange design.\nCarefully check the results!'], ...
                    rad2deg(Obj.Gap.angle));
            end

            % Compute flange segment stiffness
            stiffnessBolt = 2 ./ Segment.resilienceBoltAxial;  % half of the stud/bolt
            if Segment.FlangeType == usain.inputs.FlangeType.L
                segmentDisplacement = (Segment.aEffective + Segment.b) .* ( ...
                    (z0 .* Segment.b.^2) ./ (3 * Segment.eModulus .* Segment.inertiaFlangeRotation) + ...
                    (fictitiousResistance - preload) ./ (stiffnessBolt .* Segment.aEffective));
            else
                segmentDisplacement = (fictitiousResistance - preload) ./ stiffnessBolt;
            end
            k = z0 ./ (segmentDisplacement .* Segment.segmentWidth);
        end

        function x = calc_stiffness_correction_factor(Obj, upperLimit)
            % Compute stiffness correction factor, bounded by empirically found upper limit
            x = min( ...
                (Obj.stiffnessSegment + Obj.stiffnessGapTotal) ./ Obj.stiffnessSegment, ...
                upperLimit);
        end

        function k = calc_flange_stiffness(~, Segment, gapAngle)
            % Compute flange bending stiffness according to Misios [1]

            gapLength = Segment.diameterOutNeck / 2 * gapAngle;
            area = Segment.areaCircumferential;

            k = (384 * Segment.eModulus * Segment.inertiaGapClosing * Segment.gModulus .* area) ./ ...
                (gapLength.^2 .* ...
                (Segment.gModulus * area .* gapLength.^2 + 48 * Segment.eModulus * Segment.inertiaGapClosing));

            % [1] Misios, G.: Effect of flange waviness on the C1 wedge connection. Master's Thesis TU Delft 2019
        end

        function x = calc_gap_close_factor(~, gapAngle)
            % Compute "gap close factor", as function of gap angle

            x = min(1.0 + gapAngle / deg2rad(90) * 1.5, 2.5);
        end

        function k = calc_total_gap_stiffness(Obj)
            % Computes total "gap" stiffness = effective average stiffness which needs to be overcome to close the gap
            %
            % k: N*1 array with gap stiffness, expressed as "line stiffness" [N/m/m]
            % Segment: `usain.model.SegmentModel` instance, with N*1 array properties

            % Combine shell and flange stiffness to find linear gap closing stiffness
            k = Obj.gapCloseFactor * (Obj.stiffnessFlange + Obj.stiffnessShell);
        end

    end

    methods (Static)

        function Obj = create(Gap, Segment, preload, stiffnessShell, Tilt, gapCloseStiffnessRatio)
            % Builds model from input args

            Obj = usain.sgre2.GapCloseModel();
            Obj.Gap = Gap;
            Obj.Tilt = Tilt;
            Obj.stiffnessShell = stiffnessShell;
            Obj.gapCloseStiffnessRatio = gapCloseStiffnessRatio;

            % Call gap model parameter calculations in order (considering dependencies)
            Obj.gapCloseFactor = Obj.calc_gap_close_factor(Gap.angle);
            Obj.stiffnessFlange = Obj.calc_flange_stiffness(Segment, Gap.angle);
            Obj.stiffnessGapTotal = Obj.calc_total_gap_stiffness();
            Obj.forceParallelGapClose = Obj.calc_parallel_gap_closing_force(Segment, Gap.height);
            Obj.forceTiltClose = Obj.calc_tilt_closing_force(Segment);
            Obj.forcePrying = Obj.calc_prying_force(Segment, Gap.height, preload);
            Obj.forceGapClose = Obj.calc_gap_closing_force();
            Obj.stiffnessSegment = Obj.calc_segment_stiffness(Segment, preload);

            limit = max(1.5, 4 * 60 / rad2deg(Gap.angle));  % this is an empirically found limit, ref: IEC 61400-6/AMD1
            Obj.stiffnessCorrectionFactor = Obj.calc_stiffness_correction_factor(limit);
        end

    end

end
