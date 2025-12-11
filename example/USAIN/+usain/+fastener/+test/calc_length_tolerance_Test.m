classdef calc_length_tolerance_Test < Unittest.TestCase  % mh:ignore_style

    properties (TestParameter)
        % Inputs for parameterized test (1 test per row)
        % Column 1: tolerance grade
        % Column 2: nominal length
        % Column 3: expected tolerance
        testTable = {
            {'js14', 250e-3, 0.575e-3}
            {'js14', 251e-3, 0.650e-3}
            {'js14', 500e-3, 0.775e-3}
            {'js14', 501e-3, 0.876e-3}
            {'js14', 630e-3, 0.876e-3}
            {'js17', 190e-3, 2.300e-3}
            {'js17', 400e-3, 2.800e-3}
            {'js17', 401e-3, 3.100e-3}
            {'js17', 501e-3, 3.500e-3}
            {'js17', 800e-3, 4.000e-3}
            {'b1180-c', 195e-3, 4.00e-3}
            {'b1180-c', 200e-3, 4.60e-3}
            {'b1180-c', 320e-3, 5.70e-3}
            {'b1180-c', 395e-3, 5.70e-3}
            {'b1180-c', 400e-3, 6.30e-3}}
    end
    methods (Test, TestTags = {'unit'})

        function calc_length_tolerance__expected_tol(Obj, testTable)
            % GIVEN
            grade = testTable{1};
            len = testTable{2};
            expect = testTable{3};

            % WHEN THEN
            actual = usain.fastener.calc_length_tolerance(grade, len);
            Obj.assertEqual(actual, expect, 'AbsTol', 1e-6);
        end

        function calc_length_tolerance__extrapolation_above(Obj)
            % GIVEN
            grade = 'js14';
            len = 1234;

            % WHEN THEN
            [len, isExtrapolated] = usain.fastener.calc_length_tolerance(grade, len);
            Obj.assertTrue(isExtrapolated);
            Obj.assertEqual(len, 0.00115, 'AbsTol', 1e-6);
        end

        function calc_length_tolerance__extrapolation_below(Obj)
            % GIVEN
            grade = 'b1180-c';
            len = 0.0123;

            % WHEN THEN
            [len, isExtrapolated] = usain.fastener.calc_length_tolerance(grade, len);
            Obj.assertTrue(isExtrapolated);
            Obj.assertEqual(len, NaN, 'AbsTol', 1e-6);
        end

        function calc_length_tolerance__invalid_grade(Obj)
            % GIVEN WHEN THEN
            f = @() usain.fastener.calc_length_tolerance('not-exist', 123);
            Obj.assertError(f, 'calc_length_tolerance:InvalidGrade');
        end

    end
end
