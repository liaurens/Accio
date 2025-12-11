classdef CatalogReader < matlab.mixin.SetGet

    properties
        sourcePath char
        uniformFields logical = true  % Toggle to check for uniformity of parsed YAML sequences
        parsed struct
    end

    methods

        function Obj = CatalogReader(varargin)
            Obj = assign_varargin_2_classprop(Obj, varargin{:});
            if ~isempty(Obj.sourcePath)
                Obj.parsed = Obj.load_yaml(Obj.sourcePath);
            end
        end

        function parsed = load_yaml(Obj, yamlPath)
            % Reads and parses a *_catalog.yml file

            Obj.sourcePath = yamlPath;
            assert(isfile(yamlPath), 'CatalogReader:FileNotFound', 'File not found: %s', yamlPath);

            try
                parsed = YAML.read(yamlPath);
            catch Exc
                error('CatalogReader:YamlReadError', ...
                    'Error while reading catalog: %s\n\nOriginal error:\n%s', yamlPath, Exc.message);
            end

            if Obj.uniformFields
                Obj.check_uniform_parsed_struct(parsed.data);
            end
        end

        function check_uniform_parsed_struct(~, S)
            % Checks for uniformity of data structure
            assert(isstruct(S), 'CatalogReader:NonUniformData', ...
                'Data is not uniform. Please check inputs and make sure the data structure is uniform.');
        end

        function check_required_fields(Obj, requiredFields)
            % Verifies all required fields are present in parsed inputs
            missingFields = setdiff(requiredFields, fieldnames(Obj.parsed.data));
            assert(isempty(missingFields), 'CatalogReader:MissingRequiredFields', ...
                'Missing fields in inputs from catalog: %s\nCatalog file: %s', ...
                strjoin(missingFields, ', '), Obj.sourcePath);
        end

    end

end
