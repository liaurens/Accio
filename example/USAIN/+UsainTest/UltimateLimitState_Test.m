classdef UltimateLimitState_Test < UsainTest.UsainTestCase

    methods (Test, TestTags = {'unit'})

        function get_isFeasible_impl__utilization_below_one(Obj)
            % GIVEN all necessary data to call get_isFeasible_impl()
            Uls = UsainUtils.UltimateLimitState();
            Uls.Mdl.flangeType = 'L';
            Uls.failModeA = 1000;
            Uls.failModeB = 100;
            Uls.failModeD = 200;
            Uls.failModeE = 1000;

            % WHEN we set the utilization ratio <= 1.0
            % THEN
            Uls.utilRatio = 1.0;
            Obj.verifyTrue(Uls.get_isFeasible_impl());

            % WHEN we set the utilization ratio > 1.0
            % THEN
            Uls.utilRatio = 1.01;
            Obj.verifyFalse(Uls.get_isFeasible_impl());

            % WHEN we do the same for a T-flange (set FM A to be governing)
            % THEN
            Uls.failModeA = 99;
            Uls.Mdl.flangeType = 'T';
            Uls.utilRatio = 1.0;
            Obj.verifyTrue(Uls.get_isFeasible_impl());
            Uls.utilRatio = 1.01;
            Obj.verifyFalse(Uls.get_isFeasible_impl());
        end

        function get_isFeasible_impl__l_flange_requirements(Obj)
            % GIVEN all necessary data to call get_isFeasible_impl(), with utilization ratio <= 1.0
            Uls = UsainUtils.UltimateLimitState();
            Uls.Mdl.flangeType = 'L';
            Uls.failModeA = 1000;
            Uls.failModeE = 1000;
            Uls.utilRatio = 1.0;

            % WHEN FM B is governing
            % THEN
            Uls.failModeB = 100;
            Uls.failModeD = 101;
            Obj.verifyTrue(Uls.get_isFeasible_impl());

            % WHEN FM D is not governing
            % THEN
            Uls.failModeB = 100;
            Uls.failModeD = 99;
            Obj.verifyFalse(Uls.get_isFeasible_impl());
        end

        function get_isFeasible_impl__t_flange_requirements(Obj)
            % GIVEN all necessary data to call get_isFeasible_impl(), with utilization ratio <= 1.0
            Uls = UsainUtils.UltimateLimitState();
            Uls.Mdl.flangeType = 'T';
            Uls.failModeA = 1000;
            Uls.failModeB = 1000;
            Uls.failModeD = 1000;
            Uls.failModeE = 1000;
            Uls.utilRatio = 1.0;

            % WHEN FM A is not governing
            % THEN
            Uls.failModeA = 1001;
            Obj.verifyFalse(Uls.get_isFeasible_impl());

            % WHEN FM A is governing
            % THEN
            Uls.failModeA = 999;
            Obj.verifyTrue(Uls.get_isFeasible_impl());
        end

        function calc_limit_thickness__happy(Obj)
            % GIVEN inputs to compute the limit thickness
            Test = UsainUtils.UltimateLimitState();
            Test.Mdl.Segment.distForce = [0.10; 0.12];
            Test.Mdl.Segment.distBolt = [0.14; 0.10];
            Test.Mdl.Inputs.diamBoltHole = [60e-3; 64e-3];
            Test.Mdl.Inputs.yieldStrengthChar = [300e6; 323e6];
            Test.Mdl.Bolt.ftRc = 1040e6 * [1200e-3; 1100e-3];
            Test.Mdl.Wash.diamOut = [100e-3; 90e-3];
            Test.Mdl.Wash.len = [10e-3; 0];
            Test.Mdl.Nut.diam = [100e-3; 90e-3];

            % WHEN, THEN
            plastMoment = 1000;
            effRimDist = 0.110;
            actual = Test.calc_limit_thickness(effRimDist, plastMoment);
            expected = [2.5951; 3.8740];
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-3);
        end

        function verify_convergence__warning_logged(Obj)
            % GIVEN
            Test = UsainUtils.UltimateLimitState();
            warning('on', 'USAIN:UltimateLimitState:NotConverged');

            % WHEN we simulate no convergence
            f = @() Test.verify_convergence(false, 'X');

            % THEN expect a warning
            Obj.verify_warning_logged(f, 'USAIN:UltimateLimitState:NotConverged');

            % WHEN we simulate convergence
            f = @() Test.verify_convergence(true, 'X');

            % THEN expect no warning
            Obj.verify_no_warning_logged(f);

            % WHEN we simulate a design space with >1 point where at least 1 point did not converge
            f = @() Test.verify_convergence([true; false; true], 'X');

            % THEN expect a warning
            Obj.verify_warning_logged(f, 'USAIN:UltimateLimitState:NotConverged');
        end

        function calc_init_plastic_moment__happy(Obj)
            % GIVEN inputs to call `init_plastic_moment`
            Test = UsainUtils.UltimateLimitState();
            Test.Mdl = UsainUtils.FlangeModel();
            Test.Mdl.Inputs.thicknNoseUp = 40e-3;
            Test.Mdl.Inputs.thicknNoseLo = 40e-3;
            Test.Mdl.Space.thickness = 100e-3;
            Test.Mdl.Inputs.yieldStrengthChar = 300e6;
            Test.Mdl.Segment.distBoltAtShell = 50e-3;
            Test.Mdl.flangeType = 'L';

            % WHEN, THEN
            actual = Test.calc_init_plastic_moment();
            expected  = 6000;
            Obj.assertEqual(actual, expected, 'RelTol', 1e-4);
        end

        function calc_plastic_moment__l_flange(Obj)
            % GIVEN pre-defined inputs
            Test = UsainUtils.UltimateLimitState();
            Test.Mdl = UsainUtils.FlangeModel();
            Test.Mdl.Inputs.thicknNoseUp = 40e-3;
            Test.Mdl.Inputs.thicknNoseLo = 40e-3;
            Test.Mdl.Space.thickness = 100e-3;
            Test.yieldStrengthDes = 300e6;
            Test.Mdl.Segment.distBoltAtShell = 50e-3;
            Test.Mdl.flangeType = 'L';

            % WHEN we have no M/N interaction
            plasticLimit = Inf;

            % THEN
            failureMode = 1000;
            actual = Test.calc_plastic_moment(failureMode, plasticLimit);
            expected = 6000;
            Obj.assertEqual(actual, expected, 'AbsTol', 0.1);

            % WHEN we have M/N interaction
            plasticLimit = 10000;

            % THEN
            actual = Test.calc_plastic_moment(failureMode, plasticLimit);
            expected = 5940;
            Obj.assertEqual(actual, expected, 'AbsTol', 0.1);

            % WHEN we have M/N interaction, but the failure mode exceeds the plastic limit
            plasticLimit = 100;

            % THEN
            actual = Test.calc_plastic_moment(failureMode, plasticLimit);
            expected = 0;
            Obj.assertEqual(actual, expected, 'AbsTol', 0.1);
        end

        function calc_plastic_moment__t_flange(Obj)
            % GIVEN pre-defined inputs
            Test = UsainUtils.UltimateLimitState();
            Test.Mdl = UsainUtils.FlangeModel();
            Test.Mdl.Inputs.thicknNoseUp = 50e-3;
            Test.Mdl.Inputs.thicknNoseLo = 50e-3;
            Test.Mdl.Space.thickness = 100e-3;
            Test.yieldStrengthDes = 300e6;
            Test.Mdl.Segment.distBoltAtShell = 0.100;
            Test.Mdl.flangeType = 'T';

            % WHEN we have no M/N interaction
            plasticLimit = Inf;

            % THEN
            failureMode = 1000;
            actual = Test.calc_plastic_moment(failureMode, plasticLimit);
            expected = 75000;
            Obj.assertEqual(actual, expected, 'AbsTol', 0.1);

            % WHEN we have M/N interaction
            plasticLimit = 76000;

            % THEN
            actual = Test.calc_plastic_moment(failureMode, plasticLimit);
            expected = 74998.4;
            Obj.assertEqual(actual, expected, 'AbsTol', 0.1);

            % WHEN we have M/N interaction, but the failure mode exceeds the plastic limit
            plasticLimit = 100;

            % THEN
            actual = Test.calc_plastic_moment(failureMode, plasticLimit);
            expected = 0;
            Obj.assertEqual(actual, expected, 'AbsTol', 0.1);
        end

        function calc_strength_psf__no_robustness_tags(Obj)
            % GIVEN some dummy inputs that reflect a USAIN run with two "normal" load sets
            Test = UsainUtils.UltimateLimitState();
            Test.Mdl.Loads.Uls(1).tag = 'some_normal_load_set';
            Test.Mdl.Loads.Uls(2).tag = 'another';
            Test.Mdl.Loads.nLoadSets = 2;

            % WHEN we compute the strength PSF to be applied in calculations, for an input PSF of 1.23
            psfInp = 1.23;
            actual = Test.calc_strength_psf(psfInp);

            % THEN we expect the returned PSF to not be forced to 1.00
            expected = [1.23 1.23];
            Obj.assertEqual(actual, expected);
        end

        function calc_strength_psf__with_robustness_tags(Obj)
            % GIVEN some dummy inputs that reflect a USAIN run with one "normal" and one "robustness" load set
            Test = UsainUtils.UltimateLimitState();
            Test.Mdl.Loads.Uls(1).tag = 'some_normal_load_set';
            Test.Mdl.Loads.Uls(2).tag = 'hurricane_robustness';
            Test.Mdl.Loads.nLoadSets = 2;

            % WHEN we compute the strength PSF to be applied in calculations, for an input PSF of 1.23
            psfInp = 1.23;
            actual = Test.calc_strength_psf(psfInp);

            % THEN we expect the returned PSF for the robustness load set to be forced to 1.00
            expect = [1.23 1.00];
            Obj.assertEqual(actual, expect);
        end

        function calc_failure_mode_a__happy(Obj)
            % GIVEN
            Test = Obj.setup_fixture();

            % WHEN calculating the failure mode
            % THEN
            actual = Test.calc_failure_mode_a();
            expected = 1520064;
            Obj.assertEqual(actual, expected, 'AbsTol', 1);
        end

        function calc_failure_mode_b__analytic_equal_to_iterative(Obj)
            % GIVEN
            Test = Obj.setup_fixture();

            % WHEN calculating the failure mode (iterative and direct method)
            actualDirect = Test.calc_failure_mode_b();
            actualIterative = Test.calc_failure_mode_b_iterative();

            % THEN expect error to be < 1 Newton between the direct and iterative method, and compare to an expected
            % value
            expected = 911928;
            Obj.assertEqual(actualDirect, actualIterative, 'AbsTol', 1);
            Obj.assertEqual(actualDirect, expected, 'AbsTol', 1);

            % WHEN we do the same for a T-flange (different failure mechanism -> different logic in test class)
            Test.Mdl.flangeType = 'T';
            Test.Mdl.flangeTypeFactor = 2;
            Test.plasticLimit = 2191044;
            actualDirect = Test.calc_failure_mode_b();
            actualIterative = Test.calc_failure_mode_b_iterative();
            expected = 2884879;
            Obj.assertEqual(actualDirect, actualIterative, 'AbsTol', 1);
            Obj.assertEqual(actualDirect, expected, 'AbsTol', 1);
        end

        function calc_failure_mode_d__analytic_equal_to_iterative(Obj)
            % GIVEN
            Test = Obj.setup_fixture();

            % WHEN calculating the failure mode (iterative and direct method)
            actualDirect = Test.calc_failure_mode_d();
            actualIterative = Test.calc_failure_mode_d_iterative();

            % THEN expect error to be < 1 Newton between the direct and iterative method, and compare to an expected
            % value
            expected = 973990;
            Obj.assertEqual(actualDirect, actualIterative, 'AbsTol', 1);
            Obj.assertEqual(actualDirect, expected, 'AbsTol', 1);

            % WHEN we do the same for a T-flange (different failure mechanism -> different logic in test class)
            Test.Mdl.flangeType = 'T';
            Test.Mdl.flangeTypeFactor = 2;
            Test.plasticLimit = 2191044;
            actualDirect = Test.calc_failure_mode_d();
            actualIterative = Test.calc_failure_mode_d_iterative();

            % THEN we expect the iterative scheme to return the expected value. The direct method however does not give
            % the same result, because the flange fails under pure shear (N > 2*V_pl) and this is not correctly captured
            % by the direct method
            expected = 2613273;
            Obj.assertEqual(actualIterative, expected, 'AbsTol', 1);
            Obj.assertNotEqual(actualDirect, actualIterative);
        end

        function calc_failure_mode_e__analytic_equal_to_iterative(Obj)
            % GIVEN
            Test = Obj.setup_fixture();

            % WHEN calculating the failure mode (iterative and direct method)
            actualDirect = Test.calc_failure_mode_e();
            actualIterative = Test.calc_failure_mode_e_iterative();

            % THEN expect error to be < 1 Newton between the direct and iterative method, and compare to an expected
            % value
            expected = 2080189;
            Obj.assertEqual(actualDirect, actualIterative, 'AbsTol', 1);
            Obj.assertEqual(actualDirect, expected, 'AbsTol', 1);

            % WHEN we do the same for a T-flange (different failure mechanism -> different logic in test class)
            Test.Mdl.flangeType = 'T';
            Test.Mdl.flangeTypeFactor = 2;
            Test.plasticLimit = 2191044;
            actualDirect = Test.calc_failure_mode_e();
            actualIterative = Test.calc_failure_mode_e_iterative();

            % THEN we expect the iterative scheme to return the expected value. The direct method however does not give
            % the same result, because the flange fails under pure shear (N > 2*V_pl) and this is not correctly captured
            % by the direct method
            expected = 8820000;
            Obj.assertEqual(actualIterative, expected, 'AbsTol', 1);
            Obj.assertNotEqual(actualDirect, actualIterative);
        end

        function get_physical_solution__discards_complex_solutions(Obj)
            % GIVEN a array with complex doubles
            complexArray = [ ...
                1.0, 1.1
                2.0, 1.2 + 2.0i
                3.0, 1.3
                4.0, 1.4 + 2.0i
                5.0, 1.5];

            % WHEN, THEN
            actual = UsainUtils.UltimateLimitState().get_physical_solution(complexArray, complexArray);
            expected = [ ...
                1.0, 1.1
                2.0, nan
                3.0, 1.3
                4.0, nan
                5.0, 1.5];
            Obj.assertTrue(isreal(actual));
            Obj.assertEqual(actual, expected);
        end

        function get_physical_solution__returns_max_from_complex_array(Obj)
            % GIVEN two complex arrays, where the magnitude of the complex numbers is larger in variable `a`, but the
            % real part of the complex number is larger in variable `b`
            a = [ ...
                0.2 + 1.23i
                0.3 + 1.24i
                0.4];
            b = [ ...
                1.1 + 1.23i
                2.2 + 1.24i
                3.3 + 1.25i];

            % WHEN
            % THEN expect the NaNs to be returned
            actual = UsainUtils.UltimateLimitState().get_physical_solution(a, b);
            expected = [nan; nan; 0.4];
            Obj.verifyEqual(actual, expected);
        end

        function get_physical_solution__returns_max_from_real_array(Obj)
            % GIVEN two arrays with solutions
            soln1 = -ones(5, 2);
            soln2 = ones(5, 2);
            soln1([2 4], 2) = 1;
            soln2([2 4], 2) = -1;

            % WHEN
            Test = UsainUtils.UltimateLimitState();
            actual = Test.get_physical_solution(soln1, soln2);

            % THEN
            Obj.assertEqual(actual, ones(5, 2));

        end

        function calc_outer_width__l_flange(Obj)
            % GIVEN pre-defined inputs for L-flange
            Test = Obj.setup_fixture();

            % WHEN calculating outer width for failmodes other than 'E'
            b_notModeE = Test.calc_outer_width('notModeE');

            % THEN
            expected_notModeE = 0.0945;
            Obj.assertEqual(b_notModeE, expected_notModeE, 'AbsTol', 1e-6);

            % WHEN calculating outer width for mode 'E'
            bE = Test.calc_outer_width('E');
            expected_modeE = 0.0530;
            Obj.assertEqual(bE, expected_modeE, 'AbsTol', 1e-6);
        end

        function calc_outer_width__t_flange(Obj)
            % GIVEN pre-defined inputs for T-flange
            Test = Obj.setup_fixture();
            Test.Mdl.flangeType = 'T';

            % WHEN calculating outer width for failmodes other than 'E'
            b_notModeE = Test.calc_outer_width('notModeE');

            % THEN
            expected_notModeE = 0.0665;
            Obj.assertEqual(b_notModeE, expected_notModeE, 'AbsTol', 1e-6);

            % WHEN calculating outer width for mode 'E'
            bE = Test.calc_outer_width('E');
            expected_modeE = 0.0250;
            Obj.assertEqual(bE, expected_modeE, 'AbsTol', 1e-6);
        end

        function getter_failModeCrit__happy(Obj)
            % GIVEN inputs to call getter for property `failModeCritStr`. The inputs mimic 4 design points and 1 load
            % sets.
            Test = UsainUtils.UltimateLimitState();
            Test.failModeA = [5; 9; 9; 9];
            Test.failModeB = [9; 4; 9; 9];
            Test.failModeD = [9; 9; 3; 9];
            Test.failModeE = [9; 9; 9; 2];

            % WHEN, THEN
            actual = Test.failModeCrit;
            expected = [5; 4; 3; 2];
            Obj.assertEqual(actual, expected);
        end

        function getter_failModeCritStr__happy(Obj)
            % GIVEN inputs to call getter for property `failModeCritStr`. The inputs mimic 3 design points and 2 load
            % sets.
            Test = UsainUtils.UltimateLimitState();
            Test.failModeA = ones(3, 2);
            Test.failModeB = 2 * ones(3, 2);
            Test.failModeD = 1.5 * ones(3, 2);
            Test.failModeE = 0.9 * ones(3, 2);
            Test.failModeB(1, 1) = 0.8;
            Test.failModeD(3, 2) = 0.7;

            % WHEN, THEN
            actual = Test.failModeCritStr;
            expected = ["B", "E"; "E", "E"; "E", "D"];
            Obj.assertEqual(actual, expected);
        end

        function get_quadratic_equation_coefficients__vector(Obj)
            % GIVEN Standard fixture, but with some values extended to (dummy value) vectors to check dimension
            % consistency in the calculation
            Test = Obj.setup_fixture();
            Test.Mdl.Inputs.thicknNoseUp = repmat(Test.Mdl.Inputs.thicknNoseUp, 3, 1);
            Test.Mdl.Inputs.thicknNoseLo = repmat(Test.Mdl.Inputs.thicknNoseLo, 3, 1);
            f = [1; 2; 3];
            c = [1; 2; 3];
            Li = [1; 2; 3];
            Mi = [1; 2; 3];

            % WHEN
            [actualCoefficientA, actualCoefficientB, actualCoefficientC] = ...
                Test.get_quadratic_equation_coefficients(f, c, Li, Mi);

            % THEN we expect a specific dimension size of the coefficients
            expectSizeAC = [3 1];
            expectSizeB = [1 1];
            Obj.assertSize(actualCoefficientA, expectSizeAC);
            Obj.assertSize(actualCoefficientB, expectSizeB);
            Obj.assertSize(actualCoefficientC, expectSizeAC);

            % WHEN we do the same for a T-flange
            Test.Mdl.flangeType = 'T';
            Test.Mdl.Space.thickness = repmat(Test.Mdl.Space.thickness, 3, 1);
            [actualCoefficientA, actualCoefficientB, actualCoefficientC] = ...
                Test.get_quadratic_equation_coefficients(f, c, Li, Mi);

            % THEN we expect a specific dimension size of the coefficients, different compared to the L-flange
            expectSize = [3 1];
            Obj.assertSize(actualCoefficientA, expectSize);
            Obj.assertSize(actualCoefficientB, expectSize);
            Obj.assertSize(actualCoefficientC, expectSize);
        end

    end

    methods (Static)

        function Fixture = setup_fixture()
            Fixture = UsainUtils.UltimateLimitState();

            Fixture.Mdl.Inputs.thicknNoseUp = 40e-3;
            Fixture.Mdl.Inputs.thicknNoseLo = 40e-3;
            Fixture.Mdl.Inputs.REACTION_DISTANCE_METHOD = 'tobinaga';
            Fixture.Mdl.Inputs.diamBoltHole = 61e-3;
            Fixture.Mdl.Inputs.yieldStrengthChar = 275e6;
            Fixture.Mdl.Inputs.FILLET_RADIUS = 10e-3;

            Fixture.Mdl.Space.thickness = 120e-3;
            Fixture.Mdl.Space.nPoints = 1;
            Fixture.Mdl.Segment.ReactDist = UsainUtils.ReactionDistance(0.1355, 0.0945, 0.12);
            Fixture.Mdl.Segment.distBoltAtShell = 0.1265;
            Fixture.Mdl.Segment.distForce = 0.0945;
            Fixture.Mdl.Segment.distBolt = 0.1225;
            Fixture.Mdl.flangeType = 'L';
            Fixture.Mdl.flangeTypeFactor = 1;
            Fixture.Mdl.Loads.nLoadSets = 1;

            Fixture.Mdl.Wash.diamOut = 105e-3;
            Fixture.Mdl.Wash.len = 10e-3;
            Fixture.Mdl.Nut.diam = 105e-3;

            Fixture.boltStrengthDes = 1520064;
            Fixture.yieldStrengthDes = 250e6;
            Fixture.plasticLimit = 1265000;
        end

    end
end
