classdef BoltSpecificationString_Test < matlab.unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function constructor__empty_if_no_args(Obj)
            % GIVEN, WHEN, THEN
            Test = usain.fastener.BoltSpecificationString();
            Obj.assertEmpty(Test.specification);
        end

        function constructor__invalid_types(Obj)
            % GIVEN, WHEN, THEN
            Obj.assertError(@() usain.fastener.BoltSpecificationString(1, 0.400, 0.130), '');
            Obj.assertError(@() usain.fastener.BoltSpecificationString('HV_M42', '0.400', 0.130), '');
            Obj.assertError(@() usain.fastener.BoltSpecificationString('HV_M42', 0.400, '0.130'), '');
        end

        function constructor__standard_thread_length(Obj)
            % GIVEN, WHEN, THEN
            Test = usain.fastener.BoltSpecificationString('ISO_M72', 0.500, 0.200);
            expected = 'ISO_M72x500';
            Obj.assertEqual(Test.specification, expected);
        end

        function constructor__nonstandard_thread_length(Obj)
            % GIVEN, WHEN, THEN
            Test = usain.fastener.BoltSpecificationString('ISO_M72', 0.500, 0.123);
            expected = 'ISO_M72x500x123';
            Obj.assertEqual(Test.specification, expected);
        end

        function char__happy(Obj)
            % GIVEN, WHEN, THEN
            Test = usain.fastener.BoltSpecificationString('ISO_M56', 0.450, 0.160);
            actual = char(Test);
            expected = 'ISO_M56x450';
            Obj.assertTrue(ischar(actual));
            Obj.assertEqual(actual, expected);
        end

        function set_specification__lengths_rounded(Obj)
            % GIVEN inputs where the lenghts contain some numerical roundoff
            % WHEN
            actual = usain.fastener.BoltSpecificationString('ISO_M72', 0.475 + 1e-8, 0.155 + 1e-7).specification;

            % THEN we do not expect  this numerical roundoff to be present in the specification string
            expected = 'ISO_M72x475x155';
            Obj.assertEqual(actual, expected);
        end

    end

end
