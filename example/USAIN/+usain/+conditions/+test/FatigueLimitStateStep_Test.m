classdef FatigueLimitStateStep_Test < UsainTest.UsainTestCase

    methods (Test, TestTags = {'integration'})

        function run__happy(~)
            % TODO: Implement this test after FlangeModel is removed from USAIN framework (WPSSD-5639)
        end

        function get_conditions__multiple_conditions(Obj)
            % GIVEN a runner with a single step and inputs that define multiple FLS conditions
            Step = usain.conditions.FatigueLimitStateStep();
            Runner = runner.SequentialRunner().add(Step);

            % Construct a FlangeModel from inputs that are set such that no loads will be imported
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;
            Inputs.DO_ASSESS_ULS = false;
            Inputs.DO_ASSESS_FLS = false;
            FlangeModel = UsainUtils.FlangeModel.setup_obj('Inputs', Inputs);

            FlangeModel.Inputs.BoltFls(1).BOLT_FORCE_MODEL = "schmidtneuper";
            FlangeModel.Inputs.BoltFls(2).BOLT_FORCE_MODEL = "schmidtneuper";
            FlangeModel.Inputs.BoltFls(1).CUSTOM_PRELOAD = nan;
            FlangeModel.Inputs.BoltFls(2).CUSTOM_PRELOAD = nan;
            FlangeModel.Inputs.BoltFls(1).PRELOAD_LOSS_FACTOR_FLS = 0.9;
            FlangeModel.Inputs.BoltFls(2).PRELOAD_LOSS_FACTOR_FLS = 0.9;
            FlangeModel.Tool.defaultPreload = 1280000;
            FlangeModel.Segment = UsainUtils.SegmentModel('Mdl', FlangeModel);
            FlangeModel.Segment.distRim = 0.160;
            FlangeModel.Segment.distForce = 0.120;
            FlangeModel.Segment.loadFactor = 0.144;
            FlangeModel.Segment.distBoltAtShell = 100e-3;
            FlangeModel.Segment.distBolt = 144e-3;
            FlangeModel.Segment.resilBolt = 6.59e-10;

            Runner.set(usain.DataKeys.FlangeModel, FlangeModel);

            % WHEN, THEN
            Actual = Step.get_conditions();
            Obj.assertSize(Actual, [1, 2]);
            Obj.assertClass(Actual, 'UsainUtils.FatigueLimitState');
            Obj.verifyEqual(Actual(1).iBoltFls, 1);
            Obj.verifyEqual(Actual(2).iBoltFls, 2);
        end

        function get_conditions__multiple_gap_angles(Obj)
            % GIVEN a runner with a single step and inputs that define multiple FLS conditions, one of which is an
            % SGRE2.0 assessment with multiple gap angles
            Step = usain.conditions.FatigueLimitStateStep();
            Runner = runner.SequentialRunner().add(Step);

            FlangeModel.Inputs.BoltFls(1).BOLT_FORCE_MODEL = "schmidtneuper";
            FlangeModel.Inputs.BoltFls(2).BOLT_FORCE_MODEL = "sgre2";
            FlangeModel.Inputs.SGRE2.GAP_ANGLE = [1, 2, 3];
            FlangeModel.Tool.defaultPreload = 1280000;
            FlangeModel.Inputs.BoltFls(1).CUSTOM_PRELOAD = nan;
            FlangeModel.Inputs.BoltFls(2).CUSTOM_PRELOAD = nan;
            FlangeModel.Inputs.BoltFls(1).PRELOAD_LOSS_FACTOR_FLS = 0.9;
            FlangeModel.Inputs.BoltFls(2).PRELOAD_LOSS_FACTOR_FLS = 0.9;
            FlangeModel.Inputs.PRELOAD_LOSS_FACTOR_FLS = 0.90;
            FlangeModel.Segment.distRim = 0.160;
            FlangeModel.Segment.distForce = 0.120;
            FlangeModel.Segment.loadFactor = 0.144;

            Runner.set(usain.DataKeys.FlangeModel, FlangeModel);

            % WHEN, THEN
            Actual = Step.get_conditions();
            Obj.assertSize(Actual, [1, 4]);
            Obj.assertClass(Actual(1), 'UsainUtils.FatigueLimitState');
            Obj.assertClass(Actual(2), 'usain.sgre2.FatigueLimitStateWithSgre2_0');
            Obj.verifyEqual(Actual(1).iBoltFls, 1);
            Obj.verifyEqual(Actual(2).iBoltFls, 2);
            Obj.verifyEqual(Actual(3).iBoltFls, 2);
            Obj.verifyEqual(Actual(4).iBoltFls, 2);
        end

    end

end
