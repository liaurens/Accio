classdef solve_quadratic_function_Test < Unittest.TestCase  % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function solve_quadratic_function__expected(Obj)
            % GIVEN three coordinates along a curve
            x = [-93.2, 104.7, 1467.7];
            y = [2359.0, 2390.4, 2948.8];

            % WHEN, THEN
            actual = usain.sgre2.solve_quadratic_function(x, y);
            Obj.verifySize(actual, [1 3]);
            Obj.verifyEqual(actual(1), 2372.21842, 'AbsTol', 1e-5);
            Obj.verifyEqual(actual(2), 0.15682, 'AbsTol', 1e-5);
            Obj.verifyEqual(actual(3), 0.00016082, 'AbsTol', 1e-5);
        end

        function solve_quadratic_function__order_of_coordinates(Obj)
            % GIVEN three coordinates along a curve
            x = [-93.2, 104.7, 1467.7];
            y = [2359.0, 2390.4, 2948.8];

            % WHEN permuting the coordinates
            actual1 = usain.sgre2.solve_quadratic_function(x, y);
            actual2 = usain.sgre2.solve_quadratic_function(fliplr(x), fliplr(y));
            actual3 = usain.sgre2.solve_quadratic_function(x([1 3 2]), y([1 3 2]));

            % THEN expect numerically equal polynomnial coefficients to be computed
            Obj.verifyEqual(actual1, actual2, 'AbsTol', 1e-10);
            Obj.verifyEqual(actual1, actual3, 'AbsTol', 1e-10);
        end

        function solve_quadratic_function__array_input(Obj)
            % GIVEN coordinates for multiple (n) design points
            n = 4;
            x = ones(n, 1) * [1, 2, 3];
            y = ones(n, 1) * [12, 23, 34];

            % WHEN, THEN
            actual = usain.sgre2.solve_quadratic_function(x, y);
            Obj.verifySize(actual, [n, 3]);
        end

        function solve_quadratic_function__polyfit_compare(Obj)
            % GIVEN three coordinates along a curve
            x = [-93.2, 104.7, 1467.7];
            y = [2359.0, 2390.4, 2948.8];

            % WHEN
            actual = usain.sgre2.solve_quadratic_function(x, y);

            % THEN expect the same result as when using Matlab's built-in `polyfit` function (= least-squares fit)
            expected = polyfit(x, y, 2);
            Obj.verifyEqual(sort(actual), sort(expected), 'AbsTol', 1e-10);  % ordering of coefficients may differ
        end

    end

end
