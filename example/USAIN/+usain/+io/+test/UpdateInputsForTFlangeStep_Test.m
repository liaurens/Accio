classdef (SharedTestFixtures = {fixtures.SilentlyLogFixture(logging.Level.ERROR)}) ...
        UpdateInputsForTFlangeStep_Test < Unittest.TestCase % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function is_active__true(Obj)

            % GIVEN
            Step = usain.io.UpdateInputsForTFlangeStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.Inputs, struct());
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            % WHEN, THEN
            Obj.assertTrue(Step.is_active());
        end

        function is_active__false(Obj)

            % GIVEN
            Step = usain.io.UpdateInputsForTFlangeStep();
            Runner = runner.SequentialRunner().add(Step);
            Runner.set(usain.DataKeys.Inputs, struct());
            Runner.set(usain.DataKeys.hasFeasibleDesign, true);

            % WHEN, THEN
            Obj.assertFalse(Step.is_active());
        end

        function modify_inputs_flange_type__happy(Obj)
            % GIVEN
            Inputs = struct();
            Inputs.flangeType = 'L';
            Step = usain.io.UpdateInputsForTFlangeStep();
            Step.Inputs = Inputs;

            % WHEN
            Step.modify_inputs_flange_type();

            % THEN
            Obj.assertEqual(Step.Inputs.flangeType, 'T');
        end

        function modify_inputs_bolt_fls__without_sgre2(Obj)
            % GIVEN
            Inputs = struct();
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = 'some_model';
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = 'some_other_model';
            Inputs.BoltFls(3).BOLT_FORCE_MODEL = 'some_other_model';
            Inputs.boltOptions = {'ISO_M64', 'ISO_M72'};
            Step = usain.io.UpdateInputsForTFlangeStep();
            Step.Inputs = Inputs;

            % WHEN
            Step.modify_inputs_bolt_fls();

            % THEN
            Obj.assertEqual(length(Step.Inputs.BoltFls), 2);
            Obj.assertEqual(Step.Inputs.BoltFls(1).PRELOAD_LOSS_FACTOR_FLS, 0.7);
            Obj.assertEqual(Step.Inputs.BoltFls(1).BOLT_FORCE_MODEL, "petersen");
            Obj.assertEqual(Step.Inputs.BoltFls(1).CUSTOM_PRELOAD, [nan, nan]);
            Obj.assertEqual(Step.Inputs.BoltFls(1).PSF_BOLT_MATERIAL_FLS, 1.25);
            Obj.assertEqual(Step.Inputs.BoltFls(1).SN_CURVE_BOLT, "EC3_DC36*");
            Obj.assertEqual(Step.Inputs.BoltFls(1).THICKNESS_EXPONENT_BOLT, 0.25);
            Obj.assertEqual(Step.Inputs.BoltFls(1).TARGET_PM_SUM, 1.00);

            Obj.assertEqual(Step.Inputs.BoltFls(2).PRELOAD_LOSS_FACTOR_FLS, 0.5);
            Obj.assertEqual(Step.Inputs.BoltFls(2).BOLT_FORCE_MODEL, "petersen");
            Obj.assertEqual(Step.Inputs.BoltFls(2).CUSTOM_PRELOAD, [nan, nan]);
            Obj.assertEqual(Step.Inputs.BoltFls(2).PSF_BOLT_MATERIAL_FLS, 1.15);
            Obj.assertEqual(Step.Inputs.BoltFls(2).SN_CURVE_BOLT, "EC3_DC36*");
            Obj.assertEqual(Step.Inputs.BoltFls(2).THICKNESS_EXPONENT_BOLT, 0.25);
            Obj.assertEqual(Step.Inputs.BoltFls(2).TARGET_PM_SUM, 1.00);

            % THEN update are logged for both BoltFls blocks
            Obj.assertEqual(length(Step.LogHandler.buffer), 14); % 7 updates for each BoltFls block

            % THEN all updates are logged for first BoltFls block
            Obj.assertEqual(Step.LogHandler.buffer{1}.message, ...
                'Input "BoltFls(1).PRELOAD_LOSS_FACTOR_FLS" has been updated to: 0.7');
            Obj.assertEqual(Step.LogHandler.buffer{2}.message, ...
                'Input "BoltFls(1).PSF_BOLT_MATERIAL_FLS" has been updated to: 1.25');
            Obj.assertEqual(Step.LogHandler.buffer{3}.message, ...
                'Input "BoltFls(1).BOLT_FORCE_MODEL" has been updated to: "petersen"');
            Obj.assertEqual(Step.LogHandler.buffer{4}.message, ...
                'Input "BoltFls(1).CUSTOM_PRELOAD" has been updated to: NaN   NaN');
            Obj.assertEqual(Step.LogHandler.buffer{5}.message, ...
                'Input "BoltFls(1).SN_CURVE_BOLT" has been updated to: "EC3_DC36*"');
            Obj.assertEqual(Step.LogHandler.buffer{6}.message, ...
                'Input "BoltFls(1).THICKNESS_EXPONENT_BOLT" has been updated to: 0.25');
            Obj.assertEqual(Step.LogHandler.buffer{7}.message, ...
                'Input "BoltFls(1).TARGET_PM_SUM" has been updated to: 1');

            % THEN for second BoltFls block different PRELOAD_LOSS_FACTOR_FLS is logged
            Obj.assertEqual(Step.LogHandler.buffer{8}.message, ...
                'Input "BoltFls(2).PRELOAD_LOSS_FACTOR_FLS" has been updated to: 0.5');
            Obj.assertEqual(Step.LogHandler.buffer{9}.message, ...
                'Input "BoltFls(2).PSF_BOLT_MATERIAL_FLS" has been updated to: 1.15');
        end

        function modify_inputs_bolt_fls__with_sgre2(Obj)
            % GIVEN
            Inputs = struct();
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = 'some_model';
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = 'some_other_model';
            Inputs.BoltFls(3).BOLT_FORCE_MODEL = 'sgre2';
            Inputs.BoltFls(3).CUSTOM_PRELOAD = [nan, nan];
            Inputs.BoltFls(3).PRELOAD_LOSS_FACTOR_FLS = 0.90;
            Inputs.BoltFls(3).PSF_BOLT_MATERIAL_FLS = 1.10;
            Inputs.BoltFls(3).SN_CURVE_BOLT = 'EC3_DC50';
            Inputs.BoltFls(3).THICKNESS_EXPONENT_BOLT = 0.10;
            Inputs.BoltFls(3).TARGET_PM_SUM = 1.00;
            Inputs.BoltFls(4) = Inputs.BoltFls(3);
            Inputs.boltOptions = {'ISO_M64', 'ISO_M72'};
            Step = usain.io.UpdateInputsForTFlangeStep();
            Step.Inputs = Inputs;

            % WHEN
            Step.modify_inputs_bolt_fls();

            % THEN
            Obj.assertEqual(length(Step.Inputs.BoltFls), 4);
            Obj.assertEqual(Step.Inputs.BoltFls(1).PRELOAD_LOSS_FACTOR_FLS, 0.7);
            Obj.assertEqual(Step.Inputs.BoltFls(1).BOLT_FORCE_MODEL, "petersen");
            Obj.assertEqual(Step.Inputs.BoltFls(1).CUSTOM_PRELOAD, [nan, nan]);
            Obj.assertEqual(Step.Inputs.BoltFls(1).PSF_BOLT_MATERIAL_FLS, 1.25);
            Obj.assertEqual(Step.Inputs.BoltFls(1).SN_CURVE_BOLT, "EC3_DC36*");
            Obj.assertEqual(Step.Inputs.BoltFls(1).THICKNESS_EXPONENT_BOLT, 0.25);
            Obj.assertEqual(Step.Inputs.BoltFls(1).TARGET_PM_SUM, 1.00);

            Obj.assertEqual(Step.Inputs.BoltFls(2).PRELOAD_LOSS_FACTOR_FLS, 0.5);
            Obj.assertEqual(Step.Inputs.BoltFls(2).BOLT_FORCE_MODEL, "petersen");
            Obj.assertEqual(Step.Inputs.BoltFls(2).CUSTOM_PRELOAD, [nan, nan]);
            Obj.assertEqual(Step.Inputs.BoltFls(2).PSF_BOLT_MATERIAL_FLS, 1.15);
            Obj.assertEqual(Step.Inputs.BoltFls(2).SN_CURVE_BOLT, "EC3_DC36*");
            Obj.assertEqual(Step.Inputs.BoltFls(2).THICKNESS_EXPONENT_BOLT, 0.25);
            Obj.assertEqual(Step.Inputs.BoltFls(2).TARGET_PM_SUM, 1.00);

            Obj.assertEqual(Step.Inputs.BoltFls(3).PRELOAD_LOSS_FACTOR_FLS, 0.9);
            Obj.assertEqual(Step.Inputs.BoltFls(3).BOLT_FORCE_MODEL, 'sgre2');
            Obj.assertEqual(Step.Inputs.BoltFls(3).CUSTOM_PRELOAD, [nan, nan]);
            Obj.assertEqual(Step.Inputs.BoltFls(3).PSF_BOLT_MATERIAL_FLS, 1.10);
            Obj.assertEqual(Step.Inputs.BoltFls(3).SN_CURVE_BOLT, 'EC3_DC50');
            Obj.assertEqual(Step.Inputs.BoltFls(3).THICKNESS_EXPONENT_BOLT, 0.10);
            Obj.assertEqual(Step.Inputs.BoltFls(3).TARGET_PM_SUM, 1.00);

            Obj.assertEqual(Step.Inputs.BoltFls(4).PRELOAD_LOSS_FACTOR_FLS, 0.9);
            Obj.assertEqual(Step.Inputs.BoltFls(4).BOLT_FORCE_MODEL, 'sgre2');
            Obj.assertEqual(Step.Inputs.BoltFls(4).CUSTOM_PRELOAD, [nan, nan]);
            Obj.assertEqual(Step.Inputs.BoltFls(4).PSF_BOLT_MATERIAL_FLS, 1.10);
            Obj.assertEqual(Step.Inputs.BoltFls(4).SN_CURVE_BOLT, 'EC3_DC50');
            Obj.assertEqual(Step.Inputs.BoltFls(4).THICKNESS_EXPONENT_BOLT, 0.10);
            Obj.assertEqual(Step.Inputs.BoltFls(4).TARGET_PM_SUM, 1.00);

            % THEN update are logged for both BoltFls blocks
            % - 7 lines for each 'petersen' BoltFls block
            % - 1 lines for 'sgre2' BoltFls block
            Obj.assertEqual(length(Step.LogHandler.buffer), 15); %

            % THEN all updates are logged for first 'petersen' BoltFls block
            Obj.assertEqual(Step.LogHandler.buffer{1}.message, ...
                'Input "BoltFls(1).PRELOAD_LOSS_FACTOR_FLS" has been updated to: 0.7');
            Obj.assertEqual(Step.LogHandler.buffer{2}.message, ...
                'Input "BoltFls(1).PSF_BOLT_MATERIAL_FLS" has been updated to: 1.25');
            Obj.assertEqual(Step.LogHandler.buffer{3}.message, ...
                'Input "BoltFls(1).BOLT_FORCE_MODEL" has been updated to: "petersen"');
            Obj.assertEqual(Step.LogHandler.buffer{4}.message, ...
                'Input "BoltFls(1).CUSTOM_PRELOAD" has been updated to: NaN   NaN');
            Obj.assertEqual(Step.LogHandler.buffer{5}.message, ...
                'Input "BoltFls(1).SN_CURVE_BOLT" has been updated to: "EC3_DC36*"');
            Obj.assertEqual(Step.LogHandler.buffer{6}.message, ...
                'Input "BoltFls(1).THICKNESS_EXPONENT_BOLT" has been updated to: 0.25');
            Obj.assertEqual(Step.LogHandler.buffer{7}.message, ...
                'Input "BoltFls(1).TARGET_PM_SUM" has been updated to: 1');

            % THEN for second 'petersen' BoltFls block different PRELOAD_LOSS_FACTOR_FLS is logged
            Obj.assertEqual(Step.LogHandler.buffer{8}.message, ...
                'Input "BoltFls(2).PRELOAD_LOSS_FACTOR_FLS" has been updated to: 0.5');
            Obj.assertEqual(Step.LogHandler.buffer{9}.message, ...
                'Input "BoltFls(2).PSF_BOLT_MATERIAL_FLS" has been updated to: 1.15');

            % THEN single line for 'sgre2' BoltFls block(s)
            Obj.assertEqual(Step.LogHandler.buffer{15}.message, ...
                ['Input "BoltFls" blocks have been augmented with original "BoltFls" blocks where ', ...
                    'BOLT_FORCE_MODEL = "sgre2"']);
        end

        function modify_inputs_flangeneckscf_preload_loss_factor_fls__happy(Obj)
            % GIVEN
            Inputs = struct();
            Inputs.FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS = 0.7;
            Inputs.BoltFls(1).PRELOAD_LOSS_FACTOR_FLS = 0.7;
            Inputs.BoltFls(2).PRELOAD_LOSS_FACTOR_FLS = 0.5;
            Step = usain.io.UpdateInputsForTFlangeStep();
            Step.Inputs = Inputs;

            % WHEN
            Step.modify_inputs_flangeneckscf_preload_loss_factor_fls();

            % THEN
            Obj.assertEqual(Step.Inputs.FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS, 0.5);
            Obj.assertEqual(length(Step.LogHandler.buffer), 1);
            Obj.assertEqual(Step.LogHandler.buffer{1}.message, ...
                'Input "FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS" has been updated to: 0.5');
        end

        function modify_inputs_flange_widths__happy(Obj)
            % GIVEN
            Inputs = struct();
            Inputs.thicknNoseUp = 5;
            Inputs.minFlangeWidth = 20;
            Inputs.maxFlangeWidth = 30;
            Step = usain.io.UpdateInputsForTFlangeStep();
            Step.Inputs = Inputs;

            % WHEN
            Step.modify_inputs_flange_widths();

            % THEN
            Obj.assertEqual(Step.Inputs.minFlangeWidth, 35);
            Obj.assertEqual(Step.Inputs.maxFlangeWidth, 55);
        end

        function modify_inputs_flange_fillet__happy(Obj)
            % GIVEN
            Inputs = struct();
            Inputs.FILLET_RADIUS = 10e-3;
            Step = usain.io.UpdateInputsForTFlangeStep();
            Step.Inputs = Inputs;

            % WHEN
            Step.modify_inputs_flange_fillet();

            % THEN
            Obj.assertEqual(Step.Inputs.FILLET_RADIUS, 15e-3);
        end

        function do_post_parse_manipulations__happy(Obj)
            % GIVEN
            Inputs = struct();
            Inputs.flangeType = 'T';
            Inputs.STEPSIZE_WIDTH = 1e-3;
            Step = usain.io.UpdateInputsForTFlangeStep();
            Step.Inputs = Inputs;

            % WHEN
            Step.do_post_parse_manipulations();

            % THEN
            Obj.assertEqual(Step.Inputs.STEPSIZE_WIDTH, 2e-3);
        end

        function do_post_parse_checks__happy(~)
            % Not implemented, covered by tests for PostParseChecks
        end

        function do_post_load_checks(~)
            % Not implemented, covered by tests for PostLoadChecks
        end

    end
end
