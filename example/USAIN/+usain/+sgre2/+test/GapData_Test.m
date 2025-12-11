classdef GapData_Test < UsainTest.UsainTestCase

    methods (Test, TestTags = {'unit'})

        function constructor__expected(Obj)
            % GIVEN, WHEN, THEN
            Obj.verifyEqual(usain.sgre2.GapData(deg2rad(30), 1).angle, deg2rad(30), 'RelTol', 1e-4);
            Obj.verifyEqual(usain.sgre2.GapData(deg2rad(90), 2).angle, deg2rad(90), 'RelTol', 1e-4);
            Obj.verifyEqual(usain.sgre2.GapData(deg2rad(360), 4).angle, deg2rad(360), 'RelTol', 1e-4);

            Obj.verifyEqual(usain.sgre2.GapData(deg2rad(30), 7.5).len, 1.9635, 'RelTol', 1e-4);
            Obj.verifyEqual(usain.sgre2.GapData(deg2rad(90), 8).len, 6.2832, 'RelTol', 1e-4);
            Obj.verifyEqual(usain.sgre2.GapData(deg2rad(360), 6).len, pi * 6, 'RelTol', 1e-4);

            Obj.verifyEqual(usain.sgre2.GapData(deg2rad(30), 7.5).height, 0.8760e-3, 'RelTol', 1e-4);
            Obj.verifyEqual(usain.sgre2.GapData(deg2rad(40), 8, 1e-3).height, 0.8102e-3, 'RelTol', 1e-4);
            Obj.verifyEqual(usain.sgre2.GapData(deg2rad(120), 7.5).height, 3.9553e-3, 'RelTol', 1e-4);
            Obj.verifyEqual(usain.sgre2.GapData(deg2rad(120), 9).height, 4.4462e-3, 'RelTol', 1e-4);
        end

        function calc_local_tolerance__expected(Obj)
            % GIVEN a 7.5m outer diameter and 1.4mm/m flatness tolerance
            % WHEN, THEN
            Obj.verifyEqual(usain.sgre2.GapData.calc_local_tolerance(7.5, 1.4e-3), 1.9617e-3, 'RelTol', 1e-4);
            Obj.verifyEqual(usain.sgre2.GapData.calc_local_tolerance(7.5, 1.0e-3), 1.4012e-3, 'RelTol', 1e-4);
        end

        function calc_global_tolerance__expected(Obj)
            % GIVEN a 7.5m outer diameter and 1.4mm/m flatness tolerance
            % WHEN
            % THEN expect the global tolerance to be equal to 1.5 times the local tolerance
            expected = 1.5 * usain.sgre2.GapData.calc_local_tolerance(7.5, 1.4e-3);
            Obj.verifyEqual(usain.sgre2.GapData.calc_global_tolerance(7.5, 1.4e-3), expected, 'RelTol', 1e-4);
            Obj.verifyEqual(usain.sgre2.GapData.calc_global_tolerance(7.5, 1.4e-3), 2.9426e-3, 'RelTol', 1e-4);
        end

        function check_diameter_limitation__warning_logged(Obj)
            % GIVEN
            TestObj = usain.sgre2.GapData();

            % WHEN we report a violation
            diameterOutNeck = 11.0;
            f = @() TestObj.check_diameter_limitation(diameterOutNeck);

            % THEN we expect a warning to be logged
            expect = 'USAIN:GapData:diameterLimitExceeded';
            Obj.verify_warning_logged(f, expect);
        end

    end

end
