classdef FlangeTiltMechanics_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function calc_flange_mid_radius__tflange(Obj)
            % GIVEN
            FlangeTilt = Obj.applyFixture(usain.sgre2.test.fixtures.FlangeTiltMechanicsFixture()).data;

            % WHEN, THEN
            actual = FlangeTilt.calc_flange_mid_radius();
            Obj.verifyEqual(actual, 3.70075, 'RelTol', 1e-4);
        end

        function calc_flange_mid_radius__lflange(Obj)
            % GIVEN
            FlangeTilt = Obj.applyFixture(usain.sgre2.test.fixtures.FlangeTiltMechanicsFixture()).data;
            FlangeTilt.FlangeType = usain.inputs.FlangeType.L;

            % WHEN, THEN
            actual = FlangeTilt.calc_flange_mid_radius();
            Obj.verifyEqual(actual, 3.467, 'RelTol', 1e-4);
        end

        function calc_lever_arm__tflange(Obj)
            % GIVEN
            FlangeTilt = Obj.applyFixture(usain.sgre2.test.fixtures.FlangeTiltMechanicsFixture()).data;

            % WHEN, THEN
            actual = FlangeTilt.calc_lever_arm();
            Obj.verifyEqual(actual, 0.42225, 'RelTol', 1e-4);
        end

        function calc_lever_arm__lflange(Obj)
            % GIVEN
            FlangeTilt = Obj.applyFixture(usain.sgre2.test.fixtures.FlangeTiltMechanicsFixture()).data;
            FlangeTilt.FlangeType = usain.inputs.FlangeType.L;

            % WHEN, THEN
            actual = FlangeTilt.calc_lever_arm();
            Obj.verifyEqual(actual, 0.1885, 'RelTol', 1e-4);
        end

        function calc_shell_parameters__happy(Obj)
            % GIVEN
            FlangeTilt = Obj.applyFixture(usain.sgre2.test.fixtures.FlangeTiltMechanicsFixture()).data;

            % WHEN, THEN
            [actualN, actualK] = FlangeTilt.calc_shell_parameters();
            Obj.verifyEqual(actualN, 2.129, 'RelTol', 1e-4);
            Obj.verifyEqual(actualK, 1.8378e7, 'RelTol', 1e-4);
        end

        function calc_tilt_closing_force__happy(Obj)
            % GIVEN
            FlangeTilt = Obj.applyFixture(usain.sgre2.test.fixtures.FlangeTiltMechanicsFixture()).data;

            % WHEN, THEN
            angle = deg2rad(0.5);
            actual = FlangeTilt.calc_tilt_closing_force(angle);
            Obj.verifyEqual(actual, 141.41374e3, 'RelTol', 1e-4);

            % WHEN the tilt angle is zero
            % THEN the force is expected to be zero as well
            Obj.verifyEqual(FlangeTilt.calc_tilt_closing_force(0), 0, 'RelTol', 1e-4);

            % WHEN the tilt angle is doubled
            % THEN expect the force to be doubled as well (linear relation)
            Obj.verifyEqual( ...
                2 * FlangeTilt.calc_tilt_closing_force(0.01), ...
                FlangeTilt.calc_tilt_closing_force(0.02), ...
                'RelTol', 1e-4);
        end

    end

    methods (Test, TestTags = {'integration'})

        function create__happy(Obj)
            % GIVEN
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.TFlangeSegmentModelFixture()).data;

            % WHEN
            FlangeTilt = usain.sgre2.FlangeTiltMechanics.create(SegmentFixture);

            % THEN
            Obj.verifyEqual(FlangeTilt.FlangeType, SegmentFixture.FlangeType);
            Obj.verifyEqual(FlangeTilt.eModulus, SegmentFixture.eModulus, 'AbsTol', 1e-4);
            Obj.verifyEqual(FlangeTilt.flangeThickness, SegmentFixture.flangeThickness, 'AbsTol', 1e-4);
            Obj.verifyEqual(FlangeTilt.neckThickness, SegmentFixture.neckThickness, 'AbsTol', 1e-4);
            Obj.verifyEqual(FlangeTilt.flangeWidth, SegmentFixture.flangeWidth, 'AbsTol', 1e-4);
            Obj.verifyEqual(FlangeTilt.segmentWidth, SegmentFixture.segmentWidth, 'AbsTol', 1e-4);

            Obj.verifyEqual(FlangeTilt.radiusMidNeck, 3.70075, 'RelTol', 1e-3);
            Obj.verifyEqual(FlangeTilt.parameterB, 0.13925, 'RelTol', 1e-3);
        end

        function create__array_input(Obj)
            % GIVEN array (n>1) inputs for GapCloseModel creation
            n = 2;
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture(n = n)).data;

            % WHEN
            FlangeTilt = usain.sgre2.FlangeTiltMechanics.create(SegmentFixture);

            % THEN
            Obj.verifySize(FlangeTilt.FlangeType, [1, 1]);
            Obj.verifySize(FlangeTilt.eModulus, [1, 1]);
            Obj.verifySize(FlangeTilt.neckThickness, [1, 1]);
            Obj.verifySize(FlangeTilt.radiusMidNeck, [n, 1]);

            Obj.verifySize(FlangeTilt.flangeThickness, [n, 1]);
            Obj.verifySize(FlangeTilt.parameterB, [n, 1]);
            Obj.verifySize(FlangeTilt.flangeWidth, [n, 1]);
            Obj.verifySize(FlangeTilt.segmentWidth, [n, 1]);
        end

        function call_internal_methods__array_input(Obj)
            % GIVEN array (n>1) inputs for GapCloseModel creation
            n = 2;
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture(n = n)).data;

            % WHEN
            FlangeTilt = usain.sgre2.FlangeTiltMechanics.create(SegmentFixture);

            % WHEN calling internal methods
            % THEN expect no errors and return arguments of expected size (i.e. nx1 or 1x1)
            Obj.verifySize(FlangeTilt.calc_flange_mid_radius(), [n, 1]);
            Obj.verifySize(FlangeTilt.calc_lever_arm(), [n, 1]);
            Obj.verifySize(FlangeTilt.calc_shell_parameters(), [n, 1]);
            Obj.verifySize(FlangeTilt.calc_tilt_closing_force(0), [n, 1]);
        end

        function calc_tilt_closing_force__usain_implementation_equals_amd1(Obj)
            % GIVEN
            FlangeTilt = Obj.applyFixture(usain.sgre2.test.fixtures.FlangeTiltMechanicsFixture()).data;
            angle = deg2rad(0.2);

            % WHEN computing the tilt closing force with USAIN (i.e closed form solution) and consequently the angle
            % alpha_S closed by a 1 [N] force
            force = FlangeTilt.calc_tilt_closing_force(angle);
            actual = angle / force;

            % THEN expect the same answer as the implementation in IEC61400-6/AMD1 (i.e. with matrix operations)
            [C, D, d0] = Obj.get_iec_61400_6_amd1_matrices(FlangeTilt);
            expected = C * (D \ d0);
            % NOTE: `expected` is a 2x1 vector where element 2 is the value of interest (i.e. unit tilt angle)

            Obj.verifyEqual(actual, expected(2), 'RelTol', 1e-4);
        end

    end

    methods (Static)

        function [C, D, d0] = get_iec_61400_6_amd1_matrices(FlangeTilt)
            % Returns matrices and vector from G.3.3 in IEC 61400-6:2020/AMD1:2024
            %
            % C: 2x2 matrix of c11, c12, etc. coefficients
            % D: 2x2 matrix of d11, d12, etc. coefficients
            % d0: 2x1 vector of d01(=0) and d02

            [n, k] = FlangeTilt.calc_shell_parameters();
            leverArm = FlangeTilt.calc_lever_arm();
            radiusFlangeMid = FlangeTilt.calc_flange_mid_radius();
            gapClosingForce = 1;
            tiltClosingMoment = gapClosingForce .* leverArm ./ FlangeTilt.segmentWidth;  % Nm/m
            radiusSquared = FlangeTilt.radiusMidNeck .* radiusFlangeMid;

            d11 = 1 / (2 * k * n^3) + radiusSquared / (FlangeTilt.eModulus * FlangeTilt.flangeWidth * FlangeTilt.flangeThickness);  % mh:ignore_style
            d12 = 1 / (2 * k * n^2);
            d21 = d12;
            d22 = 1 / (k * n) + 12 * radiusSquared / (FlangeTilt.eModulus * FlangeTilt.flangeWidth * FlangeTilt.flangeThickness^3);  % mh:ignore_style

            c11 = 1 / (2 * k * n^3);
            c12 = d12;
            c21 = d12;
            c22 = 1 / (k * n);

            d01 = 0;
            d02 = 12 * tiltClosingMoment * radiusSquared / (FlangeTilt.eModulus * FlangeTilt.flangeWidth * FlangeTilt.flangeThickness^3);  % mh:ignore_style

            C = [c11, c12; c21, c22];
            D = [d11, d12; d21, d22];
            d0 = [d01; d02];
        end

    end
end
