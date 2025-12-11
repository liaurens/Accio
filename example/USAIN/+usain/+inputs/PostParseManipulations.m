classdef PostParseManipulations < logging.Loggable

    properties
        Inputs
    end

    methods

        function Obj = PostParseManipulations(varargin)
            Obj = assign_varargin_2_classprop(Obj, varargin{:});
        end

        function ManipulatedInputs = run(Obj)
            Obj.replace_run_name_whitespaces();
            Obj.assign_conditional_input_defaults();
            Obj.convert_to_enum_members();
            Obj.convert_to_cells_of_strings();
            Obj.convert_loads_block_inputs_to_cells();
            Obj.enforce_toggles_to_logical();
            Obj.expand_design_variables();
            Obj.assign_default_nut_type();
            Obj.convert_inputs_to_si_units();
            Obj.run_t_flange_manipulations();

            ManipulatedInputs = Obj.Inputs;
        end

        function run_t_flange_manipulations(Obj)
            % This method collects all manipulations applicable for T-flanges and is used in both
            % the run() method of this class and in usain.io.UpdateInputsForTFlangeStep.
            Obj.update_stepsize_width_for_t_flange();
        end

        function replace_run_name_whitespaces(Obj)
            Obj.Inputs.runName = regexprep(Obj.Inputs.runName, '\s', '_');
        end

        function assign_conditional_input_defaults(Obj)
            Obj.assign_default_bolt_extender_length();
            Obj.assign_default_bolt_youngs_modulus();
            Obj.assign_default_flange_youngs_modulus();
            Obj.assign_default_flange_steel_type();
            Obj.assign_default_bolt_resistance_jpn();
            Obj.assign_default_bolt_resistance_jpn_tag();
            Obj.assign_default_do_assess_uls();
            Obj.assign_default_do_assess_uls_jpn();

            % Manipulate `Inputs.BoltFls`
            Obj.Inputs.BoltFls = usain.inputs.BoltFlsInputBlock(Obj.Inputs.BoltFls).process_input_block();
        end

        function assign_default_bolt_extender_length(Obj)
            doAssignDefault = isnan(Obj.Inputs.lengthBoltExtender);
            if doAssignDefault
                Obj.Inputs.lengthBoltExtender = usain.inputs.get_default_bolt_extender_length(Obj.Inputs.countryCode);
            end
        end

        function assign_default_bolt_youngs_modulus(Obj)
            doAssignDefault = isnan(Obj.Inputs.E_BOLT);
            if doAssignDefault
                Obj.Inputs.E_BOLT = usain.inputs.get_default_bolt_youngs_modulus(Obj.Inputs.countryCode);
            end
        end

        function assign_default_flange_youngs_modulus(Obj)
            doAssignDefault = isnan(Obj.Inputs.E_FLANGE);
            if doAssignDefault
                Obj.Inputs.E_FLANGE = usain.inputs.get_default_flange_youngs_modulus(Obj.Inputs.countryCode);
            end
        end

        function assign_default_flange_steel_type(Obj)
            doAssignDefault = isempty(Obj.Inputs.FLANGE_STEEL_TYPE);
            if doAssignDefault
                Obj.Inputs.FLANGE_STEEL_TYPE = usain.inputs.get_default_flange_steel_type(Obj.Inputs.countryCode);
            end
        end

        function assign_default_bolt_resistance_jpn(Obj)
            doAssignDefault = isnan(Obj.Inputs.PSF_BOLT_RESISTANCE_JPN);
            if doAssignDefault
                Obj.Inputs.PSF_BOLT_RESISTANCE_JPN = ...
                    usain.inputs.get_default_bolt_resistance_jpn(Obj.Inputs.countryCode);
            end
        end

        function assign_default_bolt_resistance_jpn_tag(Obj)
            doAssignDefault = isempty(Obj.Inputs.PSF_BOLT_RESISTANCE_JPN_TAG);
            if doAssignDefault
                Obj.Inputs.PSF_BOLT_RESISTANCE_JPN_TAG = ...
                    usain.inputs.get_default_bolt_resistance_jpn_tag(Obj.Inputs.countryCode);
            end
        end

        function assign_default_do_assess_uls(Obj)
            doAssignDefault = isnan(Obj.Inputs.DO_ASSESS_ULS);
            if doAssignDefault
                Obj.Inputs.DO_ASSESS_ULS = usain.inputs.get_default_do_assess_uls(Obj.Inputs.countryCode);
            end
        end

        function assign_default_do_assess_uls_jpn(Obj)
            doAssignDefault = isnan(Obj.Inputs.DO_ASSESS_ULS_JPN);
            if doAssignDefault
                Obj.Inputs.DO_ASSESS_ULS_JPN = usain.inputs.get_default_do_assess_uls_jpn(Obj.Inputs.countryCode);
            end
        end

        function convert_to_enum_members(Obj)
            Obj.Inputs.site = usain.inputs.Site(Obj.Inputs.site);
        end

        function convert_to_cells_of_strings(Obj)
            Obj.Inputs.boltOptions = cellstr(Obj.Inputs.boltOptions);
            Obj.Inputs.tighteningMethod = cellstr(Obj.Inputs.tighteningMethod);
            Obj.Inputs.NUT_TYPE = cellstr(Obj.Inputs.NUT_TYPE);
            Obj.Inputs.TIGHTENING_SIDE_INSTALLATION = cellstr(Obj.Inputs.TIGHTENING_SIDE_INSTALLATION);
            Obj.Inputs.TIGHTENING_SIDE_TEMP_STAGES = cellstr(Obj.Inputs.TIGHTENING_SIDE_TEMP_STAGES);
        end

        function convert_loads_block_inputs_to_cells(Obj)
            % Force Loads.* to be cell of strings, for uniform handling
            Obj.Inputs.Loads.flsFilePath = cellstr(Obj.Inputs.Loads.flsFilePath);
            Obj.Inputs.Loads.S1FilePath = cellstr(Obj.Inputs.Loads.S1FilePath);
            Obj.Inputs.Loads.ulsFilePath = cellstr(Obj.Inputs.Loads.ulsFilePath);
            Obj.Inputs.Loads.dlcFilter = cellstr(Obj.Inputs.Loads.dlcFilter);
            Obj.Inputs.Loads.tag = cellstr(Obj.Inputs.Loads.tag);
            Obj.Inputs.Loads.inclinationUnit = cellstr(Obj.Inputs.Loads.inclinationUnit);
            Obj.Inputs.Loads.ALIGN_AT = cellstr(Obj.Inputs.Loads.ALIGN_AT);

            % Force Loads.ALIGN_AT to be of the same length as the number of load blocks
            nLoadsAlignAt = length(Obj.Inputs.Loads.ALIGN_AT);
            nUlsFilePath = length(Obj.Inputs.Loads.ulsFilePath);
            if nLoadsAlignAt == 1 && nUlsFilePath > 1 %#ok<ISCL>
                Obj.Inputs.Loads.ALIGN_AT = repmat(Obj.Inputs.Loads.ALIGN_AT, 1, nUlsFilePath);
            end

            Obj.Inputs.Loads.flsScalingFactor = inpfilehelper.wrap_row_in_cell(Obj.Inputs.Loads.flsScalingFactor);
            Obj.Inputs.Loads.S1ScalingFactor = inpfilehelper.wrap_row_in_cell(Obj.Inputs.Loads.S1ScalingFactor);
            Obj.Inputs.Loads.ulsScalingFactor = inpfilehelper.wrap_row_in_cell(Obj.Inputs.Loads.ulsScalingFactor);

            Obj.Inputs.Loads.flsScalingLevel = inpfilehelper.wrap_row_in_cell(Obj.Inputs.Loads.flsScalingLevel, true);
            Obj.Inputs.Loads.S1ScalingLevel = inpfilehelper.wrap_row_in_cell(Obj.Inputs.Loads.S1ScalingLevel, true);
            Obj.Inputs.Loads.ulsScalingLevel = inpfilehelper.wrap_row_in_cell(Obj.Inputs.Loads.ulsScalingLevel, true);
        end

        function enforce_toggles_to_logical(Obj)
            Obj.Inputs.DO_ASSESS_BOLT_PLASTICITY = logical(Obj.Inputs.DO_ASSESS_BOLT_PLASTICITY);
            Obj.Inputs.DO_ASSESS_BOLT_THREAD_REQ = logical(Obj.Inputs.DO_ASSESS_BOLT_THREAD_REQ);
            Obj.Inputs.DO_ASSESS_FLANGE_NECK_SCF = logical(Obj.Inputs.DO_ASSESS_FLANGE_NECK_SCF);
            Obj.Inputs.DO_ASSESS_FLANGE_PLASTICITY = logical(Obj.Inputs.DO_ASSESS_FLANGE_PLASTICITY);
            Obj.Inputs.DO_ASSESS_FLS = logical(Obj.Inputs.DO_ASSESS_FLS);
            Obj.Inputs.DO_ASSESS_GAPPING = logical(Obj.Inputs.DO_ASSESS_GAPPING);
            Obj.Inputs.DO_ASSESS_SCHMIDTNEUPER_APT = logical(Obj.Inputs.DO_ASSESS_SCHMIDTNEUPER_APT);
            Obj.Inputs.DO_ASSESS_SLS_PRETENSION = logical(Obj.Inputs.DO_ASSESS_SLS_PRETENSION);
            Obj.Inputs.DO_ASSESS_ULS = logical(Obj.Inputs.DO_ASSESS_ULS);
            Obj.Inputs.DO_ASSESS_ULS_JPN = logical(Obj.Inputs.DO_ASSESS_ULS_JPN);
            Obj.Inputs.DO_SAVE_FULL_FILE = logical(Obj.Inputs.DO_SAVE_FULL_FILE);
            Obj.Inputs.DO_TRIM_DESIGN_SPACE = logical(Obj.Inputs.DO_TRIM_DESIGN_SPACE);
            Obj.Inputs.DO_UPDATE_DESIGN_SPACE = logical(Obj.Inputs.DO_UPDATE_DESIGN_SPACE);
            Obj.Inputs.DOOR_SEGMENT.DO_INCLUDE = logical(Obj.Inputs.DOOR_SEGMENT.DO_INCLUDE);
            Obj.Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS = logical(Obj.Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS);  % mh:ignore_style
            Obj.Inputs.IGNORE_BOLT_EXTENDER = logical(Obj.Inputs.IGNORE_BOLT_EXTENDER);
            Obj.Inputs.PLOT_STRESS_PATHS = logical(Obj.Inputs.PLOT_STRESS_PATHS);
            Obj.Inputs.PLOT_STRESS_TRANSFER_FUNCS = logical(Obj.Inputs.PLOT_STRESS_TRANSFER_FUNCS);
            Obj.Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS = logical(Obj.Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS);
        end

        function expand_design_variables(Obj)
            % For all Inputs values defined below, it is allowed to:
            % - Specify one value when n `boltOptions` are defined.
            %   The value will be expanded in this method.
            % - Specify n values when n `boltOptions` are defined.
            % Any other combination will error (like 2 values for `boltOptions` and 3 values for `diamBoltCircle`)
            % The given inputs are checked in usain.inputs.PostParseChecks in the check_amount_of_bolt_options
            % function.

            nInputBolts = numel(Obj.Inputs.boltOptions);
            varNames = {'minFlangeWidth', 'maxFlangeWidth', 'minFlangeThickn', 'maxFlangeThickn', ...
                'minNBolts', 'maxNBolts', 'diamBoltHole' 'diamBoltCircle', 'TOOL_DIMENSION_CIRC_DIR', ...
                'TOOL_DIMENSION_RADIAL_DIR', 'lengthBoltExtender', 'tighteningMethod', 'NUT_TYPE', ...
                'CUSTOM_WASHER_DIAM_INNER', 'CUSTOM_WASHER_DIAM_OUTER', 'CUSTOM_WASHER_THICKNESS', ...
                'FlangeGapping.CUSTOM_PRELOAD', 'SlsPretension.CUSTOM_PRELOAD', 'FlangeNeckScf.CUSTOM_PRELOAD', ...
                'TIGHTENING_SIDE_INSTALLATION', 'TIGHTENING_SIDE_TEMP_STAGES', 'SECONDARY_HOLES_BCD', ...
                'SECONDARY_HOLES_DIAMETER', 'B_MIN'};
            for var = varNames
                thisValue = getsubfield(Obj.Inputs, var{1});
                if length(thisValue) == 1 %#ok<ISCL>
                    if ~iscellstr(thisValue)  %#ok - suggestion is not applicable here
                        expandedValue = ones(1, nInputBolts) * thisValue;
                    else
                        expandedValue = repmat(thisValue, 1, nInputBolts);
                    end
                    Obj.Inputs = setsubfield(Obj.Inputs, var{1}, expandedValue);
                end
            end

            % Do the same for the subfield `Inputs.BoltFls.CUSTOM_PRELOAD`. Different logic because `Inputs.BoltFls` may
            % be an array of structs.
            Obj.Inputs.BoltFls = inpfilehelper.split_input_blocks(Obj.Inputs.BoltFls);

            nBoltFls = length(Obj.Inputs.BoltFls);
            for iBoltFls = 1:nBoltFls
                if length(Obj.Inputs.BoltFls(iBoltFls).CUSTOM_PRELOAD) == 1 %#ok<ISCL>
                    Obj.Inputs.BoltFls(iBoltFls).CUSTOM_PRELOAD = ...
                        ones(1, nInputBolts) * Obj.Inputs.BoltFls(iBoltFls).CUSTOM_PRELOAD;
                end
            end
        end

        function assign_default_nut_type(Obj)
            % Assign default(s) for NUT_TYPE
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            defaultNuts = usain.inputs.get_default_nut_type(BoltOpts.label, Obj.Inputs.tighteningMethod);
            doReplaceDefault = cellfun(@isempty, Obj.Inputs.NUT_TYPE);
            Obj.Inputs.NUT_TYPE(doReplaceDefault) = defaultNuts(doReplaceDefault);
        end

        function convert_inputs_to_si_units(Obj)
            Schema = usain.inputs.get_schema();
            Obj.Inputs = inpfilehelper.convert_to_si_units(Schema, Obj.Inputs);

            % Convert SGRE2.FLANGE_TILT_VALUE using user-specified units
            value = Obj.Inputs.SGRE2.FLANGE_TILT_VALUE;
            unit = Unit(Obj.Inputs.SGRE2.FLANGE_TILT_UNIT);
            Obj.Inputs.SGRE2.FLANGE_TILT_VALUE = unit.to_si(value);

            % Convert inclinationValue using user-specified units
            for i = 1:length(Obj.Inputs.Loads.inclinationValue)
                value = Obj.Inputs.Loads.inclinationValue(i);
                unit = Unit(Obj.Inputs.Loads.inclinationUnit{i});
                Obj.Inputs.Loads.inclinationValue(i) = unit.to_si(value);
            end

            % Convert inclinationValueFls using user-specified units
            for i = 1:length(Obj.Inputs.Loads.inclinationValueFls)
                value = Obj.Inputs.Loads.inclinationValueFls(i);
                unit = Unit(Obj.Inputs.Loads.inclinationUnit{i});
                Obj.Inputs.Loads.inclinationValueFls(i) = unit.to_si(value);
            end
        end

        function update_stepsize_width_for_t_flange(Obj)
            % Note that this method is executed after convert_inputs_to_si_units() so STEPSIZE_WIDTH is in m.
            stepsize_width_mm = Unit.mm.from_si(Obj.Inputs.STEPSIZE_WIDTH);
            if Obj.Inputs.flangeType == usain.inputs.FlangeType.T && mod(stepsize_width_mm, 2) ~= 0
                % Round stepsize_width_mm to the next even number
                % This is required for T-flange designs, as the flange width must be even
                Obj.Inputs.STEPSIZE_WIDTH = Unit.mm.to_si(ceil(stepsize_width_mm / 2) * 2);
                Obj.Logger.info(['Input "STEPSIZE_WIDTH" should be even for a T-flange design. ', ...
                    'Value has been updated to: %0.0f mm'], Unit.mm.from_si(Obj.Inputs.STEPSIZE_WIDTH));
            end
        end

    end

end
