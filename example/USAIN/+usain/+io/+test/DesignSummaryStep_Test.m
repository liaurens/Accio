classdef DesignSummaryStep_Test < UsainTest.UsainTestCase & matlab.mock.TestCase

    methods (Test, TestTags = {'integration'})

        function run__happy(Obj)
            % TODO: Implement this test after FlangeModel is removed from USAIN framework (WPSSD-5639)
        end

    end

    methods (Test, TestTags = {'unit'})

        function print_design_load_summary__happy(Obj)
            % GIVEN inputs to print the design load summary: minimal inputs, a Loads object and a mocked segment model
            FlangeModel = UsainUtils.SelectedModel();

            FlangeModel.Loads.deadWeightFavorDesignUls = 13419400;
            FlangeModel.Loads.inclinMomentDesign = 18100000;
            FlangeModel.Loads.inclinMomentFlsDesign = 1230000;
            FlangeModel.Loads.Inputs.Loads.tag = {'foo'};
            FlangeModel.Loads.maxFlsMxy = 282200000;
            FlangeModel.Loads.maxS1MomentDesign = 1001900000;
            FlangeModel.Loads.Inputs.Loads.ulsFilePath = {'bar'};  % sets nLoadSets
            FlangeModel.Loads.ulsMxyDesign = 425400000;
            FlangeModel.Loads.Fdi = usain.loads.FlangeDamageIndicator();
            FlangeModel.Loads.Fdi.fdi =  1234567890.123;
            FlangeModel.Loads.FdiInverted = usain.loads.FlangeDamageIndicator();
            FlangeModel.Loads.FdiInverted.fdi = 99999;
            FlangeModel.Loads.Inputs.FDI_COEFFICIENT_A1 = 0.1123;
            FlangeModel.Loads.Inputs.FDI_COEFFICIENT_A2 = 0.0003123;
            FlangeModel.Loads.Inputs.DEL_WOHLER_SLOPE = 4.123;

            [SegmentModel, SegmentModelBehavior] = Obj.createMock(?UsainUtils.SegmentModel);
            Obj.assignOutputsWhen(withAnyInputs(SegmentModelBehavior.calc_segment_force()), 123400);
            FlangeModel.Segment = SegmentModel;

            % ... and a custom logger to track/test logged messages
            CustomLogger = logging.Logger.get_logger('test');
            LogHandler = logging.CellArrayHandler();
            CustomLogger.add_handler(LogHandler);
            CustomLogger.parent = [];  % decouple this logger from the root logger (which emits to the stream)
            Step = usain.io.DesignSummaryStep(Logger = CustomLogger);

            % WHEN calling test method and capturing the log output
            Step.print_design_load_summary(FlangeModel);
            logMessages = cellfun(@(x) x.message, LogHandler.buffer, 'UniformOutput', false);
            actual = string(logMessages).split(newline);

            % THEN
            Obj.verifyEqual( ...
                strtrim(actual), ...  % remove leading/trailing whitespace, we don't care about those
                [ ...
                "D E S I G N   L O A D   S U M M A R Y"
                ""
                "LOAD SET #1. . . . . . . . . . . . . . .       foo"
                "DEAD WEIGHT. . . . . . . . . . . . .   13419.4 kN"
                "INCLINATION MOMENT (ULS, S1) . . . .      18.1 MNm"
                "INCLINATION MOMENT (FLS) . . . . . .       1.2 MNm"
                "ULS BENDING MOMENT . . . . . . . . .     425.4 MNm"
                "ULS SEGMENT FORCE. . . . . . . . . .     123.4 kN"
                "S1 BENDING MOMENT. . . . . . . . . .    1001.9 MNm"
                "S1 SEGMENT FORCE . . . . . . . . . .     123.4 kN"
                "MAX. FLS BENDING MOMENT. . . . . . .     282.2 MNm"
                "MAX. FLS SEGMENT FORCE . . . . . . .     123.4 kN"
                "FDI (NORMAL SPECTRUM). . . . . . . . 1.2346e+09"
                "FDI (INVERTED SPECTRUM). . . . . . . 9.9999e+04"
                "COEFFICIENT A1 . . . . . . . . .      0.11"
                "COEFFICIENT A2 . . . . . . . . .   0.00031"
                "WOHLER SLOPE M . . . . . . . . .       4.1"
                ""
                "(values including PSF and macro-geometric SCF, excluding additional SCF)"
                "(inclination loads included in reported segment forces)"
                ""
                ""
                ]);

        end

        function print_design_space_summary__happy(Obj)
            % TODO: Implement this test after FlangeModel is removed from USAIN framework (WPSSD-5639)
        end

        function print_flange_model_summary__happy(Obj)
            % TODO: Implement this test after FlangeModel is removed from USAIN framework (WPSSD-5639)
        end

        function print_mass_summary__happy(Obj)
            % TODO: Implement this test after FlangeModel is removed from USAIN framework (WPSSD-5639)
        end

        function print_utilization_summary__happy(Obj)
            % GIVEN some test conditions in a collection, where only the first is assessed
            FlangeModel.Inputs.DO_ASSESS_NOOP_CONDITION = true;
            FlangeModel.Loads.nLoadSets = 1;
            AssessedCondition = usain.conditions.test.NoopCondition(Mdl = FlangeModel);
            AssessedCondition.evaluate_condition();

            FlangeModel.Inputs.DO_ASSESS_NOOP_CONDITION = false;
            SkippedCondition = usain.conditions.test.NoopCondition(Mdl = FlangeModel);

            FlangeModel.Inputs.DO_ASSESS_NOOP_CONDITION = true;
            FlangeModel.Loads.nLoadSets = 2;
            MultiLoadsCondition = usain.conditions.test.NoopCondition(Mdl = FlangeModel);
            MultiLoadsCondition.evaluate_condition();
            MultiLoadsCondition.utilRatio = [0.12, 3.456789];

            ConditionCollection = usain.conditions.ConditionCollection();
            ConditionCollection = ConditionCollection.append(AssessedCondition);
            ConditionCollection = ConditionCollection.append(SkippedCondition);
            ConditionCollection = ConditionCollection.append(MultiLoadsCondition);

            CustomLogger = logging.Logger.get_logger('test');
            LogHandler = logging.CellArrayHandler();
            CustomLogger.add_handler(LogHandler);
            CustomLogger.parent = [];  % decouple this logger from the root logger (which emits to the stream)
            Step = usain.io.DesignSummaryStep(Logger = CustomLogger);

            % WHEN calling test method and capturing the log output
            Step.print_utilization_summary(ConditionCollection);
            logMessages = cellfun(@(x) x.message, LogHandler.buffer, 'UniformOutput', false);
            actual = string(logMessages).split(newline);

            % THEN
            Obj.verifyLength(actual, 7); % 1 header, 3 conditions, 3 white lines
            Obj.verifySubstring(actual(1), 'U T I L I Z A T I O N   S U M M A R Y');
            Obj.verifySubstring(actual(3), 'JUST A NOOP CONDITION. . . . . . . . . . . . . . . . . . . . OK     -  0.990');  % mh:ignore_style
            Obj.verifySubstring(actual(4), 'JUST A NOOP CONDITION. . . . . . . . . . . . . . . . . . . . N.A.');
            Obj.verifySubstring(actual(5), 'JUST A NOOP CONDITION. . . . . . . . . . . . . . . . . . . . NOT OK -  0.120  3.457');  % mh:ignore_style
        end

        function is_active__true(Obj)

            % GIVEN
            Step = usain.io.DesignSummaryStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.Inputs, struct());
            Runner.set(usain.DataKeys.SelectedConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.SelectedModel, UsainUtils.FlangeModel());
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN, THEN
            Obj.assertTrue(Step.is_active());
        end

        function is_active__false(Obj)

            % GIVEN
            Step = usain.model.SelectBestDesignStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.Inputs, struct());
            Runner.set(usain.DataKeys.SelectedConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.SelectedModel, UsainUtils.FlangeModel());
            Runner.set(usain.DataKeys.hasFeasibleDesign, true);

            % WHEN, THEN
            Obj.assertFalse(Step.is_active());
        end

    end
end
