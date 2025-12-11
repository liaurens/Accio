classdef TiltData
    % Class holding flange tilt data (angular and linear)
    % Angular tilt is in radians, linear tilt is the absolute value of flange tilt in m.

    properties
        angle (:, 1) double  % angular tilt
        linear (:, 1) double  % linear (absolute) tilt
    end

    methods

        function Obj = TiltData(value, unit, width)

            arguments
                value (1, 1) double  % flange tilt, angular or linear depending on `unit`
                unit (1, 1) Unit  % `deg` (for angular) or `mm` (for linear)
                width (:, 1) double  % flange physical width

                % NOTE: if `unit` is `deg`, the value is actually in radians as internally we use SI-units
            end

            assert(any(unit == [Unit.deg, Unit.mm]), 'TiltData:UnsupportedUnit', 'Input unit must be `deg` or `mm`.');

            if unit == Unit.deg
                % If input flange tilt was angular value, directly set `angle`. This is a scalar.
                Obj.angle = ones(size(width)) .* value;
                Obj.linear = Obj.convert_angular_to_linear_deflection(value, width);
            else
                % If flange tilt is input as linear value, convert to angle using the flange width. In this case,
                % the angular flange tilt value is an N-by-1 array for N design points.
                Obj.angle = Obj.convert_linear_to_angular_deflection(value, width);
                Obj.linear = ones(size(width)) .* value;
            end
        end

    end

    methods (Static)

        function angle = convert_linear_to_angular_deflection(linear, width)
            angle = asin(linear ./ width);
        end

        function linear = convert_angular_to_linear_deflection(angle, width)
            linear = sin(angle) .* width;
        end

    end

end
