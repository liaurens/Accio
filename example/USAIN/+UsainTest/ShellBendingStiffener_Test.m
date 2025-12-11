classdef ShellBendingStiffener_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function calc_local_origin__limit(Obj)
            % GIVEN a flange with low flange thickness but large nose thickness
            Bend = UsainUtils.ShellBendingStiffener();
            Bend.thk = 100e-3;
            Bend.thkNose = 1e-3 * [100 100];

            % WHEN calculating the local origin
            actual = Bend.calc_local_origin();

            % THEN expect 0 to be returned
            expect = [0 0];
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-10);
        end

        function calc_local_origin__gt_zero(Obj)
            % GIVEN a flange with normal proportions
            Bend = UsainUtils.ShellBendingStiffener();
            Bend.thk = 125e-3;
            Bend.thkNose = 1e-3 * [35 40];

            % WHEN calculating the local origin
            actual = Bend.calc_local_origin();

            % THEN expect the origin at x = t_flange - 3 * t_nose
            expect = 1e-3 * [20 5];
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-10);
        end

        function calc_bending_coefficients__matrix_input(Obj)
            % GIVEN some stress array with dim #2 > 1 (ie. matrix)
            stressMatrix = ones(10, 3);

            % WHEN we try to compute the integration constants
            Bend = UsainUtils.ShellBendingStiffener();
            f = @() Bend.calc_bending_coefficients(stressMatrix);

            % THEN expect an error to be thrown because the stress input must be
            % a column vector
            Obj.verifyError(f, 'ShellBending:StressNotColumnVector');
        end

    end

    methods (Test, TestTags = {'integration'})

        function solve__benchmark(Obj)
            % GIVEN a test instance with pre-defined properties
            stress = [-100e6, 0, 130e6]';
            Bend = Obj.setup_benchmark();

            % WHEN we solve for the integration constants
            [q0, m0] = Bend.calc_bending_coefficients(stress);

            % THEN we expect some benchmarked intermediate results
            expectQ0 = [-126.64,   -201.15  % <- for stress = -100 MPa
                                0,         0  % <- for stress = 0 MPa
                           164.63,   261.49]; % <- for stress = 130 MPa
            expectM0 = [18377.24,  51619.71
                                0,         0
                        -23890.41, -67105.63];
            Obj.assertEqual(1e-3 * q0, expectQ0, 'AbsTol', 1e-2);
            Obj.assertEqual(m0, expectM0, 'AbsTol', 1e-2);

            % WHEN we solve for the shell bending stresses
            [stressIn, stressOut] = Bend.solve(stress);

            % THEN we expect some benchmarked end results
            expectStress = [-2.50,  10.61
                                0,      0
                             3.25, -13.80];
            Obj.verifyEqual(1e-6 * stressIn, expectStress, 'AbsTol', 1e-2);
            Obj.verifyEqual(stressIn, -stressOut);
        end

    end

    methods (Static)

        function Bend = setup_benchmark()
            % Constructs test object with inputs for which results are
            % benchmarked with Marc Seidel's Excel calculations (which in turn
            % are validated with FEA)

            Bend = UsainUtils.ShellBendingStiffener();
            Bend.eMod = 210e9;
            Bend.nu = 0.3;
            Bend.thk = 150e-3;
            Bend.wid = 322.5e-3;
            Bend.diamOutNeck = 7;
            Bend.thkNose = 1e-3 * [75 85];
            Bend.xWeldToe = 256e-3;
        end

    end
end
