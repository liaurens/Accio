classdef SlsPretensionLoss_Test < UsainTest.UsainTestCase

    properties
        TestObj UsainUtils.SlsPretensionLoss
    end

    methods (TestMethodSetup)

        function init_test_object(Obj)
            Obj.TestObj = UsainUtils.SlsPretensionLoss();
            Obj.TestObj.preload = 1680e3;

            Obj.set_design_rules_example_input_data();
        end

    end

    methods (Test, TestTags = {'unit'})

        function do_assess__l_flange(Obj)
            % GIVEN
            Condition = UsainUtils.SlsPretensionLoss();

            % WHEN the inputs enable the condition and describe an L-flange
            % THEN expect do_assess to return TRUE
            Condition.Mdl.Inputs.DO_ASSESS_SLS_PRETENSION = true;
            Condition.Mdl.Inputs.flangeType = 'L';
            Obj.verifyTrue(Condition.do_assess());

            % WHEN the inputs disable the condition and describe an L-flange
            % THEN expect do_assess to return FALSE
            Condition.Mdl.Inputs.DO_ASSESS_SLS_PRETENSION = false;
            Condition.Mdl.Inputs.flangeType = 'L';
            Obj.verifyFalse(Condition.do_assess());
        end

        function do_assess__t_flange(Obj)
            % GIVEN
            Condition = UsainUtils.SlsPretensionLoss();

            % WHEN the inputs enable the condition and describe an T-flange
            % THEN expect do_assess to return FALSE
            Condition.Mdl.Inputs.DO_ASSESS_SLS_PRETENSION = true;
            Condition.Mdl.Inputs.flangeType = 'T';
            Obj.verifyFalse(Condition.do_assess());

            % WHEN the inputs disable the condition and describe an T-flange
            % THEN expect do_assess to return FALSE
            Condition.Mdl.Inputs.DO_ASSESS_SLS_PRETENSION = false;
            Condition.Mdl.Inputs.flangeType = 'T';
            Obj.verifyFalse(Condition.do_assess());
        end

        function calc_force_application_distance__benchmark(Obj)
            % Compare results from calc_force_application_distance with design
            % rules calculation example inputs to benchmark values

            testValue = Obj.TestObj.calc_force_application_distance();
            expValue = 44.17e-3;
            Obj.verify_equal_to_benchmark(testValue, expValue, 'RelTol', 1e-4);
        end

        function calc_section_loads_at_edge_shear__benchmark(Obj)
            % Compare results from calc_section_loads_at_edge with design
            % rules calculation example inputs to benchmark values

            fApplied = 450e3;
            xForce = 44.17e-3;

            [testValue, ~] = Obj.TestObj.calc_section_loads_at_edge(fApplied, xForce);
            expValue = -30e3;
            Obj.verify_equal_to_benchmark(testValue, expValue, 'RelTol', 1e-4);
        end

        function calc_section_loads_at_edge_moment__benchmark(Obj)
            % Compare results from calc_section_loads_at_edge with design
            % rules calculation example inputs to benchmark values

            fApplied = 450e3;
            xForce   = 44.17e-3;

            [~, testValue] = Obj.TestObj.calc_section_loads_at_edge(fApplied, xForce);
            expValue = 32.15e3;
            Obj.verify_equal_to_benchmark(testValue, expValue, 'RelTol', 1e-4);
        end

        function calc_longitudinal_stress__benchmark(Obj)
            % Compare results from calc_longitudinal_stress with design
            % rules calculation example inputs to benchmark values

            testValue = Obj.TestObj.calc_longitudinal_stress();
            expValue = -89.9e6;
            Obj.verify_equal_to_benchmark(testValue, expValue, 'RelTol', 1e-3);
        end

        function calc_lateral_stress_max__benchmark(Obj)
            % Compare results from calc_lateral_stress with design
            % rules calculation example inputs to benchmark values

            shearInt  = -30e3;
            momentInt = 32.15e3;

            sigmaX = Obj.TestObj.calc_lateral_stress(shearInt, momentInt);
            testValue = max(sigmaX);
            expValue = 166.5e6;
            Obj.verify_equal_to_benchmark(testValue, expValue, 'RelTol', 1e-3);
        end

        function set_utilRatioGeom__benchmark(Obj)
            % Compare results from set.utilRatioGeom with design
            % rules calculation example inputs to benchmark values

            Obj.TestObj.Mdl.Inputs.DO_ASSESS_SLS_PRETENSION = true;
            Obj.TestObj.Mdl.Inputs.flangeType = 'L';
            testValue = Obj.TestObj.utilRatioGeom;
            expValue = 0.5469;
            Obj.verify_equal_to_benchmark(testValue, expValue, 'RelTol', 1e-4);
        end

        function verify_feasibility__warning_for_infeasible_design(Obj)
            % GIVEN a utilization ratio of 1.21 (we allow for max 1.20)
            Obj.TestObj.utilRatio = 1.21;

            % WHEN, THEN
            fTest = @() Obj.TestObj.verify_feasibility();
            Obj.verify_warning_logged(fTest, 'USAIN:SlsPretensionLoss:InfeasibleDesign');
        end

        function verify_feasibility__no_warning_for_feasible_design(Obj)
            % GIVEN a utilization ratio of < 1.20 (we allow for max 1.20)
            Obj.TestObj.utilRatio = 1.2 * rand(5, 2);

            % WHEN, THEN
            fTest = @() Obj.TestObj.verify_feasibility();
            Obj.verify_no_warning_logged(fTest);
        end

    end

    methods

        function set_design_rules_example_input_data(Obj)

            Obj.TestObj.Mdl = UsainUtils.FlangeModel();
            Obj.TestObj.Mdl.Segment.distBolt = 140e-3;
            Obj.TestObj.Mdl.Segment.distForce = 115e-3;

            Obj.TestObj.Mdl.Space.thickness = 120e-3;
            % TODO: Obj.TestObj.Mdl.Inputs.yieldStrengthChar = 250e6;

            Obj.TestObj.Mdl.Wash.diamOut = 115e-3;
            Obj.TestObj.Mdl.Wash.len = 10e-3;
            Obj.TestObj.Mdl.Nut.diam = 115e-3;
            Obj.TestObj.Mdl.Bolt.diam = 64e-3;
            Obj.TestObj.Mdl.Inputs.diamBoltHole = 70e-3;
            Obj.TestObj.Mdl.Tool.defaultPreload = 1680e3;
        end

        function verify_equal_to_benchmark(Obj, actual, expect, varargin)

            errStr = sprintf(['Unit test failure while using input values from Design Brief example!\n', ...
                '\t==> Please investigate the reason for failure.\n', ...
                '\t\tIf the calculations have changed, ', ...
                'please update the Design Brief and its example calculations.\n', ...
                '\t\tOtherwise, fix the code in USAIN in order for the test to pass again.']);

            Obj.verifyEqual(actual, expect, varargin{:}, errStr);
        end

    end
end
