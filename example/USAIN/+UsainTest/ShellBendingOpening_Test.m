classdef ShellBendingOpening_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function calc_local_origin__equals_thickness(Obj)
            % GIVEN some flange thickness
            Bend = UsainUtils.ShellBendingOpening();
            Bend.thk = 100e-3;

            % WHEN calculating the local origin
            actual = Bend.calc_local_origin();

            % THEN expect a value equal to the flange thickness to be returned
            expect = [100e-3 100e-3];
            Obj.assertSize(actual, [1 2]);
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-6);
        end

        function calc_bending_coefficients__matrix_input(Obj)
            % GIVEN some stress array with dim #2 > 1 (ie. matrix)
            stressMatrix = ones(10, 3);

            % WHEN we try to compute the integration constants
            Bend = UsainUtils.ShellBendingOpening();
            f = @() Bend.calc_bending_coefficients(stressMatrix);

            % THEN expect an error to be thrown because the stress input must be
            % a column vector
            Obj.verifyError(f, 'ShellBending:StressNotColumnVector');
        end

        function calc_gapping_force__benchmark(Obj)
            % GIVEN a test instance with pre-defined properties
            Bend = Obj.setup_benchmark();

            % WHEN we compute the force at which flange gaps up to BCD
            actual = Bend.calc_gapping_force();

            % THEN we expect some benchmarked results
            expect = 1e3 * [1110.4, 1131.5];
            Obj.verifyEqual(actual, expect, 'RelTol', 1e-3);
        end

        function calc_unit_rotations_cantilever__benchmark(Obj)
            % GIVEN a test instance with pre-defined properties
            Bend = Obj.setup_benchmark();

            % WHEN we compute rotations per unit load for cantilever behavior
            actual = Bend.calc_unit_rotations_cantilever();

            % THEN we expect some benchmarked results
            expect = 1e-3 * [1.0802, 1.0159];
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-4);
        end

        function calc_unit_rotations_gapping__benchmark(Obj)
            % GIVEN a test instance with pre-defined properties
            Bend = Obj.setup_benchmark();

            % WHEN we compute rotations per unit load for gapping
            actual = Bend.calc_unit_rotations_gapping();

            % THEN we expect some benchmarked results
            expect = 1e-3 * [0.5492, 0.5470];
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-4);
        end

        function calc_unit_rotations_compression__benchmark(Obj)
            % GIVEN a test instance with pre-defined properties
            Bend = Obj.setup_benchmark();

            % WHEN we compute rotations per unit load for compression
            actual = Bend.calc_unit_rotations_compression();

            % THEN we expect some benchmarked results
            expect = 1e-9 * [0.2346, 0.2265];
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-4);
        end

        function get_omega__benchmark(Obj)
            % GIVEN a test instance with pre-defined properties
            Bend = Obj.setup_benchmark();

            % WHEN we query property 'omega'
            actual = Bend.omega;

            % THEN we expect some benchmarked results
            expect = [0.0134, 0.0130];
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-4);
        end

    end

    methods (Test, TestTags = {'integration'})

        function solve__benchmark(Obj)
            % GIVEN a test instance with pre-defined properties and stress
            % levels that represent 1) compression, 2) zero load, 3)
            % slightly opened flange, 4) flange opened up to the bolts
            stress = [-100e6, 0, 20e6, 130e6]';
            Bend = Obj.setup_benchmark();

            % WHEN we solve for the integration constants
            [q0, m0] = Bend.calc_bending_coefficients(stress);

            % THEN we expect some benchmarked intermediate results
            expectQ0 = [34.05,     41.58   % <- for stress = -100 MPa
                                0,         0   % <- for stress = 0 MPa
                           -12.36,    -14.73   % <- for stress = 20 MPa
                          -330.50,   -386.27]; % <- for stress = 130 MPa
            expectM0 = [-11645.61, -15236.18
                                0,         0
                          4227.66,   5397.66
                        113043.14, 141537.26];
            Obj.assertEqual(1e-3 * q0, expectQ0, 'AbsTol', 1e-2);
            Obj.assertEqual(m0, expectM0, 'AbsTol', 1e-2);

            % WHEN we solve for the shell bending stresses
            [stressIn, stressOut] = Bend.solve(stress);

            % THEN we expect some benchmarked end results
            expectStress = [-8.77, -9.16
                                0,     0
                             3.18,  3.25
                            85.13, 85.11];
            Obj.verifyEqual(1e-6 * stressIn, expectStress, 'AbsTol', 1e-2);
            Obj.verifyEqual(stressIn, -stressOut);
        end

        function solve__benchmark_with_seidel_aeff(Obj)
            % GIVEN a test instance with pre-defined properties and stress
            % levels that represent 1) compression, 2) zero load, 3) slightly
            % opened flange, 4) flange opened up to the bolts. Use the benchmark
            % data but change the 'effective width' method to Seidel's
            stress = [-100e6, 0, 20e6, 130e6]';
            Bend = Obj.setup_benchmark();
            React = UsainUtils.ReactionDistance(Bend.a, Bend.b, Bend.thk);
            Bend.aEff = React.calc_aeff_seidel_fls();

            % WHEN we solve for the integration constants
            [q0, m0] = Bend.calc_bending_coefficients(stress);

            % THEN we expect some benchmarked intermediate results
            expectQ0 = [38.94,     47.13   % <- for stress = -100 MPa
                                0,         0   % <- for stress = 0 MPa
                           -15.17,    -17.95   % <- for stress = 20 MPa
                          -429.07,   -499.02]; % <- for stress = 130 MPa
            expectM0 = [-13317.90, -17269.76
                                0,         0
                          5189.73,   6577.83
                        146756.02, 182853.08];
            Obj.assertEqual(1e-3 * q0, expectQ0, 'AbsTol', 1e-2);
            Obj.assertEqual(m0, expectM0, 'AbsTol', 1e-2);

            % WHEN we solve for the shell bending stresses
            [stressIn, stressOut] = Bend.solve(stress);

            % THEN we expect some benchmarked end results
            expectStress = [-10.03, -10.39
                                 0,      0
                              3.91,   3.96
                            110.52, 109.96];
            Obj.verifyEqual(1e-6 * stressIn, expectStress, 'AbsTol', 1e-2);
            Obj.verifyEqual(stressIn, -stressOut);
        end

    end

    methods (Static)

        function Bend = setup_benchmark()
            % Constructs test object with inputs for which results are
            % benchmarked with Marc Seidel's Excel calculations (which in turn
            % are validated with FEA)

            Bend = UsainUtils.ShellBendingOpening();
            Bend.eMod = 210e9;
            Bend.nu = 0.3;
            Bend.thk = 150e-3;
            Bend.wid = 322.5e-3;
            Bend.diamOutNeck = 7;
            Bend.thkNose = 1e-3 * [75 85];
            Bend.xWeldToe = 256e-3;
            Bend.diamBolt = 72e-3;
            Bend.preload = 2180e3;
            Bend.bcd = 6675e-3;
            Bend.nBolts = 160;
            Bend.stiffnBolt = pi / 4 * Bend.diamBolt^2 * Bend.eMod / (1.4 * Bend.thk);

            % Set or compute segment model parameters. These are computed to get
            % an exact match with Marc Seidel's Excel calculations
            Bend.a = 160e-3;
            Bend.b = [125e-3 120e-3];
            React = UsainUtils.ReactionDistance(Bend.a, Bend.b, Bend.thk);
            Bend.c = UsainUtils.SegmentModel.calc_segment_width(Bend.diamOutNeck - Bend.thkNose, Bend.nBolts);
            Bend.aEff = React.calc_aeff_tobinaga();
        end

    end
end
