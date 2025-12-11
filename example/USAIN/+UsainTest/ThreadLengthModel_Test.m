classdef ThreadLengthModel_Test < Unittest.TestCase

    properties (TestParameter)
        % Setup of parameterized tests:
        %   boltLabel: Used to get reference data (e.g. from method `init_reference_iso_m42`)
        %   expectedGrippedLengthFixed: Expected length of gripped threads on fixed side
        %   expectedGrippedLengthFree: Expected length of gripped threads on free side
        %   expectedFreeLengthFree: Expected length of free threads on free side
        boltLabel = {'iso_m42', 'iso_m72', 'hv_m64', 'hv_m56'}
        expectedGrippedLengthFixed = {41.80e-3, 28.80e-3, 0, 0}
        expectedGrippedLengthFree = {65.72e-3, 68.42e-3, 22.00e-3, 24.3e-3}
        expectedFreeLengthFree = {10.92e-3, 27.92e-3, 7.00e-3, 1.30e-3}

        tighteningSide = {"upper", "lower", "upper", "lower"}
        expectedFixedSide = {"upper", "lower", "lower", "upper"}
    end

    methods (Test, TestTags = {'unit'}, ParameterCombination = 'sequential')

        function calc_gripped_length_fixed_side__expect(Obj, boltLabel, expectedGrippedLengthFixed)
            % GIVEN, WHEN, THEN
            Test = UsainTest.ThreadLengthModel_Test.(['init_reference_', boltLabel])();
            actual = Test.calc_gripped_length_fixed_side();
            Obj.assertEqual(actual, expectedGrippedLengthFixed, 'AbsTol', 1e-5);
        end

        function calc_gripped_length_free_side__expect(Obj, boltLabel, expectedGrippedLengthFree)
            % GIVEN, WHEN, THEN
            Test = UsainTest.ThreadLengthModel_Test.(['init_reference_', boltLabel])();
            actual = Test.calc_gripped_length_free_side();
            Obj.assertEqual(actual, expectedGrippedLengthFree, 'AbsTol', 1e-5);
        end

        function calc_visible_length_free_side__expect(Obj, boltLabel, expectedFreeLengthFree)
            % GIVEN, WHEN, THEN
            Test = UsainTest.ThreadLengthModel_Test.(['init_reference_', boltLabel])();
            actual = Test.calc_visible_length_free_side();
            Obj.assertEqual(actual, expectedFreeLengthFree, 'AbsTol', 1e-5);
        end

        function zero_for_bolt__stud(Obj)
            % GIVEN a ThreadLengthModel instance for a stud
            Test = UsainUtils.ThreadLengthModel('fastenerType', 'stud');

            % WHEN, THEN
            expect = 123;
            Obj.assertEqual(Test.zero_for_bolt(expect), expect);
        end

        function zero_for_bolt__bolt(Obj)
            % GIVEN a ThreadLengthModel instance for a bolt
            Test = UsainUtils.ThreadLengthModel('fastenerType', 'hex');

            % WHEN, THEN
            Obj.assertEqual(Test.zero_for_bolt(123), 0);
        end

        function zero_for_bolt__unknown_fastener_type(Obj)
            % GIVEN a ThreadLengthModel instance without a fastener type set
            Test = UsainUtils.ThreadLengthModel();

            % WHEN, THEN
            Obj.assertError(@() Test.zero_for_bolt(123), 'ThreadLengthModel:UnknownFastenerType');

            % WHEN we set the type to some unsupported type
            Test.fastenerType = 'NotSupported';

            % THEN
            Obj.assertError(@() Test.zero_for_bolt(123), 'ThreadLengthModel:UnknownFastenerType');
        end

        function calc_max__zero_nominal(Obj)
            % GIVEN a zero nominal value, and a tolerance
            nominal = 0;
            tolerance = 2e-3;

            % WHEN, THEN
            Test = UsainUtils.ThreadLengthModel();
            Obj.assertEqual(Test.calc_max(nominal, tolerance), 0);
        end

        function calc_max__nonzero_nominal(Obj)
            % GIVEN a non-zero nominal value, and a tolerance
            nominal = 10;
            tolerance = 2e-3;

            % WHEN, THEN
            Test = UsainUtils.ThreadLengthModel();
            Obj.assertEqual(Test.calc_max(nominal, tolerance), 10.002);
        end

        function calc_min__zero_nominal(Obj)
            % GIVEN a zero nominal value, and a tolerance
            nominal = 0;
            tolerance = 2e-3;

            % WHEN, THEN
            Test = UsainUtils.ThreadLengthModel();
            Obj.assertEqual(Test.calc_min(nominal, tolerance), 0);
        end

        function calc_min__nonzero_nominal(Obj)
            % GIVEN a non-zero nominal value, and a tolerance
            nominal = 10;
            tolerance = 2e-3;

            % WHEN, THEN
            Test = UsainUtils.ThreadLengthModel();
            Obj.assertEqual(Test.calc_min(nominal, tolerance), 9.998);
        end

        function set_fixed_length__hex_bolt(Obj)
            % GIVEN typical input args for a hex bolt
            Test = UsainUtils.ThreadLengthModel();
            Test.fastenerType = 'hex';

            % WHEN, THEN
            Inputs = struct();  % not used
            tighteningMethod = 'bla';  % not used
            Test.set_fixed_length(Inputs, tighteningMethod);
            actual = Test.fixedLength;
            Obj.assertEqual(actual, 0);
        end

        function set_fixed_length__torqued_stud_bolt(Obj)
            % GIVEN typical input args for a torque-tightened stud bolt
            Test = UsainUtils.ThreadLengthModel();
            Test.fastenerType = 'stud';
            Test.diamBolt = 0.072;
            Test.pitch = 0.006;

            % WHEN, THEN
            tighteningMethod = 'torque';
            Inputs.MIN_VISIBLE_THREAD_LENGTH = '1.5P';
            Test.set_fixed_length(Inputs, tighteningMethod);
            actual = Test.fixedLength;
            expected = 0.009;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-4);
        end

        function set_fixed_length__tensioned_stud_bolt(Obj)
            % GIVEN typical input args for a tension-tightened stud bolt
            Test = UsainUtils.ThreadLengthModel();
            Test.fastenerType = 'stud';
            Test.diamBolt = 0.042;
            Test.pitch = 0.0045;

            % WHEN, THEN
            tighteningMethod = 'tension';
            Inputs.MAX_VISIBLE_THREAD_LENGTH_TENSION = '1.1D';
            Test.set_fixed_length(Inputs, tighteningMethod);
            actual = Test.fixedLength;
            expected = 47e-3;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-4);
        end

        function set_fixed_and_free_side(Obj, boltLabel, tighteningSide, expectedFixedSide)
            % GIVEN, WHEN, THEN
            ThreadModel = UsainTest.ThreadLengthModel_Test.(['init_reference_', boltLabel])();
            ThreadModel.set_fixed_and_free_side(tighteningSide);
            Obj.assertEqual(ThreadModel.fixedSide, expectedFixedSide);
            oppositeSide = replace(expectedFixedSide, ["upper", "lower"], ["lower", "upper"]);
            Obj.assertEqual(ThreadModel.freeSide, oppositeSide);
        end

        function from_flange_model__happy_case(Obj)
            % GIVEN a mimicked UsainUtils.FlangeModel instance with dummy data for a single design point
            FlangeModel = UsainTest.ThreadLengthModel_Test.setup_flange_model_data();

            % WHEN
            Test = UsainUtils.ThreadLengthModel.from_flange_model(FlangeModel);

            % THEN
            Obj.assertEqual(Test.fastenerType, 'stud');
            Obj.assertEqual(Test.fixedLength, 0.047, 'AbsTol', 1e-5);
            Obj.assertEqual(Test.boltLength, 0.430);
            Obj.assertEqual(Test.boltLengthToleranceClass, 'js17');
            Obj.assertEqual(Test.diamBolt, 0.042);
            Obj.assertEqual(Test.pitch, 0.0045);
            Obj.assertEqual(Test.lengthThread, 0.100);
            Obj.assertEqual(Test.nutHeightMax, 0.042);
            Obj.assertEqual(Test.nutHeightMin, 0.041, 'RelTol', 1e-10);
            Obj.assertEqual(Test.washerHeight, 0);
            Obj.assertEqual(Test.washerHeightTolerance, 0);
            Obj.assertEqual(Test.extenderLength, 0);
            Obj.assertEqual(Test.extenderLengthTolerance, 0.001);
            Obj.assertEqual(Test.flangeThickness, 0.100);
            Obj.assertEqual(Test.flangeThicknessTolerancePlus, 0.001);
            Obj.assertEqual(Test.upperFlangeThicknessAllowance, 0.003);
            Obj.assertEqual(Test.lowerFlangeThicknessAllowance, 0.003);
        end

        function from_flange_model__multiple_design_points(Obj)
            % GIVEN a mimicked FlangeModel with multiple design points
            FlangeModel.Space.nPoints = 2;

            % WHEN, THEN
            f = @() UsainUtils.ThreadLengthModel.from_flange_model(FlangeModel);
            Obj.verifyError(f, 'ThreadLengthModel:MultipleDesignPointsFound');
        end

    end

    methods (Test, TestTags = {'integration'})

        function from_inputs__using_fixtures(Obj)
            % GIVEN processed USAIN inputs
            fixture = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2));
            Inputs = fixture.data;

            % WHEN
            Test = UsainUtils.ThreadLengthModel.from_inputs(Inputs);

            % THEN we expect a filled ThreadLengthModel object (array) to be created without errors. Check
            % some random things of the returned ThreadLengthModel object (array)
            Obj.assertInstanceOf(Test, 'UsainUtils.ThreadLengthModel');
            Obj.assertSize(Test, [1 2]);
            Obj.assertEqual(Test(1).flangeThicknessTolerancePlus, Inputs.TOL_FLANGE_THICKNESS_PLUS);
            Obj.assertEqual(Test(2).upperFlangeThicknessAllowance, Inputs.ALW_UPPER_FLANGE_THICKNESS);
            Obj.assertEqual(Test(1).lowerFlangeThicknessAllowance, Inputs.ALW_LOWER_FLANGE_THICKNESS);
            Obj.assertEqual(Test(1).fastenerType, 'stud');
            Obj.assertEqual(Test(1).fixedLength, 0.047, 'AbsTol', 1e-4);
            Obj.assertEqual(Test(1).lengthThread, 0.130, 'AbsTol', 1e-4);
            Obj.assertEqual(Test(2).fastenerType, 'stud');
            Obj.assertEqual(Test(2).fixedLength, 0.047, 'AbsTol', 1e-4);
            Obj.assertEqual(Test(1).fixedSide, "upper");
            Obj.assertEqual(Test(2).fixedSide, "upper");
        end

        function check_thread_length__expected(Obj)
            % GIVEN processed USAIN inputs
            fixture = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2));
            Inputs = fixture.data;

            % WHEN
            Test = UsainUtils.ThreadLengthModel.from_inputs(Inputs);
            Test(1).boltLength = 540e-3;
            Test(2).boltLength = 430e-3;
            % NOTE: Fixture contains 2 boltOptions
            Test(1).flangeThickness = 1e-3 * [150, 190];
            Test(2).flangeThickness = 1e-3 * [173, 175, 200];
            actualStud = Test(1).check_thread_lengths(1, 4);
            actualHex = Test(2).check_thread_lengths(1, 4);

            % THEN
            expectedStud = [false, true];
            expectedHex = [false, false, false];
            Obj.assertEqual(actualStud, expectedStud);
            Obj.assertEqual(actualHex, expectedHex);
        end

    end

    methods (Static)

        function Test = init_reference_iso_m42()
            % Constructs ThreadLengthModel with reference values based on an ISO_M42 stud
            Test = UsainUtils.ThreadLengthModel();
            Test.fastenerType = 'stud';
            Test.fixedLength = 1.1 * 42e-3;
            Test.boltLength = 540e-3;
            Test.boltLengthToleranceClass = 'js14';
            Test.diamBolt = 42e-3;
            Test.pitch = 4.5e-3;
            Test.lengthThread = 130e-3;
            Test.nutHeightMax = 42e-3;
            Test.nutHeightMin = 40.4e-3;
            Test.washerHeight = 0;
            Test.washerHeightTolerance = 0;
            Test.extenderLength = 0;
            Test.extenderLengthTolerance = 0.5e-3;
            Test.flangeThickness = 195e-3;
            Test.flangeThicknessTolerancePlus = 2.0e-3;
            Test.upperFlangeThicknessAllowance = 2.0e-3;
            Test.lowerFlangeThicknessAllowance = 2.0e-3;
        end

        function Test = init_reference_iso_m72()
            % Constructs ThreadLengthModel with reference values based on an ISO_M72 stud
            Test = UsainUtils.ThreadLengthModel();
            Test.fastenerType = 'stud';
            Test.fixedLength = 1.1 * 72e-3;
            Test.boltLength = 540e-3;
            Test.boltLengthToleranceClass = 'js14';
            Test.diamBolt = 72e-3;
            Test.pitch = 6e-3;
            Test.lengthThread = 180e-3;
            Test.nutHeightMax = 72e-3;
            Test.nutHeightMin = 70.1e-3;
            Test.washerHeight = 0;
            Test.washerHeightTolerance = 0;
            Test.extenderLength = 0;
            Test.extenderLengthTolerance = 0.5e-3;
            Test.flangeThickness = 140e-3;
            Test.flangeThicknessTolerancePlus = 2.0e-3;
            Test.upperFlangeThicknessAllowance = 2.0e-3;
            Test.lowerFlangeThicknessAllowance = 2.0e-3;
        end

        function Test = init_reference_hv_m56()
            % Constructs ThreadLengthModel with reference values based on an HV_M56 bolt
            Test = UsainUtils.ThreadLengthModel();
            Test.fastenerType = 'hex';
            Test.fixedLength = 0;
            Test.boltLength = 400e-3;
            Test.boltLengthToleranceClass = 'js17';
            Test.diamBolt = 56e-3;
            Test.pitch = 5.5e-3;
            Test.lengthThread = 90e-3;
            Test.nutHeightMax = 45e-3;
            Test.nutHeightMin = 43.4e-3;
            Test.washerHeight = 10e-3;
            Test.washerHeightTolerance = 1.2e-3;
            Test.extenderLength = 20e-3;
            Test.extenderLengthTolerance = 0.5e-3;
            Test.flangeThickness = 150e-3;
            Test.flangeThicknessTolerancePlus = 2.0e-3;
            Test.upperFlangeThicknessAllowance = 2.0e-3;
            Test.lowerFlangeThicknessAllowance = 2.0e-3;
        end

        function Test = init_reference_hv_m64()
            % Constructs ThreadLengthModel with reference values based on an HV_M64 bolt
            Test = UsainUtils.ThreadLengthModel();
            Test.fastenerType = 'hex';
            Test.fixedLength = 0;
            Test.boltLength = 430e-3;
            Test.boltLengthToleranceClass = 'js17';
            Test.diamBolt = 64e-3;
            Test.pitch = 6e-3;
            Test.lengthThread = 100e-3;
            Test.nutHeightMax = 51e-3;
            Test.nutHeightMin = 49.1e-3;
            Test.washerHeight = 18e-3;  % Custom washer
            Test.washerHeightTolerance = 1.2e-3;
            Test.extenderLength = 18e-3;
            Test.extenderLengthTolerance = 0.5e-3;
            Test.flangeThickness = 152e-3;
            Test.flangeThicknessTolerancePlus = 2.0e-3;
            Test.upperFlangeThicknessAllowance = 2.0e-3;
            Test.lowerFlangeThicknessAllowance = 2.0e-3;
        end

        function data = setup_flange_model_data()
            % Returns data (struct) that mimicks a UsainUtils.FlangeModel instance with just the data needed
            % to construct a UsainUtils.ThreadLengthModel instance
            % This method can be used to generate a test data fixture (and hence promotes re-use)

            data.Bolt.diam = 0.042;
            data.Bolt.label = {'ISO_M42'};
            data.Bolt.len = 0.430;
            data.Bolt.lengthTolerance = {'js17'};
            data.Bolt.lenThread = 0.100;
            data.Bolt.pitch = 0.0045;
            data.Bolt.type = {'stud'};
            data.Extr.len = 0;
            data.Nut.lenMax = 0.042;
            data.Nut.lenMin = 0.041;
            data.Space.nPoints = 1;
            data.Space.thickness = 0.100;
            data.Tool.tighteningMethod = {'tension'};
            data.Wash.len = 0;
            data.Wash.lenMin = 0;
            data.Inputs.ALW_UPPER_FLANGE_THICKNESS = 0.003;
            data.Inputs.ALW_LOWER_FLANGE_THICKNESS = 0.003;
            data.Inputs.MAX_VISIBLE_THREAD_LENGTH_TENSION = '1.1D';
            data.Inputs.TOL_EXTENDER_LENGTH = 0.001;
            data.Inputs.TOL_FLANGE_THICKNESS_PLUS = 0.001;
            data.Inputs.TIGHTENING_SIDE_INSTALLATION = "upper";
        end

    end

end
