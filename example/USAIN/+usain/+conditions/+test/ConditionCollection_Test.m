classdef ConditionCollection_Test < UsainTest.UsainTestCase

    methods (Test, TestTags = {'unit'})

        function append__returns_new_object(Obj)
            % GIVEN
            Collection = usain.conditions.ConditionCollection();

            % WHEN
            New = Collection.append(usain.conditions.test.NoopCondition());

            % THEN
            Obj.verifyNotEqual(Collection, New);
            Obj.verifyEqual(New, New);  % to check if the verification above makes sense
        end

        function append__condition_array(Obj)
            % GIVEN
            Collection = usain.conditions.ConditionCollection();

            % WHEN appending an array of conditions
            % THEN
            ConditionArray = [usain.conditions.test.NoopCondition(), usain.conditions.test.NoopCondition()];
            Obj.assertRaisesMessageRegex( ...
                @() Collection.append(ConditionArray), ...
                'Appending must be done with scalar UsainUtils.ICondition objects.');
        end

        function append__wrong_class(Obj)
            % GIVEN
            Collection = usain.conditions.ConditionCollection();

            % WHEN appending something that is not a UsainUtils.ICondition
            % THEN
            Obj.assertRaisesMessageRegex( ...
                @() Collection.append(123), ...
                'Appending must be done with scalar UsainUtils.ICondition objects.');
        end

        function get_assessed_conditions__all_assessed(Obj)
            % GIVEN a collection with 2 conditions, both assessed
            FlangeModel.Inputs.DO_ASSESS_NOOP_CONDITION = true;
            Collection = usain.conditions.ConditionCollection();
            Collection.ConditionArray = { ...
                usain.conditions.test.NoopCondition(Mdl = FlangeModel), ...
                usain.conditions.test.NoopCondition(Mdl = FlangeModel)};

            % WHEN, THEN
            Obj.verifyEqual(Collection.get_assessed_conditions(), Collection.ConditionArray);
        end

        function get_assessed_conditions__not_all_assessed(Obj)
            % GIVEN a collection with 2 conditions, only 1 assessed
            FlangeModelA.Inputs.DO_ASSESS_NOOP_CONDITION = true;
            FlangeModelB.Inputs.DO_ASSESS_NOOP_CONDITION = false;
            Collection = usain.conditions.ConditionCollection();
            Collection.ConditionArray = { ...
                usain.conditions.test.NoopCondition(Mdl = FlangeModelA), ...
                usain.conditions.test.NoopCondition(Mdl = FlangeModelB)};

            % WHEN, THEN
            Obj.verifyEqual(Collection.get_assessed_conditions(), Collection.ConditionArray(1));

            % WHEN all conditions are not assessed
            Collection.ConditionArray = { ...
                usain.conditions.test.NoopCondition(Mdl = FlangeModelB), ...
                usain.conditions.test.NoopCondition(Mdl = FlangeModelB)};

            % THEN
            Obj.verifyEmpty(Collection.get_assessed_conditions());
        end

        function get_condition_from_classname__expected(Obj)
            % GIVEN
            Expected = usain.conditions.FlangePlasticity();
            Collection = usain.conditions.ConditionCollection();
            Collection.ConditionArray = { ...
                usain.conditions.test.NoopCondition(), ...
                Expected, ...
                usain.conditions.test.NoopCondition()};

            % WHEN
            Actual = Collection.get_condition_from_classname('usain.conditions.FlangePlasticity');

            % THEN
            Obj.verifyEqual(Actual, Expected);

            % WHEN getting the NoopConditions
            % THEN expect both to be returned
            Actual = Collection.get_condition_from_classname('usain.conditions.test.NoopCondition');
            Obj.verifyLength(Actual, 2);
        end

        function calc_total_penalty__happy(Obj)
            % GIVEN 2 conditions with utilization ratios < 1
            Collection = usain.conditions.ConditionCollection();

            Condition1 = usain.conditions.test.NoopCondition();
            Condition1.utilRatio = [0.1; 0.11] * ones(1, 2);
            Condition1.Mdl.Inputs.DO_ASSESS_NOOP_CONDITION = true;
            Collection = Collection.append(Condition1);

            Condition2 = usain.conditions.test.NoopCondition();
            Condition2.utilRatio = [0.2; 0.22] * ones(1, 2);
            Condition2.Mdl.Inputs.DO_ASSESS_NOOP_CONDITION = true;
            Collection = Collection.append(Condition2);

            % WHEN calculating the total penalty
            % THEN expect 0 because both conditions are feasible (utilRatio < 1.0)
            Obj.verifyEqual(Collection.calc_total_penalty(), [0; 0]);

            % WHEN having infeasible condition(s) (utilRatio > 1.0)
            % THEN expect a nonzero penalty
            Condition2.utilRatio = [2; 2.1] * ones(1, 2);
            Obj.verifyEqual(Collection.calc_total_penalty(), [3; 3.41], 'AbsTol', 1e-6);
        end

        function is_feasible_for_all_conditions__happy(Obj)
            % GIVEN 2 conditions with utilization ratios < 1
            FlangeModel.Inputs.DO_ASSESS_NOOP_CONDITION = true;
            % NOTE: We need a `FlangeModel` dummy because of getter `UsainUtils.ICondition.do_assess` is always called.
            Collection = usain.conditions.ConditionCollection();

            Condition1 = usain.conditions.test.NoopCondition();
            Condition1.Mdl = FlangeModel;
            Condition1.utilRatio = [0.1; 0.11];
            Collection = Collection.append(Condition1);

            Condition2 = usain.conditions.test.NoopCondition();
            Condition2.Mdl = FlangeModel;
            Condition2.utilRatio = [0.2; 0.22];
            Collection = Collection.append(Condition2);

            % WHEN, THEN
            Obj.verifyEqual(Collection.is_feasible_for_all_conditions(), [true; true]);

            % WHEN one condition gets one infeasible design point
            % THEN
            Condition2.utilRatio = [2; 1];
            Obj.verifyEqual(Collection.is_feasible_for_all_conditions(), [false; true]);
        end

        function iter_conditions__happy(Obj)
            % GIVEN a ConditionCollection with some conditions
            Collection = usain.conditions.ConditionCollection();
            Collection = Collection.append(usain.conditions.test.NoopCondition(utilRatio = 1.2));
            Collection = Collection.append(usain.conditions.test.NoopCondition(utilRatio = 2.4));

            % WHEN calling `iter_conditions` without actually iterating
            % THEN
            Actual = Collection.iter_conditions();
            Obj.verifySize(Actual, [1, 2]);
            Obj.verifyClass(Actual, 'usain.conditions.test.NoopCondition');
            Obj.verifyEqual(Actual(1).utilRatio, 1.2);
            Obj.verifyEqual(Actual(2).utilRatio, 2.4);

            % WHEN calling `iter_conditions` with a for-loop
            % THEN
            iIter = 1;
            for Actual = Collection.iter_conditions()
                Obj.verifySize(Actual, [1, 1]);
                Obj.verifyClass(Actual, 'usain.conditions.test.NoopCondition');
                Obj.verifyEqual(Actual.utilRatio, 1.2 * iIter);  % expect 1.2 for 1st, 2.4 for 2nd
                iIter = iIter + 1;
            end
        end

    end
end
