classdef SelectBestDesignStep_Test < Unittest.TestCase
    methods (Test, TestTags = {'unit'})

        function is_active__true(Obj)

            % GIVEN
            Step = usain.model.SelectBestDesignStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.ConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.FlangeModel, UsainUtils.FlangeModel());
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN, THEN
            Obj.assertTrue(Step.is_active());
        end

        function is_active__false(Obj)

            % GIVEN
            Step = usain.model.SelectBestDesignStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.ConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.FlangeModel, UsainUtils.FlangeModel());
            Runner.set(usain.DataKeys.hasFeasibleDesign, true);

            % WHEN, THEN
            Obj.assertFalse(Step.is_active());
        end

    end

    methods (Test, TestTags = {'integration'})

        function run__no_conditions_assessed(Obj)
            % TODO: Implement this test after FlangeModel is removed from USAIN framework (WPSSD-5639)
        end

        function run__happy(Obj)
            % TODO: Implement this test after FlangeModel is removed from USAIN framework (WPSSD-5639)
        end

    end
end
