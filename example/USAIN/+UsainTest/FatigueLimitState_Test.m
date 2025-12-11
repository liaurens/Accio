classdef FatigueLimitState_Test < UsainTest.UsainTestCase

    properties
        TestObj UsainUtils.FatigueLimitState
    end

    methods (TestMethodSetup)

        function init_test_object(Obj)
            Obj.TestObj = UsainUtils.FatigueLimitState(1);
        end

    end

    methods (Test, TestTags = {'unit'})

        function calc_cycles_to_failure__mex_faster_than_m(Obj)
            % With USAIN specific inputs, verify the mex/C implementation of
            % sn_curve.SnCurve.calc_cycles_to_failure to be faster than the
            % Matlab native implementation

            % Define random stress spectrum with values in range [0, 200] MPa,
            % with "small" array size to keep unit test fast
            stress = 200 .* rand(100, 5);
            Sn = Obj.get_sncurve_object("EC3_DC36*");

            timeM = timeit(@() Sn.calc_cycles_to_failure(stress));
            timeC = timeit(@() Sn.calc_cycles_to_failure_mex(stress));
            Obj.verifyLessThan(timeC, timeM);
        end

        function calc_cycles_to_failure__mex_same_results_as_m(Obj)
            % With USAIN specific inputs, verify the mex/C implementation of
            % sn_curve.SnCurve.calc_cycles_to_failure to give the same output
            % as the Matlab native implementation

            % Define random stress spectrum with values in range [0, 200] MPa,
            % with "small" array size to keep unit test fast
            stress = 200 .* rand(100, 5);
            Sn = Obj.get_sncurve_object("EC3_DC36*");

            outM = Sn.calc_cycles_to_failure(stress);
            outC = Sn.calc_cycles_to_failure_mex(stress);

            Obj.verifyEqual(outC, outM, 'RelTol', 5 * eps);
        end

        function setup_sn_curve__expected(Obj)
            % GIVEN
            Test = UsainUtils.FatigueLimitState(1);
            Test.Mdl.Inputs.BoltFls.SN_CURVE_BOLT = "EC3_DC90";
            Test.Mdl.Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = 0.25;

            % WHEN
            actual = Test.setup_sn_curve();

            % THEN
            Obj.assertSize(actual, [1 1]);
            Obj.assertClass(actual, 'sn_curve.SnCurve');
            Obj.assertEqual(actual.tRef, 30e-3, 'AbsTol', 1e-8);
            Obj.assertEqual(actual.tExp, 0.25, 'AbsTol', 1e-8);
        end

        function setup_sn_curve__thickness_exponent(Obj)
            % GIVEN
            Test = UsainUtils.FatigueLimitState(1);
            Test.Mdl.Inputs.BoltFls.SN_CURVE_BOLT = "EC3_DC36*";

            % WHEN we set THICKNESS_EXPONENT_BOLT to several values
            Test.Mdl.Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = 0.25;
            Sn = Test.setup_sn_curve();
            actual_0p25 = Sn.tExp;
            Test.Mdl.Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = 0.10;
            Sn = Test.setup_sn_curve();
            actual_0p10 = Sn.tExp;

            % THEN
            Obj.assertEqual(actual_0p25, 0.25, 'AbsTol', 1e-8);
            Obj.assertEqual(actual_0p10, 0.10, 'AbsTol', 1e-8);
        end

        function calc_size_effect__benchmark(Obj)
            % Does calc_size_effect returns values that are as expected (from
            % benchmark)?

            expect = [1.2086; 1.2447]; % 2020-02-21
            Obj.TestObj.SnCurve = Obj.get_sncurve_object("EC3_DC36*");
            Obj.TestObj.SnCurve.tExp = 0.25;
            Obj.TestObj.Mdl.Bolt.diam = 1e-3 * [64; 72];
            actual = Obj.TestObj.calc_size_effect();
            Obj.verifyEqual(actual, expect, 'AbsTol', 5e-5);
        end

        function calc_stress_factor__benchmark(Obj)
            % Does calc_stress_factor returns values that are as expected (from
            % benchmark)?

            expect = [1.5107; 1.5559]; % 2020-02-21

            % Setup benchmark conditions
            Obj.TestObj.sizeEffect = [1.2086; 1.2447];
            Obj.TestObj.Mdl.Inputs.PSF_CMPCLASS2_FLS = 1;
            Obj.TestObj.Mdl.Inputs.BoltFls.PSF_BOLT_MATERIAL_FLS = 1.25;
            Obj.TestObj.Mdl.Inputs.ADDITIONAL_SCF_FLS = 1;

            actual = Obj.TestObj.calc_stress_factor();
            Obj.verifyEqual(actual, expect, 'AbsTol', 5e-5);
        end

        function calc_pm_sum__reduced_equal_to_full(Obj)
            % GIVEN pre-defined inputs
            Obj.TestObj = Obj.setup_benchmark();

            moment = [-7e7, -6.9e7; 6.9e7, 7e7];
            cycles = [5e3; 5e4];

            % WHEN calculating PM sums with full design space and an internally
            % reduced design space
            pmFull = Obj.TestObj.calc_pm_sum_full(moment, cycles);
            pmRed = Obj.TestObj.calc_pm_sum(moment, cycles);

            % THEN expect equal results.
            Obj.verifyEqual(pmFull, pmRed, 'AbsTol', 1e-6);
        end

        function get_description__happy(Obj)
            % GIVEN, WHEN, THEN
            Obj.verifyEqual(UsainUtils.FatigueLimitState(1).description, "Fatigue limit state (set #1)"); % mh:ignore_style
            Obj.verifyEqual(UsainUtils.FatigueLimitState(99).description, "Fatigue limit state (set #99)"); % mh:ignore_style
        end

    end

    methods (Static)

        function Sn = get_sncurve_object(snCurve)
            % Returns default S-N curve used in USAIN
            FatigueParameters = fatigue_parameters.FatigueParameters();
            SnLib = FatigueParameters.SnCurveLib;
            Sn = SnLib.get_sn_curve(snCurve);
        end

        function Obj = setup_benchmark()
            % Construct instance of class under test and subclasses

            % Set up a small design space, 1 bolt option(2 lengths), 2 options
            % for width, thickness and nBolts, hence 2^4 = 16 designCombs.
            width = [0.249, 0.250];
            thickness = [0.121, 0.122];
            nBolt = [136, 140];
            opts = [1, 2];

            desCombs = allcomb(width, thickness, nBolt, opts);
            Mdl = UsainUtils.FlangeModel();
            Mdl.Space.width = desCombs(:, 1);
            Mdl.Space.thickness = desCombs(:, 2);
            Mdl.Space.nBolts = desCombs(:, 3);
            Mdl.Space.boltId = desCombs(:, 4);
            nPts = size(Mdl.Space.nBolts, 1);

            Mdl.Inputs.thicknNoseUp = 30e-3;
            Mdl.Inputs.thicknNoseLo = 30e-3;
            Mdl.diameterOutNeck = 6 * ones(nPts, 1);
            Mdl.Inputs.PSF_CMPCLASS2_FLS = 1;
            Mdl.Inputs.BoltFls.PSF_BOLT_MATERIAL_FLS = 1;
            Mdl.Inputs.ADDITIONAL_SCF_FLS = 1;
            Mdl.Inputs.BoltFls.BOLT_FORCE_MODEL = "schmidtneuper";
            Mdl.Inputs.BoltFls.SN_CURVE_BOLT = "EC3_DC36*";
            Mdl.Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = 0.25;
            Mdl.Inputs.BoltFls.CUSTOM_PRELOAD = nan(nPts, 1);
            Mdl.Inputs.BoltFls.PRELOAD_LOSS_FACTOR_FLS = 0.90;
            Mdl.Inputs.MACRO_GEOMETRIC_SCF = 1.0;

            Mdl.Loads.Inputs.PSF_FAVORABLE_LOADS = 1;

            Mdl.Tool.defaultPreload = 1280000 * ones(nPts, 1);
            Mdl.Bolt.areaStress = 2e-3 * ones(nPts, 1);
            Mdl.Segment = UsainUtils.SegmentModel('Mdl', Mdl);

            % Construct BoltForceModel class, the benchmark uses SchmidtNeuper
            Mdl.Segment.distRim = 0.145 * ones(nPts, 1);
            Mdl.Segment.distForce = 0.09 * ones(nPts, 1);
            Mdl.Segment.loadFactor = 0.2 * ones(nPts, 1);

            % Set up actual test object
            Obj = UsainUtils.FatigueLimitState(1, 'Mdl', Mdl);
            Obj.setup_condition();

            Obj.SnCurve = Obj.setup_sn_curve();
            Obj.sizeEffect = 1.17 * ones(nPts, 1);
        end

    end
end
