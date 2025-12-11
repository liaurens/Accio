classdef InterpolatedShellStiffness_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function csv_data_file__file_exists(Obj)
            % GIVEN, WHEN, THEN
            CsvFile = usain.sgre2.InterpolatedShellStiffness.CSV_DATA_FILE;
            Obj.verifyTrue(CsvFile.is_file());
        end

        function load_csv__expect_headers(~)
            % GIVEN, WHEN, THEN
            Stiffness = usain.sgre2.InterpolatedShellStiffness();
            Csv = Stiffness.load_csv();
            Csv.verify_file_headers(["radius", "thickness", "gap_angle", "shell_stiffness"]);
        end

        function calc_stiffness__expected(Obj)
            % GIVEN
            ShellStiffness = usain.sgre2.InterpolatedShellStiffness();

            % WHEN calculating the stiffness based on samples that are in the .csv file (so no interpolation is needed)
            % THEN
            Obj.verifyEqual( ...
                ShellStiffness.calc_stiffness(3, 0.030, deg2rad(60), 210e9), ...
                1654e6, 'AbsTol', 0.5);
            Obj.verifyEqual( ...
                ShellStiffness.calc_stiffness(7, 0.070, deg2rad(10), 210e9), ...
                11891e6, 'AbsTol', 0.5);
            Obj.verifyEqual( ...
                ShellStiffness.calc_stiffness(5, 0.150, deg2rad(120), 210e9), ...
                1471e6, 'AbsTol', 0.5);

            % WHEN calculating the stiffness for which interpolation is needed
            % THEN
            Obj.verifyEqual( ...
                ShellStiffness.calc_stiffness(4.6, 0.030, deg2rad(29.8), 210e9), ...
                2726.1e6, 'RelTol', 1e-4);
            Obj.verifyEqual( ...
                ShellStiffness.calc_stiffness(7, 0.0705, deg2rad(118.8), 210e9), ...
                516.68e6, 'RelTol', 1e-4);
            Obj.verifyEqual( ...
                ShellStiffness.calc_stiffness(6, 0.0732, deg2rad(118.5), 210e9), ...
                595.13e6, 'RelTol', 1e-4);
        end

        function calc_stiffness__extrapolation_error(Obj)
            % GIVEN
            ShellStiffness = usain.sgre2.InterpolatedShellStiffness();

            % WHEN calculating the stiffness for points not covered by the FE data
            % ... diameter outside range [3, 10]m
            % ... thickness outside range [0.01, 0.15]m
            % ... angle outside range [10, 180]deg
            diamOk = 5;
            thkOk = 0.05;
            angleOk = deg2rad(60);
            Obj.verify_error_free(@() ShellStiffness.calc_stiffness(diamOk, thkOk, angleOk, 210e9));
            % THEN expect an error
            expectedErrorId = 'InterpolatedShellStiffness:calc_stiffness:ExtrapolationNeeded';

            Obj.assertRaises(@() ShellStiffness.calc_stiffness(2.9, thkOk, angleOk, 210e9), expectedErrorId);
            Obj.assertRaises(@() ShellStiffness.calc_stiffness(10.1, thkOk, angleOk, 210e9), expectedErrorId);

            Obj.assertRaises(@() ShellStiffness.calc_stiffness(diamOk, 0.005, angleOk, 210e9), expectedErrorId);
            Obj.assertRaises(@() ShellStiffness.calc_stiffness(diamOk, 0.16, angleOk, 210e9), expectedErrorId);

            Obj.assertRaises(@() ShellStiffness.calc_stiffness(diamOk, thkOk, deg2rad(9), 210e9), expectedErrorId);
            Obj.assertRaises(@() ShellStiffness.calc_stiffness(diamOk, thkOk, deg2rad(190), 210e9), expectedErrorId);
        end

        function calc_stiffness__array_inputs(Obj)
            % GIVEN the inputs for multiple design points
            SegmentFixture = Obj.applyFixture(usain.model.test.fixtures.SegmentModelFixture(n = 3)).data;
            diameterOutNeck = SegmentFixture.diameterOutNeck;
            thicknessShell = SegmentFixture.neckThickness;
            eModulus = SegmentFixture.eModulus;
            gapAngle = deg2rad(90);

            % WHEN, THEN
            ShellStiffness = usain.sgre2.InterpolatedShellStiffness();
            actual = ShellStiffness.calc_stiffness(diameterOutNeck, thicknessShell, gapAngle, eModulus);
            Obj.assertSize(actual, [3, 1]);
        end

    end
end
