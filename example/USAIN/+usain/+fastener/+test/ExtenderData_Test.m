classdef ExtenderData_Test < Unittest.TestCase
    % See also: usain.fastener.test.BaseCatalogData_Test

    methods (Test, TestTags = {'unit'})

        function get_length_options__input_nonnan(Obj)
            % GIVEN a bolt label and a step size for extender lengths
            inputLength = 20e-3;
            label = 'ISO_M42';
            stepSize = 10e-3;

            % WHEN, THEN
            actual = usain.fastener.ExtenderData.get_length_options(inputLength, label, stepSize);
            Obj.assertEqual(actual, inputLength);
        end

        function get_length_options__input_nan(Obj)
            % GIVEN a bolt label and a step size for extender lengths
            inputLength = nan;
            label = 'ISO_M42';
            stepSize = 10e-3;

            % WHEN
            actual = usain.fastener.ExtenderData.get_length_options(inputLength, label, stepSize);

            % THEN we expect a zero first, and then values > 10mm < 2*D in steps of 5mm
            expected = 1e-3 * [0, 10, 20, 30, 40, 50, 60, 70, 80];
            Obj.assertEqual(actual, expected);
        end

        function validate_extender_length__happy(Obj)
            % GIVEN valid inputs
            % WHEN calling the test method without output arguments
            % THEN we expect no errors
            usain.fastener.ExtenderData.validate_extender_length(NaN, {'ISO_M72'});
            usain.fastener.ExtenderData.validate_extender_length([NaN, NaN], {'ISO_M72', 'HV_M42'});
            usain.fastener.ExtenderData.validate_extender_length([0.015, 0], {'ISO_M64', 'JIS_M64'});
            usain.fastener.ExtenderData.validate_extender_length([0, 0], {'JIS_M42', 'ISO_M80'});

            % WHEN calling the test method with output arguments
            % THEN we expect a function handle to be returned
            actual = usain.fastener.ExtenderData.validate_extender_length(NaN, {'ISO_M72'});
            Obj.assertInstanceOf(actual, 'function_handle');
        end

        function validate_extender_length__invalid_length(Obj)
            % GIVEN invalid inputs
            % WHEN, THEN
            expectedErrorId = 'ExtenderData:validate_extender_length:ValidationError';
            Obj.assertError( ...
                @() usain.fastener.ExtenderData.validate_extender_length(0.150, {'ISO_M72'}), ...
                expectedErrorId);
            Obj.assertError( ...
                @() usain.fastener.ExtenderData.validate_extender_length([0.100, 0.123], {'HV_M48', 'HV_M42'}), ...
                expectedErrorId);
            Obj.assertError( ...
                @() usain.fastener.ExtenderData.validate_extender_length(0.008, {'ISO_M64'}), ...
                expectedErrorId);
            Obj.assertError( ...
                @() usain.fastener.ExtenderData.validate_extender_length(0.020, {'ISO_M80'}), ...
                expectedErrorId);
            Obj.assertError( ...
                @() usain.fastener.ExtenderData.validate_extender_length(0.020, {'JIS_M56'}), ...
                expectedErrorId);
        end

        function calc_mass__happy(Obj)
            % GIVEN an ISO M72 extender with 50mm length
            Lib = usain.fastener.CatalogLibrary.get_library();
            Extender = Lib.Extenders.select('label', 'ISO_M72');
            Extender.len = 0.050;

            % WHEN, THEN
            actual = usain.fastener.ExtenderData.calc_mass(Extender.diamOut, Extender.diamIn, Extender.len);
            expected = 3.47573;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-5);

            % TEARDOWN reset catalog data (because it is a singleton class)
            Lib.set_clean_data();
        end

    end

end
