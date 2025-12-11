classdef SegmentModel_Test < UsainTest.UsainTestCase

    methods (Test, TestTags = {'unit'})

        function calc_resilience_bolt__expect(Obj)
            % GIVEN, WHEN, THEN
            Test = UsainTest.SegmentModel_Test.setup_test_object();
            actual = Test.calc_resilience_bolt();
            expected = 5.2080e-07;
            Obj.assertEqual(actual, expected, 'RelTol', 1e-4);
        end

        function calc_resilience_bolt__effect_of_extender(Obj)
            % GIVEN an object with dummy data
            Test = UsainTest.SegmentModel_Test.setup_test_object();

            % WHEN we compute the resilience of the bolt in the following cases:
            % 1. With bolt extender, and not ignoring it
            Obj.assumeFalse(Test.Mdl.Inputs.IGNORE_BOLT_EXTENDER);
            Obj.assumeGreaterThan(Test.Mdl.Extr.len, 0);
            actual1 = Test.calc_resilience_bolt();
            % 2. With bolt extender, and ignoring it
            Test.Mdl.Inputs.IGNORE_BOLT_EXTENDER = true;
            actual2 = Test.calc_resilience_bolt();

            % THEN
            Obj.assertGreaterThan(actual1, actual2);
        end

        function calc_resilience_stud__effect_of_extender(Obj)
            % GIVEN an object with dummy data for a stud
            Test = UsainTest.SegmentModel_Test.setup_test_object();
            Assy = usain.fastener.CatalogLibrary.select_assemblies( ...
                usain.inputs.Site.OFFSHORE, 'ISO_M64', 'torque', 'ISO');
            Assy.Bolt.len = 0.430;
            Assy.Bolt.lenThread = 0.180;
            Test.Mdl.Bolt = Assy.Bolt.to_struct_of_arrays();
            Test.Mdl.Nut = Assy.Nut.to_struct_of_arrays();
            Test.Mdl.Wash = Assy.Washer.to_struct_of_arrays();

            % WHEN we compute the resilience of a stud in the following cases:
            % 1. With bolt extender, and not ignoring it
            Obj.assumeFalse(Test.Mdl.Inputs.IGNORE_BOLT_EXTENDER);
            Obj.assumeGreaterThan(Test.Mdl.Extr.len, 0);
            actual1 = Test.calc_resilience_stud();
            % 2. With bolt extender, and ignoring it
            Test.Mdl.Inputs.IGNORE_BOLT_EXTENDER = true;
            actual2 = Test.calc_resilience_stud();

            % THEN
            Obj.assertGreaterThan(actual1, actual2);
        end

        function calc_resilience_washers__expect(Obj)
            % GIVEN
            Test = UsainTest.SegmentModel_Test.setup_test_object();

            % WHEN, THEN
            actual = Test.calc_resilience_washers();
            expected = 1.3672e-08; % Benchmarked on: 2018-06-07
            Obj.assertEqual(actual, expected, 'RelTol', 1e-4);
        end

        function calc_resilience_washers__no_washer(Obj)
            % GIVEN a bolt assembly without washer
            Test = UsainTest.SegmentModel_Test.setup_test_object();
            Test.Mdl.Wash.len = 0;

            % WHEN, THEN
            Obj.assertEqual(Test.calc_resilience_washers(), 0);
        end

        function calc_resilience_extender__expect(Obj)
            % GIVEN
            Test = UsainTest.SegmentModel_Test.setup_test_object();

            % WHEN, THEN
            actual = Test.calc_resilience_extender();
            expected = 6.1175e-09;
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-4);

            % WHEN having a 0mm extender
            % THEN
            Test.Mdl.Extr.len = 0;
            Obj.verifyEqual(Test.calc_resilience_extender(), 0, 'RelTol', 1e-4);

            % WHEN having a 0mm extender with 0mm diameter as well
            % THEN
            Test.Mdl.Extr.len = 0;
            Test.Mdl.Extr.diamOut = 0;
            Test.Mdl.Extr.diamIn = 0;
            Obj.verifyEqual(Test.calc_resilience_extender(), 0, 'RelTol', 1e-4);
        end

        function calc_resilience_extender__effect_of_extender(Obj)
            % GIVEN an object with dummy data
            Test = UsainTest.SegmentModel_Test.setup_test_object();

            % WHEN we compute the resilience of the extender in the following cases:
            % 1. With bolt extender, and not ignoring it
            Obj.assumeFalse(Test.Mdl.Inputs.IGNORE_BOLT_EXTENDER);
            Obj.assumeGreaterThan(Test.Mdl.Extr.len, 0);
            actual1 = Test.calc_resilience_extender();
            % 2. With bolt extender, and ignoring it
            Test.Mdl.Inputs.IGNORE_BOLT_EXTENDER = true;
            actual2 = Test.calc_resilience_extender();

            % THEN
            Obj.assertGreaterThan(actual1, actual2);
            Obj.assertEqual(actual2, 0);
        end

        function test_method_calc_resilience_flanges(Obj)
            % GIVEN
            Test = UsainTest.SegmentModel_Test.setup_test_object();

            % WHEN, THEN
            actual = Test.calc_resilience_flanges();
            expected = 1.0090e-07; % Benchmarked on: 2018-06-07
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-4);
        end

        function calc_load_factor__expect(Obj)
            % GIVEN
            Test = UsainTest.SegmentModel_Test.setup_test_object();

            % WHEN, THEN
            actual = Test.calc_load_factor();
            expected = 0.1573;
            Obj.assertEqual(actual, expected, 'RelTol', 1e-4);
        end

        function calc_load_factor__effect_of_extender(Obj)
            % GIVEN an object with dummy data
            Test = UsainTest.SegmentModel_Test.setup_test_object();

            % WHEN we compute the load factor when
            % 1. including the bolt extender
            Obj.assumeFalse(Test.Mdl.Inputs.IGNORE_BOLT_EXTENDER);
            Obj.assumeGreaterThan(Test.Mdl.Extr.len, 0);
            actual1 = Test.calc_load_factor();
            % 2. ignoring the bolt extender
            Test.Mdl.Inputs.IGNORE_BOLT_EXTENDER = true;
            actual2 = Test.calc_load_factor();

            % THEN
            Obj.assertGreaterThanOrEqual(actual2, actual1);
        end

        function test_method_calc_segment_force(Obj)
            % GIVEN
            Test = UsainTest.SegmentModel_Test.setup_test_object();
            moment = 200e3;
            fz = 100;

            % WHEN, THEN
            actual = Test.calc_segment_force(moment, -fz);
            expected = 1.3414e3; % Benchmarked on: 2018-06-07
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-4);
        end

        function calc_inner_width__benchmark(Obj)
            % GIVEN pre-defined inputs
            diam = 7;
            bcd = 6675e-3;
            width = 322.5e-3;

            % WHEN computing distance "a"
            actual = UsainUtils.SegmentModel.calc_inner_width(diam, bcd, width);

            % THEN expect a benchmarked result
            expected = 160e-3;
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-6);
        end

        function calc_outer_width__l_flange(Obj)
            % GIVEN pre-defined inputs for an L-flange
            FlangeType = usain.inputs.FlangeType.L;
            diameterOutNeck = 7;
            diameterBoltCircle = 6675e-3;
            neckThicknessUp = 1e-3 * [75 85 80];
            neckThicknessLo = 1e-3 * [75 80 85];

            % WHEN computing distance "b"
            actual = UsainUtils.SegmentModel.calc_outer_width( ...
                FlangeType, diameterOutNeck, diameterBoltCircle, neckThicknessUp, neckThicknessLo);

            % THEN expect a benchmarked result
            expected = 1e-3 * [125, 122.5, 122.5];
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-6);
        end

        function calc_outer_width__t_flange(Obj)
            % GIVEN pre-defined inputs for a T-flange
            FlangeType = usain.inputs.FlangeType.T;
            diameterOutNeck = 7;
            diameterBoltCircle = 6675e-3;
            neckThicknessUp = 1e-3 * [75 85 80];
            neckThicknessLo = 1e-3 * [75 80 85];

            % WHEN computing distance "b"
            actual = UsainUtils.SegmentModel.calc_outer_width( ...
                FlangeType, diameterOutNeck, diameterBoltCircle, neckThicknessUp, neckThicknessLo);

            % THEN expect a benchmarked result
            expected = 1e-3 * [125, 120, 122.5];
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-6);
        end

        function calc_segment_width__benchmark(Obj)
            % GIVEN pre-defined inputs
            diam = 1e-3 * [6925, 6915];
            nBolts = 160;

            % WHEN computing distance "c"
            actual = UsainUtils.SegmentModel.calc_segment_width(diam, nBolts);

            % THEN expect a benchmarked result
            expected = 1e-3 * [136.0 135.8];
            Obj.verifyEqual(actual, expected, 'RelTol', 1e-3);
        end

        function calc_bending_resilience_bolt__expect(Obj)
            % GIVEN
            Mdl.Bolt.diam = 0.072;
            Mdl.Bolt.minorDiameter = 0.064219;
            Mdl.Bolt.len = 0.560;
            Mdl.Bolt.lenThread = 0.200;
            Mdl.Inputs.E_BOLT = 210e9;
            Mdl.Inputs.IGNORE_BOLT_EXTENDER = true;
            Mdl.Extr.len = 0.096;
            Mdl.Space.thickness = 0.150;
            Mdl.Wash.len = 0.010;
            SegmentModel = UsainUtils.SegmentModel();
            SegmentModel.Mdl = Mdl;

            % WHEN, THEN
            actual = SegmentModel.calc_bending_resilience_bolt();
            expected = 1.7116e-06;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-10);

            % WHEN we include the effect of a bolt extender
            % THEN we expect an increased resilience (longer effective bolt length -> lower stiffness)
            SegmentModel.Mdl.Inputs.IGNORE_BOLT_EXTENDER = false;
            actualWithExtender = SegmentModel.calc_bending_resilience_bolt();
            Obj.assertGreaterThan(actualWithExtender, actual);
        end

        function calc_bending_resilience_stud__expect(Obj)
            % GIVEN
            Mdl.Bolt.diam = 0.072;
            Mdl.Bolt.minorDiameter = 0.064219;
            Mdl.Bolt.pitchDiameter = 0.068103;
            Mdl.Bolt.len = 0.560;
            Mdl.Bolt.lenThread = 0.200;
            Mdl.Bolt.pitch = 0.006;
            Mdl.Inputs.E_BOLT = 210e9;
            Mdl.Inputs.IGNORE_BOLT_EXTENDER = true;
            Mdl.Extr.len = 0.096;
            Mdl.Space.thickness = 0.150;
            Mdl.Wash.len = 0.010;
            SegmentModel = UsainUtils.SegmentModel();
            SegmentModel.Mdl = Mdl;

            % WHEN, THEN
            actual = SegmentModel.calc_bending_resilience_stud();
            expected = 2.4192e-06;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-10);

            % WHEN we include the effect of a bolt extender
            % THEN we expect an increased resilience (longer effective bolt length -> lower stiffness)
            SegmentModel.Mdl.Inputs.IGNORE_BOLT_EXTENDER = false;
            actualWithExtender = SegmentModel.calc_bending_resilience_stud();
            Obj.assertGreaterThan(actualWithExtender, actual);
        end

        function calc_bending_resilience_fastener__stud(Obj)
            % GIVEN
            Mdl.Bolt.diam = 0.072;
            Mdl.Bolt.minorDiameter = 0.064219;
            Mdl.Bolt.pitchDiameter = 0.068103;
            Mdl.Bolt.len = 0.560;
            Mdl.Bolt.lenThread = 0.200;
            Mdl.Bolt.pitch = 0.006;
            Mdl.Inputs.E_BOLT = 210e9;
            Mdl.Inputs.IGNORE_BOLT_EXTENDER = true;
            Mdl.Extr.len = 0.096;
            Mdl.Space.thickness = 0.150;
            Mdl.Wash.len = 0.010;
            SegmentModel = UsainUtils.SegmentModel();
            SegmentModel.Mdl = Mdl;

            % WHEN we have a stud
            SegmentModel.Mdl.Bolt.type = 'stud';

            % THEN
            actual = SegmentModel.calc_bending_resilience_fastener();
            expected = SegmentModel.calc_bending_resilience_stud();
            Obj.assertEqual(actual, expected);
        end

        function calc_bending_resilience_fastener__bolt(Obj)
            % GIVEN
            Mdl.Bolt.diam = 0.072;
            Mdl.Bolt.minorDiameter = 0.064219;
            Mdl.Bolt.pitchDiameter = 0.068103;
            Mdl.Bolt.len = 0.560;
            Mdl.Bolt.lenThread = 0.200;
            Mdl.Bolt.pitch = 0.006;
            Mdl.Inputs.E_BOLT = 210e9;
            Mdl.Inputs.IGNORE_BOLT_EXTENDER = true;
            Mdl.Extr.len = 0.096;
            Mdl.Space.thickness = 0.150;
            Mdl.Wash.len = 0.010;
            SegmentModel = UsainUtils.SegmentModel();
            SegmentModel.Mdl = Mdl;

            % WHEN we have a bolt
            SegmentModel.Mdl.Bolt.type = 'hex';

            % THEN
            expected = SegmentModel.calc_bending_resilience_bolt();
            actual = SegmentModel.calc_bending_resilience_fastener();
            Obj.assertEqual(actual, expected);
        end

    end

    methods (Static)

        function Test = setup_test_object()

            Test = UsainUtils.SegmentModel();

            Test.Mdl.Space.thickness = 120e-3;
            Test.Mdl.Space.nBolts = 100;
            Test.Mdl.Space.nPoints = 1;
            Test.Mdl.Inputs.E_BOLT = 210e6;
            Test.Mdl.Inputs.E_FLANGE = 210e6;
            Test.Mdl.Inputs.diamBoltHole = 70e-3;
            Test.Mdl.Inputs.thicknNoseUp = 40e-3;
            Test.Mdl.Inputs.thicknNoseLo = 45e-3;
            Test.Mdl.diameterOutNeck = 6;
            Test.Mdl.Inputs.PSF_FAVORABLE_LOADS = 0.9;
            Test.Mdl.Inputs.IGNORE_BOLT_EXTENDER = false;

            Assy = usain.fastener.CatalogLibrary.select_assemblies( ...
                usain.inputs.Site.OFFSHORE, 'HV_M64', 'torque', 'HV');
            Assy.Bolt.len = 0.430;
            Assy.Bolt.lenThread = Assy.Bolt.defaults.lengthThread;
            Assy.Extender.len = 10e-3;

            Test.Mdl.Bolt = Assy.Bolt.to_struct_of_arrays();
            Test.Mdl.Nut = Assy.Nut.to_struct_of_arrays();
            Test.Mdl.Wash = Assy.Washer.to_struct_of_arrays();
            Test.Mdl.Extr = Assy.Extender.to_struct_of_arrays();
        end

    end
end
