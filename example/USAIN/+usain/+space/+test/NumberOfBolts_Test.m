classdef NumberOfBolts_Test < Unittest.TestCase & matlab.mock.TestCase

    properties (TestParameter)
        nDesignPoints = {1, 4}  % For testing scalar and array operations
    end

    methods

        function Inputs = get_inputs_for_single_bolt_option(Obj)
            % Returns inputs needed for pre-dimensioning calculations, mimicking 1 boltOption input
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
        end

        function Inputs = get_inputs_for_multiple_bolt_options(Obj)
            % Returns inputs needed for pre-dimensioning calculations, mimicking 2 boltOption inputs
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
        end

    end

    methods (Test, TestTags = {'unit'})

        function calc_max_number_of_bolts__happy(Obj)
            % GIVEN
            diamBoltCircle = 7.660;
            boltDistance = 0.0925;
            Test = usain.space.NumberOfBolts();

            % WHEN
            actualScalar = Test.calc_max_number_of_bolts(diamBoltCircle, boltDistance);
            actualRow = Test.calc_max_number_of_bolts([diamBoltCircle, diamBoltCircle], ...
                [boltDistance,  boltDistance]);
            actualColumn = Test.calc_max_number_of_bolts([diamBoltCircle; diamBoltCircle], ...
                [boltDistance;  boltDistance]);

            % THEN
            Obj.assertEqual(actualScalar, 260);
            Obj.assertEqual(actualRow, [260, 260]);
            Obj.assertEqual(actualColumn, [260; 260]);
        end

        function calc_max_number_of_bolts__unequal_input_size(Obj)
            % GIVEN
            diamBoltCircle = [7.660, 7.660];
            boltDistance = [0.0925; 0925];

            % WHEN, THEN
            f = @() usain.space.NumberOfBolts.calc_max_number_of_bolts(diamBoltCircle, boltDistance);
            Obj.assertError(f, 'NumberOfBolts:InconsistentInputSize');
        end

        function cal_min_number_of_bolts__max_number_of_bolts_governing(Obj)
            % GIVEN inputs such that the maximum number of bolts determines the minimum number of bolts
            diamBoltCircle = 7.660;
            diamBoltCircleVector = [7.660, 7.660];
            Inputs.GLOBAL_MAX_BOLT_DISTANCE = 0.250;
            Inputs.MIN_NUMBER_BOLTS_FRACTION = 1.0;
            maxNumberOfBoltsScalar = 123;
            maxNumberOfBoltsVector = [123, 110]; % mimics 2 boltOptions
            Test = usain.space.NumberOfBolts();

            % WHEN
            actualScalar = Test.calc_min_number_of_bolts(Inputs, diamBoltCircle, maxNumberOfBoltsScalar);
            actualRow = Test.calc_min_number_of_bolts(Inputs, diamBoltCircleVector, maxNumberOfBoltsVector);
            actualColumn = Test.calc_min_number_of_bolts(Inputs, diamBoltCircleVector', maxNumberOfBoltsVector');

            % THEN
            Obj.assertEqual(actualScalar, 123);
            Obj.assertEqual(actualRow, [123, 110]);
            Obj.assertEqual(actualColumn, [123; 110]);
        end

        function cal_min_number_of_bolts__global_max_bolt_distance_governing(Obj)
            % GIVEN inputs such that the maximum number of bolts determines the minimum number of bolts
            diamBoltCircle = 7.660;
            diamBoltCircleVector = [7.660, 7.660];
            Inputs.GLOBAL_MAX_BOLT_DISTANCE = 0.180;
            Inputs.MIN_NUMBER_BOLTS_FRACTION = 1.0;
            maxNumberOfBoltsScalar = 123;
            maxNumberOfBoltsVector = [123, 110]; % mimics 2 boltOptions
            Test = usain.space.NumberOfBolts();

            % WHEN
            actualScalar = Test.calc_min_number_of_bolts(Inputs, diamBoltCircle, maxNumberOfBoltsScalar);
            actualRow = Test.calc_min_number_of_bolts(Inputs, diamBoltCircleVector, maxNumberOfBoltsVector);
            actualColumn = Test.calc_min_number_of_bolts(Inputs, diamBoltCircleVector', maxNumberOfBoltsVector');

            % THEN
            Obj.assertEqual(actualScalar, 133);
            Obj.assertEqual(actualRow, [133, 133]);
            Obj.assertEqual(actualColumn, [133; 133]);
        end

        function calc_min_number_of_bolts__global_max_bolt_distance_not_input(Obj)
            % GIVEN
            diamBoltCircle = 7.660;
            Inputs.GLOBAL_MAX_BOLT_DISTANCE = nan;
            Inputs.MIN_NUMBER_BOLTS_FRACTION = 1.0;
            maxNumberOfBolts = 123;
            Test = usain.space.NumberOfBolts();

            % WHEN  THEN
            actual = Test.calc_min_number_of_bolts(Inputs, diamBoltCircle, maxNumberOfBolts);
            Obj.assertEqual(actual, 123);
        end

        function calc_min_number_of_bolts__unequal_input_size(Obj)
            % GIVEN
            diamBoltCircle = [7.660, 7.660];
            Inputs.GLOBAL_MAX_BOLT_DISTANCE = nan;
            Inputs.MIN_NUMBER_BOLTS_FRACTION = 1.0;
            maxNumberOfBolts = [123; 123];

            % WHEN, THEN
            f = @() usain.space.NumberOfBolts.calc_min_number_of_bolts(Inputs, diamBoltCircle, maxNumberOfBolts);
            Obj.assertError(f, 'NumberOfBolts:InconsistentInputSize');
        end

        function calc_min_bolt_distance__happy(Obj)
            % GIVEN
            InputsSingle = Obj.get_inputs_for_single_bolt_option();
            InputsMulti = Obj.get_inputs_for_multiple_bolt_options();

            % WHEN, THEN
            Test = usain.space.NumberOfBolts();
            Obj.assertEqual(Test.calc_min_bolt_distance(InputsSingle), 0.0925, 'AbsTol', 1e-4);
            Obj.assertEqual(Test.calc_min_bolt_distance(InputsMulti), [0.0925, 0.0925], 'AbsTol', 1e-4);
        end

        function calc_min_bolt_distance__global_min_bolt_distance_governing(Obj)
            % GIVEN
            Inputs = Obj.get_inputs_for_single_bolt_option();

            % WHEN mocking and setting inputs such that input GLOBAL_MIN_BOLT_DISTANCE governs the min. bolt
            % distance
            [Stub, Behavior] = Obj.createMock(?usain.space.NumberOfBolts);
            Obj.assignOutputsWhen(withAnyInputs(Behavior.calc_bolt_distance_for_washer()), 0.123);
            Obj.assignOutputsWhen(withAnyInputs(Behavior.calc_bolt_distance_for_tool()), 0.124);
            Inputs.GLOBAL_MIN_BOLT_DISTANCE = 0.200;
            Inputs.GLOBAL_MAX_BOLT_DISTANCE = 0.201;

            % THEN
            Obj.assertEqual(Stub.calc_min_bolt_distance(Inputs), 0.200, 'AbsTol', 1e-4);
        end

        function calc_min_bolt_distance__global_max_bolt_distance_governing(Obj)
            % GIVEN
            Inputs = Obj.get_inputs_for_single_bolt_option();

            % WHEN mocking and setting inputs such that input GLOBAL_MAX_BOLT_DISTANCE governs the min. bolt
            % distance
            [Stub, Behavior] = Obj.createMock(?usain.space.NumberOfBolts);
            Obj.assignOutputsWhen(withAnyInputs(Behavior.calc_bolt_distance_for_washer()), 0.123);
            Obj.assignOutputsWhen(withAnyInputs(Behavior.calc_bolt_distance_for_tool()), 0.124);
            Inputs.GLOBAL_MIN_BOLT_DISTANCE = 0.100;
            Inputs.GLOBAL_MAX_BOLT_DISTANCE = 0.120;

            % THEN
            Obj.assertEqual(Stub.calc_min_bolt_distance(Inputs), 0.120, 'AbsTol', 1e-4);
        end

        function calc_bolt_distance_for_tool__happy(Obj)
            % GIVEN
            Inputs = Obj.get_inputs_for_single_bolt_option();
            Test = usain.space.NumberOfBolts();

            % WHEN input TOOL_DIMENSION_CIRC_DIR is not specified in inputs
            Inputs.TOOL_DIMENSION_CIRC_DIR = nan;

            % THEN
            Obj.assertEqual(Test.calc_bolt_distance_for_tool(Inputs, 0.090), 0.0985, 'AbsTol', 1e-5);
            Obj.assertEqual(Test.calc_bolt_distance_for_tool(Inputs, 0.123), 0.1150, 'AbsTol', 1e-5);

            % WHEN input TOOL_DIMENSION_CIRC_DIR is specified in inputs
            Inputs.TOOL_DIMENSION_CIRC_DIR = 0.050;

            % WHEN, THEN
            Test = usain.space.NumberOfBolts();
            Obj.assertEqual(Test.calc_bolt_distance_for_tool(Inputs, 0.090), 0.0990, 'AbsTol', 1e-5);
            Obj.assertEqual(Test.calc_bolt_distance_for_tool(Inputs, 0.123), 0.1155, 'AbsTol', 1e-5);
        end

        function calc_bolt_distance_for_washer__happy(Obj)
            % GIVEN
            Inputs = Obj.get_inputs_for_single_bolt_option();

            % WHEN, THEN
            Test = usain.space.NumberOfBolts();
            Obj.assertEqual(Test.calc_bolt_distance_for_washer(Inputs, 0.090, 0.036), 0.1000, 'AbsTol', 1e-5);
            Obj.assertEqual(Test.calc_bolt_distance_for_washer(Inputs, 0.123, 0.036), 0.1330, 'AbsTol', 1e-5);
        end

        function from_inputs__happy(Obj, nDesignPoints)
            % GIVEN
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = nDesignPoints)).data;

            % WHEN
            actual = usain.space.NumberOfBolts.from_inputs(Inputs, Inputs.diamBoltCircle, Inputs.diamBoltCircle);

            % THEN
            Obj.assertInstanceOf(actual, 'design_space.DesignVariable');
            Obj.assertClass(actual, 'usain.space.NumberOfBolts');
            Obj.assertNotEmpty(actual.InputBounds);
            Obj.assertNotEmpty(actual.CalculatedBounds);
            Obj.assertNotEmpty(actual.stepSize);
        end

        function get_bolt_distance_tolerance__happy(Obj)
            % GIVEN WHEN THEN
            Obj.assertEqual( ...
                usain.space.NumberOfBolts.get_bolt_distance_tolerance({'torque'}), ...
                0.002);
            Obj.assertEqual( ...
                usain.space.NumberOfBolts.get_bolt_distance_tolerance({'tension'}), ...
                0.004);
            Obj.assertEqual( ...
                usain.space.NumberOfBolts.get_bolt_distance_tolerance({'tension', 'torque', 'torque'}), ...
                [0.004, 0.002, 0.002]);
        end

    end

end
