classdef SelectedModelInputs < matlab.mixin.SetGet
    % Class representation of "selected model input file" (for re-running with selected model)

    properties
        timeStamp string = datestr(now, 'YYYY-mm-dd_HHMMSS')
        Inputs struct  % Inputs in SI-units
        ConvertedInputs struct  % Inputs, converted to human-friendly units
    end

    properties (Constant)
        % Fields in Inputs struct that are added by USAIN and need not to be written to the selected model input file
        SKIP_FIELDS = ["Milk.Fls", "Milk.S1", "Milk.Uls", "StrMdl", "flangeMatrDesignation", ...
             "thicknWeldBulgeLo", "thicknWeldBulgeUp", "yieldStrengthChar"]
        % TODO remove thicknWeldBulgeLo/Up from this list if possible; refactored to be property of FlangeModel and not
        % assigned to Inputs anymore.

        % Input blocks that are possibly repeated/indexed (e.g. Foo(1).bar, Foo(2).bar)
        INDEXED_BLOCKS = ["Loads", "BoltFls"]
    end

    methods

        function Obj = SelectedModelInputs(varargin)
            Obj = assign_varargin_2_classprop(Obj, varargin{:});
        end

        function set.Inputs(Obj, InputsStruct)
            % When setting `Inputs`, also convert units and set `ConvertedInputs`
            Obj.Inputs = InputsStruct;
            Obj.convert_inputs_from_si_units();
        end

        function convert_inputs_from_si_units(Obj)
            Schema = usain.inputs.get_schema();
            Obj.ConvertedInputs = inpfilehelper.convert_from_si_units(Schema, Obj.Inputs);

            % Convert SGRE2.FLANGE_TILT_VALUE using user-specified units
            value = Obj.Inputs.SGRE2.FLANGE_TILT_VALUE;
            unit = Unit(Obj.Inputs.SGRE2.FLANGE_TILT_UNIT);
            Obj.ConvertedInputs.SGRE2.FLANGE_TILT_VALUE = unit.from_si(value);

            % Convert inclinationValue using user-specified units
            for i = 1:length(Obj.Inputs.Loads.inclinationValue)
                value = Obj.Inputs.Loads.inclinationValue(i);
                unit = Unit(Obj.Inputs.Loads.inclinationUnit{i});
                Obj.ConvertedInputs.Loads.inclinationValue(i) = unit.from_si(value);
            end

            % Convert inclinationValueFls using user-specified units
            for i = 1:length(Obj.Inputs.Loads.inclinationValueFls)
                value = Obj.Inputs.Loads.inclinationValueFls(i);
                unit = Unit(Obj.Inputs.Loads.inclinationUnit{i});
                Obj.ConvertedInputs.Loads.inclinationValueFls(i) = unit.from_si(value);
            end
        end

        function InputFileObj = create_filecontent(Obj, sourceInputFilePath)
            % Create InputFile object to reproduce the results for the selected model

            InputFileObj = InputFile();

            for field = Obj.get_input_field_names(Obj.ConvertedInputs)

                rawValue = get_sub_field_array(Obj.ConvertedInputs, char(field));
                % NOTE: Use `get_sub_field_array` because Obj.ConvertedInputs.BoltFls is a 1xN struct

                if field.startsWith(Obj.INDEXED_BLOCKS)
                    % Field is part of a indexed/repeated input block (e.g. Loads.*). Insert each cell entry as a
                    % separate variable in the InputFile object
                    for e = enumerate(rawValue(:)')
                        if isstring(e.value)
                            value = TexacoUtils.data_to_inputstring(cellstr(e.value));
                        elseif isnan(e.value)
                            value = '';
                        else
                            value = TexacoUtils.data_to_inputstring(e.value);
                        end
                        InputFileObj.insert_variable(char(field + " : " + value));
                    end
                else
                    % "Normal" input
                    if ~iscell(rawValue) && all(isnan(rawValue))
                        value = '';
                    else
                        value = TexacoUtils.data_to_inputstring(rawValue);
                    end
                    InputFileObj.insert_variable(char(field + " : " + value));
                end
            end

            InputFileObj.toolName = USAIN.TOOL_NAME;
            InputFileObj.toolVersion = USAIN.VERSION;
            InputFileObj.create_filecontent();

            Obj.mark_input_file(InputFileObj, sourceInputFilePath);
            InputFileObj.update_filecontent();
        end

        function fields = get_input_field_names(Obj, InputsStruct)
            % Helper to get list of field names to put in selected model input file
            fields = setdiff(string(fieldnamesr(InputsStruct)), Obj.SKIP_FIELDS);
            fields = fields(:)';  % 1xN array for direct use in for-loop
        end

        function FilePath = write_file(Obj, InputFileObj)
            FilePath = Obj.get_target_file_path();
            InputFileObj.targetFilePath = char(FilePath);
            InputFileObj.write_inputfile();
        end

        function FilePath = get_target_file_path(Obj)
            fileName = sprintf('%s_%s_%s_selectedMdl.inp', Obj.timeStamp, USAIN.TOOL_NAME, Obj.Inputs.runName);
            FilePath = pathlib.Path(Obj.Inputs.targetDir) / fileName;
            % TODO: Overwrite file if already existing?
        end

        function InputFileObj = mark_input_file(~, InputFileObj, sourceInputFilePath)
            % Print comment at top of input file to indicate the file was auto-generated

            markString = { ...
                sprintf('%% Input file auto-generated on %s', datetime('now'))
                sprintf('%% Source USAIN input file: %s', sourceInputFilePath)
                ''
                };

            InputFileObj.fileContent = [ ...
                markString
                InputFileObj.fileContent(1:end)];
        end

    end

end
