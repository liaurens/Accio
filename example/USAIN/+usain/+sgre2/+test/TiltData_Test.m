classdef TiltData_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function constructor__input_linear(Obj)
            % GIVEN linear flange tilt inputs
            Tilt = usain.sgre2.TiltData(0.123, Unit.mm, ones(3, 1));

            % WHEN
            % THEN expect properties `angle` and `linear` to be set, as an array
            Obj.verifySize(Tilt.angle, [3, 1]);
            Obj.verifySize(Tilt.linear, [3, 1]);
        end

        function constructor__input_angular(Obj)
            % GIVEN linear flange tilt inputs
            Tilt = usain.sgre2.TiltData(0.123, Unit.deg, ones(3, 1));

            % WHEN
            % THEN expect properties `angle` and `linear` to be set, as an array
            Obj.verifySize(Tilt.angle, [3, 1]);
            Obj.verifySize(Tilt.linear, [3, 1]);
        end

        function constructor__bad_unit(Obj)
            % GIVEN, WHEN, THEN
            Obj.verifyError( ...
                @() usain.sgre2.TiltData(0.123, Unit.kN, ones(3, 1)), ...
                'TiltData:UnsupportedUnit');
        end

        function convert_linear_to_angular_deflection__expected(Obj)
            % GIVEN, WHEN, THEN
            Obj.verifyEqual(usain.sgre2.TiltData.convert_linear_to_angular_deflection(0.005, 0.600), 0.008333429, 'RelTol', 1e-4);  % mh:ignore_style
            Obj.verifyEqual(usain.sgre2.TiltData.convert_linear_to_angular_deflection(0, 0.600), 0, 'RelTol', 1e-4);
        end

        function convert_angular_to_linear_deflection__expected(Obj)
            % GIVEN, WHEN, THEN
            Obj.verifyEqual(usain.sgre2.TiltData.convert_angular_to_linear_deflection(0.5, 0.600), 0.28766, 'RelTol', 1e-4);  % mh:ignore_style
            Obj.verifyEqual(usain.sgre2.TiltData.convert_angular_to_linear_deflection(0, 0.600), 0, 'RelTol', 1e-4);
        end

    end

end
