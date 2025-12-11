classdef BoltOptionsParser_Test < Unittest.TestCase

    properties (TestParameter)
        validFormat = {'HV_M42' 'HV_M42x100' 'HV_M42x100x50'}
        invalidFormat = {'M42' 'HV M42' 'HV_M42_100' 'HV_M42x100x50x30'}
        invalidAttr = {''}
        invalidType = {1, false, nan, Inf}
        validThreadLength = {'ISO_M42x280', 'HV_M64x500', 'ISO_M64x500x250'}
        invalidThreadLength = {'HV_M42x280x281'}
    end

    methods (Test, TestTags = {'unit'}, ParameterCombination = 'sequential')

        function verify_feasible_thread_length__happy(Obj, validThreadLength)
            % GIVEN WHEN THEN
            Test = usain.fastener.BoltOptionsParser(validThreadLength);
            [pass, msg] = Test.verify_feasible_thread_length();
            Obj.assertTrue(pass);
            Obj.assertEmpty(msg);
        end

        function verify_feasible_thread_length__invalid_thread_length(Obj, invalidThreadLength)
            % GIVEN WHEN THEN
            Test = usain.fastener.BoltOptionsParser(invalidThreadLength);
            [pass, msg] = Test.verify_feasible_thread_length();
            Obj.assertFalse(pass);
            Obj.assertNotEmpty(msg);
        end

        function validate_format__invalid_format(Obj, invalidFormat)
            % GIVEN WHEN THEN
            Test = usain.fastener.BoltOptionsParser(invalidFormat);
            f = @() Test.validate_format();
            Obj.assertError(f, 'BoltOptionsParser:InvalidFormat');
        end

        function validate_format__happy(Obj, validFormat)
            % GIVEN WHEN THEN
            Test = usain.fastener.BoltOptionsParser(validFormat);
            f = @() Test.validate_format();
            Obj.verify_error_free(f);
        end

        function set_input__conversion_to_cellstr(Obj)
            % GIVEN a char input
            Test = usain.fastener.BoltOptionsParser('test');

            % WHEN THEN
            Obj.assertTrue(iscellstr(Test.input));
        end

        function set_input__wrong_attributes(Obj, invalidAttr)
            % GIVEN WHEN THEN
            f = @() usain.fastener.BoltOptionsParser(invalidAttr);
            Obj.assertError(f, 'MATLAB:expectedNonempty');
        end

        function set_input__wrong_type(Obj, invalidType)
            % GIVEN WHEN THEN
            f = @() usain.fastener.BoltOptionsParser(invalidType);
            Obj.assertError(f, 'MATLAB:invalidType');
        end

        function get_boltSizeString__happy(Obj, validFormat)
            % GIVEN WHEN THEN
            Test = usain.fastener.BoltOptionsParser(validFormat);
            actual = Test.boltSizeString{1};
            expected = 'M42';
            Obj.assertEqual(actual, expected);
        end

        function get_label__happy(Obj, validFormat)
            % GIVEN WHEN THEN
            Test = usain.fastener.BoltOptionsParser(validFormat);
            actual = Test.label{1};
            expected = 'HV_M42';
            Obj.assertEqual(actual, expected);
        end

        function get_diameter__happy(Obj)
            % GIVEN, WHEN, THEN
            Obj.assertEqual(usain.fastener.BoltOptionsParser('ISO_M80').diameter, 0.080, 'AbsTol', 1e-8);
            Obj.assertEqual(usain.fastener.BoltOptionsParser('ISO_M80x600').diameter, 0.080, 'AbsTol', 1e-8);
            Obj.assertEqual(usain.fastener.BoltOptionsParser('ISO_M80x600x123').diameter, 0.080, 'AbsTol', 1e-8);
        end

        function get_inputBoltLength__defined_in_input(Obj)
            % GIVEN WHEN THEN
            Test = usain.fastener.BoltOptionsParser('ISO_M80x600');
            actual = Test.inputBoltLength;
            expected = 0.600;
            Obj.assertEqual(actual, expected);
        end

        function get_inputBoltLength__not_defined_in_input(Obj)
            % GIVEN WHEN THEN
            Test = usain.fastener.BoltOptionsParser('ISO_M80');
            actual = Test.inputBoltLength;
            expected = nan;
            Obj.assertEqual(actual, expected);
        end

        function get_inputThreadLength__defined_in_input(Obj)
            % GIVEN WHEN THEN
            Test = usain.fastener.BoltOptionsParser('JIS_M12x345x678');
            actual = Test.inputThreadLength;
            expected = 0.678;
            Obj.assertEqual(actual, expected);
        end

        function get_inputThreadLength__not_defined_in_input(Obj)
            % GIVEN WHEN THEN
            Test = usain.fastener.BoltOptionsParser('JIS_M12x345');
            actual = Test.inputThreadLength;
            expected = nan;
            Obj.assertEqual(actual, expected);
        end

        function get_nOptions__happy(Obj)
            % GIVEN WHEN THEN
            Test = usain.fastener.BoltOptionsParser('ISO_M12x34');
            Obj.assertEqual(Test.nOptions, 1);

            % WHEN defining multiple
            % THEN
            Test = usain.fastener.BoltOptionsParser({'ISO_M12x34', 'ISO_M56x78'});
            Obj.assertEqual(Test.nOptions, 2);
        end

        function get_isStandardBoltLength__happy(Obj)
            % GIVEN inputs with and without standard bolt length, and with no length defined
            Test = usain.fastener.BoltOptionsParser({'ISO_M64x400', 'ISO_M56x78', 'HV_M42'});

            % WHEN THEN
            Obj.assertTrue(Test.isStandardBoltLength(1));
            Obj.assertFalse(Test.isStandardBoltLength(2));
            Obj.assertFalse(Test.isStandardBoltLength(3));
        end

        function get_isStandardThreadLength__happy(Obj)
            % GIVEN inputs with and without standard thread length, and with no length defined
            Test = usain.fastener.BoltOptionsParser({'ISO_M64x400x180', 'ISO_M64x400x181', 'HV_M42', 'HV_M42x123'});

            % WHEN THEN
            Obj.assertTrue(Test.isStandardThreadLength(1));
            Obj.assertFalse(Test.isStandardThreadLength(2));
            Obj.assertFalse(Test.isStandardThreadLength(3));
            Obj.assertFalse(Test.isStandardThreadLength(4));
        end

    end
end
