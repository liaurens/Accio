classdef SimplifiedShellStiffness_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function calc_stiffness__iec_benchmark(Obj)
            % GIVEN the inputs for the "IEC_example_rev2" flange
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            diameterOutNeck = SegmentFixture.diameterOutNeck;
            thicknessShell = SegmentFixture.neckThickness;
            eModulus = SegmentFixture.eModulus;
            gapAngle = deg2rad(30);

            % WHEN, THEN
            actual = usain.sgre2.SimplifiedShellStiffness().calc_stiffness(diameterOutNeck, thicknessShell, gapAngle, eModulus);  % mh:ignore_style
            expected = 2873978995.71553;
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-4);
        end

        function calc_stiffness__array_inputs(Obj)
            % GIVEN the inputs for the "IEC_example_rev2" flange
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture(n = 3)).data;
            diameterOutNeck = SegmentFixture.diameterOutNeck;
            thicknessShell = SegmentFixture.neckThickness;
            eModulus = SegmentFixture.eModulus;
            gapAngle = deg2rad(90);

            % WHEN, THEN
            actual = usain.sgre2.SimplifiedShellStiffness().calc_stiffness(diameterOutNeck, thicknessShell, gapAngle, eModulus);  % mh:ignore_style
            Obj.assertSize(actual, [3, 1]);
        end

    end
end
