classdef FlangeOpeningMechanics_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function calc_omega_parameter__expect(Obj)
            % GIVEN, WHEN, THEN
            FlangeOpening = UsainTest.FlangeOpeningMechanics_Test.setup_test_object();
            actual = FlangeOpening.calc_omega_parameter();
            expected = 0.0144;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-4);
        end

        function calc_effective_a_parameter__expect(Obj)
            % GIVEN a test instance with 'tobinaga'
            FlangeOpening = UsainTest.FlangeOpeningMechanics_Test.setup_test_object();
            FlangeOpening.reactionDistanceMethod = 'tobinaga';

            % WHEN, THEN
            actualTobinaga = FlangeOpening.calc_effective_a_parameter();
            expect = 0.1582;
            Obj.assertEqual(actualTobinaga, expect, 'AbsTol', 1e-4);

            % WHEN we change to 'seidel'
            % THEN
            FlangeOpening.reactionDistanceMethod = 'seidel';
            actualSeidel = FlangeOpening.calc_effective_a_parameter();
            expect = 0.1374;
            Obj.assertEqual(actualSeidel, expect, 'AbsTol', 1e-4);
        end

        function calc_effective_a_parameter__unsupported_method(Obj)
            % GIVEN a test instance with an unsupported reaction distance method
            FlangeOpening = UsainTest.FlangeOpeningMechanics_Test.setup_test_object();
            FlangeOpening.reactionDistanceMethod = 'doesnotexist';

            % WHEN, THEN
            f = @() FlangeOpening.calc_effective_a_parameter();
            Obj.assertError(f, 'FlangeOpeningMechanics:UnsupportedReactionDistanceMethod');
        end

        function calc_bolt_force_at_bcd_opening__expect(Obj)
            % GIVEN, WHEN, THEN
            FlangeOpening = UsainTest.FlangeOpeningMechanics_Test.setup_test_object();
            actual = FlangeOpening.calc_bolt_force_at_bcd_opening();
            expected = 2.0996e6;
            Obj.assertEqual(actual, expected, 'RelTol', 1e-5);
        end

        function calc_bolt_moment_at_bcd_opening__expect(Obj)
            % GIVEN, WHEN, THEN
            FlangeOpening = UsainTest.FlangeOpeningMechanics_Test.setup_test_object();
            actual = FlangeOpening.calc_bolt_moment_at_bcd_opening();
            expected = 373.7422;
            Obj.assertEqual(actual, expected, 'RelTol', 1e-4);
        end

        function calc_bolt_axial_stress_at_bcd_opening__expect(Obj)
            % GIVEN, WHEN, THEN
            FlangeOpening = UsainTest.FlangeOpeningMechanics_Test.setup_test_object();
            actual = FlangeOpening.calc_bolt_axial_stress_at_bcd_opening();
            expected = 6.0682e8;
            Obj.assertEqual(actual, expected, 'RelTol', 1e-5);
        end

        function calc_bolt_axial_stress_at_bcd_opening__preload_default_zero(Obj)
            % GIVEN, WHEN, THEN
            FlangeOpening = UsainTest.FlangeOpeningMechanics_Test.setup_test_object();
            actual_noArg = FlangeOpening.calc_bolt_axial_stress_at_bcd_opening();
            actual_zeroPreload = FlangeOpening.calc_bolt_axial_stress_at_bcd_opening(0);
            Obj.assertEqual(actual_noArg, actual_zeroPreload, 'RelTol', 1e-6);
        end

        function calc_bolt_axial_stress_at_bcd_opening__preload_subtracted(Obj)
            % GIVEN, WHEN, THEN
            FlangeOpening = UsainTest.FlangeOpeningMechanics_Test.setup_test_object();
            actual_zeroPreload = FlangeOpening.calc_bolt_axial_stress_at_bcd_opening(0);
            actual_withPreload = FlangeOpening.calc_bolt_axial_stress_at_bcd_opening(1688e3);
            Obj.assertLessThan(actual_withPreload, actual_zeroPreload);
        end

        function calc_bolt_bending_stress_at_bcd_opening__expect(Obj)
            % GIVEN, WHEN, THEN
            FlangeOpening = UsainTest.FlangeOpeningMechanics_Test.setup_test_object();
            actual = FlangeOpening.calc_bolt_bending_stress_at_bcd_opening();
            expect = 1.3019e7;
            Obj.assertEqual(actual, expect, 'RelTol', 1e-4);
        end

    end

    methods (Static)

        function Test = setup_test_object()
            % Set up test object with data based on an actual flange design (Hywind Tampen FC3 without bolt
            % extender) that was used for comparison with Marc Seidel's implementation
            Test = UsainUtils.FlangeOpeningMechanics();
            Test.preload = 1962e3;
            Test.paramA = 0.160;
            Test.paramB = 0.120;
            Test.paramC = 0.144;
            Test.thickness = 0.157;
            Test.bendingResilienceBolt = 2.48e-6;
            Test.axialResilienceBolt = 6.59e-10;
            Test.eModulus = 210e9;
            Test.loadFactor = 0.1337;
            Test.reactionDistanceMethod = 'tobinaga';
            Test.stressAreaBolt = 3460e-6;
            Test.loadIntroductionFactor = 0.2005;
        end

    end
end
