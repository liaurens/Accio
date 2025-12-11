classdef WriteSummaryFileStep_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function get_summary_file_path__expected(Obj)
            % GIVEN
            Inputs.targetDir = 'c:/foo';
            Inputs.runName = 'bar';

            % WHEN, THEN
            Actual = usain.sgre2.WriteSummaryFileStep().get_summary_file_path(Inputs, '1234');
            Obj.assertClass(Actual, 'pathlib.Path');
            Obj.verifyEqual(Actual, pathlib.Path('c:/foo/1234_USAIN_bar_sgre2_summary.xlsx'));
        end

        function is_active__active(Obj)
            % GIVEN a runner with a WriteFilesStep
            Step = usain.sgre2.WriteSummaryFileStep();
            Runner = runner.SequentialRunner().add(Step);

            % WHEN inputs describe an `sgre2` BOLT_FORCE_MODEL as well SGRE2.WRITE_INTERMEDIATE_RESULTS enabled
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS = true;
            Inputs.DO_ASSESS_FLS = true;
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % THEN
            Obj.verifyTrue(Step.is_active());
        end

        function is_active__inactive(Obj)
            % GIVEN a runner with a WriteFilesStep
            Step = usain.sgre2.WriteSummaryFileStep();
            Runner = runner.SequentialRunner().add(Step);

            % WHEN inputs describe no `sgre2` BOLT_FORCE_MODEL
            Inputs.BoltFls.BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS = true;
            Inputs.DO_ASSESS_FLS = true;
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % THEN
            Obj.verifyFalse(Step.is_active());

            % WHEN inputs describe an `sgre2` BOLT_FORCE_MODEL but with SGRE2.WRITE_INTERMEDIATE_RESULTS disabled
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS = false;
            Inputs.DO_ASSESS_FLS = true;
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % THEN
            Obj.verifyFalse(Step.is_active());

            % WHEN inputs describe an `sgre2` BOLT_FORCE_MODEL with SGRE2.WRITE_INTERMEDIATE_RESULTS enabled, but with
            % DO_ASSESS_FLS set to false
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS = true;
            Inputs.DO_ASSESS_FLS = false;
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % THEN
            Obj.verifyFalse(Step.is_active());
        end

    end
end
