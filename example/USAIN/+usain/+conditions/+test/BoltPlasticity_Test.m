classdef BoltPlasticity_Test < UsainTest.UsainTestCase & matlab.mock.TestCase

    methods (Test, TestTags = {'unit'})

        function verify_feasibility__warning_for_infeasible_design(Obj)
            % GIVEN a utilization ratio of 1.01 (max 1.00 is allowed by default)
            Condition = usain.conditions.BoltPlasticity(1, 1);
            Condition.utilRatio = 1.01;

            % WHEN, THEN
            Obj.verify_warning_logged( ...
                @() Condition.verify_feasibility(), ...
                'USAIN:BoltPlasticity:InfeasibleDesign');

            % WHEN the utilization ratio is decreased to 0.91, and the target to 0.90
            Condition.utilRatio = 0.91;
            Condition.targetUtilRatio = 0.90;

            % THEN expect the same
            Obj.verify_warning_logged( ...
                @() Condition.verify_feasibility(), ...
                'USAIN:BoltPlasticity:InfeasibleDesign');
        end

        function verify_feasibility__no_warning_for_feasible_design(Obj)
            % GIVEN a utilization ratio of < 1.00 (max 1.00 is allowed by default)
            Condition = usain.conditions.BoltPlasticity(1, 1);
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
            % GIVEN a BoltPlasticity condition that:
            % - always returns a bolt force of 1234 N
            [Condition, ConditionBehavior] = Obj.createMock(?usain.conditions.BoltPlasticity, ...
                'ConstructorInputs', {1, 1});
            Obj.assignOutputsWhen(withAnyInputs(ConditionBehavior.calc_max_fls_bolt_force()), 1234);

            % ... and a FlangeModel that:
            % - contains a SegmentModel that always returns a segment force of 1234 N
            % - contains some dummy fastener data
            [SegmentModelStub, SegmentModelBehavior] = Obj.createMock(?UsainUtils.SegmentModel);
            Obj.assignOutputsWhen(withAnyInputs(SegmentModelBehavior.calc_segment_force()), 1234);
            FlangeModel = UsainUtils.FlangeModel();
            FlangeModel.Segment = SegmentModelStub;
            FlangeModel.Bolt.areaStress = 3463;
            FlangeModel.Bolt.yieldStrengthNominal = 900;
            FlangeModel.Loads.maxFlsMxy = 12;
            FlangeModel.Inputs.MACRO_GEOMETRIC_SCF = 1.1;
            Condition.Mdl = FlangeModel;

            % WHEN, THEN
            Condition.evaluate_condition();
            Obj.verifyEqual(Condition.utilRatio, 4.6580e-04, 'AbsTol', 1e-6);

            % WHEN changing the target utilization ratio such that the design becomes infeasible
            Condition.targetUtilRatio = 1e-6;
            Obj.verify_warning_logged( ...
                @() Condition.evaluate_condition(), ...
                'USAIN:BoltPlasticity:InfeasibleDesign');
        end

    end

end
