classdef FlangeGapping_Test < UsainTest.UsainTestCase

    properties
        TestObj UsainUtils.FlangeGapping
    end

    methods (TestMethodSetup)

        function init_test_object(Obj)
            Obj.TestObj = UsainUtils.FlangeGapping();
            Obj.TestObj.preload = 1914e3;
        end

    end

    methods (Test, TestTags = {'unit'})

        function do_assess__l_flange(Obj)
            % GIVEN
            Condition = UsainUtils.FlangeGapping();

            % WHEN the inputs enable the condition and describe an L-flange
            % THEN expect do_assess to return TRUE
            Condition.Mdl.Inputs.DO_ASSESS_GAPPING = true;
            Condition.Mdl.Inputs.flangeType = 'L';
            Obj.verifyTrue(Condition.do_assess());

            % WHEN the inputs disable the condition and describe an L-flange
            % THEN expect do_assess to return FALSE
            Condition.Mdl.Inputs.DO_ASSESS_GAPPING = false;
            Condition.Mdl.Inputs.flangeType = 'L';
            Obj.verifyFalse(Condition.do_assess());
        end

        function do_assess__t_flange(Obj)
            % GIVEN
            Condition = UsainUtils.FlangeGapping();

            % WHEN the inputs enable the condition and describe an T-flange
            % THEN expect do_assess to return FALSE
            Condition.Mdl.Inputs.DO_ASSESS_GAPPING = true;
            Condition.Mdl.Inputs.flangeType = 'T';
            Obj.verifyFalse(Condition.do_assess());

            % WHEN the inputs disable the condition and describe an T-flange
            % THEN expect do_assess to return FALSE
            Condition.Mdl.Inputs.DO_ASSESS_GAPPING = false;
            Condition.Mdl.Inputs.flangeType = 'T';
            Obj.verifyFalse(Condition.do_assess());
        end

        function calc_opening_force__benchmark(Obj)

            % Setup test
            Obj.set_example_input_data();

            % Run test
            actual = Obj.TestObj.calc_opening_force();
            expect = 894703; % Benchmarked 2019-10-03

            % Verify output
            Obj.verifyEqual(actual, expect, 'RelTol', 1e-4);
        end

        function verify_feasibility__warning_for_infeasible_design(Obj)
            % Does verify_feasibility throw a warning when the utilization ratio
            % exceeds 1.0?

            Obj.TestObj.utilRatio = 1.01;
            fTest = @() Obj.TestObj.verify_feasibility();
            Obj.verify_warning_logged(fTest, 'USAIN:FlangeGapping:InfeasibleDesign');
        end

        function verify_feasibility__no_warning_for_feasible_design(Obj)
            % Does verify_feasibility throw no warning when the utilization
            % ratio is <= 1.0?

            Obj.TestObj.utilRatio = rand(5, 2);
            fTest = @() Obj.TestObj.verify_feasibility();
            Obj.verify_no_warning_logged(fTest);
        end

    end

    methods

        function set_example_input_data(Obj)

            Obj.TestObj.Mdl = UsainUtils.FlangeModel();

            % Segment model
            Obj.TestObj.Mdl.Segment.distRim    = 188.5e-3;
            Obj.TestObj.Mdl.Segment.distForce  = 128e-3;
            Obj.TestObj.Mdl.Segment.distBolt   = 156.25e-3;
            Obj.TestObj.Mdl.Segment.loadFactor = 0.06;
            Obj.TestObj.Mdl.Segment.resilBolt  = 2.5216e-10;
            Obj.TestObj.Mdl.Segment.ReactDist = UsainUtils.ReactionDistance( ...
                188.5e-3, 128e-3, 154e-3);

            % Design space variables
            Obj.TestObj.Mdl.Space.thickness = 154e-3;

            % Fastener properties
            Obj.TestObj.Mdl.Bolt.diam = 72e-3;
            Obj.TestObj.Mdl.Tool.defaultPreload = 1914e3;

            % Other properties
            Obj.TestObj.Mdl.Inputs.E_BOLT = 210e9;
        end

    end
end
