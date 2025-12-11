classdef USAIN_Test < Unittest.TestCase % mh:ignore_style

    methods (TestClassSetup)

        function setup(Obj)
            Obj.testDir = fileparts(mfilename('fullpath'));
        end

    end

    methods (Test, TestTags = {'unit'})

        function all_input_fields_in_template_and_schema__happy(Obj)
            % GIVEN
            testClass = validate.test.CommonTests();
            schema = usain.inputs.get_schema();
            toolName = 'USAIN';

            % WHEN THEN
            testClass.all_input_fields_in_template_and_schema(Obj, schema, toolName);
        end

    end

    methods (Test, TestTags = {'integration'})

        function copy_inputfiles__no_error(Obj)
            % GIVEN
            targetDir = Obj.get_file_path('_generated');

            % WHEN
            fTest = @() USAIN.copy_inputfiles(targetDir);

            % THEN
            outFilePaths = Obj.verify_error_free(fTest);
            Obj.verifyNotEmpty(outFilePaths);
            Obj.verifySize(outFilePaths, [2, 1]);
        end

        function reference_docs__all_inputs_documented(Obj)
            % GIVEN
            % the input variables listed in the USAIN input file template
            Inp = InputFile(USAIN.get_template_path());
            allNames = string(Inp.VarListStruct.varName);
            inputVarNames = allNames(~allNames.endsWith('__'));
            % the input variables documented in docs/reference/inputfile.md
            inputsDoc = fileread(Obj.get_file_path('../docs/reference/inputfile.md'));
            documentedInputs = deblank(string(extractBetween(inputsDoc, '#### `', '`:')));
            % the input variables documented in docs/reference/expert-inputs.md
            expertInputsDoc = fileread(Obj.get_file_path('../docs/reference/expert-inputs.md'));
            documentedExpertInputs = deblank(string(extractBetween(expertInputsDoc, '#### `', '`:')));

            for var = inputVarNames(:)'
                % WHEN we check if a variable in the input file template is also documented in one of the .md files
                % THEN
                Obj.verifyTrue( ...
                    ismember(var, documentedInputs) || ismember(var, documentedExpertInputs), ...
                    sprintf(['Input variable %s does not seem to be documented in either ', ...
                    'docs/reference/inputfile.md or docs/reference/expert-inputs.md.\n', ...
                    'Please make sure to update the documentation when inputs are added.'], var));

                % WHEN we check if a variable is in both .md files
                % THEN
                Obj.verifyFalse( ...
                    ismember(var, documentedInputs) && ismember(var, documentedExpertInputs), ...
                    sprintf(['Input variable %s seems to be documented in BOTH ', ...
                    'docs/reference/inputfile.md and docs/reference/expert-inputs.md.\n', ...
                    'Please make sure to update the documentation.'], var));
            end
        end

        function reference_docs__all_documented_inputs_in_template(Obj)
            % GIVEN
            % the input variables listed in the USAIN input file template
            Inp = InputFile(USAIN.get_template_path());
            allNames = string(Inp.VarListStruct.varName);
            inputVarNames = allNames(~allNames.endsWith('__'));
            % the input variables documented in docs/reference/inputfile.md
            inputsDoc = fileread(Obj.get_file_path('../docs/reference/inputfile.md'));
            documentedInputs = deblank(string(extractBetween(inputsDoc, '#### `', '`:')));
            % the input variables documented in docs/reference/expert-inputs.md
            expertInputsDoc = fileread(Obj.get_file_path('../docs/reference/expert-inputs.md'));
            documentedExpertInputs = deblank(string(extractBetween(expertInputsDoc, '#### `', '`:')));

            documentedInputs = [documentedInputs; documentedExpertInputs]';
            for var = documentedInputs(:)'
                % WHEN we check if a documented variable is also in the input file template
                % THEN
                Obj.verifyTrue( ...
                    ismember(var, inputVarNames), ...
                    sprintf(['Documented input variable %s does not seem to be in the inputfile template.\n', ...
                    'Please make sure to update the inputfile template and/or docs.'], var));
            end
        end

        function verify_changelog_with_tool_version__happy(Obj)
            % GIVEN WHEN comparing the "latest" version in the changelog with the tool version
            ToolVersion = tracking.SemanticVersion(USAIN.VERSION);
            changelogFile = ToolBasis.get_changelog_file('USAIN', 'changelog.yml');
            Changelog = tracking.Changelog.from_file(changelogFile);
            ChangelogVersion = Changelog.Latest;

            % THEN
            Obj.verifyEqual(ToolVersion.major, ChangelogVersion.major);
            Obj.verifyEqual(ToolVersion.minor, ChangelogVersion.minor);
            Obj.verifyEqual(ToolVersion.patch, ChangelogVersion.patch);
        end

        function skip_steps_for_feasible_design__happy(Obj)
            % GIVEN: A runner with steps that would be executed for a T-flange design if no valid L-flange design is
            % found
            ConditionsOnFlangeModel = usain.conditions.get_condition_steps("flangemodel");
            ConditionsOnSelectedModel = usain.conditions.get_condition_steps("selectedmodel");
            steps = {
                usain.io.UpdateInputsForTFlangeStep(), ...
                usain.conditions.ClearConditionCollectionStep(), ...
                usain.io.CrossCheckStep(), ...
                usain.model.FlangeModelStep(), ...
                ConditionsOnFlangeModel{:}, ...
                usain.model.SelectBestDesignStep(), ...
                ConditionsOnSelectedModel{:}, ...
                usain.io.DesignSummaryStep() ...
              };
            Runner = runner.SequentialRunner().add(steps{:});

            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;
            Runner.set(usain.DataKeys.ConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.Inputs, Inputs);
            Runner.set(usain.DataKeys.SelectedConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.hasFeasibleDesign, true);

            % WHEN, THEN: All steps would be skipped
            for iStep = 1:length(steps)
                ActualStep = steps{iStep};
                Obj.assertFalse(ActualStep.is_active());
            end

        end

        function notify_major_version_update__happy(Obj)
            % This is not really a test, more a notification system to inform the developer to update the code where
            % needed when having a major version increase.
            % GIVEN
            ToolVersion = tracking.SemanticVersion(USAIN.VERSION);

            % WHEN, THEN
            msg = "You updated the major version of USAIN. Please make sure to clear the deprecated inputs list.";
            Obj.verifyEqual(ToolVersion.major, 5, msg);
        end

    end

    methods (Test, TestTags = {'system_integration'})

        function test_run__all_files(~)
            % GIVEN all testcases
            testFiles = string(pathlib.Path('$ENGINEERING_CODEBASE_HOME\test_data\usain\happy\').expandvars().glob('testcase*.inp'))';  % mh:ignore_style

            % WHEN THEN
            for testFile = testFiles
                USAIN.run(char(testFile));
            end
        end

        function test_run_batch__all_files(~)
            % GIVEN all testcases
            testFiles = string(pathlib.Path('$ENGINEERING_CODEBASE_HOME\test_data\usain\happy\').expandvars().glob('*testcase*_runner.inp'))';  % mh:ignore_style

            % WHEN THEN
            for testFile = testFiles
                USAIN.run_batch(char(testFile));
            end
        end

    end

end
