classdef ClearConditionCollectionStep_Test < Unittest.TestCase
    methods (Test, TestTags = {'integration'})

        function run__happy(Obj)
            % GIVEN: a runner with a ClearConditionCollectionStep and a non-empty ConditionCollection and
            % SelectedConditionCollection
            Runner = runner.SequentialRunner().add(usain.conditions.ClearConditionCollectionStep());
            Collection = usain.conditions.ConditionCollection();
            Collection.ConditionArray = { ...
                usain.conditions.test.NoopCondition(), ...
                usain.conditions.test.NoopCondition()};
            Runner.set(usain.DataKeys.ConditionCollection, Collection);

            SelectedCollection = usain.conditions.ConditionCollection();
            SelectedCollection.ConditionArray = {usain.conditions.test.NoopCondition()};
            Runner.set(usain.DataKeys.SelectedConditionCollection, SelectedCollection);

            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN
            Runner.run();

            % THEN
            ActualConditionCollection = Runner.get(usain.DataKeys.ConditionCollection);
            Obj.verifyEmpty(ActualConditionCollection.ConditionArray);

            ActualSelectedConditionCollection = Runner.get(usain.DataKeys.SelectedConditionCollection);
            Obj.verifyEmpty(ActualSelectedConditionCollection.ConditionArray);
        end

    end

    methods (Test, TestTags = {'unit'})

        function is_active__true(Obj)

            % GIVEN
            Step = usain.conditions.ClearConditionCollectionStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.ConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN, THEN
            Obj.assertTrue(Step.is_active());
        end

        function is_active__false(Obj)

            % GIVEN
            Step = usain.conditions.ClearConditionCollectionStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.ConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.hasFeasibleDesign, true);

            % WHEN, THEN
            Obj.assertFalse(Step.is_active());
        end

    end
end
