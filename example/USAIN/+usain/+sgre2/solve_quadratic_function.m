function coeffs = solve_quadratic_function(x, y)
    % Uses closed-form solution to fit a quadratic function (y = ax^2 + bx + c) given x and y.
    % The unit tests prove that this gives the same results as `polyfit`.
    % The latter is not used because it is very slow for `size(x, 1) >> 1`.
    %
    % x, y: N-by-3 arrays with x/y coordinates of N curves
    % coeffs: N-by-3 array with polynomial coefficients, such that f = coeff(:, 1) + coeff(:, 2)*x + coeff(:, 3)*x^2

    assert(isequal(size(x), size(y)), 'Args x and y must have the same size.');
    assert(size(x, 2) == 3, 'Expected 3 coordinates.');

    a = ((y(:, 2) - y(:, 1)) .* (x(:, 3) - x(:, 1)) - (y(:, 3) - y(:, 1)) .* (x(:, 2) - x(:, 1))) ./ ((x(:, 2).^2 - x(:, 1).^2) .* (x(:, 3) - x(:, 1)) - (x(:, 3).^2 - x(:, 1).^2) .* (x(:, 2) - x(:, 1)));  % mh:ignore_style
    b = (y(:, 3) - y(:, 1) - a .* (x(:, 3).^2 - x(:, 1).^2)) ./ (x(:, 3) - x(:, 1));
    c = y(:, 1) - a .* (x(:, 1).^2) - b .* x(:, 1);

    % See docstring for why we return c, then b, then a instead of the other way around
    coeffs = [c, b, a];
end
