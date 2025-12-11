classdef CrossCheckStep_Test < UsainTest.UsainTestCase

    methods (TestClassSetup)

        function setup_dir(Obj)
            Obj.testDir = fileparts(mfilename('fullpath'));
        end

    end

    methods (Test, TestTags = {'unit'})

        function convert_scaling_levels__strmdl_happy(Obj)
            % GIVEN
            StructuralModelPath = pathlib.Path(Obj.testDir) / 'data' / 'simple_structural_model.mat';
            Inputs.StrMdl = StructuralModel(StructuralModelPath.char());
            Inputs.Loads.ulsScalingLevel = {{4, 'interface'}, {'towerTop', 7}};
            Inputs.Loads.flsScalingLevel = {{40, 50}, {60, 70}};
            Inputs.Loads.S1ScalingLevel = {{4.1, 'interface'}, {'towerTop', 7.1}};

            % WHEN
            actual = usain.io.CrossCheckStep().convert_scaling_levels(Inputs);

            % THEN
            Obj.assertEqual(actual.Loads.ulsScalingLevel, {[4 -17.300], [-138.540 7]});
            Obj.assertEqual(actual.Loads.flsScalingLevel, {[40 50], [60 70]});
            Obj.assertEqual(actual.Loads.S1ScalingLevel, {[4.1 -17.300], [-138.540 7.1]});
        end

        function convert_scaling_levels__no_strmdl_happy(Obj)
            % GIVEN
            Inputs.StrMdl = [];
            Inputs.Loads.ulsScalingLevel = {{4, 5}, {6, 7}};
            Inputs.Loads.flsScalingLevel = {{40, 50}, {60, 70}};
            Inputs.Loads.S1ScalingLevel = {{1, 2}, {3, 4}};

            % WHEN
            actual = usain.io.CrossCheckStep().convert_scaling_levels(Inputs);

            % THEN
            Obj.assertEqual(actual.Loads.ulsScalingLevel, {[4 5], [6 7]});
            Obj.assertEqual(actual.Loads.flsScalingLevel, {[40 50], [60 70]});
            Obj.assertEqual(actual.Loads.S1ScalingLevel, {[1 2], [3 4]});
        end

        function is_active__true(Obj)

            % GIVEN
            Step = usain.io.CrossCheckStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.Inputs, struct());
            Runner.set(usain.DataKeys.StructuralModel, StructuralModel());
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN, THEN
            Obj.assertTrue(Step.is_active());
        end

        function is_active__false(Obj)

            % GIVEN
            Step = usain.io.CrossCheckStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.Inputs, struct());
            Runner.set(usain.DataKeys.StructuralModel, StructuralModel());
            Runner.set(usain.DataKeys.hasFeasibleDesign, true);

            % WHEN, THEN
            Obj.assertFalse(Step.is_active());
        end

    end
end
