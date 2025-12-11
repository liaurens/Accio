classdef DetermineFeasibleDesignStep_Test < Unittest.TestCase

    methods (Test, TestTags = {'integration'})

        function run__has_feasible_design__happy(Obj)
            % GIVEN a selected model which has all util rations < 1
            Runner = runner.SequentialRunner().add(usain.model.DetermineFeasibleDesignStep());

            % NOTE: We need a `FlangeModel` dummy because of getter `UsainUtils.ICondition.do_assess` is always called.
            FlangeModel.Inputs.DO_ASSESS_NOOP_CONDITION = true;

            SelectedConditionCollection = usain.conditions.ConditionCollection();

            Condition1 = usain.conditions.test.NoopCondition();
            Condition1.Mdl = FlangeModel;
            Condition1.utilRatio = [0.1];
            SelectedConditionCollection = SelectedConditionCollection.append(Condition1);

            Condition2 = usain.conditions.test.NoopCondition();
            Condition2.Mdl = FlangeModel;
            Condition2.utilRatio = [0.9];
            SelectedConditionCollection = SelectedConditionCollection.append(Condition2);

            Runner.set(usain.DataKeys.SelectedConditionCollection, SelectedConditionCollection);
            Inputs.DO_ALLOW_SWITCH_L_TO_T = false;
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % WHEN, THEN
            Runner.run();

            % THEN
            Obj.verifyTrue(Runner.get(usain.DataKeys.hasFeasibleDesign));
        end

        function run__has_infeasible_design__happy(Obj)
            % GIVEN a selected model which has one util rations > 1
            Runner = runner.SequentialRunner().add(usain.model.DetermineFeasibleDesignStep());

            % NOTE: We need a `FlangeModel` dummy because of getter `UsainUtils.ICondition.do_assess` is always called.
            FlangeModel.Inputs.DO_ASSESS_NOOP_CONDITION = true;

            SelectedConditionCollection = usain.conditions.ConditionCollection();

            Condition1 = usain.conditions.test.NoopCondition();
            Condition1.Mdl = FlangeModel;
            Condition1.utilRatio = [0.11];
            SelectedConditionCollection = SelectedConditionCollection.append(Condition1);

            Condition2 = usain.conditions.test.NoopCondition();
            Condition2.Mdl = FlangeModel;
            Condition2.utilRatio = [1.2];
            SelectedConditionCollection = SelectedConditionCollection.append(Condition2);

            Runner.set(usain.DataKeys.SelectedConditionCollection, SelectedConditionCollection);
            Inputs.DO_ALLOW_SWITCH_L_TO_T = false;
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % WHEN, THEN
            Runner.run();

            % THEN
            Obj.verifyFalse(Runner.get(usain.DataKeys.hasFeasibleDesign));
        end

    end
end
