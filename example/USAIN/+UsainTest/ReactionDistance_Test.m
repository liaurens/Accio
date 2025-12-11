classdef ReactionDistance_Test < UsainTest.UsainTestCase

    methods (Test, TestTags = {'unit'})

        function calc_aeff_seidel_fls__b_governing(Obj)
            % GIVEN a ReactionDistance object with b > a
            a = 100e-3;
            b = 111e-3;
            t = 100e-3;
            TestObj = UsainUtils.ReactionDistance(a, b, t);

            % WHEN we compute the effective width a* according to Seidel's
            % method (for FLS)
            actual = TestObj.calc_aeff_seidel_fls();

            % THEN we expect 90% of the thickness to be returned
            Obj.verifyEqual(actual, 0.9 * t, 'RelTol', 1e-4);
        end

        function calc_aeff_seidel_fls__t_governing(Obj)
            % GIVEN a ReactionDistance object with a > b
            a = 120e-3;
            b = 100e-3;
            t = 100e-3;
            TestObj = UsainUtils.ReactionDistance(a, b, t);

            % WHEN we compute the effective width a* according to Seidel's
            % method (for FLS)
            actual = TestObj.calc_aeff_seidel_fls();

            % THEN we expect 90% of the thickness to be returned
            Obj.verifyEqual(actual, 0.9 * t, 'RelTol', 1e-4);
        end

        function calc_aeff_seidel_fls__a_governing(Obj)
            % GIVEN a ReactionDistance object with a == b and a large thickness
            a = 100e-3;
            b = 100e-3;
            t = 120e-3;
            TestObj = UsainUtils.ReactionDistance(a, b, t);

            % WHEN we compute the effective width a* according to Seidel's
            % method (for FLS)
            actual = TestObj.calc_aeff_seidel_fls();

            % THEN we expect the returned effective width to be equal to "a"
            Obj.verifyEqual(actual, a, 'RelTol', 1e-4);
        end

        function calc_aeff_seidel_uls__benchmark(Obj)
            % GIVEN a ReactionDistance object with pre-defined inputs
            a = [300e-3; 400e-3; 1e-6];
            b = [50e-3;  100e-3; 100e-3];
            t = [50e-3; 100e-3; 100e-3];
            TestObj = UsainUtils.ReactionDistance(a, b, t);

            % WHEN we compute the effective width a' according to Seidel's
            % method (for ULS)
            tLim = [50e-3; 1e-3; 100e-3];
            actual = TestObj.calc_aeff_seidel_uls(tLim);

            % THEN we expect the returned values to match with benchmark values
            expect = [0.0625; 0.300; 1e-6];
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-4);
        end

        function calc_aeff_tobinaga__benchmark(Obj)
            % GIVEN a ReactionDistance object with pre-defined inputs
            a = [160e-3; 125e-3; 270e-3];
            b = [125e-3; 85e-3; 109e-3];
            t = [150e-3; 90e-3; 200e-3];
            TestObj = UsainUtils.ReactionDistance(a, b, t);

            % WHEN we compute the effective width a' according to Tobinaga's
            % method
            actual = TestObj.calc_aeff_tobinaga();

            % THEN we expect the returned values to match with benchmark values
            expect = [158.5e-3; 115.7e-3; 245.1e-3];
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-4);
        end

        function calc_tobinaga_correction__no_correction_if_ab_ratio_leq_1p25(Obj)
            % GIVEN a ReactionDistance object with pre-defined inputs such that the a/b ratio is <= 1.25
            a = [125e-3; 120e-3; 149e-3];
            b = [100e-3; 100e-3; 120e-3];
            t = [200e-3; 200e-3; 204e-3];
            Test = UsainUtils.ReactionDistance(a, b, t);

            % WHEN the correction factor (lambda) for Tobinaga's method is computed
            actual = Test.calc_tobinaga_correction();

            % THEN we expect 1.00 to be returned for all three design points
            Obj.verifyEqual(actual, ones(3, 1), 'AbsTol', 1e-6);
        end

        function report_tobinaga_violation__warning_logged(Obj)
            % GIVEN a flange design that violates Tobinaga's limits
            a = 270e-3;
            b = 109e-3;
            t = 200e-3;
            TestObj = UsainUtils.ReactionDistance(a, b, t);

            % WHEN we report any violation
            f = @() TestObj.report_tobinaga_violation();

            % THEN we expect a warning to be logged
            expect = 'USAIN:ReactionDistance:TobinagaLimitExceeded';
            Obj.verify_warning_logged(f, expect);
        end

        function check_tobinaga_limits__pass(Obj)
            % GIVEN a flange design that satisfies Tobinaga's geometry limits
            a = 200e-3;
            b = 100e-3;
            t = 200e-3;
            TestObj = UsainUtils.ReactionDistance(a, b, t);

            % WHEN we check the limits
            actual = TestObj.check_tobinaga_limits();

            % THEN we expect it to pass
            Obj.verifyTrue(actual);
        end

        function check_tobinaga_limits__fail(Obj)
            % GIVEN a flange design that does not satisfy Tobinaga's geometry limits
            a = [300e-3; 251e-3];
            b = [100e-3; 100e-3];
            t = [200e-3; 200e-3];
            TestObj = UsainUtils.ReactionDistance(a, b, t);

            % WHEN we check the limits
            actual = TestObj.check_tobinaga_limits();

            % THEN we expect it to fail
            Obj.verifyLength(actual, 2);
            Obj.verifyFalse(any(actual));
        end

    end
end
