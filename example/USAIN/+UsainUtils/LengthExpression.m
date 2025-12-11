classdef LengthExpression
    % Length expression, e.g. '0.4D', '1.1D' or '4P'
    %
    % This value class can be used the check the format of length expressions and to convert them to
    % numeric values
    %
    % EXAMPLES;
    % >> T = UsainUtils.LengthExpression('0.4D');
    % >> T.calc_length(0.064, 0.006)
    %       ans = 0.0256  % 0.4 * 64mm
    %
    % >> T = UsainUtils.LengthExpression('1.1P', @(x) round_up(x, 3));
    % >> T.calc_length(0.072, 0.006)
    %       ans = 0.0070  % 1.1 * 6mm, rounded up to nearest millimeter

    properties
        str
        roundFunction function_handle = @(x) x
    end
    properties (Hidden, Constant)
        REGEX_FILTER = '^(\d+(?:\.\d+)?)(P|D)$'
    end

    methods

        function Obj = LengthExpression(str, roundFunction)
            Obj.str = str;
            if nargin > 1
                Obj.roundFunction = roundFunction;
            end
        end

        function value = calc_length(Obj, diameter, pitch)
            % Converts length expression to a numeric value
            %
            % diameter: bolt diameter
            % pitch: thread pitch

            if endsWith(Obj.str, 'D')
                value = str2double(extractBefore(Obj.str, 'D')) * diameter;
            elseif endsWith(Obj.str, 'P')
                value = str2double(extractBefore(Obj.str, 'P')) * pitch;
            else
                value = nan;
            end
            value = Obj.roundFunction(value);
        end

        function Obj = set.str(Obj, value)
            UsainUtils.LengthExpression.validate_str(value);
            Obj.str = upper(value);
        end

    end

    methods (Static)

        function validate_str(str)
            % Validates type and format of length expression
            %
            % str: length expression

            assert(ischar(str) || isstring(str), 'LengthExpression:NotAString', 'Not a string.');
            assert(~isempty(regexpi(str, UsainUtils.LengthExpression.REGEX_FILTER)), ...
                'LengthExpression:RegexMismatch', ...
                'Expression must start with number (integer or float), followed by D or P.');
        end

        function str = format_input_variable_name(minOrMax, visibleOrGripped, tighteningMethod)
            % Returns input variable name for length expression
            %
            % minOrMax: Limit identification string: 'min', 'max' (case-insensitive)
            % visibleOrGripped: Thread identification string: 'visible', 'gripped' (case-insensitive)
            % tighteningMethod: Optional. Tightening method: 'torque', 'tension' (case-insensitive)

            % Validate strings and make uppercase because the length expression input variable is an
            % expert input (in UPPER_SNAKE_CASE)
            visibleOrGripped = validatestring(visibleOrGripped, {'VISIBLE', 'GRIPPED'});
            minOrMax = validatestring(minOrMax, {'MIN', 'MAX'});
            tighteningMethod = validatestring(tighteningMethod, {'TORQUE', 'TENSION'});

            % Concatenate string
            if strcmp(minOrMax, 'MIN')
                % Independent of tightening method
                str = sprintf('%s_%s_THREAD_LENGTH', minOrMax, visibleOrGripped);
            else
                str = sprintf('%s_%s_THREAD_LENGTH_%s', minOrMax, visibleOrGripped, tighteningMethod);
            end
        end

    end
end
