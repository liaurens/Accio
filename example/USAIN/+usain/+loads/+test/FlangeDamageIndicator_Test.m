classdef FlangeDamageIndicator_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function constructor_input_args_assigned(Obj)
            % GIVEN, WHEN, THEN
            Fdi = usain.loads.FlangeDamageIndicator(a1 = 0.1, a2 = 0.0003, m = 4);
            Obj.verifyEqual(Fdi.a1, 0.1);
            Obj.verifyEqual(Fdi.a2, 0.0003);
            Obj.verifyEqual(Fdi.m, 4);
        end

        function calc_fdi__array_sizes(Obj)
            % GIVEN Markov array entries of inconsistent sizes
            ranges = ones(10, 1);
            cycles = ones(10, 1);
            means = ones(1, 1);

            % WHEN, THEN
            Fdi = usain.loads.FlangeDamageIndicator(a1 = 0.1, a2 = 0.0003, m = 4);
            Obj.assertRaisesMessageRegex( ...
                @() Fdi.calc_fdi(ranges, cycles, means), ...
                'Input vectors must be of equal length.');
        end

        function calc_fdi__expected(Obj)
            % GIVEN dummy Markov array entries
            ranges = [47.6516, 9403700, 18807400, 28211000, 37614700]';
            cycles = [22663.2, 899.13, 0, 0.005, 980314]';
            means = [-262138000, -262138000, 32544500, 32544500, 260253000]';

            % WHEN, THEN
            actual = usain.loads.FlangeDamageIndicator(a1 = 0.1, a2 = 0.0003, m = 3).calc_fdi(ranges, cycles, means).fdi;  % mh:ignore_style
            expected = 876859978;
            Obj.verifyEqual(actual, expected, 'AbsTol', 0.5);
        end

        function calc_fdi__compressive_cycles_only(Obj)
            % GIVEN dummy Markov array entries where all load cycles are fully compressive
            ranges = [123, 234, 345, 456]';
            cycles = [1000, 1000, 1000, 1000]';
            means = [-1230, -2340, -3450, -4560]';

            % WHEN, THEN
            actual = usain.loads.FlangeDamageIndicator(a1 = 0.1, a2 = 0.0003, m = 4).calc_fdi(ranges, cycles, means).fdi;  % mh:ignore_style
            expected = 0;
            Obj.verifyEqual(actual, expected, 'AbsTol', 0.5);
        end

    end
end
