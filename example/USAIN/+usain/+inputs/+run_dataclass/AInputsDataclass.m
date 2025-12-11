classdef AInputsDataclass < dataclasses.DataClass % mh:ignore_style

    properties
        % List here all required inputs for a USAIN run
        boltOptions (1, :) cell
        site (1, 1) string
        tighteningMethod (1, :) cell
        zFlange (1, 1) double
        flangeType (1, 1) string

        OptionalInputs (1, 1) struct = struct()
    end

    properties (Constant)
        Schema = usain.inputs.get_schema()
    end

    methods

        function Inputs = get_optional_inputs(Obj)
            Inputs = struct();
            fieldNames = fieldnamesr(Obj.OptionalInputs);
            for i = 1:numel(fieldNames)
                fieldName = fieldNames{i};
                assert(Obj.Schema.is_field(fieldName), "'%s' is not a valid USAIN input field", fieldName);

                Inputs = setsubfield(Inputs, fieldName, getsubfield(Obj.OptionalInputs, fieldName));
            end
        end

        function Inputs = get_all_inputs(Obj)
            Inputs = Obj.to_struct();
            ExtraOptionalInputs = Obj.get_optional_inputs();
            Inputs = structhelper.merge(Inputs, ExtraOptionalInputs);

            fieldnames = Obj.Schema.get_field_names_with_default();

            for i = 1:numel(fieldnames)
                field = fieldnames{i};
                default = Obj.Schema.get_default(field);

                % if already set in DataClass, skip setting it from schema
                if ~issubfield(Inputs, field)
                    Inputs = setsubfield(Inputs, field, default);
                end
            end

        end

        function S = to_struct(Obj)
            S = struct(Obj);
            S = rmfield(S, 'OptionalInputs');
        end

    end

end
