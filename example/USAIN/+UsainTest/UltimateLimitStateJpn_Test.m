classdef UltimateLimitStateJpn_Test < UsainTest.UsainTestCase

    properties (TestParameter)
        nDesignPt = {1, 10}
        nLoadSet  = {1, 10}
    end

    methods (Test, TestTags = {'integration'})

        function evaluate_condition__happy_case(Obj)
            % GIVEN a test instance with pre-defined properties
            Test = Obj.setup_benchmark();

            % WHEN we try to evaluate the condition
            f = @() Test.evaluate_condition();

            % THEN we expect no error, properties assigned with correct sizes, and benchmarked utilizations
            Obj.verify_error_free(f);
            Obj.assertEqual(Test.fDesign, 1e6 * [0.9616, 0.6450, 1.6853], 'RelTol', 1e-4);
            Obj.assertEqual(Test.psfYield, [1.2500, 1.8750, 1.0000], 'RelTol', 1e-4);
            Obj.assertEqual(Test.yieldStrengthDes, ones(1, 3) * 2.6818e+08, 'RelTol', 1e-4);
            Obj.assertEqual(Test.failModeA, 1e6 * [0.8109, 0.5406, 1.0136], 'RelTol', 1e-4);
            Obj.assertEqual(Test.failModeB, 1e6 * [0.9486, 0.6783, 1.1513], 'RelTol', 1e-4);
            Obj.assertEqual(Test.failModeC, ones(1, 3) * 7.9465e5, 'RelTol', 1e-4);
            Obj.assertEqual(Test.utilRatio, [1.2101, 1.1931, 2.1209], 'AbsTol', 1e-4);
        end

    end

    methods (Test, TestTags = {'unit'})

        function calc_effective_rim_distance__seidel_not_supported(Obj)
            % GIVEN the string 'seidel' for input REACTION_DISTANCE_METHOD
            Test = UsainUtils.UltimateLimitStateJpn();
            Test.Mdl.Inputs.REACTION_DISTANCE_METHOD = 'seidel';

            % WHEN we want to compute value a'
            % THEN
            Obj.assertError(@() Test.calc_effective_rim_distance(), ...
                'MATLAB:UltimateLimitStateJpn:unrecognizedStringChoice');
        end

        function determine_utilization__n_design_points_n_load_sets(Obj, nDesignPt, nLoadSet)
            % GIVEN dummy failure mode results for N design points and M load sets, where failure mode A is
            % force to be critical
            Test = UsainUtils.UltimateLimitStateJpn();
            Test.failModeA = 1 * ones(nDesignPt, nLoadSet);
            Test.failModeB = 2 * ones(nDesignPt, nLoadSet);
            Test.failModeC = 3 * ones(nDesignPt, 1);
            Test.fDesign = rand(nDesignPt, nLoadSet); % < 1

            % WHEN we determine the ULS util ratio
            actual = Test.determine_utilization();

            % THEN we expect an NxM array equal to the util ratio for failure mode A
            Obj.assertSize(actual, [nDesignPt, nLoadSet]);
            Obj.assertEqual(actual, Test.fDesign, 'AbsTol', 1e-6);
        end

        function calc_design_tension_resistance_bolt__different_psfs(Obj)
            % GIVEN dummy input for M=3 design points and N=2 load sets
            Test = UsainUtils.UltimateLimitStateJpn();
            Test.Mdl.Bolt.ftRc = 1000 * ones(3, 1);
            Test.psfYield = [1, 2];

            % WHEN
            actual = Test.calc_design_tension_resistance_bolt();

            % THEN
            expect = ones(3, 1) * [900, 450];
            Obj.assertEqual(actual, expect, 'AbsTol', 1e-6);
        end

        function calc_bolt_yield_psf__different_valid_load_events(Obj)
            % GIVEN
            Test = UsainUtils.UltimateLimitStateJpn();
            Test.Mdl.Loads.Uls(1).tag = 'shortTerm';
            Test.Mdl.Loads.Uls(2).tag = 'longTerm';
            Test.Mdl.Loads.Uls(3).tag = 'seismic';
            Test.Mdl.Inputs.PSF_BOLT_RESISTANCE_JPN_TAG = {Test.Mdl.Loads.Uls.tag};
            Test.Mdl.Inputs.PSF_BOLT_RESISTANCE_JPN = [1, 2, 3];

            % WHEN
            actual = Test.calc_bolt_yield_psf();

            % THEN
            Obj.assertEqual(actual, [1, 2, 3], 'AbsTol', 1e-6);
        end

        function calc_design_yield_strength(Obj)
            % GIVEN
            Test = UsainUtils.UltimateLimitStateJpn();
            Test.Mdl.Inputs.PSF_CMPCLASS2_ULS = 1.23;
            Test.Mdl.Inputs.PSF_MATERIAL_ULS = 4.56;
            Test.Mdl.Inputs.yieldStrengthChar = 7.89;
            Test.Mdl.Inputs.countryCode = 'JPN';
            Test.Mdl.Loads.nLoadSets = 2;

            % WHEN
            actual = Test.calc_design_yield_strength();

            % THEN we expect an 1xM array (for M load sets) similar to the case of UsainUtils.UlsCondition
            Obj.assertSize(actual, [1, 2]);

            % THEN excpect the values to be identical
            expect = ones(1, 2) * 1.406718;
            Obj.assertEqual(actual, expect, 'AbsTol', 1e-6);
        end

        function calc_outer_width__L_benchmark(Obj)
            % GIVEN pre-defined inputs for L-flange
            Test = Obj.setup_benchmark();

            % WHEN calculating outer width for failmodes
            b = Test.calc_outer_width();

            % THEN
            expected_notModeC = 0.105;
            Obj.verifyEqual(b, expected_notModeC, 'AbsTol', 1e-6);

        end

        function calc_outer_width__T_benchmark(Obj)
            % GIVEN pre-defined inputs for T-flange
            Test = Obj.setup_benchmark();
            Test.Mdl.flangeType = 'T';

            % WHEN calculating outer width for failmodes
            b = Test.calc_outer_width();

            % THEN
            expected_notModeC = 0.0690;
            Obj.verifyEqual(b, expected_notModeC, 'AbsTol', 1e-6);

        end

    end

    methods (Static)

        function Test = setup_benchmark()
            Test = UsainUtils.UltimateLimitStateJpn();

            Test.Mdl.flangeType = 'L';
            Test.Mdl.flangeTypeFactor = 1;

            Test.Mdl.Inputs.countryCode = 'JPN';
            Test.Mdl.Inputs.thicknNoseUp = 62e-3;
            Test.Mdl.Inputs.thicknNoseLo = 62e-3;
            Test.Mdl.diameterOutNeck = 6;
            Test.Mdl.Inputs.REACTION_DISTANCE_METHOD = 'tobinaga';
            Test.Mdl.Inputs.diamBoltHole = 61e-3;
            Test.Mdl.Inputs.yieldStrengthChar = 295e6;
            Test.Mdl.Inputs.PSF_BOLT_RESISTANCE_JPN_TAG = {'shortTerm', 'longTerm', 'seismic'};
            Test.Mdl.Inputs.PSF_BOLT_RESISTANCE_JPN = [1.2500, 1.8750, 1.0000];
            Test.Mdl.Inputs.PSF_CMPCLASS2_ULS = 1;
            Test.Mdl.Inputs.PSF_MATERIAL_ULS = 1.1;
            Test.Mdl.Inputs.ADDITIONAL_SCF_ULS = 1.0;
            Test.Mdl.Inputs.FILLET_RADIUS = 10e-3;

            Test.Mdl.Space.thickness = 112e-3;
            Test.Mdl.Space.nBolts = 148;
            Test.Mdl.Space.nPoints = 1;

            Test.Mdl.Bolt.ftRc = 1000e6 * 2030e-6;
            Test.Mdl.Wash.diamOut = 105e-3;

            Test.Mdl.Loads.nLoadSets = 3;
            Test.Mdl.Loads.Uls(1).tag = 'shortTerm';
            Test.Mdl.Loads.Uls(2).tag = 'longTerm';
            Test.Mdl.Loads.Uls(3).tag = 'seismic';
            Test.Mdl.Loads.ulsMxyDesign = 1e8 * [2.1746, 1.4789, 3.7647];
            Test.Mdl.Loads.inclinMomentDesign = 1e6 * [5.4821, 5.4821, 5.4821];
            Test.Mdl.Loads.deadWeightFavorDesignUls = 7.8619e+06;

            Test.Mdl.Segment = UsainUtils.SegmentModel('Mdl', Test.Mdl);
            Test.Mdl.Segment.ReactDist = UsainUtils.ReactionDistance(0.1320, 0.1050, 0.112);
            Test.Mdl.Segment.distForce = 0.1050;
            Test.Mdl.Segment.distBolt = 0.1216;
            Test.Mdl.Segment.distBoltAtShell = 0.1260;
        end

    end
end
