classdef BoltForceModelFactory < logging.Loggable
    % Factory class for constructing bolt load transfer function instances

    properties (Constant)
        % Valid options for bolt load models
        OPTIONS = ["petersen", "schmidtneuper", "sgre2"]
    end

    methods

        function Model = get_model(Obj, FlangeModel, modelType, preload, gapAngle)
            % Factory method to set up bolt load model instance
            %
            % FlangeModel: FlangeModel instance
            % modelType: Bolt load model type
            % preload: Design preload to be used in bolt load model
            % gapAngle: Single gap angle, required for modelType = 'sgre2' only

            switch lower(modelType)
                case 'petersen'
                    governingFailureMode = UsainUtils.UltimateLimitState.calc_critical_failure_mode(FlangeModel);

                    hasSameGoverninglMode = all(governingFailureMode(:, 1) == governingFailureMode, 2);
                    if ~all(hasSameGoverninglMode)
                        Obj.Logger.warning( ...
                            'USAIN:UltimateLimitState:NonUniformFailureMode', ...  % suppressed during optimization
                            ['Governing ULS failure is not the same for all input load sets. ', ...
                            'For the "petersen" bolt force model, ', ...
                            'the first defined load set (tag: "%s") is used to find the governing failure mode.'], ...
                            FlangeModel.Inputs.Loads.tag{1});
                    end
                    Model = UsainUtils.Petersen.from_flange_model(FlangeModel, preload, governingFailureMode(:, 1));

                case 'schmidtneuper'
                    Model = UsainUtils.SchmidtNeuper.from_flange_model(FlangeModel, preload);

                case 'sgre2'
                    assert(nargin == 5, 'Gap angle must be input.');
                    SegmentModel = usain.model.SegmentModel.create(FlangeModel);

                    Gap = usain.sgre2.GapData( ...
                        gapAngle, SegmentModel.diameterOutNeck, FlangeModel.Inputs.SGRE2.FLATNESS_TOLERANCE);

                    Tilt = usain.sgre2.TiltData( ...
                        FlangeModel.Inputs.SGRE2.FLANGE_TILT_VALUE, ...
                        FlangeModel.Inputs.SGRE2.FLANGE_TILT_UNIT, ...
                        SegmentModel.flangeWidth);

                    % Create local `usain.sgre2.ShellStiffness` instance and compute shell stiffness
                    ShellStiffness = usain.sgre2.ShellStiffness.create(FlangeModel.Inputs.SGRE2.SHELL_STIFFNESS_METHOD);
                    stiffnessShell = ShellStiffness.calc_stiffness( ...
                        SegmentModel.diameterOutNeck, SegmentModel.neckThickness, gapAngle, SegmentModel.eModulus);

                    GapModel = usain.sgre2.GapCloseModel.create(Gap, SegmentModel, preload, stiffnessShell, Tilt, ...
                        FlangeModel.Inputs.SGRE2.GAP_CLOSE_STIFFNESS_RATIO);
                    Model = usain.sgre2.BoltLoadModel.create( ...
                        FlangeModel.Inputs, SegmentModel, GapModel, FlangeModel.Loads.deadWeightFavorDesign, preload);

                otherwise
                    Obj.Logger.error('BoltForceModel:UnsupportedModelType', ...
                        'Model type %s is not supported. Choose from: %s', ...
                        modelType, join(UsainUtils.BoltForceModelFactory.OPTIONS, ', '));
            end
        end

    end
end
