classdef (SharedTestFixtures = {fixtures.SilentlyLogFixture(logging.Level.WARNING)}) ...
    AInputsDataClass_Test < Unittest.TestCase % mh:ignore_style

    methods

        function inputData = get_data_for_test_dataclass(~)
            % Happy case test data to be used for `usain.inputs.run_dataclass.test.TestDataClass`
            inputData = struct();
            inputData.boltOptions = {'ISO_M72'};
            inputData.site = 'offshore';
            inputData.tighteningMethod = {'tension'};
            inputData.zFlange = 0;
            inputData.flangeType = 'L';

            inputData.diameter = 7000;
        end

    end

    methods (Test, TestTags = {'unit'})

        function get_optional_inputs__happy(Obj)
            % GIVEN a input data structure, where we set 2 optional inputs: minFlangeWidth and STEPSIZE_WIDTH
            inputData = Obj.get_data_for_test_dataclass();
            inputData.OptionalInputs.minFlangeWidth = 500;
            inputData.OptionalInputs.STEPSIZE_WIDTH = 10;
            DC = usain.inputs.run_dataclass.test.TestDataClass(inputData);

            % WHEN
            actual = DC.get_optional_inputs();

            % THEN
            Obj.assertEqual(actual, inputData.OptionalInputs);
        end

        function get_optional_inputs__unknown_input(Obj)
            % GIVEN a input data structure, where we set 2 optional inputs: minFlangeWidth and unknown DOES_NOT_EXIST
            inputData = Obj.get_data_for_test_dataclass();
            inputData.OptionalInputs.minFlangeWidth = 500;
            inputData.OptionalInputs.DOES_NOT_EXIST = 10;
            DC = usain.inputs.run_dataclass.test.TestDataClass(inputData);

            % WHEN THEN
            Obj.assertRaisesMessageRegex(@() DC.get_optional_inputs(), ...
                "'DOES_NOT_EXIST' is not a valid USAIN input field");
        end

        function get_all_inputs__happy(Obj)
            % GIVEN a input data structure, where we set 2 optional inputs: minFlangeWidth and STEPSIZE_WIDTH
            inputData = Obj.get_data_for_test_dataclass();
            inputData.OptionalInputs.minFlangeWidth = 987;
            inputData.OptionalInputs.STEPSIZE_WIDTH = 10;
            DC = usain.inputs.run_dataclass.test.TestDataClass(inputData);

            % WHEN
            actual = DC.get_all_inputs();

            % THEN check that the number of fields in actual is the same number of inputs defined in the schema
            Obj.assertEqual(numel(fieldnamesr(actual)), usain.inputs.get_schema().fields.numEntries);

            % THEN spot check if a default from the schema is correctly assigned
            Obj.assertEqual(actual.runName, '');

            % THEN check that a given optional value is used
            Obj.assertEqual(actual.minFlangeWidth, 987);

        end

        function to_struct__happy(Obj)
            % GIVEN
            inputData = Obj.get_data_for_test_dataclass();
            inputData.OptionalInputs.minFlangeWidth = 500;
            DC = usain.inputs.run_dataclass.test.TestDataClass(inputData);

            % WHEN
            actual = DC.to_struct();

            % THEN
            Obj.assertEqual(actual.tighteningMethod, {'tension'}); % spot check
            Obj.assertFalse(isfield(actual, 'OptionalInputs'));
        end

    end
end
