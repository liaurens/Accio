classdef BoltFlsInputBlock < logging.Loggable
    % Class representation of the BoltFls input block, able to assign default values and convert to convenient data
    % formats.

    properties
        InputsBlock struct
        LogHandler logging.CellArrayHandler
    end

    methods

        function Obj = BoltFlsInputBlock(InputsBlock)

            arguments
                InputsBlock struct
            end

            Obj.InputsBlock = InputsBlock;

            Obj.LogHandler = logging.CellArrayHandler();
            Obj.Logger.add_handler(Obj.LogHandler);
        end

        function ManipulatedInputsBlock = process_input_block(Obj)

            % NOTE: The input `InputsBlock` will be in the "non-manipulated inputs" InputFile data formats.
            % First, convert these to convenient formats. Then, assign default values.
            ConvertedInputsBlock = Obj.convert_to_string(Obj.InputsBlock);
            ManipulatedInputsBlock = Obj.assign_conditional_defaults(ConvertedInputsBlock);
        end

        function InputsBlock = convert_to_string(~, InputsBlock)
            InputsBlock.BOLT_FORCE_MODEL = string(InputsBlock.BOLT_FORCE_MODEL);
            InputsBlock.SN_CURVE_BOLT = string(InputsBlock.SN_CURVE_BOLT);
        end

        function InputsBlock = assign_conditional_defaults(Obj, InputsBlock)
            % Assigns conditionally default values, i.e. defaults for fields that depend on other input fields.
            % The input `InputsBlock` is expected to be converted to convenient data formats.

            InputsBlock = Obj.assign_default_thickness_exponent(InputsBlock);
            InputsBlock = Obj.assign_default_psf(InputsBlock);
            InputsBlock = Obj.assign_default_sn_curve(InputsBlock);
        end

        function InputsBlock = assign_default_thickness_exponent(Obj, InputsBlock)
            % Default thickness exponent for non-sgre2 models is 0.25.
            % Set this value, unless the user has set an override value in the input file.

            isSgre2 = strcmpi(InputsBlock.BOLT_FORCE_MODEL, "sgre2");
            hasUserInput = ~isnan(InputsBlock.THICKNESS_EXPONENT_BOLT);

            % Log a warning message if:
            % 1. sgre2 model is combined with a user input for THICKNESS_EXPONENT_BOLT
            % 2. non-sgre2 model is combined with a user input for THICKNESS_EXPONENT_BOLT that is not 0.25
            isNonDefault = ...
                (hasUserInput & isSgre2) | ...
                (abs(InputsBlock.THICKNESS_EXPONENT_BOLT - 0.25) > 1e-6 & ~isSgre2);
            Obj.log_nondefault(isNonDefault, "THICKNESS_EXPONENT_BOLT", string(InputsBlock.THICKNESS_EXPONENT_BOLT));

            % Assign default
            InputsBlock.THICKNESS_EXPONENT_BOLT(~hasUserInput & ~isSgre2) = 0.25;
        end

        function InputsBlock = assign_default_psf(Obj, InputsBlock)
            % Default PSF is 1.10 for sgre2, and 1.25 for all other models.
            % Set this value, unless the user has set an override value in the input file.

            isSgre2 = strcmpi(InputsBlock.BOLT_FORCE_MODEL, "sgre2");
            hasUserInput = ~isnan(InputsBlock.PSF_BOLT_MATERIAL_FLS);

            % Log a warning message if:
            % 1. sgre2 model is combined with a user input for PSF_BOLT_MATERIAL_FLS that is not 1.10
            % 2. non-sgre2 model is combined with a user input for PSF_BOLT_MATERIAL_FLS that is not 1.25
            isNonDefault = ...
                (abs(InputsBlock.PSF_BOLT_MATERIAL_FLS - 1.10) > 1e-6 & isSgre2) | ...
                (abs(InputsBlock.PSF_BOLT_MATERIAL_FLS - 1.25) > 1e-6 & ~isSgre2);
            Obj.log_nondefault(isNonDefault, "PSF_BOLT_MATERIAL_FLS", string(InputsBlock.PSF_BOLT_MATERIAL_FLS));

            % Assign default
            InputsBlock.PSF_BOLT_MATERIAL_FLS(~hasUserInput & ~isSgre2) = 1.25;
            InputsBlock.PSF_BOLT_MATERIAL_FLS(~hasUserInput & isSgre2) = 1.10;
        end

        function InputsBlock = assign_default_sn_curve(Obj, InputsBlock)
            % Default S-N curve is DC50 for sgre2, and DC36* for all other models.
            % Set this value, unless the user has set an override value in the input file.

            isSgre2 = strcmpi(InputsBlock.BOLT_FORCE_MODEL, "sgre2");
            hasUserInput = InputsBlock.SN_CURVE_BOLT ~= "";

            % Log a warning message if:
            % 1. sgre2 model is combined with a user input for SN_CURVE_BOLT that is not EC3_DC50 (or empty)
            % 2. non-sgre2 model is combined with a user input for SN_CURVE_BOLT that is not EC3_DC36* (or empty)
            isNonDefault = ...
                ~strcmp(InputsBlock.SN_CURVE_BOLT, '') & ...
                ((~strcmp(InputsBlock.SN_CURVE_BOLT, 'EC3_DC50') & isSgre2) | ...
                (~strcmp(InputsBlock.SN_CURVE_BOLT, 'EC3_DC36*') & ~isSgre2));
            Obj.log_nondefault(isNonDefault, "SN_CURVE_BOLT", string(InputsBlock.SN_CURVE_BOLT));

            % Assign default
            InputsBlock.SN_CURVE_BOLT(~hasUserInput & ~isSgre2) = {'EC3_DC36*'};
            InputsBlock.SN_CURVE_BOLT(~hasUserInput & isSgre2) = {'EC3_DC50'};
        end

        function log_nondefault(Obj, condition, fieldName, valueAsString)
            % Logs warning if non-default value is used

            for cond = enumerate(condition)
                if cond.value
                    Obj.Logger.warning( ...
                        'USAIN:BoltFlsInputBlock:NonDefaultUserInput', ...
                        'Non-default value for input "%s(%i)" will be used: %s', ...
                        fieldName, cond.count, valueAsString(cond.count));
                end
            end

        end

    end
end
