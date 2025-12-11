classdef WriteSelectedModelInputFileStep_Test < UsainTest.UsainTestCase

    methods (TestClassSetup)

        function setup_dir(Obj)
            Obj.testDir = fileparts(mfilename('fullpath'));
        end

    end

    methods (Test, TestTags = {'integration'})

        function run__happy(Obj)
            % GIVEN a sequential runner with just the step for this test class and set inputs such that the step can run
            Runner = runner.SequentialRunner().add( ...
                usain.io.WriteSelectedModelInputFileStep() ...
                );

            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.targetDir = char(pathlib.Path(Obj.testDir) / '_generated');
            SelectedModel.Inputs = Inputs;
            Runner.set(usain.DataKeys.SelectedModel, SelectedModel);
            % NOTE: WriteSelectedModelInputFileStep takes inputs from SelectedModel (see also TODO in Step class)
            Runner.set(usain.DataKeys.SourceInputFilePath, 'some_dummy_source_file_path.inp');
            Runner.set(usain.DataKeys.TimeStamp, '1234');

            % WHEN, THEN
            Runner.run();
            Obj.verifyEmpty(Runner.SkippedSteps);
            Obj.verifyTrue(Runner.is_gettable(usain.DataKeys.SelectedModelInputFilePath));
        end

    end

end
