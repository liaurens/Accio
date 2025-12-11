classdef SelectedModelInputs_Test < UsainTest.UsainTestCase & matlab.mock.TestCase

    methods (TestClassSetup)

        function setup_dir(Obj)
            Obj.testDir = fileparts(mfilename('fullpath'));
        end

    end

    methods (Test, TestTags = {'unit'})

        function convert_inputs_from_si_units_schema__happy(Obj)
            % GIVEN inputs from fixture, which are already in SI units (representing parsed inputs)
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;

            % AND using two BoltFls blocks (also representing parsed inputs)
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.BoltFls(1).CUSTOM_PRELOAD = nan;
            Inputs.BoltFls(1).PSF_BOLT_MATERIAL_FLS = 1.25;
            Inputs.BoltFls(1).SN_CURVE_BOLT = "EC3_DC36*";
            Inputs.BoltFls(1).THICKNESS_EXPONENT_BOLT = 0.25;
            Inputs.BoltFls(1).TARGET_PM_SUM = 0.9;

            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "sgre2";
            Inputs.BoltFls(2).CUSTOM_PRELOAD = [1.234e6 5.678e6];
            Inputs.BoltFls(2).PSF_BOLT_MATERIAL_FLS = 1.1;
            Inputs.BoltFls(2).SN_CURVE_BOLT = "EC3_DC50";
            Inputs.BoltFls(2).THICKNESS_EXPONENT_BOLT = 0.10;
            Inputs.BoltFls(2).TARGET_PM_SUM = 1.0;

            % AND two load sets
            Inputs.Loads.inclinationValue = [0.01309, 0.01];
            Inputs.Loads.inclinationValueFls = [0.002182, 0];
            Inputs.Loads.inclinationUnit = {'deg', 'mm_m'};

            % WHEN
            SelectedModelInputs = usain.io.SelectedModelInputs(Inputs = Inputs);
            SelectedModelInputs.convert_inputs_from_si_units();

            % THEN perform spot checks on inputs with and without conversion factor
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.diameter, 8000);
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.thicknNoseLo, 100);
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.zFlange, 0);
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.REACTION_DISTANCE_METHOD, 'tobinaga');
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.SGRE2.FLANGE_TILT_VALUE, 0.2);
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.Loads.inclinationValue, [0.75, 10], 'RelTol', 1e-3);
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.Loads.inclinationValueFls, [0.125, 0], 'RelTol', 1e-3);

            % AND in particular verify the BoltFls block, for which only `CUSTOM_PRELOAD` has unit conversion.
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.BoltFls(1).BOLT_FORCE_MODEL, "schmidtneuper");
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.BoltFls(2).BOLT_FORCE_MODEL, "sgre2");
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.BoltFls(1).CUSTOM_PRELOAD, nan);
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.BoltFls(2).CUSTOM_PRELOAD, [1234 5678]);
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.BoltFls(1).PSF_BOLT_MATERIAL_FLS, 1.25);
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.BoltFls(2).PSF_BOLT_MATERIAL_FLS, 1.1);
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.BoltFls(1).SN_CURVE_BOLT, "EC3_DC36*");
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.BoltFls(2).SN_CURVE_BOLT, "EC3_DC50");
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.BoltFls(1).THICKNESS_EXPONENT_BOLT, 0.25);
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.BoltFls(2).THICKNESS_EXPONENT_BOLT, 0.1);
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.BoltFls(1).TARGET_PM_SUM, 0.9);
            Obj.verifyEqual(SelectedModelInputs.ConvertedInputs.BoltFls(2).TARGET_PM_SUM, 1.0);
        end

        function create_filecontent__happy(Obj)
            % GIVEN a set of inputs (from a fixture)
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            FakeSourceFilePath = 'c:/foo.bar';

            % WHEN creating the file content for a selected model input file using these inputs
            Actual = usain.io.SelectedModelInputs(Inputs = Inputs).create_filecontent(FakeSourceFilePath);

            % THEN
            Obj.assertClass(Actual, 'InputFile');
            Obj.verifyNotEmpty(Actual.fileContent);
            Obj.verifyTrue(any(startsWith(Actual.fileContent, '<START>')));
            Obj.verifyTrue(any(startsWith(Actual.fileContent, '<END>')));
            Obj.verifyTrue(any(startsWith(Actual.fileContent, 'zFlange')));
            Obj.verifyTrue(any(startsWith(Actual.fileContent, 'SGRE2.FLANGE_TILT_VALUE')));
            Obj.verifyTrue(any(startsWith(Actual.fileContent, 'SGRE2.FLANGE_TILT_UNIT')));
            Obj.verifyTrue(any(startsWith(Actual.fileContent, 'Loads.inclinationValue')));
            Obj.verifyTrue(any(startsWith(Actual.fileContent, 'Loads.inclinationUnit')));
        end

        function create_filecontent__multiple_loads_blocks(Obj)
            % GIVEN a set of inputs with 2 Loads.* input blocks
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.Loads.tag = {'foo', 'bar'};
            Inputs.Loads.flsFilePath = {'f/o.o', 'b/a.r'};
            Inputs.Loads.flsScalingFactor = {[1 1], [1.2 1.3]};
            Inputs.Loads.flsScalingLevel = {[-200 200], [-200 200]};
            Inputs.Loads.ulsFilePath = {'f/o.o', 'b/a.r'};
            Inputs.Loads.ulsScalingFactor = {[1 1], [1.2 1.3]};
            Inputs.Loads.ulsScalingLevel = {[-200 200], [-200 200]};
            Inputs.Loads.inclinationValue = [1.2, 3.4];
            Inputs.Loads.inclinationUnit = {'deg', 'mm_m'};
            Inputs.Loads.dlcFilter = {'foo', 'bar'};
            FakeSourceFilePath = 'c:/foo.bar';

            % WHEN creating the file content for a selected model input file using these inputs
            Actual = usain.io.SelectedModelInputs(Inputs = Inputs).create_filecontent(FakeSourceFilePath);

            % THEN
            Obj.assertClass(Actual, 'InputFile');
            Obj.verifyTrue(any(startsWith(Actual.fileContent, 'Loads.inclinationValue(1)')));
            Obj.verifyTrue(any(startsWith(Actual.fileContent, 'Loads.inclinationValue(2)')));
            Obj.verifyTrue(any(startsWith(Actual.fileContent, 'Loads.inclinationUnit(1)')));
            Obj.verifyTrue(any(startsWith(Actual.fileContent, 'Loads.inclinationUnit(2)')));
        end

        function create_filecontent__multiple_boltfls_blocks(Obj)
            % GIVEN a set of inputs (from a fixture)
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;

            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.BoltFls(1).CUSTOM_PRELOAD = nan;
            Inputs.BoltFls(1).PSF_BOLT_MATERIAL_FLS = 1.25;
            Inputs.BoltFls(1).SN_CURVE_BOLT = "EC3_DC36*";
            Inputs.BoltFls(1).THICKNESS_EXPONENT_BOLT = 0.25;
            Inputs.BoltFls(1).TARGET_PM_SUM = 0.9;

            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "sgre2";
            Inputs.BoltFls(2).CUSTOM_PRELOAD = [1.234e6 5.678e6];
            Inputs.BoltFls(2).PSF_BOLT_MATERIAL_FLS = 1.1;
            Inputs.BoltFls(2).SN_CURVE_BOLT = "EC3_DC50";
            Inputs.BoltFls(2).THICKNESS_EXPONENT_BOLT = 0.10;
            Inputs.BoltFls(2).TARGET_PM_SUM = 1.0;

            FakeSourceFilePath = 'c:/foo.bar';

            % WHEN creating the file content for a selected model input file using these inputs
            Actual = usain.io.SelectedModelInputs(Inputs = Inputs).create_filecontent(FakeSourceFilePath);

            % THEN
            Obj.assertClass(Actual, 'InputFile');
            Obj.verifyTrue(any(startsWith(Actual.fileContent, 'BoltFls.CUSTOM_PRELOAD(1)')));
            Obj.verifyTrue(any(startsWith(Actual.fileContent, 'BoltFls.CUSTOM_PRELOAD(2)')));
        end

        function get_input_field_names__happy(Obj)
            % GIVEN dummy inputs
            Inputs.foo = 'foo';
            Inputs.bar = 'bar';
            Inputs.flangeMatrDesignation = 'this will be skipped';

            % WHEN, THEN
            actual = usain.io.SelectedModelInputs().get_input_field_names(Inputs);
            Obj.verifySize(actual, [1, 2]);
            Obj.verifyTrue(any(actual.contains('foo')));
            Obj.verifyTrue(any(actual.contains('bar')));
            Obj.verifyFalse(any(actual.contains('flangeMatrDesignation')));
        end

        function write_file__happy(Obj)
            % GIVEN a dummy InputFile object with a set target file path pointing to a file that does not exist
            [Stub, Behavior] = Obj.createMock(?usain.io.SelectedModelInputs);
            TargetPath = pathlib.Path(Obj.testDir) / '_generated' / 'test_write_file.inp';
            Obj.assignOutputsWhen(withAnyInputs(Behavior.get_target_file_path()), TargetPath);

            InputFileObj = InputFile();
            InputFileObj.fileContent = {'<START>'; '<END>'};
            InputFileObj.targetFilePath = char(TargetPath);

            if TargetPath.exists()
                delete(char(TargetPath));
            end

            % WHEN, THEN
            Actual = Stub.write_file(InputFileObj);
            Obj.verifyTrue(Actual.is_file());
            Obj.verifyTrue(Actual.exists());
        end

        function get_target_file_path__happy(Obj)
            % GIVEN
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.targetDir = 'c:/foo';
            Inputs.runName = 'bar';
            SelectedModelInputs = usain.io.SelectedModelInputs(Inputs = Inputs, timeStamp = '1234');

            % WHEN, THEN
            Actual = SelectedModelInputs.get_target_file_path();
            Obj.assertClass(Actual, 'pathlib.Path');
            Obj.verifyEqual(Actual, pathlib.Path('c:/foo/1234_USAIN_bar_selectedMdl.inp'));
        end

        function mark_input_file__happy(Obj)
            % GIVEN a dummy/fake InputFile object
            FakeInputFile.fileContent = { ...
                'inputFile : USAIN'
                'toolVersion : 1.2.3'
                ''
                '<START>'
                'foo : bar'
                '<END>'
              };

            % WHEN marking the (fake) input file
            SelectedModelInputs = usain.io.SelectedModelInputs(timeStamp = '1234');
            FakeSourceFilePath = 'c:/foo.bar';
            Actual = SelectedModelInputs.mark_input_file(FakeInputFile, FakeSourceFilePath);

            % THEN
            Obj.verifyTrue(startsWith(Actual.fileContent{1}, '% Input file auto-generated on'));
            Obj.verifyEqual(Actual.fileContent{2}, '% Source USAIN input file: c:/foo.bar');
            Obj.verifyEqual(Actual.fileContent{3}, '');
        end

    end

end
