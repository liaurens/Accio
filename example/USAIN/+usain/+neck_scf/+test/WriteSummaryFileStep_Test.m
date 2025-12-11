classdef WriteSummaryFileStep_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function get_summary_file_path__expected(Obj)
            % GIVEN
            Inputs.targetDir = 'c:/foo';
            Inputs.runName = 'bar';

            % WHEN, THEN
            Actual = usain.neck_scf.WriteSummaryFileStep().get_summary_file_path(Inputs, '1234');
            Obj.assertClass(Actual, 'pathlib.Path');
            Obj.verifyEqual(Actual, pathlib.Path('c:/foo/1234_USAIN_bar_flange_neck_scf_summary.xlsx'));
        end

        function is_active__active(Obj)
            % GIVEN a runner with a WriteFilesStep
            Step = usain.neck_scf.WriteSummaryFileStep();
            Runner = runner.SequentialRunner().add(Step);

            % WHEN inputs describe a flange neck bending stress assessment, with writing intermediate results
            Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS = true;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = true;
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % THEN
            Obj.verifyTrue(Step.is_active());
        end

        function is_active__inactive(Obj)
            % GIVEN a runner with a WriteFilesStep
            Step = usain.neck_scf.WriteSummaryFileStep();
            Runner = runner.SequentialRunner().add(Step);

            % WHEN inputs describe not to do a flange neck bending stress assessment
            Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS = true;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % THEN
            Obj.verifyFalse(Step.is_active());

            % WHEN inputs describe to do a flange neck bending stress assessment, without writing intermediate results
            Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS = false;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = true;
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % THEN
            Obj.verifyFalse(Step.is_active());
        end

    end
end
