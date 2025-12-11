classdef ThreadLengthChecker_Test < Unittest.TestCase

    properties (TestParameter)
        % Test parameters to repeat tests that are independent of tightening method and/or fastener type
        tighteningMethod = {'torque', 'tension'}
        fastenerType = {'stud', 'hex'}
    end

    methods (Test, TestTags = {'unit'})

        function is_valid_lengths__all_scalar(Obj)
            % GIVEN scalar thread length utilizations
            tighteningSide = "upper";
            ThreadChecker = UsainUtils.ThreadLengthChecker();
            ThreadChecker.GrippedThreadFixedSide = UsainUtils.ThreadLengthData(tighteningSide, 1);
            ThreadChecker.GrippedThreadFixedSide.utilization = 0.1;
            ThreadChecker.VisibleThreadFixedSide = UsainUtils.ThreadLengthData(tighteningSide, 2);
            ThreadChecker.VisibleThreadFixedSide.utilization = 0.2;
            ThreadChecker.GrippedThreadFreeSide = UsainUtils.ThreadLengthData(tighteningSide, 3);
            ThreadChecker.GrippedThreadFreeSide.utilization = 0.3;
            ThreadChecker.VisibleThreadFreeSide = UsainUtils.ThreadLengthData(tighteningSide, 4);
            ThreadChecker.VisibleThreadFreeSide.utilization = 0.4;

            % WHEN, THEN
            actual = ThreadChecker.is_valid_lengths();
            expected = true;
            Obj.assertEqual(actual, expected);
        end

        function is_valid_lengths__some_vectors(Obj)
            % GIVEN thread length utilizations, some scalar and some vector (vectors all the same size)
            tighteningSide = "upper";
            ThreadChecker = UsainUtils.ThreadLengthChecker();
            ThreadChecker.GrippedThreadFixedSide = UsainUtils.ThreadLengthData(tighteningSide, 1);
            ThreadChecker.GrippedThreadFixedSide.utilization = 0.1;
            ThreadChecker.VisibleThreadFixedSide = UsainUtils.ThreadLengthData(tighteningSide, 2);
            ThreadChecker.VisibleThreadFixedSide.utilization = 0.2;
            ThreadChecker.GrippedThreadFreeSide = UsainUtils.ThreadLengthData(tighteningSide, 3);
            ThreadChecker.GrippedThreadFreeSide.utilization = ones(1, 15) .* 0.3;
            ThreadChecker.VisibleThreadFreeSide = UsainUtils.ThreadLengthData(tighteningSide, 4);
            ThreadChecker.VisibleThreadFreeSide.utilization = ones(1, 15) .* 0.4;

            % WHEN, THEN
            actual = ThreadChecker.is_valid_lengths();
            expected = true(1, 15);
            Obj.assertEqual(actual, expected);
        end

        function calc_thread_length_limit__min_visible(Obj, tighteningMethod)
            % GIVEN an M72 fastener and length expression inputs
            Test = UsainTest.ThreadLengthChecker_Test.setup_with_m72_and_thread_length_expression_inputs();
            Test.tighteningMethod = tighteningMethod;  % result is independent of tightening method

            % WHEN, THEN
            actual = Test.calc_thread_length_limit('min', 'visible');
            expected = 0.018;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-4);
        end

        function calc_thread_length_limit__max_visible_tension(Obj)
            % GIVEN an M72 fastener and length expression inputs
            Test = UsainTest.ThreadLengthChecker_Test.setup_with_m72_and_thread_length_expression_inputs();
            Test.tighteningMethod = 'tension';

            % WHEN, THEN
            actual = Test.calc_thread_length_limit('max', 'visible');
            expected = 0.0792;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-4);
        end

        function calc_thread_length_limit__max_visible_torque(Obj)
            % GIVEN an M72 fastener and length expression inputs
            Test = UsainTest.ThreadLengthChecker_Test.setup_with_m72_and_thread_length_expression_inputs();
            Test.tighteningMethod = 'torque';

            % WHEN, THEN
            actual = Test.calc_thread_length_limit('max', 'visible');
            expected = 0.0288;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-4);
        end

        function calc_thread_length_limit__min_gripped(Obj, tighteningMethod)
            % GIVEN an M72 fastener and length expression inputs
            Test = UsainTest.ThreadLengthChecker_Test.setup_with_m72_and_thread_length_expression_inputs();
            Test.tighteningMethod = tighteningMethod;  % result is independent of tightening method

            % WHEN, THEN
            actual = Test.calc_thread_length_limit('min', 'gripped');
            expected = 0.024;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-4);
        end

        function calc_thread_length_limit__max_gripped(Obj, tighteningMethod)
            % GIVEN an M72 fastener and length expression inputs
            Test = UsainTest.ThreadLengthChecker_Test.setup_with_m72_and_thread_length_expression_inputs();
            Test.tighteningMethod = tighteningMethod;  % result is independent of tightening method

            % WHEN, THEN
            Obj.verifyError(@()Test.calc_thread_length_limit('max', 'gripped'), ...
                'ThreadLengthChecker:InputNotFound');
        end

        function check_gripped_thread_fixed_side__stud(Obj, tighteningMethod)
            % GIVEN a mimicked FlangeModel data structure with data to compute the gripped thread length on
            % the fixed side of a stud
            tighteningSide = "upper";
            ThreadChecker = UsainUtils.ThreadLengthChecker();
            ThreadChecker.diameter = 0.072;
            ThreadChecker.pitch = 0.006;
            ThreadChecker.fastenerType = 'stud';
            ThreadChecker.tighteningMethod = tighteningMethod;  % result is independent of tightening method
            ThreadChecker.Inputs.MIN_GRIPPED_THREAD_LENGTH = '4P';

            % WHEN, THEN
            ThreadChecker.check_gripped_thread_fixed_side(tighteningSide, 0.030);
            expectedUtilization = 0.8;
            Obj.assertEqual(ThreadChecker.GrippedThreadFixedSide.utilization, expectedUtilization);
        end

        function check_gripped_thread_fixed_side__zero_for_hex_bolt(Obj, tighteningMethod)
            % GIVEN a mimicked FlangeModel data structure with data to compute the gripped thread length on
            % the fixed side of a hex-bolt (which is always zero)
            tighteningSide = "upper";
            ThreadChecker = UsainUtils.ThreadLengthChecker();
            ThreadChecker.diameter = 0.072;
            ThreadChecker.pitch = 0.006;
            ThreadChecker.fastenerType = 'hex';
            ThreadChecker.tighteningMethod = tighteningMethod;  % result is independent of tightening method
            ThreadChecker.Inputs.MIN_GRIPPED_THREAD_LENGTH = '4P';

            % WHEN, THEN
            ThreadChecker.check_gripped_thread_fixed_side(tighteningSide, 0.030);
            expectedUtilization = 0.0;
            Obj.assertEqual(ThreadChecker.GrippedThreadFixedSide.utilization, expectedUtilization);
        end

        function check_visible_thread_fixed_side__stud_torque(Obj)
            % GIVEN a mimicked FlangeModel data structure with data to compute the visible thread length on
            % the fixed side of a stud
            tighteningSide = "upper";
            ThreadChecker = UsainUtils.ThreadLengthChecker();
            ThreadChecker.diameter = 0.072;
            ThreadChecker.pitch = 0.006;
            ThreadChecker.fastenerType = 'stud';
            ThreadChecker.tighteningMethod = 'torque';
            ThreadChecker.Inputs.MIN_VISIBLE_THREAD_LENGTH = '1.5P';
            ThreadChecker.Inputs.MAX_VISIBLE_THREAD_LENGTH_TORQUE = '0.4D';

            % WHEN, THEN
            ThreadChecker.check_visible_thread_fixed_side(tighteningSide, 0.012);
            expectedUtilization = 0.75;
            Obj.assertEqual(ThreadChecker.VisibleThreadFixedSide.utilization, expectedUtilization, 'AbsTol', 1e-5);
        end

        function check_visible_thread_fixed_side__stud_tension(Obj)
            % GIVEN a mimicked FlangeModel data structure with data to compute the visible thread length on
            % the fixed side of a stud
            tighteningSide = "upper";
            ThreadChecker = UsainUtils.ThreadLengthChecker();
            ThreadChecker.diameter = 0.072;
            ThreadChecker.pitch = 0.006;
            ThreadChecker.fastenerType = 'stud';
            ThreadChecker.tighteningMethod = 'tension';
            ThreadChecker.Inputs.MIN_VISIBLE_THREAD_LENGTH = '2P';
            ThreadChecker.Inputs.MAX_VISIBLE_THREAD_LENGTH_TENSION = '1.1D';

            % WHEN, THEN
            ThreadChecker.check_visible_thread_fixed_side(tighteningSide, 0.080);
            expectedUtilization = 1.0;
            Obj.assertEqual(ThreadChecker.VisibleThreadFixedSide.utilization, expectedUtilization);
        end

        function check_visible_thread_fixed_side__zero_for_hex_bolt(Obj)
            % GIVEN a mimicked FlangeModel data structure with data to compute the visible thread length on
            % the fixed side of a hex-bolt (which is always zero)
            tighteningSide = "upper";
            ThreadChecker = UsainTest.ThreadLengthChecker_Test.setup_with_m72_and_thread_length_expression_inputs();
            ThreadChecker.fastenerType = 'hex';
            ThreadChecker.tighteningMethod = 'torque';

            % WHEN, THEN
            ThreadChecker.check_visible_thread_fixed_side(tighteningSide, 0.0792);
            expectedUtilization = 0.0;
            Obj.assertEqual(ThreadChecker.VisibleThreadFixedSide.utilization, expectedUtilization);
        end

        function check_gripped_thread_free_side__expected(Obj, tighteningMethod, fastenerType)
            % GIVEN a mimicked FlangeModel data structure with data to compute the gripped thread length on
            % the free side of a fastener
            tighteningSide = "upper";
            ThreadChecker = UsainTest.ThreadLengthChecker_Test.setup_with_m72_and_thread_length_expression_inputs();
            ThreadChecker.fastenerType = fastenerType;  % result is independent of fastener type
            ThreadChecker.tighteningMethod = tighteningMethod;  % result is independent of tightening method

            % WHEN, THEN
            ThreadChecker.check_gripped_thread_free_side(tighteningSide, 0.060);
            expectedUtilization = 0.4;
            Obj.assertEqual(ThreadChecker.GrippedThreadFreeSide.utilization, expectedUtilization);
        end

        function check_visible_thread_free_side__torque(Obj)
            % GIVEN a mimicked FlangeModel data structure with data to compute the visible thread length on
            % the free side of a torqued fastener
            tighteningSide = "upper";
            ThreadChecker = UsainTest.ThreadLengthChecker_Test.setup_with_m72_and_thread_length_expression_inputs();
            ThreadChecker.fastenerType = 'hex';
            ThreadChecker.tighteningMethod = 'torque';

            % WHEN the thread length is too short
            % THEN
            ThreadChecker.check_visible_thread_free_side(tighteningSide, 0.003);
            expectedUtilization = 6.0;
            Obj.assertEqual(ThreadChecker.VisibleThreadFreeSide.utilization, expectedUtilization, 'AbsTol', 1e-5);

            % WHEN the thread length is too long
            % THEN
            ThreadChecker.check_visible_thread_free_side(tighteningSide, 0.030);
            expectedUtilization = 1.04167;
            Obj.assertEqual(ThreadChecker.VisibleThreadFreeSide.utilization, expectedUtilization, 'AbsTol', 1e-5);
        end

        function check_visible_thread_free_side__tension(Obj, fastenerType)
            % GIVEN a mimicked FlangeModel data structure with data to compute the visible thread length on
            % the free side of a tensioned fastener
            tighteningSide = "upper";
            ThreadChecker = UsainTest.ThreadLengthChecker_Test.setup_with_m72_and_thread_length_expression_inputs();
            ThreadChecker.fastenerType = fastenerType;  % result is independent of fastener type
            ThreadChecker.tighteningMethod = 'tension';

            % WHEN we check with 3mm
            % THEN we expect an over-utilization of 6 (utilization of 1 would be 3*P = 18mm)
            ThreadChecker.check_visible_thread_free_side(tighteningSide, 0.003);
            Obj.assertEqual(ThreadChecker.VisibleThreadFreeSide.utilization, 6, 'AbsTol', 1e-5);
        end

        function from_flange_model__happy_case(Obj)
            % GIVEN a fake UsainUtils.FlangeModel instance with dummy data
            fixture = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture);
            FlangeModel.Inputs = fixture.data;
            FlangeModel.Tool.tighteningMethod = {'torque', 'tension'};
            FlangeModel.Bolt.diam = [0.042, 0.042];
            FlangeModel.Bolt.pitch = [0.0045, 0.0045];
            FlangeModel.Bolt.type = {'hex', 'stud'};

            % WHEN we select data for the second bolt option
            % THEN
            Test = UsainUtils.ThreadLengthChecker.from_flange_model(FlangeModel, 2);
            Obj.assertEqual(Test.tighteningMethod, 'tension');
            Obj.assertEqual(Test.diameter, 0.042);
            Obj.assertEqual(Test.pitch, 0.0045);
            Obj.assertEqual(Test.fastenerType, 'stud');
            Obj.assertNotEmpty(Test.Inputs);

            % WHEN we do not define a bolt option index
            % THEN the first index is expected to be used
            Test = UsainUtils.ThreadLengthChecker.from_flange_model(FlangeModel);
            Obj.assertEqual(Test.tighteningMethod, 'torque');
            Obj.assertEqual(Test.fastenerType, 'hex');
        end

    end

    methods (Static)

        function data = setup_flange_model_data()
            % Returns data (struct) that mimicks a UsainUtils.FlangeModel instance with just the data needed
            % to construct a UsainUtils.ThreadLengthModel instance
            % This method can be used to generate a test data fixture (and hence promotes re-use)

            % Build on flange model test data from ThreadLengthModel test case
            data = UsainTest.ThreadLengthModel_Test.setup_flange_model_data();
            data.Inputs.MIN_GRIPPED_THREAD_LENGTH = '4P';
            data.Inputs.MIN_VISIBLE_THREAD_LENGTH = '3P';
            data.Inputs.MAX_VISIBLE_THREAD_LENGTH_TENSION = '1.1D';
            data.Inputs.MAX_VISIBLE_THREAD_LENGTH_TORQUE = '0.4D';
        end

        function Test = setup_with_m72_and_thread_length_expression_inputs()
            % Construct ThreadLengthChecker instance with data for M72 fastener and the default thread length
            % expression inputs
            %
            % Test: UsainUtils.ThreadLengthChecker test instance

            Test = UsainUtils.ThreadLengthChecker();
            Test.diameter = 0.072;
            Test.pitch = 0.006;
            Inputs.MIN_GRIPPED_THREAD_LENGTH = '4P';
            Inputs.MIN_VISIBLE_THREAD_LENGTH = '3P';
            Inputs.MAX_VISIBLE_THREAD_LENGTH_TENSION = '1.1D';
            Inputs.MAX_VISIBLE_THREAD_LENGTH_TORQUE = '0.4D';
            Test.Inputs = Inputs;
        end

    end
end
