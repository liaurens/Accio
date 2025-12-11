classdef WriteFilesStep_Test < UsainTest.UsainTestCase

    methods (Test, TestTags = {'integration'})

        function run_happy(Obj)
            % TODO: Implement this test after FlangeModel is removed from USAIN framework (WPSSD-5639)
        end

        function run__create_full_file__happy(Obj)
            % TODO: Implement this test after FlangeModel is removed from USAIN framework (WPSSD-5639)
        end

    end

    methods (Test, TestTags = {'unit'})

        function get_usn_file_path__happy(Obj)
            % GIVEN, WHEN, THEN
            Inputs.targetDir = 'c:/foo';
            Inputs.runName = 'bar';
            timeStamp = '1234';

            % WHEN, THEN
            Actual = usain.io.WriteFilesStep().get_usn_file_path(Inputs, timeStamp);
            Obj.assertClass(Actual, 'pathlib.Path');
            Obj.verifyEqual(Actual, pathlib.Path('c:/foo/1234_USAIN_bar.usn'));
        end

        function prepare_selectedmodel_for_saving__skipped_fields(Obj)
            % GIVEN a data struct that represents a SelectedModel
            SelectedModel.Inputs.DO_ASSESS_FLS = false;
            SelectedModel.foo = 'bar';
            SelectedModel.Mdl = 'skipped';
            SelectedModel.bar.StrMdl = 'skipped';
            SelectedModel.Parent.baz = 'skipped';
            SelectedModel.Tab = 'skipped';

            % WHEN
            Actual = usain.io.WriteFilesStep().prepare_selectedmodel_for_saving(SelectedModel);

            % THEN expect some fields to not be present
            Obj.verifyEqual(fieldnames(Actual), {'Inputs', 'foo', 'bar'}');
        end

        function get_structural_model_output_path__optional_key(Obj)
            % GIVEN
            Step = usain.io.WriteFilesStep();
            Runner = runner.SequentialRunner().add(Step);

            % WHEN, THEN
            Obj.verifyEqual(Step.get_structural_model_output_path(), '');

            % WHEN, THEN
            DummyPath = pathlib.Path('c:/foo.bar');
            expected = char(DummyPath);
            Runner.set(usain.DataKeys.StructuralModelOutputPath, DummyPath);
            Obj.verifyEqual(Step.get_structural_model_output_path(), expected);
            Obj.verifyEmpty(Runner.SkippedSteps);
        end

    end

end
