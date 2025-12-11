classdef BoltPlasticityStep_Test < UsainTest.UsainTestCase

    methods (Test, TestTags = {'integration'})

        function run__happy(~)
            % TODO: Implement this test after FlangeModel is removed from USAIN framework (WPSSD-5639)
        end

    end

    methods (Test, TestTags = {'unit'})

        function get_conditions__multiple_boltfls_blocks(Obj)
            % GIVEN a runner with a single step and inputs that define 3 BoltFls blocks (2 with sgre2), and 1 gap angle
            Step = usain.conditions.BoltPlasticityStep();
            Runner = runner.SequentialRunner().add(Step);

            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "sgre2";
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.BoltFls(3).BOLT_FORCE_MODEL = "sgre2";
            Inputs.SGRE2.GAP_ANGLE = 123;

            Runner.set(usain.DataKeys.Inputs, Inputs);

            % WHEN, THEN
            Actual = Step.get_conditions();
            Obj.assertSize(Actual, [1, 2]);
            Obj.assertClass(Actual, 'usain.conditions.BoltPlasticity');
            Obj.verifyEqual(Actual(1).iBoltFls, 1);
            Obj.verifyEqual(Actual(2).iBoltFls, 3);
        end

        function get_conditions__multiple_gap_angles(Obj)
            % GIVEN a runner with a single step and inputs that define 1 BoltFls block (sgre2), and 3 gap angles
            Step = usain.conditions.BoltPlasticityStep();
            Runner = runner.SequentialRunner().add(Step);

            % Get inputs that reflect 3 BoltFls blocks (2 with sgre2), and 1 gap angle
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "sgre2";
            Inputs.SGRE2.GAP_ANGLE = [1, 2, 3];

            Runner.set(usain.DataKeys.Inputs, Inputs);

            % WHEN, THEN
            Actual = Step.get_conditions();
            Obj.assertSize(Actual, [1, 3]);
            Obj.assertClass(Actual, 'usain.conditions.BoltPlasticity');
            Obj.verifyEqual(Actual(1).iBoltFls, 1);
            Obj.verifyEqual(Actual(2).iBoltFls, 1);
            Obj.verifyEqual(Actual(3).iBoltFls, 1);
            Obj.verifyEqual(Actual(1).iAngle, 1);
            Obj.verifyEqual(Actual(2).iAngle, 2);
            Obj.verifyEqual(Actual(3).iAngle, 3);
        end

    end

end
