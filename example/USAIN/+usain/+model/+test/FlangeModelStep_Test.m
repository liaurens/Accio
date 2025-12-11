classdef (SharedTestFixtures = {Unittest.fixtures.SilentlyLogWarningsFixture}) ...
        FlangeModelStep_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function is_active__true(Obj)

            % GIVEN
            Step = usain.model.FlangeModelStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.Inputs, struct());
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN, THEN
            Obj.assertTrue(Step.is_active());
        end

        function is_active__false(Obj)

            % GIVEN
            Step = usain.model.FlangeModelStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.Inputs, struct());
            Runner.set(usain.DataKeys.hasFeasibleDesign, true);

            % WHEN, THEN
            Obj.assertFalse(Step.is_active());
        end

        function do_setup_loads__do_setup(Obj)
            % GIVEN
            doSetupLoads = true;
            Step = usain.model.FlangeModelStep(doSetupLoads);

            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;

            % We dont want to actually load the Loads in this test, because that would take time...
            Inputs.DO_ASSESS_FLS = false;
            Inputs.DO_ASSESS_ULS = false;

            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.Inputs, Inputs);
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN
            Runner.run();

            % THEN
            actual = Runner.get(usain.DataKeys.FlangeModel);
            Obj.assertTrue(actual.doSetupLoads);
        end

        function do_setup_loads__do_not_setup(Obj)
            % GIVEN
            doSetupLoads = false;
            Step = usain.model.FlangeModelStep(doSetupLoads);

            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;

            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.Inputs, Inputs);
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN
            Runner.run();

            % THEN
            actual = Runner.get(usain.DataKeys.FlangeModel);
            Obj.assertFalse(actual.doSetupLoads);
        end

    end

end
