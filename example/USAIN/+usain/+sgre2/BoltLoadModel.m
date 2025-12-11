classdef BoltLoadModel < matlab.mixin.SetGet

    properties
        Segment usain.model.SegmentModel
        GapModel usain.sgre2.GapCloseModel

        preload (:, 1) double  % design preload
        deadWeight (:, 1) double  % dead weight per segment (design value, absolute)
        forceGapClose (:, 1) double
        stiffnessCorrectionFactor (:, 1) double

        % bolt force parameters
        polynomialCoeffs (:, 3) double
        initialSlopeForceCurve (:, 1) double
        minBoltForce (:, 1) double

        % bolt moment parameters
        aModified (:, 1) double
        residualMoment (:, 1) double
        initialSlopeMomentCurve (:, 1) double
        minBoltMoment (:, 1) double
    end

    properties (Dependent)
        fullContactCompression (:, 1) double
        preloadRatio (:, 1) double
    end

    properties (Constant)
        DELTA_FORCE = 100  % Used for moment's curve initial slope (finite difference)
    end

    methods

        function value = get.fullContactCompression(Obj)
            % Compute (constant) bolt force for case where compressive loads close gaps fully
            value = -Obj.forceGapClose + -Obj.deadWeight;
        end

        function value = get.preloadRatio(Obj)
            % Compute ratio preload needed to close the gap
            value = Obj.forceGapClose ./ Obj.preload;
            if Obj.Segment.FlangeType == usain.inputs.FlangeType.T
                value = value ./ 2;
            end
        end

        function force = calc_bolt_force(Obj, segmentForce, iCalc)
            % segmentForce: N-by-M array with segment forces for N design points and M load bins
            % iCalc: K-by-1 vector with index mask with to be included design points
            % force: K-by-M array with bolt forces for K design points and M load bins

            if nargin < 3
                iCalc = 1:size(segmentForce, 1);
            end

            % Compute (constant) bolt force for case where compressive loads close gaps fully
            isFullContact = segmentForce(iCalc, :) <= Obj.fullContactCompression(iCalc);
            force = Obj.minBoltForce(iCalc) * ones(1, size(segmentForce, 2));

            % Compute bolt force for compressive loading
            isCompressive = ~isFullContact & segmentForce(iCalc, :) < -Obj.deadWeight(iCalc);
            if any(isCompressive(:))
                boltForceCompression = Obj.calc_bolt_force_compression(segmentForce, iCalc);
                force(isCompressive) = boltForceCompression(isCompressive);
            end

            % Compute bolt force for tensile loading
            isTensile = ~isFullContact & ~isCompressive;
            if any(isTensile(:))
                boltForceTension = Obj.calc_bolt_force_tension(segmentForce, iCalc);
                force(isTensile) = boltForceTension(isTensile);
            end
        end

        function force = calc_bolt_force_compression(Obj, segmentForce, iCalc)
            % Computes bolt force for compressive segment force
            % For args, see method `calc_bolt_force`

            if nargin < 3
                iCalc = 1:size(segmentForce, 1);
            end

            shiftedForce = segmentForce(iCalc, :) - -Obj.deadWeight(iCalc);
            force = Obj.preload(iCalc) + ...
                Obj.initialSlopeForceCurve(iCalc) .* shiftedForce + ...
                Obj.initialSlopeForceCurve(iCalc) ./ (2 * Obj.forceGapClose(iCalc)) .* shiftedForce.^2;
        end

        function force = calc_bolt_force_tension(Obj, segmentForce, iCalc)
            % Computes bolt force for tensile segment force
            % For args, see method `calc_bolt_force`

            if nargin < 3
                iCalc = 1:size(segmentForce, 1);
            end

            % Evaluate 2nd order polynomial
            coeffs = Obj.polynomialCoeffs(iCalc, :);
            force = coeffs(:, 1) + ...
                coeffs(:, 2) .* segmentForce(iCalc, :) + ...
                coeffs(:, 3) .* segmentForce(iCalc, :).^2;
        end

        function moment = calc_bolt_moment(Obj, segmentForce, boltForce, iCalc)
            % segmentForce: N-by-M array with segment forces for N design points and M load bins
            % boltForce: N-by-M array with bolt forces, computed by this class, for N design points and M load bins
            % iCalc: K-by-1 vector with index mask with to be included design points
            % moment: K-by-M array with bolt moments for N design points and M load bins

            assert(all(size(segmentForce) == size(boltForce)), ...
                'BoltLoadModel:InconsistentInputSize', ...
                'Inputs "segmentForce" and "boltForce" must have the same dimensions');

            if nargin < 4
                iCalc = 1:size(segmentForce, 1);
            end

            % Compute (constant) bolt moment for case where compressive loads close gaps fully
            isFullContact = segmentForce(iCalc, :) <= Obj.fullContactCompression(iCalc);
            moment = Obj.minBoltMoment(iCalc) * ones(1, size(segmentForce, 2));

            % Compute bolt moment for compressive loading
            isCompressive = ~isFullContact & segmentForce(iCalc, :) < -Obj.deadWeight(iCalc);
            if any(isCompressive(:))
                momentCompressive = Obj.calc_bolt_moment_compression(segmentForce, iCalc);
                moment(isCompressive) = momentCompressive(isCompressive);
            end

            % Compute bolt moment for tensile loading
            isTensile = ~isFullContact & ~isCompressive;
            if any(isTensile(:))
                momentTensile = Obj.calc_bolt_moment_tension(segmentForce, boltForce, iCalc);
                moment(isTensile) = momentTensile(isTensile);
            end
        end

        function moment = calc_bolt_moment_compression(Obj, segmentForce, iCalc)
            % Computes bolt moment for compressive segment force
            % For args, see method `calc_bolt_moment`

            if nargin < 3
                iCalc = 1:size(segmentForce, 1);
            end

            shiftedForce = segmentForce(iCalc, :) - -Obj.deadWeight(iCalc);
            moment = Obj.residualMoment(iCalc) + ...
                Obj.initialSlopeMomentCurve(iCalc) .* shiftedForce + ...
                Obj.initialSlopeMomentCurve(iCalc) ./ (2 * Obj.forceGapClose(iCalc)) .* shiftedForce.^2;
        end

        function moment = calc_bolt_moment_tension(Obj, segmentForce, boltForce, iCalc)
            % Computes bolt moment for tensile segment force
            % For args, see method `calc_bolt_moment`

            if nargin < 4
                iCalc = 1:size(segmentForce, 1);
            end

            % Shortcuts
            b = Obj.Segment.b(iCalc);
            flexRigidity = Obj.Segment.eModulus .* Obj.Segment.inertiaFlangeRotation(iCalc);

            if Obj.Segment.FlangeType == usain.inputs.FlangeType.L
                axialStiffness = 1 ./ Obj.Segment.resilienceBoltAxial(iCalc);
                moment = ...
                    (2 ./ Obj.Segment.resilienceBoltBending(iCalc)) .* ...
                    (segmentForce(iCalc, :) .* b .* Obj.aModified(iCalc) ./ (Obj.stiffnessCorrectionFactor(iCalc) .* 3 .* flexRigidity) + ...  % mh:ignore_style
                    (boltForce(iCalc, :) - Obj.preload(iCalc)) ./ (Obj.aModified(iCalc) .* 2 .* axialStiffness));

            else
                unitShearAngle = (0.85 * Obj.Segment.gModulus * Obj.Segment.areaTangential(iCalc));

                studRotationLowLoads = (boltForce(iCalc, :) - Obj.preload(iCalc)) .* ...
                    ((b.^2 ./ (2 * flexRigidity)) + (1 ./ unitShearAngle));

                studRotationHighLoads = segmentForce(iCalc, :) .* ...
                    ((b.^2 ./ (Obj.stiffnessCorrectionFactor(iCalc) .* 4 .* flexRigidity)) + (1 ./ unitShearAngle));

                % Interpolate stud rotation between dead weight and "Z2"
                limitLoad = 2 * max(Obj.Segment.ftRd(iCalc), 1.25 * Obj.preload(iCalc));  % = Z_0 for T-flanges
                segmentLoadGapClose = -Obj.deadWeight(iCalc) - Obj.forceGapClose(iCalc);
                % TODO: Make helper method?

                studRotation = studRotationLowLoads + ...
                    (studRotationHighLoads - studRotationLowLoads) ./ (limitLoad - segmentLoadGapClose) .* ...
                    (segmentForce(iCalc, :) - segmentLoadGapClose);
                moment = (2 ./ Obj.Segment.resilienceBoltBending(iCalc)) .* studRotation;
            end
        end

        function initialSlope = calc_initial_slope_force_curve(Obj)
            % Computes initial slope of bolt force curve (when zero net tensile force is acting on flange, i.e. Z =
            % dead weight).
            initialSlope = Obj.polynomialCoeffs(:, 2) + Obj.polynomialCoeffs(:, 3) * 2 .* -Obj.deadWeight;
        end

        function initialSlope = calc_initial_slope_moment_curve(Obj)
            % Computes initial slope of bolt moment curve (when zero net tensile force is acting on flange, i.e. Z =
            % dead weight).

            boltForceDelta = Obj.calc_bolt_force_compression(-Obj.deadWeight + Obj.DELTA_FORCE);
            boltMomentDelta = Obj.calc_bolt_moment_tension(-Obj.deadWeight + Obj.DELTA_FORCE, boltForceDelta);
            initialSlope = (boltMomentDelta - Obj.residualMoment) / Obj.DELTA_FORCE;
        end

        function residualMoment = calc_residual_moment(Obj)
            % Computes residual moment M_0 (when zero net tensile force is acting on flange, i.e. Z = dead weight)

            flexRigidity = Obj.Segment.eModulus .* Obj.Segment.inertiaFlangeRotation;
            b = Obj.Segment.b;
            if Obj.Segment.FlangeType == usain.inputs.FlangeType.L
                residualMoment = (2 * -Obj.deadWeight .* b .* Obj.aModified) ./ ...
                    (Obj.Segment.resilienceBoltBending .* Obj.stiffnessCorrectionFactor .* 3 .* flexRigidity);

            else
                % Make use of fact that, by definition, the flange rotation at low external load is zero when Z = dead
                % weight
                unitShearAngle = (0.85 * Obj.Segment.gModulus * Obj.Segment.areaTangential);

                studRotationHighLoads = -Obj.deadWeight .* ...
                    ((b.^2 ./ (Obj.stiffnessCorrectionFactor .* 4 .* flexRigidity)) + (1 ./ unitShearAngle));

                limitLoad = 2 * max(Obj.Segment.ftRd, 1.25 * Obj.preload);  % = Z_0 for T-flanges
                segmentLoadGapClose = -Obj.deadWeight - Obj.forceGapClose;

                studRotation = studRotationHighLoads ./ (limitLoad - segmentLoadGapClose) .* Obj.forceGapClose;
                residualMoment = (2 ./ Obj.Segment.resilienceBoltBending) .* studRotation;
            end
            % For testing purposes, the code above does the same as
            %    b = Obj.calc_bolt_moment_tension(-Obj.deadWeight, Obj.preload);
            % But is an order of magnitude faster and requires fewer inputs
        end

        function [x, y] = calc_polynomial_coords(Obj, Inputs)
            % Computes coordinates for 'point 1' to determine tensile polynomial

            % Compute coordinates for 'point 1'
            x1 = -Obj.deadWeight;
            y1 = Obj.preload;

            % Compute coordinates for 'point 2'
            y2 = max(Obj.Segment.ftRd, 1.25 * Obj.preload);
            if Obj.Segment.FlangeType == usain.inputs.FlangeType.L
                limitLoad = y2 ./ (1 + (Obj.Segment.b ./ Obj.Segment.aEffective));  % = Z_0
            else
                limitLoad = 2 * y2;  % = Z_0
            end
            x2 = min(limitLoad, ...
                max(limitLoad - Obj.forceGapClose, 0.2 * limitLoad) .* Obj.stiffnessCorrectionFactor);

            % Compute coordinates for 'point 3'
            gapClosingRatio = Obj.preloadRatio ./ Inputs.SGRE2.INITIAL_SLOPE_REFERENCE_PRELOAD;
            maxSlope = (y2 - y1) ./ (x2 - x1);
            if Obj.Segment.FlangeType == usain.inputs.FlangeType.L
                initialSlopeFactor = gapClosingRatio;
            else
                initialSlopeFactor = gapClosingRatio * 0.5;
            end
            initialSlopeModified = min(initialSlopeFactor .* Obj.Segment.loadFactor, maxSlope);

            x3 = Inputs.SGRE2.INITIAL_POINT_OFFSET * limitLoad .* Obj.stiffnessCorrectionFactor;
            y3 = Obj.preload + initialSlopeModified .* (x3 - x1);

            x = [x1, x2, x3];
            y = [y1, y2, y3];
        end

        function bool = is_width_dependent(~, fAppliedMax)
            % See UsainUtils.BoltForceModel.is_width_dependent

            % TODO: Temporary implementation because it is expected by UsainUtils.FatigueLimitState
            bool = true(size(fAppliedMax));
        end

        function report_results(~, ~)
            % NOOP - reporting results is, for now, done in usain.sgre2.FatigueLimitStateWithSgre2_0
            % TODO: Temporary implementation because it is expected by UsainUtils.SelectedModel
        end

    end

    methods (Static)

        function Sgre2Model = create(Inputs, Segment, GapModel, deadWeight, preload)

            % Init empty object
            Sgre2Model = usain.sgre2.BoltLoadModel();

            % Setup gap close model and fill general/shared properties
            Sgre2Model.GapModel = GapModel;
            Sgre2Model.Segment = Segment;
            Sgre2Model.preload = preload;
            Sgre2Model.deadWeight = deadWeight ./ Segment.nSegments;
            Sgre2Model.forceGapClose = GapModel.forceGapClose;
            Sgre2Model.stiffnessCorrectionFactor = GapModel.stiffnessCorrectionFactor;

            % Setup bolt force model
            [x, y] = Sgre2Model.calc_polynomial_coords(Inputs);
            Sgre2Model.polynomialCoeffs = usain.sgre2.solve_quadratic_function(x, y);
            Sgre2Model.initialSlopeForceCurve = Sgre2Model.calc_initial_slope_force_curve();
            Sgre2Model.minBoltForce = Sgre2Model.calc_bolt_force_compression(Sgre2Model.fullContactCompression);

            % Setup bolt moment model
            Sgre2Model.aModified = Segment.calc_a_modified();
            Sgre2Model.residualMoment = Sgre2Model.calc_residual_moment();
            Sgre2Model.initialSlopeMomentCurve = Sgre2Model.calc_initial_slope_moment_curve();
            Sgre2Model.minBoltMoment = Sgre2Model.calc_bolt_moment_compression(Sgre2Model.fullContactCompression);
        end

    end
end
