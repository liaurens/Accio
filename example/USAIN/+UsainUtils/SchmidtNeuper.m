classdef SchmidtNeuper < UsainUtils.BoltForceModel
    % SCHMIDTNEUPER Schmidt-Neuper tri-linear bolt force model representation
    %   This class describes the model by Schmidt and Neuper that defines a
    %   trilinear relation between the applied force on a flange segment and the
    %   corresponding force in the bolt of that segment, as described in:
    %       Schmidt, H.; Neuper, M. - Zum elastostatischen Tragverhalten
    %       exzentrisch gezogener L-Stoesse mit vorgespannten Schrauben.

    properties
        preload double  % Preload used in this model. Typically, this is the FLS value (90% of nominal)
        loadFactor double   % Load factor, computed with axial resiliences
        lambda double  % Parameter lambda* in Schmidt-Neuper model
        z1 double  % Parameter ZI in Schmidt-Neuper model
        z2 double  % Parameter ZII in Schmidt-Neuper model
        boltCurveXy double  % Schmidt-Neuper bolt force curve values
        boltCurveMrks  % [struct] Max ULS & FLS loads vs bolt force values
    end

    methods

        function Obj = SchmidtNeuper(varargin)
            if nargin
                Obj = assign_varargin_2_classprop(Obj, varargin{:});
            end
        end

        function fBolt = get_bolt_force(Obj, fApplied, iCalc)
            % See UsainUtils.BoltForceModel.get_bolt_force
            %
            % This method calls C-code, for speed
            % The equivalent Matlab-code is found in UsainUtils.SchmidtNeuper.get_bolt_force_m

            if nargin < 3
                % If fApplied is not for the full design space, make sure iCalc is provided!
                iCalc = 1:size(fApplied, 1);
            end

            % Call mex file
            fBolt = UsainUtils.get_bolt_force_schmidt_neuper_mex(Obj.preload(iCalc), ...
                Obj.loadFactor(iCalc), Obj.lambda(iCalc), Obj.z1(iCalc), Obj.z2(iCalc), fApplied);
        end

        function bool = is_width_dependent(Obj, fAppliedMax)
            % See UsainUtils.BoltForceModel.is_width_dependent

            % The first linear region of Schmidt-Neuper is independent of flange width
            bool = fAppliedMax > Obj.z1;
        end

        function store_plot_data(Obj, FlangeModel)
            % Store bolt forces and applied loads for Schmidt-Neuper curve fig gen

            % Initialising NAN data for empty bolt force curve
            Obj.boltCurveXy = nan(4, 2);

            % Initialising NAN data for empty bolt force markers
            Obj.boltCurveMrks.fls = nan(1, 2);
            Obj.boltCurveMrks.uls = nan(1, 2);

            % Check for FLS results within USAIN. FLS is leading over
            % ULS to define bolt force curve.
            if FlangeModel.Inputs.DO_ASSESS_FLS

                % Get maximum FLS load for all input load sets
                % TODO: Instead of get_bolt_force_m, use get_bolt_force (mex function)
                maxFlsAll = max(FlangeModel.Loads.maxFlsMxy + FlangeModel.Loads.inclinMomentFlsDesign);
                fz = FlangeModel.Loads.deadWeightFavorDesign;
                flsSegmentLoad = FlangeModel.Segment.calc_segment_force(maxFlsAll, -fz);
                sn.fBoltMax(1) = Obj.get_bolt_force_m(Obj.preload, Obj.loadFactor, ...
                    Obj.lambda, Obj.z1, Obj.z2, flsSegmentLoad);

                sn.fBolt = Obj.get_bolt_force_m(Obj.preload, Obj.loadFactor, ...
                    Obj.lambda, Obj.z1, Obj.z2, [Obj.z1 Obj.z2]);

                % Structuring of tri-linear bolt curve data
                Obj.boltCurveXy(:, 1) = [0 Obj.z1 Obj.z2 1.25 * Obj.z2]';
                Obj.boltCurveXy(:, 2) = [Obj.preload sn.fBolt(1) sn.fBolt(2) 1.25 * sn.fBolt(2)]';

                % Storing of load marker data in terms of bolt and applied segment load
                Obj.boltCurveMrks.fls = [flsSegmentLoad sn.fBoltMax(1)];

                % Add marker data to boltCurve if it is outside the boltCurve
                if flsSegmentLoad > max(Obj.boltCurveXy(:, 1))
                    Obj.boltCurveXy(end + 1, :) = Obj.boltCurveMrks.fls;
                end

                if FlangeModel.Inputs.DO_ASSESS_ULS || FlangeModel.Inputs.DO_ASSESS_ULS_JPN
                    UlsCondit = UsainUtils.UlsCondition.get_uls_condition_for_countrycode( ...
                        FlangeModel.Condit, FlangeModel.Inputs.countryCode);
                    fAppliedUls = max(UlsCondit.fDesign);
                    sn.fBoltMax(2) = Obj.get_bolt_force_m(Obj.preload, Obj.loadFactor, ...
                        Obj.lambda, Obj.z1, Obj.z2, fAppliedUls);

                    Obj.boltCurveMrks.uls = [fAppliedUls sn.fBoltMax(2)];

                    % Add marker data to boltCurve if it is outside the boltCurve
                    if fAppliedUls > max(Obj.boltCurveXy(:, 1))
                        Obj.boltCurveXy(end + 1, :) = Obj.boltCurveMrks.uls;
                    end
                end
            end
        end

        function str = get_intermediate_results(Obj)
            % Reports summary of bolt force model to log

            str = { ...
                sprintf('Applied bolt force model     |  schmidtneuper')
                sprintf('Load factor                  | %14.3f', Obj.loadFactor)
                sprintf('Knee point, Z1               | %14.0fkN', 1e-3 * Obj.z1)
                sprintf('Knee point, Z2               | %14.0fkN', 1e-3 * Obj.z2)
                sprintf('Preload                      | %14.0fkN', 1e-3 * Obj.preload)
                };
        end

    end

    methods (Static)

        function Obj = from_flange_model(FlangeModel, preload)

            % Compute dependencies in Schmidt-Neuper model. Assign to variables with names equal to that in
            % literature
            a = FlangeModel.Segment.distRim;
            b = FlangeModel.Segment.distForce;
            p = FlangeModel.Segment.loadFactor;
            lambda = (0.7 * a + b) ./ (0.7 * a);
            z1 = preload .* (a - (0.5 * b)) ./ (a + b);
            z2 = preload .* (1 ./ (lambda .* (1 - p)));

            % Construct object
            Obj = UsainUtils.SchmidtNeuper( ...
                'preload', preload, ...
                'loadFactor', p, ...
                'lambda', lambda, ...
                'z1', z1, ...
                'z2', z2);
        end

        function fBolt = get_bolt_force_m(preload, p, lambda, z1, z2, fApplied)
            % Matlab-implementation equivalent of UsainUtils.get_bolt_force_schmidt_neuper_mex

            % Define index mask for applied forces <= first knee point (Z1)
            % Compute bolt forces for this part in Schmidt-Neuper's model. Store
            % to return value (to be modified afterwards)
            fBolt = bsxfun(@plus, preload, bsxfun(@times, p, fApplied));

            % Define index mask for applied forces > first knee point (Z1), but
            % <= second knee point (Z2)
            isIn2 = bsxfun(@gt, fApplied, z1) & bsxfun(@le, fApplied, z2);
            % If any, compute bolt force for this part and modify return value
            if nnz(isIn2) >= 1
                fTemp2 = bsxfun(@plus, preload + (p .* z1), ...
                    bsxfun(@times, (lambda .* z2 - (preload + p .* z1)) ./ (z2 - z1), ...
                    bsxfun(@minus, fApplied, z1)));
                fBolt(isIn2) = fTemp2(isIn2);
            end

            % Define index mask for applied forces > second knee point (Z2)
            isIn3 = bsxfun(@gt, fApplied, z2);
            % If any, compute bolt force for this part and modify return value
            if nnz(isIn3) >= 1
                fTemp3 = bsxfun(@times, lambda, fApplied);
                fBolt(isIn3) = fTemp3(isIn3);
            end
        end

    end
end
