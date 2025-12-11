classdef SegmentModel_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function calc_a_modified__expected(Obj)
            % GIVEN
            Model = usain.model.SegmentModel(usain.inputs.FlangeType.L);
            Model.aEffective = 0.2169;
            Model.b = 0.1385;
            Model.flangeThickness = 0.212;

            % WHEN, THEN
            Obj.verifyEqual(Model.calc_a_modified(), 0.08676, 'AbsTol', 1e-4);
        end

        function calc_a_modified__limits(Obj)
            % GIVEN combinations of `aEffective`, `b` and `flangeThickness`
            Model = usain.model.SegmentModel(usain.inputs.FlangeType.L);
            Model.aEffective = ones(1, 100) * 100;
            Model.b = linspace(0, 500, 100);
            Model.flangeThickness = linspace(0, 1000, 100);

            % WHEN computing `a*`
            actual = Model.calc_a_modified();

            % THEN we expect that a* is always >= 20% and <= 100% of `aEffective
            Obj.verifyGreaterThanOrEqual(min(actual), 20);
            Obj.verifyLessThanOrEqual(max(actual), 100);
        end

        function calc_a_modified__tflange(Obj)
            % GIVEN a T-flange segment model
            Model = usain.model.SegmentModel(usain.inputs.FlangeType.T);

            % WHEN, computing `a*`
            actual = Model.calc_a_modified();

            % THEN we expect NaN as `a*` is relevant for L-flanges only
            Obj.verifyEqual(actual, NaN);
        end

        function calc_inner_diameter__expected(Obj)
            % GIVEN, WHEN, THEN
            diameterOut = 6.000;
            width = 0.250;

            Obj.verifyEqual( ...
                usain.model.SegmentModel.calc_inner_diameter(diameterOut, width), ...
                5.500, 'AbsTol', 1e-4);
        end

        function calc_parameter_a__expected(Obj)
            % GIVEN, WHEN, THEN
            diameterIn = 6.355;
            diameterBoltCircle = 6.675;

            Obj.verifyEqual( ...
                usain.model.SegmentModel.calc_parameter_a(diameterIn, diameterBoltCircle), ...
                0.160, 'AbsTol', 1e-4);
        end

        function calc_parameter_b__l_flange(Obj)
            % GIVEN inputs for an L-flange
            FlangeType = usain.inputs.FlangeType.L;
            diameterOutNeck = 7;
            diameterBoltCircle = 6675e-3;
            neckThicknessUp = [0.075 0.085 0.080];
            neckThicknessLo = [0.075 0.080 0.085];

            % WHEN, THEN
            Obj.verifyEqual( ...
                usain.model.SegmentModel.calc_parameter_b( ...
                FlangeType, diameterOutNeck, diameterBoltCircle, neckThicknessUp, neckThicknessLo), ...
                [0.125, 0.1225, 0.1225], 'AbsTol', 1e-4);
        end

        function calc_parameter_b__t_flange(Obj)
            % GIVEN inputs for an T-flange
            FlangeType = usain.inputs.FlangeType.T;
            diameterOutNeck = 7;
            diameterBoltCircle = 6675e-3;
            neckThicknessUp = [0.075 0.085 0.080];
            neckThicknessLo = [0.075 0.080 0.085];

            % WHEN, THEN
            Obj.verifyEqual( ...
                usain.model.SegmentModel.calc_parameter_b( ...
                FlangeType, diameterOutNeck, diameterBoltCircle, neckThicknessUp, neckThicknessLo), ...
                [0.125, 0.120, 0.1225], 'AbsTol', 1e-4);
        end

        function getters__expected_value_from_fixture_data(Obj)
            % GIVEN, WHEN, THEN
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            Obj.verifyEqual(SegmentFixture.areaCircumferential, 0.020425, 'RelTol', 1e-4);
            Obj.verifyEqual(SegmentFixture.areaTangential, 0.008973, 'RelTol', 1e-4);
            Obj.verifyEqual(SegmentFixture.boltDistance, 0.09156089, 'RelTol', 1e-4);
            Obj.verifyEqual(SegmentFixture.inertiaGapClosing, 1.53613e-5, 'RelTol', 1e-4);
            Obj.verifyEqual(SegmentFixture.inertiaFlangeRotation, 6.74857e-6, 'RelTol', 1e-4);
            Obj.verifyEqual(SegmentFixture.neckThickness, 0.030, 'RelTol', 1e-4);
            Obj.verifyEqual(SegmentFixture.segmentWidth, 0.094454463, 'RelTol', 1e-4);
        end

    end

end
