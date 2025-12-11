classdef GapCloseModel_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function calc_gap_closing_force__happy(Obj)
            % GIVEN
            GapModel = usain.sgre2.GapCloseModel();
            GapModel.forceParallelGapClose = 1.2e3;
            GapModel.forcePrying = 2.3e3;
            GapModel.forceTiltClose = 3.4e3;

            % WHEN, THEN
            Obj.verifyEqual(GapModel.calc_gap_closing_force(), 6.9e3, 'RelTol', 1e-4);
        end

        function calc_parallel_gap_closing_force__iec_benchmark(Obj)
            % GIVEN the inputs for the "IEC_example_rev2" flange
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            GapModel = usain.sgre2.GapCloseModel();
            GapModel.stiffnessGapTotal = 7614.26953125e6;
            GapModel.gapCloseStiffnessRatio = 0.5;
            gapHeight = 0.000745454013347625;

            % WHEN, THEN
            actual = GapModel.calc_parallel_gap_closing_force(SegmentFixture, gapHeight);
            expected = 268065.90625;
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-4);
            GapModel.forceGapClose = actual;
        end

        function calc_parallel_gap_closing_force__gap_close_ratio(Obj)
            % GIVEN dummy inputs
            GapModel = Obj.applyFixture(usain.sgre2.test.fixtures.GapCloseModelFixture(n = 1)).data;
            Segment.segmentWidth = 1;
            gapHeight = 1;

            % WHEN computing the gap closing force for a ratio of 0.5 and 1.0
            GapModel.gapCloseStiffnessRatio = 0.5;
            actual1 = GapModel.calc_parallel_gap_closing_force(Segment, gapHeight);

            GapModel.gapCloseStiffnessRatio = 1.0;
            actual2 = GapModel.calc_parallel_gap_closing_force(Segment, gapHeight);

            % THEN expect 100% difference
            Obj.verifyEqual(2 * actual1, actual2, 'RelTol', 1e-4);
        end

        function calc_prying_force__zero_for_lflange(Obj)
            % GIVEN
            GapModel = usain.sgre2.GapCloseModel();
            Segment.FlangeType = usain.inputs.FlangeType.L;
            gapHeight = 1.2;
            preload = 2.3;

            % WHEN, THEN
            actual = GapModel.calc_prying_force(Segment, gapHeight, preload);
            Obj.verifyEqual(actual, 0, 'RelTol', 1e-4);
        end

        function calc_prying_force__tflange(Obj)
            % GIVEN inputs for a T-flange
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.TFlangeSegmentModelFixture()).data;
            GapModel = usain.sgre2.GapCloseModel();
            GapModel.stiffnessShell = 2323.649876e6;
            GapModel.stiffnessFlange = 36.61756e6;
            gapHeight = 1.60284e-3;
            preload = 909e3;

            % WHEN, THEN
            actual = GapModel.calc_prying_force(SegmentFixture, gapHeight, preload);
            expected = 234.2994e3;
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-4);
        end

        function calc_tilt_closing_force__tflange(Obj)
            % GIVEN T-flange inputs to compute the tilt closing force
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.TFlangeSegmentModelFixture()).data;
            GapModel = usain.sgre2.GapCloseModel();
            GapModel.Tilt = usain.sgre2.TiltData(deg2rad(0.2), Unit.deg, SegmentFixture.flangeWidth);

            % WHEN computing the tilt closing force for a T-flange
            % THEN expect a T-flange value > 0
            Obj.verifyGreaterThan(GapModel.calc_tilt_closing_force(SegmentFixture), 0);

            % WHEN the tilt angle is 0
            % THEN expect 0 force
            GapModel.Tilt = usain.sgre2.TiltData(0, Unit.deg, SegmentFixture.flangeWidth);
            Obj.verifyEqual(GapModel.calc_tilt_closing_force(SegmentFixture), 0);
        end

        function calc_tilt_closing_force__lflange(Obj)
            % GIVEN L-flange inputs to compute the tilt closing force
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            GapModel = usain.sgre2.GapCloseModel();
            GapModel.Tilt = usain.sgre2.TiltData(deg2rad(0.5), Unit.deg, SegmentFixture.flangeWidth);

            % WHEN computing the tilt closing force for an L-flange
            % THEN expect an L-flange value < 0
            Obj.verifyLessThan(GapModel.calc_tilt_closing_force(SegmentFixture), 0);

            % WHEN the tilt angle is 0
            % THEN expect 0 force
            GapModel.Tilt = usain.sgre2.TiltData(0, Unit.deg, SegmentFixture.flangeWidth);
            Obj.verifyEqual(GapModel.calc_tilt_closing_force(SegmentFixture), 0);
        end

        function calc_segment_stiffness__iec_benchmark(Obj)
            % GIVEN the inputs for the "IEC_example_rev2" flange
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            preload = 680747.5;
            GapModel = usain.sgre2.GapCloseModel();
            GapModel.forceParallelGapClose = 268065.90625;  % see calc_parallel_gap_closing_force__iec_benchmark

            % WHEN, THEN
            actual = GapModel.calc_segment_stiffness(SegmentFixture, preload);
            expected = 22977.614053e6;
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-4);
            GapModel.stiffnessSegment = actual;
        end

        function calc_segment_stiffness__tflange(Obj)
            % GIVEN the inputs for the "IEC_example_rev2" flange
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.TFlangeSegmentModelFixture()).data;
            preload = 909e3;
            GapModel = usain.sgre2.GapCloseModel();
            GapModel.forceParallelGapClose = 439834.974;

            % WHEN, THEN
            actual = GapModel.calc_segment_stiffness(SegmentFixture, preload);
            expected = 171760e6;
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-4);
            GapModel.stiffnessSegment = actual;
        end

        function calc_stiffness_correction_factor__expected(Obj)
            % GIVEN the inputs for the "IEC_example_rev2" flange
            GapModel = usain.sgre2.GapCloseModel();
            GapModel.stiffnessGapTotal = 7614.26953125e6;
            GapModel.stiffnessSegment = 18092.349609375e6;  % see calc_segment_stiffness__iec_benchmark

            % WHEN setting a ridicilously high upper limit
            % THEN
            actual = GapModel.calc_stiffness_correction_factor(99);
            expected = 1.42085576057434;
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-4);

            % WHEN lowering the upper limit such that it becomes governing
            % THEN
            actual = GapModel.calc_stiffness_correction_factor(expected / 2);
            expected = expected / 2;
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-4);
        end

        function calc_flange_stiffness__iec_benchmark(Obj)
            % GIVEN the inputs for the "IEC_example_rev2" flange
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            GapModel = usain.sgre2.GapCloseModel();
            gapAngle = deg2rad(30);

            % WHEN, THEN
            actual = GapModel.calc_flange_stiffness(SegmentFixture, gapAngle);
            expected = 553143692.5;
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-4);
        end

        function calc_gap_close_factor__happy(Obj)
            % GIVEN gap a gap angle
            gapAnglesLessThan90Degrees = [0, 30, 60, 79];
            gapAnglesGreaterEqual90Degrees = [90, 120, 180];
            % WHEN calculating the gap close factor
            % THEN expect 1<= value <2.5 for gap angles <90deg, and value =2.5 for gap angles >=90deg.
            for gapAngle = gapAnglesLessThan90Degrees
                actual = usain.sgre2.GapCloseModel().calc_gap_close_factor(deg2rad(gapAngle));
                Obj.verifyGreaterThanOrEqual(actual, 1.0);
                Obj.verifyLessThan(actual, 2.5);
            end

            for gapAngle = gapAnglesGreaterEqual90Degrees
                actual = usain.sgre2.GapCloseModel().calc_gap_close_factor(deg2rad(gapAngle));
                Obj.verifyEqual(actual, 2.5);
            end
        end

        function calc_total_gap_stiffness__happy(Obj)
            % GIVEN the inputs for the "IEC_example_rev2" flange
            GapModel = usain.sgre2.GapCloseModel();
            GapModel.stiffnessFlange = 1.2;
            GapModel.stiffnessShell = 3.4;
            GapModel.gapCloseFactor = 2.2;

            % WHEN, THEN
            actual = GapModel.calc_total_gap_stiffness();
            expected = 10.12;
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-4);
        end

    end

    methods (Test, TestTags = {'integration'})

        function create__lflange(Obj)
            % GIVEN
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            Gap = usain.sgre2.GapData(deg2rad(70), 7.5);
            preload = 2359000;
            stiffnessShell = 4251.872924866155e5;
            gapCloseStiffnessRatio = 0.5;
            Tilt = usain.sgre2.TiltData(deg2rad(0.2), Unit.deg, SegmentFixture.flangeWidth);

            % WHEN
            GapModel = usain.sgre2.GapCloseModel.create( ...
                Gap, SegmentFixture, preload, stiffnessShell, Tilt, gapCloseStiffnessRatio);

            % THEN
            Obj.verifyEqual(GapModel.Gap.angle, deg2rad(70), 'AbsTol', 1e-4);
            Obj.verifyEqual(GapModel.Tilt.angle, deg2rad(0.2), 'AbsTol', 1e-4);
            Obj.verifyGreaterThan(GapModel.forceGapClose, 1);
            Obj.verifyGreaterThan(GapModel.forceParallelGapClose, 1);
            Obj.verifyGreaterThanOrEqual(GapModel.forcePrying, 0);  % always 0 for L-flanges
            Obj.verifyLessThan(GapModel.forceTiltClose, 0);  % always negative (favorable) for L-flanges
            Obj.verifyGreaterThan(GapModel.stiffnessFlange, 1);
            Obj.verifyGreaterThan(GapModel.stiffnessShell, 1);
            Obj.verifyGreaterThan(GapModel.stiffnessGapTotal, 1);
            Obj.verifyGreaterThan(GapModel.stiffnessSegment, 1);
            Obj.verifyGreaterThan(GapModel.stiffnessCorrectionFactor, 1);
        end

        function create__tflange(Obj)
            % GIVEN
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.TFlangeSegmentModelFixture()).data;
            Gap = usain.sgre2.GapData(deg2rad(60), 7.5, 1.4e-3);
            preload = 909000;
            stiffnessShell = 123e6;
            gapCloseStiffnessRatio = 0.5;
            Tilt = usain.sgre2.TiltData(deg2rad(0.2), Unit.deg, SegmentFixture.flangeWidth);

            % WHEN
            GapModel = usain.sgre2.GapCloseModel.create( ...
                Gap, SegmentFixture, preload, stiffnessShell, Tilt, gapCloseStiffnessRatio);

            % THEN
            Obj.verifyEqual(GapModel.Gap.angle, deg2rad(60), 'AbsTol', 1e-4);
            Obj.verifyEqual(GapModel.Tilt.angle, deg2rad(0.2), 'AbsTol', 1e-4);
            Obj.verifyGreaterThan(GapModel.Tilt.linear, 0);
            Obj.verifyGreaterThan(GapModel.forceGapClose, 1);
            Obj.verifyGreaterThan(GapModel.forceParallelGapClose, 1);
            Obj.verifyGreaterThan(GapModel.forcePrying, 1);
            Obj.verifyGreaterThan(GapModel.forceTiltClose, 1);
            Obj.verifyGreaterThan(GapModel.stiffnessFlange, 1);
            Obj.verifyGreaterThan(GapModel.stiffnessShell, 1);
            Obj.verifyGreaterThan(GapModel.stiffnessGapTotal, 1);
            Obj.verifyGreaterThan(GapModel.stiffnessSegment, 1);
            Obj.verifyGreaterThan(GapModel.stiffnessCorrectionFactor, 1);
        end

        function create__array_input(Obj)
            % GIVEN array (n>1) inputs for GapCloseModel creation
            n = 2;
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture(n = n)).data;
            Gap = usain.sgre2.GapData(deg2rad(70), 7.5 * ones(n, 1));
            preload = 2359000 * ones(n, 1);
            stiffnessShell = 4251.872924866155e5 * ones(n, 1);
            gapCloseStiffnessRatio = 0.5;
            Tilt = usain.sgre2.TiltData(deg2rad(0.2), Unit.deg, SegmentFixture.flangeWidth);

            % WHEN, THEN
            GapModel = usain.sgre2.GapCloseModel.create( ...
                Gap, SegmentFixture, preload, stiffnessShell, Tilt, gapCloseStiffnessRatio);

            Obj.verifySize(GapModel.Gap, [1, 1]);
            Obj.verifySize(GapModel.Gap.angle, [1, 1]);

            Obj.verifySize(GapModel.Tilt, [1, 1]);
            Obj.verifySize(GapModel.Tilt.angle, [n, 1]);
            Obj.verifySize(GapModel.Tilt.linear, [n, 1]);

            Obj.verifySize(GapModel.forceGapClose, [n, 1]);
            Obj.verifySize(GapModel.forceParallelGapClose, [n, 1]);
            Obj.verifySize(GapModel.forcePrying, [n, 1]);
            Obj.verifySize(GapModel.forceTiltClose, [n, 1]);
            Obj.verifySize(GapModel.stiffnessFlange, [n, 1]);
            Obj.verifySize(GapModel.stiffnessShell, [n, 1]);
            Obj.verifySize(GapModel.stiffnessGapTotal, [n, 1]);
            Obj.verifySize(GapModel.stiffnessSegment, [n, 1]);
            Obj.verifySize(GapModel.stiffnessCorrectionFactor, [n, 1]);
        end

    end
end
