classdef FlangePlasticity_Test < UsainTest.UsainTestCase & matlab.mock.TestCase

    methods (Test, TestTags = {'unit'})

        function do_assess__l_flange(Obj)
            % GIVEN
            Condition = usain.conditions.FlangePlasticity();

            % WHEN the inputs enable the condition and describe an L-flange
            % THEN expect do_assess to return TRUE
            Condition.Mdl.Inputs.DO_ASSESS_FLANGE_PLASTICITY = true;
            Condition.Mdl.Inputs.flangeType = 'L';
            Obj.verifyTrue(Condition.do_assess());

            % WHEN the inputs disable the condition and describe an L-flange
            % THEN expect do_assess to return FALSE
            Condition.Mdl.Inputs.DO_ASSESS_FLANGE_PLASTICITY = false;
            Condition.Mdl.Inputs.flangeType = 'L';
            Obj.verifyFalse(Condition.do_assess());
        end

        function do_assess__t_flange(Obj)
            % GIVEN
            Condition = usain.conditions.FlangePlasticity();

            % WHEN the inputs enable the condition and describe an T-flange
            % THEN expect do_assess to return FALSE
            Condition.Mdl.Inputs.DO_ASSESS_FLANGE_PLASTICITY = true;
            Condition.Mdl.Inputs.flangeType = 'T';
            Obj.verifyFalse(Condition.do_assess());

            % WHEN the inputs disable the condition and describe an T-flange
            % THEN expect do_assess to return FALSE
            Condition.Mdl.Inputs.DO_ASSESS_FLANGE_PLASTICITY = false;
            Condition.Mdl.Inputs.flangeType = 'T';
            Obj.verifyFalse(Condition.do_assess());
        end

        function verify_feasibility__warning_for_infeasible_design(Obj)
            % GIVEN a utilization ratio of 1.01 while max 1.00 is allowed
            Condition = usain.conditions.FlangePlasticity();
            Condition.targetUtilRatio = 1.00;
            Condition.utilRatio = 1.01;

            % WHEN, THEN
            Obj.verify_warning_logged( ...
                @() Condition.verify_feasibility(), ...
                'USAIN:FlangePlasticity:InfeasibleDesign');

            % WHEN the utilization ratio is decreased to 0.91, and the target to 0.90
            Condition.targetUtilRatio = 0.90;
            Condition.utilRatio = 0.91;

            % THEN expect the same
            Obj.verify_warning_logged( ...
                @() Condition.verify_feasibility(), ...
                'USAIN:FlangePlasticity:InfeasibleDesign');
        end

        function verify_feasibility__no_warning_for_feasible_design(Obj)
            % GIVEN a utilization ratio of < 1.00 while max 1.00 is allowed
            Condition = usain.conditions.FlangePlasticity();
            Condition.targetUtilRatio = 1.00;
            Condition.utilRatio = [ ...
                0.1, 0.2
                0.3, 0.4
                0.5, 0.6
                0.7, 0.8];  % 2 load sets, 4 design points

            % WHEN, THEN
            Obj.verify_no_warning_logged(@() Condition.verify_feasibility());
        end

    end

    methods (Test, TestTags = {'integration'})

        function evaluate_condition__happy(Obj)
            % GIVEN a FlangePlasticity condition that:
            % - sets FM D to 1000 N
            [Condition, ConditionBehavior] = Obj.createMock(?usain.conditions.FlangePlasticity);
            Obj.assignOutputsWhen(withAnyInputs(ConditionBehavior.calc_failure_mode_d()), 1000);

            % ... and a FlangeModel that:
            % - contains a SegmentModel that always returns a segment force of 600 N
            % - contains some dummy fastener data
            [SegmentModelStub, SegmentModelBehavior] = Obj.createMock(?UsainUtils.SegmentModel);
            Obj.assignOutputsWhen(withAnyInputs(SegmentModelBehavior.calc_segment_force()), 660);
            FlangeModel = UsainUtils.FlangeModel();
            FlangeModel.Segment = SegmentModelStub;
            FlangeModel.Bolt.areaStress = 3463;
            FlangeModel.Bolt.yieldStrengthNominal = 940;
            FlangeModel.Loads.maxS1MomentDesign = 12;
            FlangeModel.Inputs.MAX_FAILURE_MODE_D_FLS_UTILIZATION = 2 / 3;
            Condition.Mdl = FlangeModel;

            % WHEN, THEN
            Condition.evaluate_condition();
            Obj.verifyEqual(Condition.utilRatio, 0.99, 'AbsTol', 1e-6);

            % WHEN changing the target utilization ratio such that the design becomes infeasible
            Condition.Mdl.Inputs.MAX_FAILURE_MODE_D_FLS_UTILIZATION = 0.6;
            Obj.verify_warning_logged( ...
                @() Condition.evaluate_condition(), ...
                'USAIN:FlangePlasticity:InfeasibleDesign');
        end

    end

end
