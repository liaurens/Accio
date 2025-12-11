classdef Petersen < UsainUtils.BoltForceModel
    % PETERSEN TODO description to be used for T-flanges

    properties
        preload double
        loadFactor double
        lambda double
        zCr
        boltCurveXy double
        boltCurveMrks
    end

    methods

        function Obj = Petersen(varargin)
            if nargin
                Obj = assign_varargin_2_classprop(Obj, varargin{:});
            end
        end

        function fBolt = get_bolt_force(Obj, fApplied, iCalc)
            % See UsainUtils.BoltForceModel.get_bolt_force

            if nargin < 3
                iCalc = 1:size(fApplied, 1);
            end

            % TODO replace with new mex function. Jira WPSSD-7181
            fBolt = Obj.get_bolt_force_m(Obj.preload(iCalc), Obj.loadFactor(iCalc), Obj.lambda(iCalc), fApplied);
        end

        function store_plot_data(Obj, FlangeModel)
            % Store bolt forces and applied loads for Petersen curve fig gen

            % Initialising NAN data for empty bolt force curve
            Obj.boltCurveXy = nan(3, 2);

            % Initialising NAN data for empty bolt force markers
            Obj.boltCurveMrks.fls = nan(1, 2);
            Obj.boltCurveMrks.uls = nan(1, 2);

            % Check for FLS results within USAIN. FLS is leading over
            % ULS to define bolt force curve.
            if FlangeModel.Inputs.DO_ASSESS_FLS

                % Get maximum FLS load for all input load sets
                maxFlsAll = max(FlangeModel.Loads.maxFlsMxy + FlangeModel.Loads.inclinMomentFlsDesign);
                fz = FlangeModel.Loads.deadWeightFavorDesign;
                flsSegmentLoad = FlangeModel.Segment.calc_segment_force(maxFlsAll, -fz);

                sn.fBoltMax(1) = Obj.get_bolt_force_m(Obj.preload, Obj.loadFactor, Obj.lambda, flsSegmentLoad);

                % Get fBolt at knee point zCr
                sn.fBolt = Obj.get_bolt_force_m(Obj.preload, Obj.loadFactor, Obj.lambda, Obj.zCr);

                % Structuring of tri-linear bolt curve data
                Obj.boltCurveXy(:, 1) = [0 Obj.zCr 1.25 * Obj.zCr]';
                Obj.boltCurveXy(:, 2) = [Obj.preload sn.fBolt  1.25 * sn.fBolt]';

                % Store load marker data in terms of bolt and applied segment load
                Obj.boltCurveMrks.fls = [flsSegmentLoad sn.fBoltMax(1)];

                % Add marker data to boltCurve if it is outside the boltCurve
                if flsSegmentLoad > max(Obj.boltCurveXy(:, 1))
                    Obj.boltCurveXy(end + 1, :) = Obj.boltCurveMrks.fls;
                end

                if FlangeModel.Inputs.DO_ASSESS_ULS || FlangeModel.Inputs.DO_ASSESS_ULS_JPN
                    UlsCondit = UsainUtils.UlsCondition.get_uls_condition_for_countrycode( ...
                        FlangeModel.Condit, FlangeModel.Inputs.countryCode);
                    fAppliedUls = max(UlsCondit.fDesign);
                    sn.fBoltMax(2) = Obj.get_bolt_force_m(Obj.preload, Obj.loadFactor, Obj.lambda, fAppliedUls);

                    Obj.boltCurveMrks.uls = [fAppliedUls sn.fBoltMax(2)];

                    % Add marker data to boltCurve if it is outside the boltCurve
                    if fAppliedUls > max(Obj.boltCurveXy(:, 1))
                        Obj.boltCurveXy(end + 1, :) = Obj.boltCurveMrks.uls;
                    end
                end
            end
        end

        function bool = is_width_dependent(~, fAppliedMax)
            % See UsainUtils.BoltForceModel.is_width_dependent

            % This bolt force model is dependent of flange width (hidden in parameter a'), so return TRUE
            bool = true(size(fAppliedMax));
        end

        function str = get_intermediate_results(Obj)
            % Reports summary of bolt force model to log

            str = { ...
                sprintf('Applied bolt force model     |       petersen')
                sprintf('Load factor                  | %14.3f', Obj.loadFactor)
                sprintf('Knee point, Zcr              | %14.0fkN', 1e-3 * Obj.zCr)
                sprintf('Preload                      | %14.0fkN', 1e-3 * Obj.preload)
                };
        end

    end

    methods (Static)

        function Obj = from_flange_model(FlangeModel, preload, governingUlsFailMode)

            % Compute dependencies in Petersen model
            b = FlangeModel.Segment.distForce;
            r = FlangeModel.Inputs.FILLET_RADIUS;
            thkNose = min([FlangeModel.Inputs.thicknNoseUp, FlangeModel.Inputs.thicknNoseLo]);
            bPrime = b - 0.5 .* thkNose - 0.8 .* r;
            effRimDist = FlangeModel.Segment.ReactDist.calc_aeff_tobinaga();

            % Calculate lambda, when the governing ULS failure mode is "A", then set lambda = 1
            lambda = (effRimDist + bPrime) ./ (effRimDist);
            isGoverningModeA = governingUlsFailMode == "A";
            lambda(isGoverningModeA) = 1;

            p = FlangeModel.Segment.loadFactor;
            zCr = preload ./ (lambda .* (1 - p));

            % Construct object
            Obj = UsainUtils.Petersen( ...
                'preload', preload, ...
                'loadFactor', p, ...
                'lambda', lambda, ...
                'zCr', zCr);
        end

        function fBolt = get_bolt_force_m(preload, loadFactor, lambda, fApplied)
            % Matlab-implementation equivalent of UsainUtils.get_bolt_force_petersen_mex
            % TODO make the mex function

            % The model describes two linear curves (f1 and f2) with knee point at Zcr.
            % Since the second part of the model will always be larger than the first part after the knee point,
            % it's possible to simply use max(f1, f2) and by doing so taking out the dependency of Zcr.

            fBolt = max(bsxfun(@plus, preload, bsxfun(@times, loadFactor .* lambda, fApplied)), ...
                bsxfun(@times, lambda, fApplied));

        end

    end
end
