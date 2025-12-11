classdef UpdateInputsForTFlangeStep < runner.BaseStep & logging.Loggable % mh:ignore_style
    properties
        Inputs struct
        LogHandler logging.CellArrayHandler
    end

    methods

        function Obj = UpdateInputsForTFlangeStep() % mh:ignore_style
            Obj.InputKeys.Inputs =  usain.DataKeys.Inputs;
            Obj.InputKeys.hasFeasibleDesign = usain.DataKeys.hasFeasibleDesign;

            Obj.OutputKeys.Inputs = usain.DataKeys.Inputs;

            Obj.LogHandler = logging.CellArrayHandler();
            Obj.Logger.add_handler(Obj.LogHandler);
        end

        function str = print_label(~)
            str = 'Update input data for T-flange design';
        end

        function pass = is_active(Obj)
            passSuperclass = is_active@runner.BaseStep(Obj);
            hasFeasibleDesign = Obj.get(Obj.InputKeys.hasFeasibleDesign);
            pass = passSuperclass && ~hasFeasibleDesign;
        end

        function run(Obj)
            Obj.Logger.info('No feasible design found for L-flange, switching to T-flange');
            Obj.Inputs = Obj.get(usain.DataKeys.Inputs);

            Obj.modify_inputs_flange_type();
            Obj.modify_inputs_bolt_fls();
            Obj.modify_inputs_flangeneckscf_preload_loss_factor_fls();
            Obj.modify_inputs_flange_widths();
            Obj.modify_inputs_flange_fillet();
            Obj.do_post_parse_manipulations();
            Obj.do_post_parse_checks();
            Obj.do_post_load_checks();

            Obj.set(usain.DataKeys.Inputs, Obj.Inputs);
        end

        function modify_inputs_flange_type(Obj)
            Obj.Inputs.flangeType = 'T';
        end

        function modify_inputs_bolt_fls(Obj)

            % Use hardcoded defaults for T-flange. This is considered appropriate at the design stage. For detailed
            % design, the flange type will be knwon and this step will not be executed.
            UpdatedBoltFls = struct();
            UpdatedBoltFls(1).PRELOAD_LOSS_FACTOR_FLS = 0.7;
            UpdatedBoltFls(2).PRELOAD_LOSS_FACTOR_FLS = 0.5;
            UpdatedBoltFls(1).PSF_BOLT_MATERIAL_FLS = 1.25;
            UpdatedBoltFls(2).PSF_BOLT_MATERIAL_FLS = 1.15;
            for iFls = 1:2
                UpdatedBoltFls(iFls).BOLT_FORCE_MODEL = "petersen";
                UpdatedBoltFls(iFls).CUSTOM_PRELOAD = nan(size(Obj.Inputs.boltOptions));
                UpdatedBoltFls(iFls).SN_CURVE_BOLT = "EC3_DC36*";
                UpdatedBoltFls(iFls).THICKNESS_EXPONENT_BOLT = 0.25;
                UpdatedBoltFls(iFls).TARGET_PM_SUM = 1.00;

                for field_name = fieldnames(UpdatedBoltFls(iFls))'
                    value = UpdatedBoltFls(iFls).(field_name{1});
                    formattedValue = strtrim(formattedDisplayText(value, ...
                        "NumericFormat", "SHORTG", "UseTrueFalseForLogical", true));
                    if isstring(value) || ischar(value)
                        formattedValue = """" + formattedValue + """";
                    end
                    Obj.Logger.info('Input "BoltFls(%u).%s" has been updated to: %s', ...
                        iFls, field_name{1}, formattedValue);
                end
            end

            idxSgre2 = string({Obj.Inputs.BoltFls.BOLT_FORCE_MODEL}) == "sgre2";
            if any(idxSgre2)
                BoltFlsSgre2 = Obj.Inputs.BoltFls(idxSgre2);
                UpdatedBoltFls = [UpdatedBoltFls, BoltFlsSgre2];
                Obj.Logger.info(['Input "BoltFls" blocks have been augmented with original "BoltFls" blocks where ', ...
                    'BOLT_FORCE_MODEL = "sgre2"']);
            end
            Obj.Inputs.BoltFls = UpdatedBoltFls;
        end

        function modify_inputs_flangeneckscf_preload_loss_factor_fls(Obj)
            factorsBoltFls = [Obj.Inputs.BoltFls.PRELOAD_LOSS_FACTOR_FLS];
            Obj.Inputs.FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS = min(factorsBoltFls);
            Obj.Logger.info('Input "FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS" has been updated to: %g', ...
                Obj.Inputs.FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS);
        end

        function modify_inputs_flange_widths(Obj)
            if isnan(Obj.Inputs.thicknNoseUp)
                return
            end

            if ~isnan(Obj.Inputs.minFlangeWidth)
                Obj.Inputs.minFlangeWidth = 2 * Obj.Inputs.minFlangeWidth - Obj.Inputs.thicknNoseUp;
                Obj.Logger.info('Input "minFlangeWidth" has been updated to: %0.0f mm', ...
                    Unit.mm.from_si(Obj.Inputs.minFlangeWidth));
            end
            if ~isnan(Obj.Inputs.maxFlangeWidth)
                Obj.Inputs.maxFlangeWidth = 2 * Obj.Inputs.maxFlangeWidth - Obj.Inputs.thicknNoseUp;
                Obj.Logger.info('Input "maxFlangeWidth" has been updated to: %0.0f mm', ...
                    Unit.mm.from_si(Obj.Inputs.maxFlangeWidth));
            end
        end

        function modify_inputs_flange_fillet(Obj)
            if Obj.Inputs.FILLET_RADIUS < usain.inputs.PostLoadChecks.EXPECTED_MIN_FILLET_RADIUS_T_FLANGE
                Obj.Inputs.FILLET_RADIUS = usain.inputs.PostLoadChecks.EXPECTED_MIN_FILLET_RADIUS_T_FLANGE;
                Obj.Logger.info('Input "FILLET_RADIUS" has been updated to: %0.0f mm', ...
                    Unit.mm.from_si(Obj.Inputs.FILLET_RADIUS));
            end
        end

        function do_post_parse_manipulations(Obj)
            % At this point post-parse manipulations have already been executed once (for L-flange). Therefore we only
            % need to rerun the manipulations that are applicable to T-flanges.
            PostParseManipulations = usain.inputs.PostParseManipulations(Inputs = Obj.Inputs);
            PostParseManipulations.run_t_flange_manipulations();
            Obj.Inputs = PostParseManipulations.Inputs;
        end

        function do_post_parse_checks(Obj)
            % At this piont post-parse manipulations have already been executed once (for L-flange). Therefore not all
            % checks from PostParseChecks works, since they expect unmanipulated inputs. Therefore we only run the
            % checks that are applicable to T-flanges or cover the manipulations that have been done in this step.
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Obj.Inputs);
            PostParseChecks.run_common_checks();
        end

        function do_post_load_checks(Obj)
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Obj.Inputs);
            PostLoadChecks.run();
        end

    end
end
