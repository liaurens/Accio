function [tol, isExtrapolated] = calc_length_tolerance(grade, len)
    % Returns (symmetrical) tolerances on bolt length, for various tolerance grades
    %
    %   grade: option from VALID_GRADES (see below)
    %   len: nominal length

    VALID_GRADES = {'js14', 'js17', 'b1180-c'};
    assert(any(strcmp(grade, VALID_GRADES)), 'calc_length_tolerance:InvalidGrade', ...
        'Tolerance grade not supported. Choose from: %s', strjoin(VALID_GRADES, ', '));

    % Ugly tables with tolerances. No time is spend to implement this nicely because the values are not
    % expected to ever change (and therefore not much maintenance to this code is expected)
    % Columns:
    %  1: above length [mm]
    %  2: up to and including length [mm]
    % 3+: tolerance grades
    if startsWith(grade, 'js')
        % Values up to 500mm from Table A.2 in ISO 4759-1. >500mm distilled from ISO 286-1.
        tolerances = {
               '>',    '<=',     'js14',     'js17'
            180e-3,  250e-3,   0.575e-3,   2.300e-3
            250e-3,  315e-3,   0.650e-3,   2.600e-3
            315e-3,  400e-3,   0.700e-3,   2.800e-3
            400e-3,  500e-3,   0.775e-3,   3.100e-3
            500e-3,  630e-3,   0.876e-3,   3.500e-3
            630e-3,  800e-3,   1.000e-3,   4.000e-3
            800e-3, 1000e-3,   1.150e-3,   4.500e-3
            };
        isGrade = strcmp(tolerances(1, :), grade);
        from = cell2mat(tolerances(2:end, 1));
        upTo = [from(1); cell2mat(tolerances(2:end, 2))];
        values = cell2mat(tolerances([2 2:end], isGrade));
    else
        % Values up to 560mm from ZPS1042575/004, Table 4. For >560e-3, taking nearest
        tolerances = {
               '>',    '<=', 'b1180-c'
            180e-3,  195e-3, 4.0e-3
            195e-3,  255e-3, 4.6e-3
            255e-3,  315e-3, 5.2e-3
            315e-3,  395e-3, 5.7e-3
            395e-3,  560e-3, 6.3e-3
            };
        from = cell2mat(tolerances(2:end, 1));
        upTo = [from(1); cell2mat(tolerances(2:end, 2))];
        values = cell2mat(tolerances([2 2:end], 3));
    end

    interpTol = griddedInterpolant(upTo, values, 'next', 'previous');
    tol = interpTol(len);
    isExtrapolated = any(len <= min(from)) | any(len >= max(upTo));
end
