classdef (SharedTestFixtures = {Unittest.fixtures.RandomNumberGeneratorFixture(0)}) ...
        FlangeNeckScf_Test < Unittest.TestCase

    methods (Test, TestTags = {'integration'})

        function evaluate_condition__happy_case(Obj)
            % GIVEN a test instance with pre-defined properties
            TestObj = Obj.setup_benchmark();

            % WHEN evaluate the fatigue damage due to flange neck SCFs
            TestObj.evaluate_condition();

            % THEN we expect no error, properties assigned with correct sizes,
            % and benchmarked PM-sums
            Obj.verifySize(TestObj.pmSumNorm, [4, 1]);
            Obj.verifySize(TestObj.scfEqv, [4, 1]);
            Obj.verifyEqual(TestObj.pmSumNorm, [0.2448, 0.1119, 0.0073, 0.0108]', 'AbsTol', 1e-4);
            Obj.verifyEqual(TestObj.scfEqv, [1.5907, 1.4970, 0.7872, 0.9372]', 'AbsTol', 1e-4);
            Obj.verifyEqual(TestObj.BendOpen.preload, 1810980, 'AbsTol', 1e-4);

            % WHEN using a CUSTOM_PRELOAD
            TestObj.Mdl.Inputs.FlangeNeckScf.CUSTOM_PRELOAD = 2.5e+06;
            f = @() TestObj.evaluate_condition();

            % THEN
            Obj.verify_error_free(f);
            Obj.verifyEqual(TestObj.BendOpen.preload, 0.9 * 2.5e6, 'AbsTol', 1e-4);
        end

        function calc_eqv_scf_iterative__damage_comparison(Obj)
            % GIVEN S-N curves for linear and nonlinear damage calculations
            FatigueParameters = fatigue_parameters.FatigueParameters();
            Lib = FatigueParameters.SnCurveLib;
            NeckScf = UsainUtils.FlangeNeckScf();
            NeckScf.SnCurve = Lib.get_sn_curve('SGRE_110');

            % ... and a fictitious fatigue spectrum (stress and cycles)
            stressNominal = 1e9 * rand(10, 1);
            stressHotspot = (1 + rand(10, 1)) .* stressNominal;
            cycles = 10 * ones(size(stressNominal));

            % WHEN computing the "nonlinear" damage (i.e. hotspot stress with `NeckScf.SnCurve`)
            pmActual = NeckScf.calc_damage_sum(NeckScf.SnCurve, stressHotspot, cycles);

            % ... and WHEN computing the linearized SCF for nominal stress and `NeckScf.SnCurve_forScf`, and
            % correspondingly the "linear" damage
            linearScf = NeckScf.calc_eqv_scf_iterative(stressNominal, cycles, pmActual);
            pmLinearized = NeckScf.calc_damage_sum(NeckScf.SnCurve, linearScf * stressNominal, cycles);

            % THEN expect both PM-sums to be equal
            Obj.verifyEqual(pmActual, pmLinearized, 'AbsTol', 1e-4);
        end

    end

    methods (Test, TestTags = {'unit'})

        function do_assess__no_selected_model(Obj)
            % GIVEN a FlangeNeckScf condition with a SelectedModel
            Condition = UsainUtils.FlangeNeckScf();
            Condition.Mdl = struct();

            % WHEN the inputs enable the condition and describe an L-flange
            % THEN expect do_assess to return FALSE because the condition does not have a SelectedModel
            Condition.Mdl.Inputs.DO_ASSESS_FLANGE_NECK_SCF = true;
            Condition.Mdl.Inputs.flangeType = 'L';
            Obj.verifyFalse(Condition.do_assess());
        end

        function do_assess__l_flange(Obj)
            % GIVEN a FlangeNeckScf condition with a SelectedModel
            Condition = UsainUtils.FlangeNeckScf();
            Condition.Mdl = UsainUtils.SelectedModel();

            % WHEN the inputs enable the condition and describe an L-flange
            % THEN expect do_assess to return TRUE
            Condition.Mdl.Inputs.DO_ASSESS_FLANGE_NECK_SCF = true;
            Condition.Mdl.Inputs.flangeType = 'L';
            Obj.verifyTrue(Condition.do_assess());

            % WHEN the inputs disable the condition and describe an L-flange
            % THEN expect do_assess to return FALSE
            Condition.Mdl.Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;
            Condition.Mdl.Inputs.flangeType = 'L';
            Obj.verifyFalse(Condition.do_assess());
        end

        function do_assess__t_flange(Obj)
            % GIVEN a FlangeNeckScf condition with a SelectedModel
            Condition = UsainUtils.FlangeNeckScf();
            Condition.Mdl = UsainUtils.SelectedModel();

            % WHEN the inputs enable the condition and describe an T-flange
            % THEN expect do_assess to return FALSE
            Condition.Mdl.Inputs.DO_ASSESS_FLANGE_NECK_SCF = true;
            Condition.Mdl.Inputs.flangeType = 'T';
            Obj.verifyFalse(Condition.do_assess());

            % WHEN the inputs disable the condition and describe an T-flange
            % THEN expect do_assess to return FALSE
            Condition.Mdl.Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;
            Condition.Mdl.Inputs.flangeType = 'T';
            Obj.verifyFalse(Condition.do_assess());
        end

        function setup_sn_curve__return_object(Obj)
            % GIVEN
            TestObj = UsainUtils.FlangeNeckScf();

            % WHEN querying an S-N curve instance
            actual = TestObj.setup_sn_curve('EC3_DC100');

            % THEN
            Obj.verifyNotEmpty(actual);
            Obj.verifySize(actual, [1 1]);
            Obj.verifyClass(actual, 'sn_curve.SnCurve');
        end

        function calc_size_effect__no_sn_curve_setup(Obj)
            % GIVEN a FlangeNeckScf object without properly setup S-N curve
            TestObj = UsainUtils.FlangeNeckScf();

            % WHEN
            f = @() TestObj.calc_size_effect();

            % THEN
            Obj.verifyError(f, 'FlangeNeckScf:NoSnCurve');
        end

        function calc_size_effect__benchmark(Obj)
            % GIVEN a FlangeNeckScf object with S-N curve object
            FatigueParameters = fatigue_parameters.FatigueParameters();
            Lib = FatigueParameters.SnCurveLib;
            TestObj = UsainUtils.FlangeNeckScf();
            TestObj.SnCurve = Lib.get_sn_curve('EC3_DC100');
            TestObj.Mdl.Inputs.thicknNoseUp = 75e-3;
            TestObj.Mdl.Inputs.thicknNoseLo = 25e-3;

            % WHEN we compute the size effect
            actual = TestObj.calc_size_effect();

            % THEN we expect some benchmarked result
            expect = [1.2457, 1.0000];
            Obj.verifySize(actual, [1 2]);
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-4);

            % WHEN the nose thickness is below the threshold of 25mm
            TestObj.Mdl.Inputs.thicknNoseLo = 20e-3;
            actual = TestObj.calc_size_effect();

            % THEN the thickness effect is limited to 1.00
            Obj.verifyEqual(actual(2), 1.00, 'AbsTol', 1e-4);
        end

        function calc_nominal_stress__benchmark(Obj)
            % GIVEN sufficient inputs to compute the section modulus of a shell
            TestObj = UsainUtils.FlangeNeckScf();
            TestObj.Mdl.Inputs.thicknNoseUp = 75e-3;
            TestObj.Mdl.Inputs.thicknNoseLo = 25e-3;
            TestObj.Mdl.diameterOutNeck = 6;
            TestObj.Mdl.Inputs.MACRO_GEOMETRIC_SCF = 1.0;

            % WHEN we compute the nominal stress given some bending moments
            moment = [-100, 0, 1, 100];
            [actualUp, actualLo] = TestObj.calc_nominal_stress(moment);

            % THEN we expect some benchmarked results
            expectUp = 0.4896 * moment;
            expectLo = 1.4325 * moment;
            Obj.verifyEqual(actualUp, expectUp, 'AbsTol', 1e-2);
            Obj.verifyEqual(actualLo, expectLo, 'AbsTol', 1e-2);
        end

        function calc_stress_factor__benchmark(Obj)
            % GIVEN sufficient inputs to compute the stress factor
            TestObj = UsainUtils.FlangeNeckScf();
            TestObj.Mdl.Inputs.PSF_CMPCLASS2_FLS = 1.1;
            TestObj.Mdl.Inputs.PSF_FLANGE_MATERIAL_FLS = 1.2;
            TestObj.sizeEffect = [1.1, 1.2];

            % WHEN we compute the stress factor
            actual = TestObj.calc_stress_factor();

            % THEN we expect some benchmarked results
            expect = [1.4520, 1.5840];
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-4);
        end

        function normalize_pm_sum__non_unity_target(Obj)
            % GIVEN a target PM-sum < 1.00
            TestObj = UsainUtils.FlangeNeckScf();
            TestObj.Mdl.Inputs.FlangeNeckScf.TARGET_PM_SUM = 0.50;

            % WHEN we normalize a PM-sum
            pm = ones(1, 4);
            actual = TestObj.normalize_pm_sum(pm);

            % THEN we expect the normalized PM-sum to be pm / target = 0.5
            expect = 2 * ones(1, 4);
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-6);
        end

        function normalize_pm_sum__unity_target(Obj)
            % GIVEN a target PM-sum == 1.00
            TestObj = UsainUtils.FlangeNeckScf();
            TestObj.Mdl.Inputs.FlangeNeckScf.TARGET_PM_SUM = 1.00;

            % WHEN we normalize a PM-sum
            pm = ones(1, 4);
            actual = TestObj.normalize_pm_sum(pm);

            % THEN we expect the normalized PM-sum to be pm / target = 1.00
            Obj.verifyEqual(actual, pm, 'AbsTol', 1e-6);
        end

        function calc_eqv_scf_iterative__expected(Obj)
            % GIVEN a test object with properties to compute an equivalent SCF
            FatigueParameters = fatigue_parameters.FatigueParameters();
            Lib = FatigueParameters.SnCurveLib;
            TestObj = UsainUtils.FlangeNeckScf();
            TestObj.SnCurve = Lib.get_sn_curve('EC3_DC90');

            % WHEN computing the SCF with a random stress vector
            stress = 1e10 * ones(10, 1);
            cycles = ones(size(stress));
            target = 1;
            actual = TestObj.calc_eqv_scf_iterative(stress, cycles, target);

            % THEN we expect a benchmarked SCF
            expect = 0.5263;
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-4);
        end

    end

    methods (Static)

        function Obj = setup_benchmark()
            % Construct instances of class under test and dependent classes
            Mdl = UsainUtils.SelectedModel('flangeType', usain.inputs.FlangeType.L);
            Obj = UsainUtils.FlangeNeckScf('Mdl', Mdl);
            Obj.Mdl.Space = usain.space.DesignSpace();
            Obj.Mdl.Segment = UsainUtils.SegmentModel();

            % Mimic USAIN inputs of benchmark flange
            Obj.Mdl.Space.width = 323e-3;
            Obj.Mdl.Space.thickness = 150e-3;
            Obj.Mdl.Space.nBolts = 160;
            Obj.Mdl.Space.boltId = 1;

            Obj.Mdl.diameterOutNeck = 7;
            Obj.Mdl.Inputs.thicknNoseUp = 75e-3;
            Obj.Mdl.Inputs.thicknNoseLo = 85e-3;
            Obj.Mdl.Inputs.heightNoseUp = 62e-3;
            Obj.Mdl.Inputs.heightNoseLo = 62e-3;
            Obj.Mdl.Inputs.diamBoltCircle = 6675e-3;
            Obj.Mdl.Inputs.FlangeNeckScf.CUSTOM_PRELOAD = NaN;
            Obj.Mdl.Inputs.FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS = 0.90;
            Obj.Mdl.Inputs.MACRO_GEOMETRIC_SCF = 1.0;
            Obj.Mdl.Inputs.BoltFls.PRELOAD_LOSS_FACTOR_FLS = 0.90;
            Obj.Mdl.Bolt.diam = 72e-3;
            Obj.Mdl.Tool.defaultPreload = 2.0122e6;
            Obj.Mdl.Segment.loadFactor = 0.1372;
            Obj.Mdl.Segment.resilBolt = 6e-10;
            Obj.Mdl.Segment.distRim = 160.5e-3;

            Obj.Mdl.Inputs.DO_ASSESS_FLANGE_NECK_SCF = true;
            Obj.Mdl.Inputs.SN_CURVE_NECK = 'EC3_DC100';
            Obj.Mdl.Inputs.E_FLANGE = 210e9;
            Obj.Mdl.Inputs.REACTION_DISTANCE_METHOD = 'tobinaga';
            Obj.Mdl.Inputs.FlangeNeckScf.TARGET_PM_SUM = 1.00;
            Obj.Mdl.Inputs.PSF_CMPCLASS2_FLS = 1.00;
            Obj.Mdl.Inputs.PSF_FLANGE_MATERIAL_FLS = 1.25;
            Obj.Mdl.Inputs.BEVEL_ANGLE = Unit.deg.to_si(42);
            Obj.Mdl.Inputs.BEVEL_ROOT_FACE = 4e-3;
            Obj.Mdl.Inputs.RADIUS_SHIFT_SHELL = 0;
            Obj.Mdl.Inputs.RADIUS_SHIFT_FLANGE = 0;
            Obj.Mdl.Inputs.DEL_WOHLER_SLOPE = 4;

            Obj.Mdl.Loads.Inputs.Loads.ulsFilePath = {''}; % For getter nLoadSets
            Obj.Mdl.Loads.flsMxyDesign{1} = [1.1e6, 0.9e6] .* [-150, -20, 0, 1, 20, 150]';
            Obj.Mdl.Loads.flsMxyDesignInv = Obj.Mdl.Loads.flsMxyDesign;
            Obj.Mdl.Loads.flsCycles{1} = 1e8 * ones(length(Obj.Mdl.Loads.flsMxyDesign{1}), 1);
            Obj.Mdl.Loads.inclinMomentFlsDesign = 0;
        end

    end
end
