classdef ThreadRequirements_Test < Unittest.TestCase & matlab.mock.TestCase

    properties (TestParameter)
        % Test parameters to repeat tests that are independent of tightening method and/or fastener type
        tighteningMethod = {'torque', 'tension'}
        fastenerType = {'stud', 'hex'}
    end

    methods (Test, TestTags = {'unit'})

        function calc_penalty__expected(Obj)
            % GIVEN a mock UsainUtils.ThreadRequirements object whose do_assess() method calls always return
            % TRUE
            [Stub, Behavior] = Obj.createMock(?UsainUtils.ThreadRequirements);
            Obj.assignOutputsWhen(withExactInputs(Behavior.do_assess()), true);

            % WHEN we calculate the penalty function for 2 design points (one infeasible, one feasible)
            Stub.utilRatio = [0.5; 1.5];
            actual = Stub.calc_penalty();

            % THEN
            expected = [0; 1];
            Obj.assertEqual(actual, expected);
        end

        function do_assess__selected_model_and_activated_input(Obj)
            % GIVEN
            Test = UsainUtils.ThreadRequirements();

            % WHEN the condition is enabled through inputs, for a "selected" best design
            % THEN we expect do_assess to return TRUE
            Test.Mdl = UsainUtils.SelectedModel();
            Test.Mdl.Inputs.DO_ASSESS_BOLT_THREAD_REQ = true;
            actual = Test.do_assess();
            Obj.assertTrue(actual);
        end

        function do_assess__selected_model_and_deactivated_input(Obj)
            % GIVEN
            Test = UsainUtils.ThreadRequirements();

            % WHEN the condition is disabled through inputs
            % THEN we expect do_assess to return FALSE
            Test.Mdl = UsainUtils.SelectedModel();
            Test.Mdl.Inputs.DO_ASSESS_BOLT_THREAD_REQ = false;
            actual = Test.do_assess();
            Obj.assertFalse(actual);
        end

        function do_assess__no_selected_model_and_activated_input(Obj)
            % GIVEN
            Test = UsainUtils.ThreadRequirements();

            % WHEN the condition is enabled, but the flange model is not for a "selected" best design
            % THEN we expect do_assess to return FALSE
            Test.Mdl = UsainUtils.FlangeModel();
            Test.Mdl.Inputs.DO_ASSESS_BOLT_THREAD_REQ = true;
            actual = Test.do_assess();
            Obj.assertFalse(actual);
        end

        function assign_visible_and_gripped_thread_lengths_to_flange_side__happy(Obj)
            % GIVEN ThreadRequirement dummy lengths and indicating the `fixed side` to be assigned to upper flange and
            % therefore the `free side` to the lower flange
            ThreadReqs = UsainUtils.ThreadRequirements();
            ThreadReqs.GrippedThreadFixedSide = UsainUtils.ThreadLengthData("upper", 10);
            ThreadReqs.VisibleThreadFixedSide = UsainUtils.ThreadLengthData("upper", 20);
            ThreadReqs.GrippedThreadFreeSide = UsainUtils.ThreadLengthData("lower", 30);
            ThreadReqs.VisibleThreadFreeSide = UsainUtils.ThreadLengthData("lower", 40);

            % WHEN
            ThreadReqs.assign_visible_and_gripped_thread_lengths_to_flange_side();

            % THEN verify the lengths are assigned to the flange side
            Obj.verifyEqual(ThreadReqs.grippedThreadUpperFlange, 10);
            Obj.verifyEqual(ThreadReqs.visibleThreadUpperFlange, 20);
            Obj.verifyEqual(ThreadReqs.grippedThreadLowerFlange, 30);
            Obj.verifyEqual(ThreadReqs.visibleThreadLowerFlange, 40);
        end

        function report_results__happy(Obj)
            % GIVEN ThreadRequirement dummy data
            ThreadReqs = UsainUtils.ThreadRequirements( ...
                'visibleThreadUpperFlange', 0.123, ...
                'grippedThreadUpperFlange', 0.456, ...
                'visibleThreadLowerFlange', 0.789, ...
                'grippedThreadLowerFlange', 0.321);
            ThreadReqs.Mdl.Inputs.TIGHTENING_SIDE_INSTALLATION = {'upper'};

            % WHEN THEN
            ThreadReqs.Logger.level = logging.Level.WARNING;  % prevents logging to stream
            actual = ThreadReqs.report_results();
            expected = { ...
                'Tightening side for installation   |     upper'
                'Visible thread length, upper       |     123.0 mm'
                'Gripped thread length, upper       |     456.0 mm'
                'Visible thread length, lower       |     789.0 mm'
                'Gripped thread length, lower       |     321.0 mm'
                };

            Obj.assertEqual(actual, expected);
        end

    end

    methods (Test, TestTags = {'integration'})

        function evaluate_condition__happy_case(Obj)
            % GIVEN a mimicked UsainUtils.FlangeModel instance with dummy data for a single design point
            Test = UsainUtils.ThreadRequirements();
            Test.Mdl = UsainTest.ThreadRequirements_Test.setup_flange_model_data();

            % WHEN
            Test.evaluate_condition();

            % THEN
            Obj.verifyEqual(Test.utilRatio, 1.6364, 'AbsTol', 1e-4);
            Obj.verifyEqual(Test.targetUtilRatio, 1.0);
            Obj.verifyEqual(Test.GrippedThreadFixedSide.utilization, 1.6364, 'AbsTol', 1e-4);
            Obj.verifyEqual(Test.VisibleThreadFixedSide.utilization, 1.0);
            Obj.verifyEqual(Test.GrippedThreadFreeSide.utilization, 1.0451, 'AbsTol', 1e-4);
            Obj.verifyEqual(Test.VisibleThreadFreeSide.utilization, 0.1536, 'AbsTol', 1e-4);
            Obj.verifyEqual(Test.grippedThreadUpperFlange, Test.GrippedThreadFixedSide.len);
            Obj.verifyEqual(Test.visibleThreadUpperFlange, Test.VisibleThreadFixedSide.len);
            Obj.verifyEqual(Test.grippedThreadLowerFlange, Test.GrippedThreadFreeSide.len);
            Obj.verifyEqual(Test.visibleThreadLowerFlange, Test.VisibleThreadFreeSide.len);

            % NEXT WHEN changing Inputs.TIGHTENING_SIDE_INSTALLATION
            Test.Mdl.Inputs.TIGHTENING_SIDE_INSTALLATION = "lower";
            Test.evaluate_condition();

            % THEN expect that upper flange now reflects the "free side" and lower flange the "fixed side"
            Obj.verifyEqual(Test.utilRatio, 1.6364, 'AbsTol', 1e-4);
            Obj.verifyEqual(Test.grippedThreadUpperFlange, Test.GrippedThreadFreeSide.len);
            Obj.verifyEqual(Test.visibleThreadUpperFlange, Test.VisibleThreadFreeSide.len);
            Obj.verifyEqual(Test.grippedThreadLowerFlange, Test.GrippedThreadFixedSide.len);
            Obj.verifyEqual(Test.visibleThreadLowerFlange, Test.VisibleThreadFixedSide.len);
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
            % Construct ThreadRequirements instance with data for M72 fastener and the default thread length
            % expression inputs
            %
            % Test: UsainUtils.ThreadRequirements test instance

            Test = UsainUtils.ThreadRequirements();
            Test.Mdl.Bolt.diam = 0.072;
            Test.Mdl.Bolt.pitch = 0.006;
            Test.Mdl.Inputs.MIN_GRIPPED_THREAD_LENGTH = '4P';
            Test.Mdl.Inputs.MIN_VISIBLE_THREAD_LENGTH = '3P';
            Test.Mdl.Inputs.MAX_VISIBLE_THREAD_LENGTH_TENSION = '1.1D';
            Test.Mdl.Inputs.MAX_VISIBLE_THREAD_LENGTH_TORQUE = '0.4D';
        end

    end
end
