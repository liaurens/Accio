classdef BaseConditionStep_Test < UsainTest.UsainTestCase & matlab.mock.TestCase

    methods (Test, TestTags = {'unit'})

        function is_active__false_has_feasible_design(Obj)

            % GIVEN a sequentual step runner with hasFeasibleDesign set to true
            Step = usain.conditions.test.NoopConditionStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.FlangeModel, UsainUtils.FlangeModel());
            Runner.set(usain.DataKeys.SelectedModel, UsainUtils.FlangeModel());
            Runner.set(usain.DataKeys.hasFeasibleDesign, true);

            % WHEN, THEN
            Obj.assertFalse(Step.is_active());
        end

    end

    methods (Test, TestTags = {'integration'})

        function run__with_flange_model(Obj)
            % GIVEN a sequential step runner with a BaseConditionStep for one condition, and a minimal set of inputs
            Runner = runner.SequentialRunner().add( ...
                usain.conditions.test.NoopConditionStep() ...
                );

            FlangeModel.Inputs.DO_ASSESS_NOOP_CONDITION = true;
            FlangeModel.Space = usain.space.DesignSpace();
            FlangeModel.Space.thickness = 1;  % for getter nPoints
            FlangeModel.Space.index = 123;
            Inputs.DO_UPDATE_DESIGN_SPACE = false;

            Runner.set(usain.DataKeys.ConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.FlangeModel, FlangeModel);
            Runner.set(usain.DataKeys.Inputs, Inputs);
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN, THEN
            Obj.verify_error_free(@() Runner.run());
            Obj.verifyEmpty(Runner.SkippedSteps);
            Obj.verifyEqual(FlangeModel.Space.index, 1);  % verify design space index is reset
        end

        function run__with_selected_model(Obj)
            % GIVEN a sequential step runner with a BaseConditionStep for one condition, and a minimal set of inputs
            Runner = runner.SequentialRunner().add( ...
                usain.conditions.test.NoopConditionStep(doRunOnSelectedModel = true) ...
                );

            SelectedModel.Inputs.DO_ASSESS_NOOP_CONDITION = true;
            SelectedModel.Space = usain.space.DesignSpace();
            SelectedModel.Space.thickness = 1;  % for getter nPoints
            SelectedModel.Space.index = 4;
            Inputs.DO_UPDATE_DESIGN_SPACE = false;

            Runner.set(usain.DataKeys.SelectedConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.SelectedModel, SelectedModel);
            Runner.set(usain.DataKeys.Inputs, Inputs);
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN, THEN
            Obj.verify_error_free(@() Runner.run());
            Obj.verifyEmpty(Runner.SkippedSteps);
            Obj.verifyEqual(SelectedModel.Space.index, 1);  % verify design space index is reset
        end

        function append_condition_collection__happy(Obj)
            % GIVEN a sequential step runner with a BaseConditionStep for one condition, and a minimal set of inputs
            Runner = runner.SequentialRunner().add( ...
                usain.conditions.test.NoopConditionStep() ...
                );

            FlangeModel.Inputs.DO_ASSESS_NOOP_CONDITION = true;
            FlangeModel.Space = usain.space.DesignSpace();
            FlangeModel.Space.thickness = 1;  % for getter nPoints
            Inputs.DO_UPDATE_DESIGN_SPACE = false;

            Runner.set(usain.DataKeys.ConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.FlangeModel, FlangeModel);
            Runner.set(usain.DataKeys.Inputs, Inputs);
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN
            Runner.run();

            % THEN expect the ConditionCollection data key to be appending with a NoopCondition object
            ConditionCollection = Runner.get(usain.DataKeys.ConditionCollection);
            Obj.verifyEqual(length(ConditionCollection.ConditionArray), 1);

            % THEN the condition is appended to the ConditionCollection and also filled with data
            Condition = ConditionCollection.ConditionArray{1};
            Obj.verifyTrue(isa(Condition, 'usain.conditions.test.NoopCondition'));
            Obj.verifyNotEmpty(Condition.utilRatio);

            % WHEN we run it again
            % THEN expect 2 conditions in the ConditionCollection data key
            Runner.run();
            ConditionCollection = Runner.get(usain.DataKeys.ConditionCollection);
            Obj.verifyEqual(length(ConditionCollection.ConditionArray), 2);
        end

        function is_active__false_do_assess_false(Obj)
            % GIVEN a custom logger setup to conveniently capture log messages (and not print them to stream)
            CustomLogger = logging.Logger.get_logger('test');
            LogHandler = logging.CellArrayHandler();
            CustomLogger.add_handler(LogHandler);
            CustomLogger.parent = [];  % decouple this logger from the root logger (which emits to the stream)

            % GIVEN a sequentual step runner where we disable the test condition
            Runner = runner.SequentialRunner(Logger = CustomLogger);
            Runner.add(usain.conditions.test.NoopConditionStep(Logger = CustomLogger));

            FlangeModel.Inputs.DO_ASSESS_NOOP_CONDITION = false;
            FlangeModel.Space.nPoints = 1;

            Runner.set(usain.DataKeys.ConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.FlangeModel, FlangeModel);
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN
            Runner.run();

            % THEN the log messages contains a "skip design condition" message
            logMessages = cellfun(@(x) x.message, LogHandler.buffer, 'UniformOutput', false);
            containsCorrectLogMessage = contains(string(logMessages), ...
                'Skipping evaluation of NOOP condition for testing');
            Obj.verifyTrue(any(containsCorrectLogMessage));

            % THEN the FlangeModel data-key is not updated
            Obj.verifyEqual(Runner.get(usain.DataKeys.FlangeModel), FlangeModel);

            % THEN the condition is appended to the ConditionCollection, but not assessed
            ConditionCollection = Runner.get(usain.DataKeys.ConditionCollection);
            Condition = ConditionCollection.ConditionArray{1};
            Obj.verifyTrue(isa(Condition, 'usain.conditions.test.NoopCondition'));
            Obj.verifyEmpty(Condition.utilRatio);
        end

    end
end
