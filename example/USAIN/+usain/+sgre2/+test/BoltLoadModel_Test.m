classdef (SharedTestFixtures = {Unittest.fixtures.RandomNumberGeneratorFixture(0)}) ...
        BoltLoadModel_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function getter_fullContactCompression__expected(Obj)
            % GIVEN
            Model = usain.sgre2.BoltLoadModel();
            Model.forceGapClose = 123;
            Model.deadWeight = 234;

            % WHEN, THEN
            Obj.verifyEqual(Model.fullContactCompression, -357, 'RelTol', 1e-4);
        end

        function getter_preloadRatio__expected(Obj)
            % GIVEN
            Model = usain.sgre2.BoltLoadModel();
            Model.Segment = usain.model.SegmentModel(usain.inputs.FlangeType.L);
            Model.forceGapClose = 100;
            Model.preload = 200;

            % WHEN, THEN
            Obj.verifyEqual(Model.preloadRatio, 0.50, 'RelTol', 1e-4);

            % WHEN having a T-flange
            Model.Segment = usain.model.SegmentModel(usain.inputs.FlangeType.T);
            Obj.verifyEqual(Model.preloadRatio, 0.25, 'RelTol', 1e-4);
        end

        function calc_bolt_force__expected(Obj)
            % GIVEN
            Model = usain.sgre2.BoltLoadModel();
            Model.preload = 2359;
            Model.deadWeight = 93.2;
            Model.forceGapClose = 603.4;
            Model.initialSlopeForceCurve = 0.121681;
            Model.minBoltForce = 2322.29;
            Model.polynomialCoeffs = [2371.8, 0.15411, 0.00017483];
            Model.stiffnessCorrectionFactor = 0.1914;

            % WHEN calculating bolt forces for the different regions in the model
            % THEN
            Obj.verifyEqual(Model.calc_bolt_force(0), 2371.8, 'AbsTol', 1e-1);
            Obj.verifyEqual(Model.calc_bolt_force(-93.2), 2359, 'AbsTol', 1e-1);  % limit tensile/compressive
            Obj.verifyEqual(Model.calc_bolt_force(1234), 2828.2, 'AbsTol', 1e-1);  % tensile
            Obj.verifyEqual(Model.calc_bolt_force(-123), 2355.5, 'AbsTol', 1e-1);  % compressive
            Obj.verifyEqual(Model.calc_bolt_force(-1234), 2322.3, 'AbsTol', 1e-1);  % full contact

            % WHEN calculating bolt forces for compressive segment forces lower than the full contact compression force
            % THEN expect a constant minimum bolt force to be returned
            Obj.verifyEqual( ...
                Model.calc_bolt_force(Model.fullContactCompression), ...
                Model.calc_bolt_force(2 * Model.fullContactCompression), 'RelTol', 1e-4);
        end

        function calc_bolt_force__multiple_load_bins(Obj)
            % GIVEN a setup for n>1 design point and n>1 load bins, with a segment force leading to both tensile and
            % compressive bolt forces
            nDesignPoints = 2;
            Model = usain.sgre2.BoltLoadModel();
            Model.preload = ones(nDesignPoints, 1) * 1000;
            Model.deadWeight = ones(nDesignPoints, 1) * 100;
            Model.forceGapClose = ones(nDesignPoints, 1) * 500;
            Model.initialSlopeForceCurve = ones(nDesignPoints, 1) * 0.123;
            Model.minBoltForce = ones(nDesignPoints, 1) * 2000;
            Model.polynomialCoeffs = ones(nDesignPoints, 1) * [1234, 0.123, 0.000456];
            Model.stiffnessCorrectionFactor = ones(nDesignPoints, 1) * 0.20;

            segmentForce = ones(nDesignPoints, 1) * [-1000, -900, -200, -300, 200, 300];
            nLoadBins = size(segmentForce, 2);

            % WHEN, THEN
            actual = Model.calc_bolt_force(segmentForce);
            Obj.verifySize(actual, [nDesignPoints, nLoadBins]);
            Obj.verifyTrue(nnz(isnan(actual)) == 0);
        end

        function calc_bolt_force_compression__expected(Obj)
            % GIVEN the inputs for the "IEC_example_rev2" flange
            Model = usain.sgre2.BoltLoadModel();
            Model.preload = 680747.5;
            Model.deadWeight = 28552.630859375;
            Model.forceGapClose = 513.7e3;
            Model.initialSlopeForceCurve = 0.7329;

            % WHEN computing the (compressive) bolt force for a full contact compressive segment force
            % THEN
            Obj.verifyEqual(Model.fullContactCompression, -542252, 'RelTol', 1e-4);
            Obj.verifyEqual(Model.calc_bolt_force_compression(Model.fullContactCompression), 492502, 'RelTol', 1e-4);

            % WHEN, THEN
            benchmarkForce = -Model.deadWeight + 100;
            Obj.verifyEqual(Model.calc_bolt_force_compression(benchmarkForce), 680820, 'RelTol', 1e-4);
        end

        function calc_bolt_force_tension__expected(Obj)
            % GIVEN
            Model = usain.sgre2.BoltLoadModel();
            Model.polynomialCoeffs = [2371.8, 0.15411, 0.00017483];
            Model.deadWeight = 93.2;

            % WHEN calculating the bolt force for the tensile region
            % THEN
            Obj.verifyEqual(Model.calc_bolt_force_tension(0), 2371.8, 'AbsTol', 1e-1);
            Obj.verifyEqual(Model.calc_bolt_force_tension(100), 2389.0, 'AbsTol', 1e-1);
            Obj.verifyEqual(Model.calc_bolt_force_tension(999), 2700.3, 'AbsTol', 1e-1);
        end

        function calc_bolt_moment__expected(Obj)
            % GIVEN
            Model = usain.sgre2.BoltLoadModel();
            Model.Segment = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            Model.preload = 2359000;
            Model.aModified = 0.0772;
            Model.deadWeight = 93200;
            Model.forceGapClose = 603400;
            Model.initialSlopeMomentCurve = 0.00056;
            Model.residualMoment = -9.87;
            Model.stiffnessCorrectionFactor = 1.19;
            Model.minBoltMoment = -179.07;

            % WHEN calculating bolt moment for the different regions in the model
            % THEN
            Obj.verifyEqual(Model.calc_bolt_moment(1234e3, 2828.2e3), 907867.8565, 'RelTol', 1e-4);  % tensile
            Obj.verifyEqual(Model.calc_bolt_moment(-321e3, 2336.5e3), -113.3578, 'RelTol', 1e-4);  % compressive
            Obj.verifyEqual(Model.calc_bolt_moment(-1234e3, 2322.3e3), -179.0700, 'RelTol', 1e-4);  % full contact
            Obj.verifyEqual(Model.calc_bolt_moment(0, 2359e3), 0, 'RelTol', 1e-4);  % zero external load

            % WHEN calculating bolt moment for compressive segment forces lower than the full contact compression force
            % THEN expect a constant minimum bolt moment to be returned; note fullContactCompression is negative.
            Obj.verifyEqual( ...
                Model.calc_bolt_moment(Model.fullContactCompression, 0), ...
                Model.calc_bolt_moment(2 * Model.fullContactCompression, 0), 'RelTol', 1e-4);
        end

        function calc_bolt_moment__unequal_input_dimensions(Obj)
            % GIVEN
            Model = usain.sgre2.BoltLoadModel();
            Model.Segment = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            Model.preload = 2359000;
            Model.aModified = 0.0772;
            Model.deadWeight = 93200;
            Model.forceGapClose = 603400;
            Model.initialSlopeMomentCurve = 0.00056;
            Model.residualMoment = -9.87;
            Model.stiffnessCorrectionFactor = 1.19;
            Model.minBoltMoment = -179.07;

            % WHEN calling the method with unequal input dimensions
            % THEN expect an error
            f = @() Model.calc_bolt_moment(1234e3, [2828.2e3, 2828e3]);
            Obj.assertError(f, 'BoltLoadModel:InconsistentInputSize');
        end

        function calc_bolt_moment__tflange(Obj)
            % GIVEN
            Model = usain.sgre2.BoltLoadModel();
            Model.Segment = Obj.applyFixture(usain.model.test.fixtures.TFlangeSegmentModelFixture()).data;
            Model.Segment.gModulus = 80.769e9;
            Model.preload = 909000;
            Model.deadWeight = 83636.4;
            Model.forceGapClose = 814000;
            Model.initialSlopeMomentCurve = 0.1351e-3;
            Model.residualMoment = -10.4410;
            Model.stiffnessCorrectionFactor = 1.037;
            Model.minBoltMoment = -65.41;

            % WHEN calculating bolt forces for the different regions in the model
            % THEN
            Obj.verifyEqual(Model.calc_bolt_moment(1234e3, 1073e3), 444.36, 'AbsTol', 1e-2);  % tensile
            Obj.verifyEqual(Model.calc_bolt_moment(-321e3, 900e3), -37.83, 'AbsTol', 1e-2);  % compressive
            Obj.verifyEqual(Model.calc_bolt_moment(-1234e3, 892.5e3), -65.41, 'AbsTol', 1e-2);  % full contact
            Obj.verifyEqual(Model.calc_bolt_moment(0, 912.8e3), 2.0805, 'AbsTol', 1e-2);  % zero external load

            % WHEN calculating bolt moment for compressive segment forces lower than the full contact compression force
            % THEN expect a constant minimum bolt moment to be returned; note fullContactCompression is negative.
            Obj.verifyEqual( ...
                Model.calc_bolt_moment(Model.fullContactCompression, 0), ...
                Model.calc_bolt_moment(2 * Model.fullContactCompression, 0), 'RelTol', 1e-4);
        end

        function calc_bolt_moment__multiple_load_bins(Obj)
            % GIVEN a setup for n>1 design point and n>1 load bins, with a segment force leading to both tensile and
            % compressive bolt moments
            nDesignPoints = 2;
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture(n = nDesignPoints)).data;

            Model = usain.sgre2.BoltLoadModel();
            Model.Segment = SegmentFixture;
            Model.preload = ones(nDesignPoints, 1) * 2359000;
            Model.aModified = ones(nDesignPoints, 1) * 0.080;
            Model.deadWeight = ones(nDesignPoints, 1) * 100000;
            Model.forceGapClose = ones(nDesignPoints, 1) * 600000;
            Model.initialSlopeMomentCurve = ones(nDesignPoints, 1) * 0.0005;
            Model.residualMoment = ones(nDesignPoints, 1) * -10;
            Model.stiffnessCorrectionFactor = ones(nDesignPoints, 1) * 1.23;
            Model.minBoltMoment = ones(nDesignPoints, 1) * -200;

            segmentForce = ones(nDesignPoints, 1) * [-800000, -900000, -500000, -123456, 200000, 123000];
            boltForce = ones(size(segmentForce));
            nLoadBins = size(segmentForce, 2);

            % WHEN, THEN
            actual = Model.calc_bolt_moment(segmentForce, boltForce);
            Obj.verifySize(actual, [nDesignPoints, nLoadBins]);
            Obj.verifyTrue(nnz(isnan(actual)) == 0);
        end

        function calc_bolt_moment_compression__expected(Obj)
            % GIVEN the inputs for the "IEC_example_rev2" flange
            Model = usain.sgre2.BoltLoadModel();
            Model.deadWeight = 28552.630859375;
            Model.forceGapClose = 268065.90625;
            Model.initialSlopeMomentCurve = 0.361127942800522;
            Model.residualMoment = -2201.80688476562;

            % WHEN computing the (compressive) bolt moment for a full contact compressive segment force
            % THEN
            Obj.verifyEqual(Model.fullContactCompression, -296618.53125, 'RelTol', 1e-4);
            Obj.verifyEqual( ...
                Model.calc_bolt_moment_compression(Model.fullContactCompression), -50604.8515143, 'RelTol', 1e-4);

            % WHEN, THEN
            benchmarkForce = -Model.deadWeight + 100;
            Obj.verifyEqual(Model.calc_bolt_moment_compression(benchmarkForce), -2165.69409179687, 'RelTol', 1e-4);
        end

        function calc_bolt_moment_tension__expected(Obj)
            % GIVEN
            Model = usain.sgre2.BoltLoadModel();
            Model.Segment = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            Model.preload = 2359000;
            Model.aModified = 0.0772;
            Model.stiffnessCorrectionFactor = 1.19;

            % WHEN calculating the bolt moment for the tensile region
            % THEN
            Obj.verifyEqual(Model.calc_bolt_moment_tension(0, 2359e3), 0, 'RelTol', 1e-4);
            Obj.verifyEqual(Model.calc_bolt_moment_tension(0, 2371.8e3), 17068.4809, 'RelTol', 1e-4);
            Obj.verifyEqual(Model.calc_bolt_moment_tension(100e3, 2389.0e3), 62873.0814, 'RelTol', 1e-4);
            Obj.verifyEqual(Model.calc_bolt_moment_tension(999e3, 2700.3e3), 683574.6462, 'RelTol', 1e-4);
        end

        function calc_bolt_moment_tension__tflange(Obj)
            % GIVEN
            Model = usain.sgre2.BoltLoadModel();
            Model.Segment = Obj.applyFixture(usain.model.test.fixtures.TFlangeSegmentModelFixture()).data;
            Model.deadWeight = 83636.4;
            Model.forceGapClose = 814000;
            Model.preload = 909000;
            Model.stiffnessCorrectionFactor = 1.037;
            Model.Segment.gModulus = 80769e6;

            % WHEN calculating the bolt moment for the tensile region
            % THEN
            Obj.verifyEqual(Model.calc_bolt_moment_tension(100e3, 918600), 20.32, 'AbsTol', 1e-2);
            Obj.verifyEqual(Model.calc_bolt_moment_tension(-80e3, 909.1e3), -9.97, 'AbsTol', 1e-2);
        end

        function calc_initial_slope_force_curve__expected(Obj)
            % GIVEN the intermediate results of the "IEC_example_rev2" flange
            Model = usain.sgre2.BoltLoadModel();
            Model.polynomialCoeffs = [683793.9375, 0.130250886082649, 8.2500480402814E-07];
            Model.deadWeight = 28552.630859375;

            % WHEN, THEN
            Obj.verifyEqual(Model.calc_initial_slope_force_curve(), 0.0831387713551521, 'RelTol', 1e-3);
        end

        function calc_initial_slope_moment_curve__expected(Obj)
            % GIVEN the intermediate results of the "IEC_example_rev2" flange
            Model = usain.sgre2.BoltLoadModel();
            Model.Segment = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            Model.deadWeight = 28552.630859375;
            Model.preload = 680747.5;
            Model.forceGapClose = 268065.90625;
            Model.initialSlopeForceCurve = 0.0831387713551521;
            Model.residualMoment = -2201.80688476562;
            Model.stiffnessCorrectionFactor = 1.42085576057434;
            Model.aModified = 30.1298522949218e-3;

            % WHEN, THEN
            Obj.verifyEqual(Model.calc_initial_slope_moment_curve(), 1.03337355280133, 'RelTol', 1e-4);
        end

        function calc_residual_moment__expected(Obj)
            % GIVEN the intermediate results of the "IEC_example_rev2" flange
            Model = usain.sgre2.BoltLoadModel();
            Model.Segment = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            Model.deadWeight = 28552.630859375;
            Model.aModified = 30.1298522949218e-3;
            Model.stiffnessCorrectionFactor = 1.42085576057434;

            % WHEN, THEN
            actual = Model.calc_residual_moment();
            Obj.verifyEqual(actual, -2134.3554, 'RelTol', 1e-4);

            % ... as an additional check, the calculated residual moment is expected to be the same as the bolt moment
            % when the segment force equals the dead weight (and the bolt force equals the preload)
            Model.preload = 680747.5;
            Obj.verifyEqual(actual, Model.calc_bolt_moment_tension(-Model.deadWeight, Model.preload), 'RelTol', 1e-4);
        end

        function calc_residual_moment__tflange(Obj)
            % GIVEN a T-flange
            Model = usain.sgre2.BoltLoadModel();
            Model.Segment = Obj.applyFixture(usain.model.test.fixtures.TFlangeSegmentModelFixture()).data;
            Model.deadWeight = 83636.363636;
            Model.stiffnessCorrectionFactor = 1.0366;
            Model.preload = 909000;
            Model.forceGapClose = 814024.5346;

            % WHEN, THEN
            actual = Model.calc_residual_moment();
            Obj.verifyEqual(actual, -10.44085, 'RelTol', 1e-4);

            % ... as an additional check, the calculated residual moment is expected to be the same as the bolt moment
            % when the segment force equals the dead weight (and the bolt force equals the preload)
            Obj.verifyEqual(actual, Model.calc_bolt_moment_tension(-Model.deadWeight, Model.preload), 'RelTol', 1e-4);
        end

        function calc_polynomial_coords__expected(Obj)
            % GIVEN the intermediate results of the "IEC_example_rev2" flange
            Model = usain.sgre2.BoltLoadModel();
            Model.Segment = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            Model.deadWeight = 28552.630859375;
            Model.forceGapClose = 513.7e3;
            Model.preload = 680747.5;
            Model.stiffnessCorrectionFactor = 1.906;

            Inputs.SGRE2.INITIAL_POINT_OFFSET = 0.05;
            Inputs.SGRE2.INITIAL_SLOPE_REFERENCE_PRELOAD = 0.5;

            % WHEN
            [x, y] = Model.calc_polynomial_coords(Inputs);

            % THEN
            Obj.verifySize(x, [1 3]);
            Obj.verifySize(y, [1 3]);
            Obj.verifyEqual(x(1), -28552.630859375, 'RelTol', 1e-4);
            Obj.verifyEqual(x(2), 203609, 'RelTol', 1e-4);
            Obj.verifyEqual(x(3), 50902, 'RelTol', 1e-4);
            Obj.verifyEqual(y(1), 680747.5, 'RelTol', 1e-4);
            Obj.verifyEqual(y(2), 850934.375, 'RelTol', 1e-4);
            Obj.verifyEqual(y(3), 697295, 'RelTol', 1e-4);
        end

        function calc_polynomial_coords__tflange(Obj)
            % GIVEN a T-flange
            Model = usain.sgre2.BoltLoadModel();
            Model.Segment = Obj.applyFixture(usain.model.test.fixtures.TFlangeSegmentModelFixture()).data;
            Model.deadWeight = 83636.363636;
            Model.forceGapClose = 814024.5346;
            Model.preload = 909000;
            Model.stiffnessCorrectionFactor = 1.0366;

            Inputs.SGRE2.INITIAL_POINT_OFFSET = 0.05;
            Inputs.SGRE2.INITIAL_SLOPE_REFERENCE_PRELOAD = 0.5;

            % WHEN
            [x, y] = Model.calc_polynomial_coords(Inputs);

            % THEN
            Obj.verifySize(x, [1 3]);
            Obj.verifySize(y, [1 3]);
            Obj.verifyEqual(x(1), -83636.363636, 'RelTol', 1e-4);
            Obj.verifyEqual(x(2), 1511883.0736, 'RelTol', 1e-4);
            Obj.verifyEqual(x(3), 117785.81012, 'RelTol', 1e-4);
            Obj.verifyEqual(y(1), 909000, 'RelTol', 1e-4);
            Obj.verifyEqual(y(2), 1136250, 'RelTol', 1e-4);
            Obj.verifyEqual(y(3), 919200.66, 'RelTol', 1e-4);
        end

    end

    methods (Test, TestTags = {'integration'})

        function create__expected(Obj)
            % GIVEN inputs for the "IEC_Example_Rev2" flange
            Inputs.SGRE2.INITIAL_POINT_OFFSET = 0.05;
            Inputs.SGRE2.INITIAL_SLOPE_REFERENCE_PRELOAD = 0.5;
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            GapModelFixture = Obj.applyFixture(usain.sgre2.test.fixtures.GapCloseModelFixture()).data;
            deadWeight = 1.3 * 4340e3;
            preload = 680700;

            % WHEN
            % THEN expect that the model can be successfully created and properties are set as expected
            Model = usain.sgre2.BoltLoadModel.create(Inputs, SegmentFixture, GapModelFixture, deadWeight, preload);

            Obj.verifyEqual(Model.preload, 680700, 'RelTol', 1e-4);
            Obj.verifyEqual(Model.deadWeight, 37118.4, 'RelTol', 1e-4);
            Obj.verifyEqual(Model.forceGapClose, 276900, 'RelTol', 1e-4);
            Obj.verifyEqual(Model.stiffnessCorrectionFactor, 1.43, 'RelTol', 1e-4);

            Obj.verifyEqual(Model.fullContactCompression, -314018.4, 'RelTol', 1e-4);

            Obj.assertSize(Model.polynomialCoeffs, [1 3]);
            Obj.verifyEqual(Model.polynomialCoeffs(1), 683542, 'RelTol', 1e-4);
            Obj.verifyEqual(Model.polynomialCoeffs(2), 0.11127, 'RelTol', 1e-4);
            Obj.verifyEqual(Model.polynomialCoeffs(3), 9.345e-7, 'RelTol', 1e-4);
            Obj.verifyEqual(Model.initialSlopeForceCurve, 0.041897, 'RelTol', 1e-4);
            Obj.verifyEqual(Model.minBoltForce, 674899, 'RelTol', 1e-4);

            Obj.verifyEqual(Model.aModified, 0.0472, 'RelTol', 1e-3);
            Obj.verifyEqual(Model.residualMoment, -4319.5, 'RelTol', 1e-4);
            Obj.verifyEqual(Model.initialSlopeMomentCurve, 0.2078, 'RelTol', 1e-3);
            Obj.verifyEqual(Model.minBoltMoment, -33083, 'RelTol', 1e-3);
        end

        function create__array_inputs(Obj)
            % GIVEN array (n>1) inputs for BoltLoadModel creation
            n = 2;
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture(n = n)).data;
            Inputs.SGRE2.GAP_ANGLE = deg2rad(70);
            Inputs.SGRE2.INITIAL_SLOPE_REFERENCE_PRELOAD = 0.2;
            Inputs.SGRE2.INITIAL_POINT_OFFSET = 0.05;
            Inputs.MACRO_GEOMETRIC_SCF = 1.3;
            GapModelFixture = Obj.applyFixture(usain.sgre2.test.fixtures.GapCloseModelFixture(n = n)).data;
            deadWeight = 13800000;
            preload = 2359000 * ones(n, 1);

            % WHEN, THEN
            Model = usain.sgre2.BoltLoadModel.create(Inputs, SegmentFixture, GapModelFixture, deadWeight, preload);

            Obj.verifySize(Model.deadWeight, [n, 1]);
            Obj.verifySize(Model.forceGapClose, [n, 1]);
            Obj.verifySize(Model.fullContactCompression, [n, 1]);
            Obj.verifySize(Model.polynomialCoeffs, [n, 3]);
            Obj.verifySize(Model.initialSlopeForceCurve, [n, 1]);
            Obj.verifySize(Model.minBoltForce, [n, 1]);
            Obj.verifySize(Model.residualMoment, [n, 1]);
            Obj.verifySize(Model.initialSlopeMomentCurve, [n, 1]);
            Obj.verifySize(Model.minBoltMoment, [n, 1]);
        end

        function create__call_internal_methods(Obj)
            % GIVEN array (n>1) inputs for BoltLoadModel creation
            n = 2;
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture(n = n)).data;
            Inputs.SGRE2.GAP_ANGLE = deg2rad(70);
            Inputs.SGRE2.INITIAL_SLOPE_REFERENCE_PRELOAD = 0.2;
            Inputs.SGRE2.INITIAL_POINT_OFFSET = 0.05;
            Inputs.MACRO_GEOMETRIC_SCF = 1.3;
            GapModelFixture = Obj.applyFixture(usain.sgre2.test.fixtures.GapCloseModelFixture(n = n)).data;
            deadWeight = 13800000;
            preload = 2359000 * ones(n, 1);

            % WHEN calling internal methods
            % THEN expect no errors and, where applicable, return arguments with an expected size
            Model = usain.sgre2.BoltLoadModel.create(Inputs, SegmentFixture, GapModelFixture, deadWeight, preload);
            m = 3;
            Obj.verifySize(Model.calc_bolt_force(ones(n, m)), [n, m]);
            Obj.verifySize(Model.calc_bolt_force_compression(ones(n, m)), [n, m]);
            Obj.verifySize(Model.calc_bolt_force_tension(ones(n, m)), [n, m]);
            Obj.verifySize(Model.calc_bolt_moment(ones(n, m), ones(n, m)), [n, m]);
            Obj.verifySize(Model.calc_bolt_moment_compression(ones(n, m)), [n, m]);
            Obj.verifySize(Model.calc_bolt_moment_tension(ones(n, m), ones(n, m)), [n, m]);
            Obj.verifySize(Model.is_width_dependent(ones(n, 1)), [n, 1]);

            % WHEN doing the same, with a T-flange model
            % THEN
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.TFlangeSegmentModelFixture(n = n)).data;
            Model = usain.sgre2.BoltLoadModel.create(Inputs, SegmentFixture, GapModelFixture, deadWeight, preload);
            m = 3;
            Obj.verifySize(Model.calc_bolt_force(ones(n, m)), [n, m]);
            Obj.verifySize(Model.calc_bolt_force_compression(ones(n, m)), [n, m]);
            Obj.verifySize(Model.calc_bolt_force_tension(ones(n, m)), [n, m]);
            Obj.verifySize(Model.calc_bolt_moment(ones(n, m), ones(n, m)), [n, m]);
            Obj.verifySize(Model.calc_bolt_moment_compression(ones(n, m)), [n, m]);
            Obj.verifySize(Model.calc_bolt_moment_tension(ones(n, m), ones(n, m)), [n, m]);
            Obj.verifySize(Model.is_width_dependent(ones(n, 1)), [n, 1]);
        end

        function calc_bolt_force__continuity(Obj)
            % GIVEN the "IEC_Example_Rev2" flange that was used to compare results in the IEC 61400-6/AMD1 working
            % group.
            Inputs.SGRE2.INITIAL_POINT_OFFSET = 0.05;
            Inputs.SGRE2.INITIAL_SLOPE_REFERENCE_PRELOAD = 0.2;
            Inputs.MACRO_GEOMETRIC_SCF = 1.3;
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            GapModelFixture = Obj.applyFixture(usain.sgre2.test.fixtures.GapCloseModelFixture()).data;
            deadWeight = 4340e3;
            preload = 680747.5;

            Model = usain.sgre2.BoltLoadModel.create(Inputs, SegmentFixture, GapModelFixture, deadWeight, preload);

            % WHEN computing the bolt force using the compressive and tensile regions, for an applied segment force
            % equal to the dead weight (=at the boundary between tensile and compressive region)
            forceFromCompression = Model.calc_bolt_force_compression(-Model.deadWeight);
            forceFromTension = Model.calc_bolt_force_tension(-Model.deadWeight);

            % THEN expect the result to be the same (equal to the preload)
            Obj.verifyEqual(forceFromTension, forceFromCompression, 'RelTol', 1e-4);
            Obj.verifyEqual(forceFromTension, Model.preload, 'RelTol', 1e-4);
        end

        function calc_bolt_moment__continuity(Obj)
            % GIVEN the "IEC_Example_Rev2" flange that was used to compare results in the IEC 61400-6/AMD1 working
            % group.
            Inputs.SGRE2.INITIAL_POINT_OFFSET = 0.05;
            Inputs.SGRE2.INITIAL_SLOPE_REFERENCE_PRELOAD = 0.2;
            Inputs.MACRO_GEOMETRIC_SCF = 1.3;
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture()).data;
            GapModelFixture = Obj.applyFixture(usain.sgre2.test.fixtures.GapCloseModelFixture()).data;
            deadWeight = 4340e3;
            preload = 680747.5;

            Model = usain.sgre2.BoltLoadModel.create(Inputs, SegmentFixture, GapModelFixture, deadWeight, preload);

            % WHEN computing the bolt moments using the compressive and tensile regions, for an applied segment force
            % equal to the dead weight (=at the boundary between tensile and compressive region)
            momentFromCompression = Model.calc_bolt_moment_compression(-Model.deadWeight);
            momentFromTension = Model.calc_bolt_moment_tension(-Model.deadWeight, Model.preload);

            % THEN expect the result to be the same
            Obj.verifyEqual(momentFromTension, momentFromCompression, 'RelTol', 1e-4);
        end

    end
end
