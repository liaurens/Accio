classdef LengthExpression_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function constructor__set_str(Obj)
            % GIVEN, WHEN, THEN
            Test = UsainUtils.LengthExpression('1.1D');
            Obj.assertEqual(Test.str, '1.1D');
        end

        function calc_length__expected(Obj)
            % GIVEN, WHEN, THEN
            Obj.assertEqual(UsainUtils.LengthExpression('0.4D').calc_length(0.048, 0.0045), 0.0192, 'AbsTol', 1e-4);
            Obj.assertEqual(UsainUtils.LengthExpression('1.1D').calc_length(0.072, 0.0060), 0.0792, 'AbsTol', 1e-4);
            Obj.assertEqual(UsainUtils.LengthExpression('4P').calc_length(0.064, 0.0060), 0.0240, 'AbsTol', 1e-4);

            % WHEN applying a rounding function with the same calculations
            % THEN we expect rounded values
            roundFunc = @(x) round_up(x, 3);
            Obj.assertEqual(UsainUtils.LengthExpression('0.4D', roundFunc).calc_length(0.048, 0.0045), 0.0200, 'AbsTol', 1e-4);  % mh:ignore_style
            Obj.assertEqual(UsainUtils.LengthExpression('1.1D', roundFunc).calc_length(0.072, 0.0060), 0.0800, 'AbsTol', 1e-4);  % mh:ignore_style
            Obj.assertEqual(UsainUtils.LengthExpression('4P', roundFunc).calc_length(0.064, 0.0060), 0.0240, 'AbsTol', 1e-4);  % mh:ignore_style
        end

        function validate_str__not_a_string(Obj)
            % GIVEN, WHEN, THEN
            Obj.verifyError(@() UsainUtils.LengthExpression(1.0), 'LengthExpression:NotAString');
            Obj.verifyError(@() UsainUtils.LengthExpression(nan), 'LengthExpression:NotAString');
            Obj.verifyError(@() UsainUtils.LengthExpression(2), 'LengthExpression:NotAString');
        end

        function validate_str__regex_mismatch(Obj)
            % GIVEN, WHEN, THEN
            Obj.verifyError(@() UsainUtils.LengthExpression('1.0'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('D'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('P'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('4.P'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('.4D'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('.D'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('1.23.D'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('1.2.3D'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('10..24D'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('1.23DP'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('1.23PD'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('1DP'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('1.2PD'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('D1.2'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('P1.2'), 'LengthExpression:RegexMismatch');
            Obj.verifyError(@() UsainUtils.LengthExpression('0.1*D'), 'LengthExpression:RegexMismatch');
        end

        function validate_str__happy_case(Obj)
            % GIVEN, WHEN, THEN
            Obj.verify_error_free(@() UsainUtils.LengthExpression('1.0D'));
            Obj.verify_error_free(@() UsainUtils.LengthExpression('1D'));
            Obj.verify_error_free(@() UsainUtils.LengthExpression('4P'));
            Obj.verify_error_free(@() UsainUtils.LengthExpression('0.4D'));
            Obj.verify_error_free(@() UsainUtils.LengthExpression('1.0d'));
            Obj.verify_error_free(@() UsainUtils.LengthExpression('1.0p'));
            Obj.verify_error_free(@() UsainUtils.LengthExpression('1d'));
            Obj.verify_error_free(@() UsainUtils.LengthExpression('1p'));
        end

        function format_input_variable_name__visible_min_torque(Obj)
            % GIVEN a set of strings (see test method name)
            % WHEN, THEN
            actual = UsainUtils.LengthExpression.format_input_variable_name('min', 'visible', 'torque');
            expected = 'MIN_VISIBLE_THREAD_LENGTH';
            Obj.assertEqual(actual, expected);
        end

        function format_input_variable_name__visible_min_tension(Obj)
            % GIVEN a set of strings (see test method name)
            % WHEN, THEN
            actual = UsainUtils.LengthExpression.format_input_variable_name('min', 'visible', 'tension');  % mh:ignore_style
            expected = 'MIN_VISIBLE_THREAD_LENGTH';
            Obj.assertEqual(actual, expected);
        end

        function format_input_variable_name__visible_max_torque(Obj)
            % GIVEN a set of strings (see test method name)
            % WHEN, THEN
            actual = UsainUtils.LengthExpression.format_input_variable_name('max', 'visible', 'torque');
            expected = 'MAX_VISIBLE_THREAD_LENGTH_TORQUE';
            Obj.assertEqual(actual, expected);
        end

        function format_input_variable_name__visible_max_tension(Obj)
            % GIVEN a set of strings (see test method name)
            % WHEN, THEN
            actual = UsainUtils.LengthExpression.format_input_variable_name('max', 'visible', 'tension');  % mh:ignore_style
            expected = 'MAX_VISIBLE_THREAD_LENGTH_TENSION';
            Obj.assertEqual(actual, expected);
        end

        function format_input_variable_name__gripped_min_torque(Obj)
            % GIVEN a set of strings (see test method name)
            % WHEN, THEN
            actual = UsainUtils.LengthExpression.format_input_variable_name('min', 'gripped', 'torque');
            expected = 'MIN_GRIPPED_THREAD_LENGTH';
            Obj.assertEqual(actual, expected);
        end

        function format_input_variable_name__gripped_min_tension(Obj)
            % GIVEN a set of strings (see test method name)
            % WHEN, THEN
            actual = UsainUtils.LengthExpression.format_input_variable_name('min', 'gripped', 'tension');  % mh:ignore_style
            expected = 'MIN_GRIPPED_THREAD_LENGTH';
            Obj.assertEqual(actual, expected);
        end

    end

end
