classdef PostParseChecks < logging.Loggable

    properties
        Inputs
        LogHandler logging.CellArrayHandler
    end

    methods

        function Obj = PostParseChecks(varargin)
            Obj = assign_varargin_2_classprop(Obj, varargin{:});

            Obj.LogHandler = logging.CellArrayHandler();
            Obj.Logger.add_handler(Obj.LogHandler);
        end

        function throw_error(Obj)
            isErrorMessage = cellfun(@(x) isequal(logging.Level.ERROR, x.level), Obj.LogHandler.buffer);
            if any(isErrorMessage)
                Obj.Logger.error('One or more post-parse checks failed. Please read the above error message(s)');
            end
        end

        function run(Obj)

            % check for min/max/default of schema
            Schema = usain.inputs.get_schema();
            validate.Validator().report(Schema, Obj.Inputs);

            Obj.run_common_checks();
            Obj.check_custom_washers();
            Obj.check_emodulus_for_interpolated_shell_stiffness();
            Obj.check_gap_angles_for_interpolated_shell_stiffness();
            Obj.check_flangeneckscf_preload_loss_factor_fls();
            Obj.check_flangeneckscf_write_intermediate_results();
            Obj.check_flangeneckscf_write_scf_output();
            Obj.check_loads_scaling_equal_length();
            Obj.check_dead_weight_structural_model();
            Obj.check_s1_load_input_combinations();
            Obj.check_uls_load_input_combination();
            Obj.check_strmdl_inclination_angle();
            Obj.check_inclination_moment_fls_override();
            Obj.check_inclination_values_expected();
            Obj.check_inclination_values_order();
            Obj.check_nose_heights_ge_min_height();
            Obj.check_expected_bolt_length();
            Obj.check_expected_thread_length();
            Obj.check_bolt_holes();
            Obj.check_hv_bolts_provided();
            Obj.check_valid_hv_bolt_length();
            Obj.check_hv_bolts_do_assess_thread_requirement_combination();
            Obj.check_hv_bolts_bolt_extenders_combination();
            Obj.check_iso_m36_provided();
            Obj.check_iso_m39_provided();
            Obj.check_iso_m90_provided();
            Obj.check_iso_m100_provided();
            Obj.check_iso_tightening_method_site_combination();
            Obj.check_bolt_sn_curves();
            Obj.check_thickness_tolerance_allowance_combination();
            Obj.check_active_design_conditions();
            Obj.check_fls_schmidtneuper_model_combination();
            Obj.check_scaling_reference_levels();
            Obj.check_uls_bolt_diameter_selection_requirement();
            Obj.check_mixed_bolt_series();
            Obj.check_diam_bolt_circle_b_min_combination();

            Obj.throw_error();
        end

        function run_common_checks(Obj)
            % This method collects all checks applicable for T-flanges and is used in both
            % the run() method of this class and in and usain.io.UpdateInputsForTFlangeStep.
            Obj.check_flange_type_for_switch_to_t_flange();
            Obj.check_amount_of_bolt_options();
            Obj.check_min_max_design_variables();
            Obj.check_design_variables_step_size();
            Obj.check_secondary_holes();
            Obj.check_boltfls_first_block_not_sgre2();
            Obj.check_boltfls_custom_preload_across_assessments();
            Obj.check_boltfls_no_custom_preload_for_hv_bolts();
            Obj.check_boltfls_custom_preload_wrt_bolt_yield_strength();
            Obj.check_boltfls_number_of_sgre2_blocks();
            Obj.check_boltfls_sgre2_required_reaction_distance_method();
            Obj.check_boltfls_petersen_required_reaction_distance_method();
            Obj.check_boltfls_expected_thickness_exponent();
        end

        function check_flange_type_for_switch_to_t_flange(Obj)
            % If automatic switch from L to T is allowed, flangeType is required to be 'L'.
            % Note that leaving flangeType empty is not allowed, as this would get the flange type from the structural
            % model. This leads to unexpected behavior for a TEXACO run where USAIN is executed in multiple iterations,
            % since the structural model is updated after each USAIN run.
            if Obj.Inputs.DO_ALLOW_SWITCH_L_TO_T && ~strcmp(Obj.Inputs.flangeType, 'L')
                Obj.Logger.error(['Input DO_ALLOW_SWITCH_L_TO_T is set to true, while input flangeType is not ', ...
                    'set to ''L''. This is not allowed.'], abortOnError = false);
            end
        end

        function check_amount_of_bolt_options(Obj)
            % For all Inputs values defined below, it is allowed to:
            % - Specify one value when n `boltOptions` are defined.
            %   When this happens, the value gets expanded in the do_post_parse_manipulations() function.
            % - Specify n values when n `boltOptions` are defined.
            % Any other combination will error (like 2 values for `boltOptions` and 3 values for `diamBoltCircle`)
            nInputBolts = numel(Obj.Inputs.boltOptions);

            Obj.check_valid_amount(Obj.Inputs.minFlangeWidth, "minFlangeWidth", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.maxFlangeWidth, "maxFlangeWidth", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.minFlangeThickn, "minFlangeThickn", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.maxFlangeThickn, "maxFlangeThickn", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.minNBolts, "minNBolts", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.maxNBolts, "maxNBolts", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.diamBoltHole, "diamBoltHole", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.diamBoltCircle, "diamBoltCircle", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.B_MIN, "B_MIN", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.TOOL_DIMENSION_CIRC_DIR, "TOOL_DIMENSION_CIRC_DIR", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.TOOL_DIMENSION_RADIAL_DIR, "TOOL_DIMENSION_RADIAL_DIR", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.lengthBoltExtender, "lengthBoltExtender", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.tighteningMethod, "tighteningMethod", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.NUT_TYPE, "NUT_TYPE", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.CUSTOM_WASHER_DIAM_INNER, "CUSTOM_WASHER_DIAM_INNER", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.CUSTOM_WASHER_DIAM_OUTER, "CUSTOM_WASHER_DIAM_OUTER", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.CUSTOM_WASHER_THICKNESS, "CUSTOM_WASHER_THICKNESS", nInputBolts);
            Obj.check_valid_amount(Obj.Inputs.FlangeGapping.CUSTOM_PRELOAD, "FlangeGapping.CUSTOM_PRELOAD", nInputBolts); % mh:ignore_style
            Obj.check_valid_amount(Obj.Inputs.SlsPretension.CUSTOM_PRELOAD, "SlsPretension.CUSTOM_PRELOAD", nInputBolts); % mh:ignore_style
            Obj.check_valid_amount(Obj.Inputs.FlangeNeckScf.CUSTOM_PRELOAD, "FlangeNeckScf.CUSTOM_PRELOAD", nInputBolts); % mh:ignore_style

            % Check for BoltFls done separate since it can be an array
            nBoltFls = length(Obj.Inputs.BoltFls);
            for iBoltFls = 1:nBoltFls
                Obj.check_valid_amount(Obj.Inputs.BoltFls(iBoltFls).CUSTOM_PRELOAD, "BoltFls.CUSTOM_PRELOAD", nInputBolts); % mh:ignore_style
            end
        end

        function check_valid_amount(Obj, inputValue, varName, nOptions)
            if ~any(numel(inputValue) == [1 nOptions])
                Obj.Logger.error(['\tExpected input ''%s'' to be either empty, a single value or %i values ', ...
                    '(i.e. one for each input ''boltOptions'').'], varName, nOptions, ...
                    abortOnError = false);
            end
        end

        function check_expected_bolt_length(Obj)
            % Compare length of bolt with expected/default values
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);

            % Compare length of bolt with expected/default values
            isStandardLength = isnan(BoltOpts.inputBoltLength) | BoltOpts.isStandardBoltLength;
            if any(~isStandardLength)
                msg = sprintf([ ...
                    'One or more inputs for "boltOptions" define non-standard bolt length(s):', ...
                    '\n\n\t%s\n\n', ...
                    '\tStandard bolt lengths are listed in the design rules.'], ...
                    strjoin(Obj.Inputs.boltOptions(~isStandardLength), ', '));
                Obj.Logger.warning(msg);
            end
        end

        function check_expected_thread_length(Obj)
            % Compare length of bolt thread with expected/default values
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);

            isStandardThreadLength = isnan(BoltOpts.inputThreadLength) | BoltOpts.isStandardThreadLength;
            if any(~isStandardThreadLength)
                msg = sprintf([ ...
                    'One or more inputs for "boltOptions" define non-standard thread length(s):', ...
                    '\n\n\t%s\n\n', ...
                    '\tStandard thread lengths are listed in the design rules.'], ...
                    strjoin(Obj.Inputs.boltOptions(~isStandardThreadLength), ', '));
                Obj.Logger.warning(msg);
            end

        end

        function check_min_max_design_variables(Obj)
            % Verify max >= min for design variable ranges
            varNames = {'FlangeWidth', 'FlangeThickn', 'NBolts'};
            for var = varNames
                maxVar = sprintf('max%s', var{1});
                minVar = sprintf('min%s', var{1});

                if any(Obj.Inputs.(maxVar) < Obj.Inputs.(minVar))
                    Obj.Logger.error('Input "%s" must be >= input "%s".', maxVar, minVar, abortOnError = false);
                end
            end
        end

        function check_design_variables_step_size(Obj)
            % Verify user inputs for design variables w.r.t. their respective stepsize

            % If the minX and maxX input have the same value, that means that part of the flange design is fixed.
            % In that case we dont need the designspace, so we can ignore the constraint.
            fAlmostEqual = @(x, y) abs(x - y) < 1e-6;

            if ~fAlmostEqual(Obj.Inputs.minNBolts, Obj.Inputs.maxNBolts)
                [pass, msg] = design_space.is_multiple(Obj.Inputs.minNBolts, Obj.Inputs.STEPSIZE_NBOLTS);
                if ~all(pass)
                    Obj.Logger.warning('minNBolts: %s', msg);
                end

                [pass, msg] = design_space.is_multiple(Obj.Inputs.maxNBolts, Obj.Inputs.STEPSIZE_NBOLTS);
                if ~all(pass)
                    Obj.Logger.warning('maxNBolts: %s', msg);
                end
            end

            if ~fAlmostEqual(Obj.Inputs.minFlangeThickn, Obj.Inputs.maxFlangeThickn)
                [pass, msg] = design_space.is_multiple(Unit.mm.from_si(Obj.Inputs.minFlangeThickn), ...
                    Unit.mm.from_si(Obj.Inputs.STEPSIZE_THICKN));
                if ~all(pass)
                    Obj.Logger.warning('minFlangeThickn: %s', msg);
                end

                [pass, msg] = design_space.is_multiple(Unit.mm.from_si(Obj.Inputs.maxFlangeThickn), ...
                    Unit.mm.from_si(Obj.Inputs.STEPSIZE_THICKN));
                if ~all(pass)
                    Obj.Logger.warning('maxFlangeThickn: %s', msg);
                end
            end

            if ~fAlmostEqual(Obj.Inputs.minFlangeWidth, Obj.Inputs.maxFlangeWidth)
                [pass, msg] = design_space.is_multiple(Unit.mm.from_si(Obj.Inputs.minFlangeWidth), ...
                    Unit.mm.from_si(Obj.Inputs.STEPSIZE_WIDTH));
                if ~all(pass)
                    Obj.Logger.warning('minFlangeWidth: %s', msg);
                end

                [pass, msg] = design_space.is_multiple(Unit.mm.from_si(Obj.Inputs.maxFlangeWidth), ...
                    Unit.mm.from_si(Obj.Inputs.STEPSIZE_WIDTH));
                if ~all(pass)
                    Obj.Logger.warning('maxFlangeWidth: %s', msg);
                end
            end
        end

        function check_secondary_holes(Obj)
            % Verify that the SECONDARY_HOLES_BCD < diameter and also < diamBoltCircle

            % Use "NOT min > max" instead of "min <= max" to properly account for NaN values (which should be skipped)
            pass = ~(Obj.Inputs.SECONDARY_HOLES_BCD > Obj.Inputs.diameter);
            if ~all(pass)
                Obj.Logger.error('Input "diameter" must be > input "SECONDARY_HOLES_BCD".', abortOnError = false);
            end

            pass = ~(Obj.Inputs.SECONDARY_HOLES_BCD > Obj.Inputs.diamBoltCircle);
            if ~all(pass)
                Obj.Logger.error('Input "diamBoltCircle" must be > input "SECONDARY_HOLES_BCD".', abortOnError = false);
            end

            % Verify that SECONDARY_HOLES_BCD and SECONDARY_HOLES_DIAMETER are both (non)empty
            pass = ~xor(isnan(Obj.Inputs.SECONDARY_HOLES_BCD), isnan(Obj.Inputs.SECONDARY_HOLES_DIAMETER));
            if ~all(pass)
                Obj.Logger.error(['Inputs "SECONDARY_HOLES_BCD" and "SECONDARY_HOLES_DIAMETER" should both be ', ...
                    'either defined or left blank.'], abortOnError = false);
            end

        end

        function check_boltfls_first_block_not_sgre2(Obj)

            if strcmp(Obj.Inputs.BoltFls(1).BOLT_FORCE_MODEL, "sgre2")
                Obj.Logger.error(['The first BoltFls input block is not allowed to define the "sgre2" ', ...
                    'bolt force model since this is not supported in DOCTOR.'], abortOnError = false);
            end
        end

        function check_custom_washers(Obj)
            % Group multiple checks related to custom washers
            Obj.check_custom_washers_uniformly_defined();
            Obj.check_custom_washers_bolt_fits();
            Obj.check_custom_washers_diameters();
            Obj.check_custom_washers_tightening_method();
        end

        function check_custom_washers_uniformly_defined(Obj)
            % Verify that all CUSTOM_WASHER_* inputs are (non)empty (i.e. all defined or
            % all NaN)
            washVars = {'CUSTOM_WASHER_DIAM_INNER', 'CUSTOM_WASHER_DIAM_OUTER', 'CUSTOM_WASHER_THICKNESS'};
            pass = all(~xor(isnan(Obj.Inputs.(washVars{1})), isnan(Obj.Inputs.(washVars{2}))) & ...
                ~xor(isnan(Obj.Inputs.(washVars{1})), isnan(Obj.Inputs.(washVars{3}))));
            if ~pass
                Obj.Logger.error('The inputs %s should be either all defined or all left blank.', ...
                  strjoin(washVars, ', '), abortOnError = false);
            end
        end

        function check_custom_washers_bolt_fits(Obj)
            % check if custom washer inner diameter is large enough to fit a bolt
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            diamBolts = 1e-3 * str2double(regexpi(BoltOpts.label, '(?<=^\w+_M)\d+', 'match', 'once'));

            pass = ~(Obj.Inputs.CUSTOM_WASHER_DIAM_INNER <= diamBolts);
            if ~all(pass)
                Obj.Logger.error(['One or more values for input "CUSTOM_WASHER_DIAM_INNER" ', ...
                    'is too small to fit the bolts.'], abortOnError = false);
            end
        end

        function check_custom_washers_diameters(Obj)
            % Verify that custom washer's outer diameter > inner diameter
            pass = all(~(Obj.Inputs.CUSTOM_WASHER_DIAM_OUTER <= Obj.Inputs.CUSTOM_WASHER_DIAM_INNER));
            if ~pass
                Obj.Logger.error('Input "CUSTOM_WASHER_DIAM_OUTER" must be > input "CUSTOM_WASHER_DIAM_INNER".', ...
                    abortOnError = false);
            end
        end

        function check_custom_washers_tightening_method(Obj)
            % Throw error if the tightening method is tension and any of the CUSTOM_WASHER_* inputs is not NaN
            washVars = {'CUSTOM_WASHER_DIAM_INNER', 'CUSTOM_WASHER_DIAM_OUTER', 'CUSTOM_WASHER_THICKNESS'};
            customWasherInputs = cellfun(@(x) Obj.Inputs.(x), washVars, 'UniformOutput', false);

            hasCustomWasher = cellfun(@(x) ~isnan(x), customWasherInputs, 'UniformOutput', false);
            isTensionTighteningMethod = cellfun(@(x) strcmp(x, 'tension'), Obj.Inputs.tighteningMethod, ...
                'UniformOutput', false);

            pass = ~(any(cell2mat(hasCustomWasher)) && any(cell2mat(isTensionTighteningMethod)));
            if ~pass
                Obj.Logger.error(['The input tighteningMethod should not be tension if any '...
                    'of the custom washer inputs are defined'], abortOnError = false);
            end

        end

        function check_emodulus_for_interpolated_shell_stiffness(Obj)
            % Throw error if the E-modulus is not 210 MPa while SGRE2.0 is used in this run, in combination with
            % interpolated shell stiffness.

            hasSgre2 = any([Obj.Inputs.BoltFls.BOLT_FORCE_MODEL] == "sgre2");
            if ~hasSgre2
                return
            end

            if strcmp(Obj.Inputs.SGRE2.SHELL_STIFFNESS_METHOD, 'interpolated') && ...
                    abs(Obj.Inputs.E_FLANGE - 210e9) > 1e6
                Obj.Logger.error([ ...
                    'Modulus of elasticity of flange must be 210 MPa for interpolating shell stiffness. ', ...
                    'Use the `simplified` shell stiffness method instead (input SGRE2.SHELL_STIFFNESS_METHOD).'], ...
                    abortOnError = false);
            end
        end

        function check_gap_angles_for_interpolated_shell_stiffness(Obj)
            % Throw error if the SGRE2.0 gap angles are outside range [10, 180]deg, in combination with interpolated
            % shell stiffness.

            hasSgre2 = any([Obj.Inputs.BoltFls.BOLT_FORCE_MODEL] == "sgre2");
            if ~hasSgre2
                return
            end

            if strcmp(Obj.Inputs.SGRE2.SHELL_STIFFNESS_METHOD, 'interpolated') && ...
                    (any(rad2deg(Obj.Inputs.SGRE2.GAP_ANGLE) < 10) || any(rad2deg(Obj.Inputs.SGRE2.GAP_ANGLE) > 180))
                Obj.Logger.error([ ...
                    'Gap angles selected for SGRE2.0 must be in range [10, 180]deg for interpolating shell stiffness. ', ...  % mh:ignore_style
                    'Use the `simplified` shell stiffness method instead (input SGRE2.SHELL_STIFFNESS_METHOD).'], ...
                    abortOnError = false);
            end
        end

        function check_boltfls_custom_preload_across_assessments(Obj)
            % Validate the BoltFls custom preload in combination with other three assessments.
            [pass, errorMsg] = usain.inputs.validate_custom_preload_combinations(Obj.Inputs.BoltFls, ...
                Obj.Inputs.FlangeGapping.CUSTOM_PRELOAD, Obj.Inputs.SlsPretension.CUSTOM_PRELOAD, ...
                Obj.Inputs.FlangeNeckScf.CUSTOM_PRELOAD);
            if ~pass
                Obj.Logger.error(errorMsg, abortOnError = false);
            end
        end

        function check_boltfls_no_custom_preload_for_hv_bolts(Obj)
            % CUSTOM_PRELOAD is not expected to be used for HV bolts
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            isHvBolt = startsWith(BoltOpts.label, 'HV');

            customPreloadValues = [ ...
                cat(1, Obj.Inputs.BoltFls.CUSTOM_PRELOAD); ...
                Obj.Inputs.FlangeGapping.CUSTOM_PRELOAD; ...
                Obj.Inputs.SlsPretension.CUSTOM_PRELOAD; ...
                Obj.Inputs.FlangeNeckScf.CUSTOM_PRELOAD];

            isHvWithCustomPreload = any(~isnan(customPreloadValues), 1) & isHvBolt;

            if any(isHvWithCustomPreload)
                Obj.Logger.warning('One or more "*.CUSTOM_PRELOAD" inputs used for HV bolts. This is not expected.');
            end
        end

        function check_boltfls_custom_preload_wrt_bolt_yield_strength(Obj)
            % Verify CUSTOM_PRELOAD is within 50% - 100% of bolt yield strength
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);

            customPreloadValues = [ ...
                cat(1, Obj.Inputs.BoltFls.CUSTOM_PRELOAD); ...
                Obj.Inputs.FlangeGapping.CUSTOM_PRELOAD; ...
                Obj.Inputs.SlsPretension.CUSTOM_PRELOAD; ...
                Obj.Inputs.FlangeNeckScf.CUSTOM_PRELOAD];

            for iLabel = 1:length(BoltOpts.label)
                label = BoltOpts.label{iLabel};
                expectedRange = usain.fastener.FastenerData.calc_expected_range_preload(label);
                if any(customPreloadValues(:, iLabel) < expectedRange(1)) || ...
                        any(customPreloadValues(:, iLabel) > expectedRange(2))
                    Obj.Logger.warning([ ...
                        'One or more "*.CUSTOM_PRELOAD" inputs found with a value <50%% or >100%% of yield. ', ...
                        'This is not expected.']);
                    % Terminate for-loop; we only want 1 warning message
                    break
                end
            end
        end

        function check_boltfls_number_of_sgre2_blocks(Obj)
            % If more that a single "sgre2" block is defined, only the first will be reported in the SGRE2.0 Excel
            % summary file (in `usain.sgre2.WriteSummaryFileStep`).

            numberOfSgre2Blocks = nnz([Obj.Inputs.BoltFls.BOLT_FORCE_MODEL] == "sgre2");
            if Obj.Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS && (numberOfSgre2Blocks > 1)
                Obj.Logger.warning([ ...
                    'More than one "sgre2" analyses are defined. ', ...
                    'Only the first will be reported in the SGRE2.0 Excel summary file.']);
            end
        end

        function check_boltfls_sgre2_required_reaction_distance_method(Obj)
            % Verify "sgre2" is only used in combination with `tobinaga`
            isSgre2 = any([Obj.Inputs.BoltFls.BOLT_FORCE_MODEL] == "sgre2");
            isTobinaga = strcmp(Obj.Inputs.REACTION_DISTANCE_METHOD, 'tobinaga');
            pass = ~(isSgre2 && ~isTobinaga);

            if ~pass
                Obj.Logger.error(['An FLS assessment with "sgre2" is requested, ', ...
                    'while input REACTION_DISTANCE_METHOD is not set to "tobinaga". This is not allowed.'], ...
                    abortOnError = false);
            end
        end

        function check_boltfls_petersen_required_reaction_distance_method(Obj)
            % Verify `petersen` is only used in combination with `tobinaga`
            isPetersen = any([Obj.Inputs.BoltFls.BOLT_FORCE_MODEL] == "petersen");
            isTobinaga = strcmp(Obj.Inputs.REACTION_DISTANCE_METHOD, 'tobinaga');
            pass = ~(isPetersen && ~isTobinaga);

            if ~pass
                Obj.Logger.error(['An FLS assessment with "petersen" is requested, ', ...
                    'while input REACTION_DISTANCE_METHOD is not set to "tobinaga". This is not allowed.'], ...
                    abortOnError = false);
            end
        end

        function check_boltfls_expected_thickness_exponent(Obj)
            % Check that thickness exponent settings in inputs correspond to bolt force model
            %
            % Bolt force model  | Exponent
            % ------------------+-------------------
            % schmidtneuper     | 0.25
            % sgre2             | NaN*
            % petersen          | 0.25
            %    ( * = NaN means it is not set in inputs and therefore computed internally)
            %
            % A NaN value is only allowed for sgre2 analyses.

            if ~Obj.Inputs.DO_ASSESS_FLS
                % Not applicable if bolt FLS will not be assessed
                return
            end

            isSchmidtNeuper = [Obj.Inputs.BoltFls.BOLT_FORCE_MODEL] == "schmidtneuper";
            isSgre2 = [Obj.Inputs.BoltFls.BOLT_FORCE_MODEL] == "sgre2";
            isPetersen = [Obj.Inputs.BoltFls.BOLT_FORCE_MODEL] == "petersen";
            exponent = [Obj.Inputs.BoltFls.THICKNESS_EXPONENT_BOLT];

            if any(isSgre2 & ~isnan(exponent))
                Obj.Logger.warning([ ...
                    'Input BoltFls.THICKNESS_EXPONENT_BOLT is expected to be empty for analyses ', ...
                    'where "sgre2" is used for input BoltFls.BOLT_FORCE_MODEL.']);
            end

            if any(~isSgre2 & isnan(exponent))
                Obj.Logger.error([ ...
                    'Input BoltFls.THICKNESS_EXPONENT_BOLT must be defined for analyses ', ...
                    'where input BoltFls.BOLT_FORCE_MODEL is not "sgre2".'], abortOnError = false);
            end

            if any((isSchmidtNeuper | isPetersen) & ~(abs(exponent - 0.25) < 1e-6))
                Obj.Logger.warning([ ...
                    'A value of 0.25 for input BoltFls.THICKNESS_EXPONENT_BOLT is expected for analyses ', ...
                    'where "schmidtneuper" and/or "petersen" is used for input BoltFls.BOLT_FORCE_MODEL.']);
            end

        end

        function check_flangeneckscf_preload_loss_factor_fls(Obj)
            % Verify that FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS is equal to at least one of the values of
            % BoltFls.PRELOAD_LOSS_FACTOR_FLS

            if ~Obj.Inputs.DO_ASSESS_FLS || ~Obj.Inputs.DO_ASSESS_FLANGE_NECK_SCF
                % Not applicable if (flange neck) FLS will not be assessed
                return
            end

            factorFlangeNeckScf = Obj.Inputs.FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS;
            factorsBoltFls = [Obj.Inputs.BoltFls.PRELOAD_LOSS_FACTOR_FLS];
            if ~any(factorFlangeNeckScf == factorsBoltFls)
                Obj.Logger.error(['FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS should correspond to one of the values ', ...
                    'for BoltFls.PRELOAD_LOSS_FACTOR_FLS'], abortOnError = false);
            end
        end

        function check_flangeneckscf_write_intermediate_results(Obj)
            % Warn if FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS is set to true, while no flange neck scf assessment will
            % be performed

            if ~Obj.Inputs.DO_ASSESS_FLANGE_NECK_SCF && Obj.Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS
                Obj.Logger.warning(['Input FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS is set to true, ', ...
                    'while input DO_ASSESS_FLANGE_NECK_SCF is set to false. ', ...
                    'FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS will be ingored.']);
            end
        end

        function check_flangeneckscf_write_scf_output(Obj)
            % Warn if no StructuralModel is provided, while a flange neck scf assessment will be performed

            if Obj.Inputs.DO_ASSESS_FLANGE_NECK_SCF && isempty(Obj.Inputs.structureInpFilePath)
                Obj.Logger.warning( ...
                    'Equivalent SCFs for STIFT can not be output, because no StructuralModel is provided in inputs.');
            end
        end

        function check_loads_scaling_equal_length(Obj)
            % Verify ULS and FLS scaling factors and levels have equal length.
            varNames = {'uls', 'fls', 'S1'};
            for var = varNames
                varFactor = [var{1} 'ScalingFactor'];
                varLevel = [var{1} 'ScalingLevel'];
                equalVecLen = isequal(cellfun(@length, Obj.Inputs.Loads.(varFactor)), ...
                                      cellfun(@length, Obj.Inputs.Loads.(varLevel)));

                if ~equalVecLen
                    Obj.Logger.error('Vector sizes for inputs "Loads.%s" and "Loads.%s" must be the same.', ...
                        varFactor, varLevel, abortOnError = false);
                end
            end

        end

        function check_dead_weight_structural_model(Obj)
            % Log error if input DEAD_WEIGHT is set, as well as a StructuralModel
            hasStrMdl = ~isempty(Obj.Inputs.structureInpFilePath);
            if ~isnan(Obj.Inputs.DEAD_WEIGHT) && hasStrMdl
                Obj.Logger.error('Both inputs DEAD_WEIGHT and structureInpFilePath are set. This is not allowed.', ...
                    abortOnError = false);
            end
        end

        function check_s1_load_input_combinations(Obj)
            % Verifications on `Loads.S1FilePath` and `S1_BENDING_MOMENT`, if S1 loads are required for active
            % condition(s)

            % Return if this run has no active conditions that require S1 loads
            doChecksForS1 = usain.loads.Loads.check_is_required_s1(Obj.Inputs);
            if ~doChecksForS1
                return
            end

            % If S1 loads are required for active condition(s), make sure they are provided in inputs (either through
            % `S1_BENDING_MOMENT`, `Loads.S1FilePath` or ``Loads.flsFilePath``)
            hasS1LoadsFile = ~cellfun(@isempty, Obj.Inputs.Loads.S1FilePath);
            hasFlsLoadsFile = ~cellfun(@isempty, Obj.Inputs.Loads.flsFilePath);
            hasS1Override = ~isnan(Obj.Inputs.S1_BENDING_MOMENT);
            if any(~hasS1LoadsFile & ~hasFlsLoadsFile & ~hasS1Override)
                Obj.Logger.error([ ...
                    'Input "Loads.S1FilePath", "S1_BENDING_MOMENT" or "Loads.flsFilePath" must be specified ', ...
                    'to assess S1 (related) design criteria.'], ...
                    abortOnError = false);
            end

            % If both `Loads.S1FilePath` and `S1_BENDING_MOMENT` are input, log a warning
            if any(hasS1LoadsFile & hasS1Override)
                iLoadSets = find(hasS1LoadsFile & hasS1Override);
                Obj.Logger.warning([ ...
                    'For loads set(s) %s, both "Loads.S1FilePath" and "S1_BENDING_MOMENT" are specified.\n', ...
                    '\t==> Value for "S1_BENDING_MOMENT" will be used for all load sets.'], ...
                    join("#" + string(iLoadSets), " and "));
            end

            % If both `Loads.S1FilePath` and `S1_BENDING_MOMENT` are not input, but `Loads.flsFilePath` is, log a
            % warning
            if any(~hasS1LoadsFile & ~hasS1Override & hasFlsLoadsFile)
                iLoadSets = find(~hasS1LoadsFile & ~hasS1Override & hasFlsLoadsFile);
                Obj.Logger.warning([ ...
                    'For loads set(s) %s, neither "Loads.S1FilePath" nor "S1_BENDING_MOMENT" are specified.\n', ...
                    '\t==> Maximum FLS moment will be used for load set(s) %s.'], ...
                    join("#" + string(iLoadSets), " and "), join("#" + string(iLoadSets), " and "));
            end
        end

        function check_uls_load_input_combination(Obj)
            doChecksForUls = usain.loads.Loads.check_is_required_uls(Obj.Inputs);
            hasUlsOverride = ~isnan(Obj.Inputs.ULS_BENDING_MOMENT);
            hasInclinationOverride = ~isnan(Obj.Inputs.INCLINATION_MOMENT);

            hasUlsLoadsFile = any(~cellfun(@isempty, Obj.Inputs.Loads.ulsFilePath));
            hasLoadsInclination = any(~isnan(Obj.Inputs.Loads.inclinationValue));
            hasUlsScaling = any(~isnan([Obj.Inputs.Loads.ulsScalingFactor{:}]));
            hasUlsScalingLevel = any(cellfun(@(x) any(~isnan(x)), [Obj.Inputs.Loads.ulsScalingLevel{:}]));
            hasUlsLoadsBlockInputs = hasUlsLoadsFile || hasLoadsInclination || hasUlsScaling || hasUlsScalingLevel;

            hasUlsInput = hasUlsLoadsFile || hasUlsOverride;

            % When ULS_BENDING_MOMENT is provided ensure all ULS related items in the "Loads." block are not provided.
            if hasUlsOverride && hasUlsLoadsBlockInputs
                Obj.Logger.error(['Expert input "ULS_BENDING_MOMENT" is set in combination with (some) ULS ', ...
                    'related inputs in the "Loads." input block. This is not allowed.'], abortOnError = false);
            end

            if hasInclinationOverride && hasLoadsInclination
                Obj.Logger.error(['Expert input "INCLINATION_MOMENT" is set in combination with ', ...
                    '"Loads.inclinationValue". This is not allowed.'], abortOnError = false);
            end

            if doChecksForUls && ~hasUlsInput
                Obj.Logger.error(['Input block "Loads." or "ULS_BENDING_MOMENT" must be specified in order ', ...
                  'to assess ULS (related) design criteria.'], abortOnError = false);
            end

            if ~doChecksForUls && hasUlsInput
                Obj.Logger.warning(['Input "Loads.ulsFilePath" or "ULS_BENDING_MOMENT" is specified, but ', ...
                    'expert input "DO_ASSESS_ULS" is set to false.\n\t==> ULS loads will not be loaded.']);
            end

            if ~doChecksForUls && hasLoadsInclination
                Obj.Logger.warning(['Input "Loads.inclinationValue" is specified, but no ULS (related) design ', ...
                    'criteria are enabled\n\t==> Input will be ignored.']);
            end

        end

        function check_strmdl_inclination_angle(Obj)
            % If structuralModel is not defined, and an inclination value is set, give warning

            if ~isempty(Obj.Inputs.structureInpFilePath)
                return
            end

            if any(abs(Obj.Inputs.Loads.inclinationValue) > 1e-6) || ...
                any(abs(Obj.Inputs.Loads.inclinationValueFls) > 1e-6)
                Obj.Logger.warning(['Insufficient inputs to compute inclination loads ', ...
                    '(empty input "structureInpFilePath").\n', ...
                    '\t==> Continuing without inclination loads.']);
            end

        end

        function check_inclination_moment_fls_override(Obj)
            % Error if expert input INCLINATION_MOMENT_FLS is provided together with non-zero value(s) for
            % Loads.inclinationValueFls.
            hasInclinationOverride = ~isnan(Obj.Inputs.INCLINATION_MOMENT_FLS);
            hasLoadsInclination = any(~isnan(Obj.Inputs.Loads.inclinationValueFls));
            if hasInclinationOverride && hasLoadsInclination
                Obj.Logger.error(['Expert input "INCLINATION_MOMENT_FLS" is set in combination with ', ...
                    '"Loads.inclinationValueFls". This is not allowed.'], abortOnError = false);
            end
        end

        function check_inclination_values_expected(Obj)
            % Warn if FLS inclination values are not equal to 0.125 deg, or 0. These are the options (for OF and ON,
            % respectively) according to IEC61400-6/AMD1.
            isExpectedValue = ...
                (abs(Obj.Inputs.Loads.inclinationValueFls - deg2rad(0.125)) < 1e-6) | ...
                (abs(Obj.Inputs.Loads.inclinationValueFls) < 1e-6);
            if any(~isExpectedValue)
                Obj.Logger.warning([ ...
                    'For load set(s) %s, an unexpected value for "Loads.inclinationValueFls" is input.\n', ...
                    'Expected values are either 0.125 deg, or 0.'], ...
                    join("#" + string(find(~isExpectedValue)), " and "));
            end
        end

        function check_inclination_values_order(Obj)
            % Warn if FLS inclination is greater than the inclination considered for other conditions (ULS, SLS)
            isExpectedOrder = Obj.Inputs.Loads.inclinationValueFls <= Obj.Inputs.Loads.inclinationValue;
            if any(~isExpectedOrder)
                Obj.Logger.warning([ ...
                    'For load set(s) %s, "Loads.inclinationValueFls" is greater than "Loads.inclinationValue".\n', ...
                    'This is unexpected.'], ...
                    join("#" + string(find(~isExpectedOrder)), " and "));
            end
        end

        function check_nose_heights_ge_min_height(Obj)
            % Verify that heightNose(Up|Lo) >= MIN_NOSE_HEIGHT
            varNames = {'heightNoseLo', 'heightNoseUp'};
            for var = varNames
                pass = ~(Obj.Inputs.(var{1}) < Obj.Inputs.MIN_NOSE_HEIGHT);

                if ~pass
                    Obj.Logger.error('Input "%s" must be >= input "MIN_NOSE_HEIGHT".', ...
                      var{1}, abortOnError = false);
                end
            end
        end

        function check_bolt_holes(Obj)
            % Group checks related to bolt holes
            Obj.check_default_hole_diameter();
            Obj.check_bolt_holes_bolts_fit();
        end

        function check_default_hole_diameter(Obj)
            %  Issue warning if non-default bolt hole diameter is input
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            Lib = usain.fastener.CatalogLibrary.get_library();
            defaultBoltHoleDiam = cellfun(@(x) Lib.Fasteners.select('label', x).get_default('boltHoleDiam'), ...
                BoltOpts.label);
            isNondef = abs(Obj.Inputs.diamBoltHole - defaultBoltHoleDiam) > 1e-6; % Skips NaNs
            if any(isNondef)
                warnStr = arrayfun(@(opt, def, inp) sprintf(['\n\t- For bolt option %s, ', ....
                    'default value is %gmm (input is %gmm)'], opt{1}, 1e3 * def, 1e3 * inp), ...
                    BoltOpts.label(isNondef), defaultBoltHoleDiam(isNondef), Obj.Inputs.diamBoltHole(isNondef), ...
                    'uni', 0);
                Obj.Logger.warning(['Non-default values for input "diamBoltHole" found:', ...
                    warnStr{:}, '\n\n']);
            end
        end

        function check_bolt_holes_bolts_fit(Obj)
            % Check if bolt hole diameter is large enough to fit a bolt (without considering tolerances)
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            diamBolts = 1e-3 * str2double(regexpi(BoltOpts.label, '(?<=^\w+_M)\d+', 'match', 'once'));
            isNofit = Obj.Inputs.diamBoltHole <= diamBolts; % Skips NaNs
            if any(isNofit)
                warnStr = arrayfun(@(opt, inp) sprintf(['\n\t- For bolt option %s, ', ....
                    'the input value is too small (%gmm).'], opt{1}, 1e3 * inp), ...
                    BoltOpts.label(isNofit), Obj.Inputs.diamBoltHole(isNofit), 'uni', 0);
                Obj.Logger.warning(['One or more values for input "diamBoltHole" seem incorrect:', ...
                    warnStr{:}, '\n\n']);
            end
        end

        function check_hv_bolts_provided(Obj)
            % Issue warning HV bolt is input
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            isHvLabel = startsWith(BoltOpts.label, 'HV');
            if any(contains(BoltOpts.label, 'HV_M36'))
                Obj.Logger.warning([ ...
                    'HV_M36 bolts detected!\n\n', ...
                    'Note that HV bolts are not a preferred option!\n', ...
                    '\tISO studs are the preferred solution!\n', ...
                    '\t==> Only use HV_M36 to check old (onshore) flange designs.\n\n']);
            elseif any(isHvLabel)
                Obj.Logger.warning(['One or more inputs for "boltOptions" define HV bolts.\n', ...
                  '\tISO studs are the preferred solution!']);
            end
        end

        function check_valid_hv_bolt_length(Obj)
            % Check if the provided length is also in the DASt table3a

            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            isHvLabel = startsWith(BoltOpts.label, 'HV');
            if ~any(isHvLabel)
                return
            end

            % Check, if provided, that the bolt length is part of the DASt table.
            for iOpt = 1:BoltOpts.nOptions
                if ~isHvLabel(iOpt) || isnan(BoltOpts.inputBoltLength(iOpt))
                    continue
                else

                    boltSize = usain.fastener.BoltOptionsParser(BoltOpts.label{iOpt}).boltSizeString;
                    dastData = usain.fastener.DastHvLengthData.get_dast3a_data_for_bolt_size(boltSize);
                    isInTable = any(abs(dastData(:, 1) - BoltOpts.inputBoltLength(iOpt)) < 1e-6);

                    if ~isInTable
                        Obj.Logger.error(['One or more inputs for HV bolt length is not an option according to ', ...
                            'the table 3a in DASt. This is not allowed'], abortOnError = false);
                        return % A single violation is sufficient
                    end
                end
            end

        end

        function check_hv_bolts_do_assess_thread_requirement_combination(Obj)
            % Check that for HV bolts DO_ASSESS_THREAD_REQ is disabled, these requirements are not applicable for HV
            % bolts.

            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            isHvLabel = startsWith(BoltOpts.label, 'HV');

            if any(isHvLabel) && Obj.Inputs.DO_ASSESS_BOLT_THREAD_REQ
                warnStr = ['HV bolts provided in inputs and DO_ASSESS_BOLT_THREAD_REQ is set to true.\n', ...
                    'These requirements are not representative for HV bolts, since they are selected and/or ', ...
                    'checked according to DASt Ri 021 Table 3a.'];
                Obj.Logger.warning(warnStr);
            end

        end

        function check_hv_bolts_bolt_extenders_combination(Obj)
            % Check that for HV bolts bolt extenders are disabled, i.e. lengthBoltExtender = 0

            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            isHvLabel = startsWith(BoltOpts.label, 'HV');

            if ~any(isHvLabel)
                return
            end

            hasExtender = ~(Obj.Inputs.lengthBoltExtender < 1e-6);

            if any(hasExtender & isHvLabel)
                warnStr = ['HV bolts provided in inputs and bolt extenders are enable.\n', ...
                    'This configuration is not recommended for HV bolts.\n', ...
                    'Only use HV bolts with bolt extenders to check old (onshore) flange designs.'];
                Obj.Logger.warning(warnStr);
            end

        end

        function check_iso_m36_provided(Obj)
            % Temporarily throw a big fat warning if ISO_M36 bolts are selected
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            if any(contains(BoltOpts.label, 'ISO_M36'))
                Obj.Logger.warning([ ...
                    'ISO_M36 studs detected!\n\n', ...
                    'Note that the properties of M36 fastener components are not finalized and may contain rough assumptions.\n', ...  % mh:ignore_style
                    'The known assumptions/limitations are:\n', ...
                    '- Thin-walled socket dimensions are extrapolated from smaller sizes.\n', ...
                    '- The tensioner tool dimensions are not finalized.\n', ...
                    '- The assembly value and preload are not finalized.', ...
                    '- Cost and mass of ISO_M36 based on extrapolation\n', ...
                    '- This list is not complete!\n\n', ...
                    '\t==> Only use ISO_M36 if this has been discussed with topic owners\n\n']);
            end
        end

        function check_iso_m39_provided(Obj)
            % Temporarily throw a big fat warning if ISO_M39 bolts are selected
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            if any(contains(BoltOpts.label, 'ISO_M39'))
                Obj.Logger.warning([ ...
                    'ISO_M39 studs detected!\n\n', ...
                    'Note that the properties of M39 fastener components are not finalized and may contain rough assumptions.\n', ...  % mh:ignore_style
                    'The known assumptions/limitations are:\n', ...
                    '- Thin-walled socket dimensions are extrapolated from smaller sizes.\n', ...
                    '- The tensioner tool dimensions are not finalized.\n', ...
                    '- The assembly value and preload are not finalized.', ...
                    '- Cost and mass of ISO_M39 based on extrapolation\n', ...
                    '- This list is not complete!\n\n', ...
                    '\t==> Only use ISO_M39 if this has been discussed with topic owners\n\n']);
            end
        end

        function check_iso_m90_provided(Obj)
            % Temporarily throw a big fat warning if ISO_M90 bolts are selected
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            if any(contains(BoltOpts.label, 'ISO_M90'))
                Obj.Logger.warning([ ...
                    'ISO_M90 studs detected!\n\n', ...
                    'Note that the properties of M90 fastener components are not finalized and may contain rough assumptions.\n', ...  % mh:ignore_style
                    'The known assumptions/limitations are:\n', ...
                    '- Thin-walled socket dimensions are extrapolated from smaller sizes.\n', ...
                    '- The tensioner tool dimensions are not finalized.\n', ...
                    '- Maximum allowed stud length is unknown.\n', ...
                    '- Cost and mass of ISO_M90 based on extrapolation\n', ...
                    '- This list is not complete!\n\n', ...
                    '\t==> Only use ISO_M90 if this has been discussed with topic owners\n\n']);
            end
        end

        function check_iso_m100_provided(Obj)
            % Temporarily throw a big fat warning if ISO_M100 bolts are selected
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            if any(contains(BoltOpts.label, 'ISO_M100'))
                Obj.Logger.warning([ ...
                    'ISO_M100 studs detected!\n\n', ...
                    'Note that the properties of M100 fastener components are not finalized and may contain rough assumptions.\n', ...  % mh:ignore_style
                    'The known assumptions/limitations are:\n', ...
                    '- Thin-walled socket dimensions are extrapolated from smaller sizes.\n', ...
                    '- The tensioner tool dimensions are not finalized.\n', ...
                    '- Maximum allowed stud length is unknown.\n', ...
                    '- Cost and mass of ISO_M100 based on extrapolation\n', ...
                    '- This list is not complete!\n\n', ...
                    '\t==> Only use ISO_M100 if this has been discussed with topic owners\n\n']);
            end
        end

        function check_iso_tightening_method_site_combination(Obj)
            % For onshore ISO studs torque tightening is available in the bolts catalogue and is:
            % - allowed (and default) for temporary stages
            % - not allowed for installation --> this in this function
            isOnshore = strcmpi(Obj.Inputs.site, 'onshore');
            if ~isOnshore
                return
            end

            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            for i = 1:BoltOpts.nOptions
                boltLabel = BoltOpts.label{i};
                isIso = startsWith(boltLabel, 'ISO');
                isTorque = strcmpi(Obj.Inputs.tighteningMethod{i}, 'torque');
                if isTorque && isIso
                    Obj.Logger.error(['Input site is set to "onshhore" and TIGHTENING_METHOD is set to "torque"', ...
                        ' for %s studs. This combination is not allowed.'], boltLabel, abortOnError = false);
                end
            end
        end

        function check_bolt_sn_curves(Obj)
            % Throw error if S-N curve is not from Eurocode, i.e. in format EC3_DC**
            isEc3Label = startsWith([Obj.Inputs.BoltFls.SN_CURVE_BOLT], "EC3_DC");
            if ~all(isEc3Label)
                Obj.Logger.error( ...
                    'All S-N curves defined for bolts must be Eurocode S-N curves, i.e. in format EC3_DC**.', ...
                    abortOnError = false);
            end
        end

        function check_thickness_tolerance_allowance_combination(Obj)
            if any(Obj.Inputs.TOL_FLANGE_THICKNESS_MINUS > ...
                    [Obj.Inputs.ALW_UPPER_FLANGE_THICKNESS, Obj.Inputs.ALW_LOWER_FLANGE_THICKNESS])
                Obj.Logger.error(['Input "TOL_FLANGE_THICKNESS_MINUS" is larger than the allowance(s).\n', ...
                    'This is not allowed!'], abortOnError = false);
            end
        end

        function check_active_design_conditions(Obj)
            % Warn if none of the condition toggles are active in the input file (i.e. the DO_ASSESS_* inputs), because
            % that is a weird setup (but technically possible).
            toggles = UsainUtils.ICondition.CONDITION_CLASS_NAMES;
            hasActiveCondition = any(cellfun(@(x) Obj.Inputs.(x), toggles));
            if ~hasActiveCondition
                Obj.Logger.warning(['None of the condition toggles (i.e. the DO_ASSESS_* inputs) are enabled. ', ...
                    'USAIN will run, but the results will not guarantee a feasible flange design.']);
            end
        end

        function check_fls_schmidtneuper_model_combination(Obj)
            % Warn if there is an unexpected combination of inputs regarding FLS assessment with SchmidtNeuper
            isSchmidtNeuper = any([Obj.Inputs.BoltFls.BOLT_FORCE_MODEL] == "schmidtneuper");

            if Obj.Inputs.DO_ASSESS_FLS
                if xor(Obj.Inputs.DO_ASSESS_SCHMIDTNEUPER_APT, isSchmidtNeuper)
                    Obj.Logger.warning(['FLS will be assessed. The provided inputs indicate that SchmidtNeuper ', ...
                        'is applicable.\nIn that case it is expected that both DO_ASSESS_SCHMIDTNEUPER_APT = true ', ...
                        'and at least one BoltFls.BOLT_FORCE_MODEL = schmidtneuper']);
                end
            else
                if Obj.Inputs.DO_ASSESS_SCHMIDTNEUPER_APT || isSchmidtNeuper
                    Obj.Logger.warning(['FLS will not be assessed. In that case it is expected that input ', ...
                        'DO_ASSESS_SCHMIDTNEUPER_APT = false and that there is no BoltFls.BOLT_FORCE_MODEL defined.']);
                end
            end

        end

        function check_scaling_reference_levels(Obj)
            % scalingLevels are not allowed to contain reference levels if no StrMdl is provided
            if isempty(Obj.Inputs.structureInpFilePath)

                nLoadSets = length(Obj.Inputs.Loads.ulsScalingLevel);
                varNames = {'ulsScalingLevel', 'flsScalingLevel'};

                for i = 1:nLoadSets
                    for var = varNames
                        varName = var{1};
                        scalingLevel = Obj.Inputs.Loads.(varName){i};

                        isAllNumeric = all(cellfun(@(x) isnumeric(x), scalingLevel));
                        if ~isAllNumeric
                            Obj.Logger.error(['Loads(%i).%s are not all numbers. If you want to input reference ', ...
                                'levels (like "towerTop"), you need to provide a Structural Model.'], ...
                                i, varName, abortOnError = false);
                        end
                    end
                end
            end
        end

        function check_uls_bolt_diameter_selection_requirement(Obj)
            % Check input combinations when BOLT_DIAMETER_SELECTION is set to "uls"

            % Warn if ULS-based bolt diameter selection is enabled, but no ULS assessment is done
            if strcmpi(Obj.Inputs.BOLT_DIAMETER_SELECTION, "uls") && ~Obj.Inputs.DO_ASSESS_ULS
                Obj.Logger.warning([ ...
                    'Input "BOLT_DIAMETER_SELECTION" is set to "uls", but "DO_ASSESS_ULS" is disabled.\n', ...
                    '\t==> Input will be ignored.']);
            end

            % Warn if ULS-based bolt diameter selection is enabled, but DO_UPDATE_DESIGN_SPACE is disabled
            if strcmpi(Obj.Inputs.BOLT_DIAMETER_SELECTION, "uls") && ~Obj.Inputs.DO_UPDATE_DESIGN_SPACE
                Obj.Logger.warning([ ...
                    'Input "BOLT_DIAMETER_SELECTION" is set to "uls", but "DO_UPDATE_DESIGN_SPACE" is disabled.\n', ...
                    '\t==> Input will be ignored.']);
            end

        end

        function check_mixed_bolt_series(Obj)
            % Error if ULS-based bolt diameter selection is enabled, and multiple bolt series are input
            BoltOptions = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            uniqueSeries = string(unique(extractBefore(BoltOptions.label, '_')));
            if strcmpi(Obj.Inputs.BOLT_DIAMETER_SELECTION, "uls") && length(uniqueSeries) > 1
                Obj.Logger.error([ ...
                    'It is not allowed to set input "BOLT_DIAMETER_SELECTION" to "uls" and ', ...
                    'select multiple bolt series (%s).'], uniqueSeries.join(', '), ...
                    abortOnError = false);
            end
        end

        function check_diam_bolt_circle_b_min_combination(Obj)
            % Warn if both diamBoltCircle and B_MIN are set in the inputs
            hasDiamBoltCircle = any(~isnan(Obj.Inputs.diamBoltCircle));
            hasBMin = any(~isnan(Obj.Inputs.B_MIN));

            if hasDiamBoltCircle && hasBMin
                Obj.Logger.warning(['Both inputs "diamBoltCircle" and "B_MIN" are set.\n', ...
                    'USAIN will design the flange with the provided value for "diamBoltCircle"!\n', ...
                    'Potentially violating the criteria from "B_MIN".']);
            end
        end

    end

end
