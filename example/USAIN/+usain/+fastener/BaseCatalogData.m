classdef BaseCatalogData < matlab.mixin.Copyable
    % Base class for catalog data
    % Inherits from matlab.mixin.Copyable due to implementation in singleton class usain.fastener.CatalogLibrary

    properties (Abstract, Constant)
        % List of fields expected to be present in the catalog file
        REQUIRED_FIELDS

        % List of fields exported to struct in to_struct_of_arrays()
        EXPORT_FIELDS
    end

    methods

        function Obj = BaseCatalogData(S)
            if nargin
                Obj.import_struct(S);
            end
        end

        function import_struct(Obj, S)
            % Imports data from struct
            % This is a convenience method to fill a BaseCatalogData child class

            assert(all(contains(Obj.REQUIRED_FIELDS, fieldnames(S))), ...
                'BaseCatalogData:import_struct:MissingField', ...
                'Input struct misses one or more required fields.');

            for prop = Obj.REQUIRED_FIELDS
                Obj.(prop{1}) = S.(prop{1});
            end
        end

        function S = to_struct_of_arrays(Obj)
            % Converts object array to struct with arrays
            % This step is used to improve runspeed in USAIN (structs have much less overhead than custom
            % class instances)
            S = struct();
            for prop = Obj(1).EXPORT_FIELDS
                % Convert to struct
                if ischar(Obj(1).(prop{1}))
                    % Char properties become cells of strings
                    S.(prop{1}) = {Obj.(prop{1})};
                else
                    % Numeric properties remain numeric
                    S.(prop{1}) = cat(2, Obj.(prop{1}));
                end
            end
        end

        function validate(Obj) %#ok
            % Method to validate data. To be implemented in subclasses
        end

        function Inp = select(Obj, varargin)
            % Selects single entry from catalog data, based on provided name-value pairs
            %
            % % Get washer data for label 'ISO_M42'
            % >> Lib = usain.fastener.CatalogLibrary.get_library();
            % >> Lib.Washers.select('label', 'ISO_M42');
            %
            % % Get garniture data for fastener label 'ISO_M64' and 'torque' tightening
            % >> Lib.Garnitures.select('label', 'ISO_M64', 'tighteningMethod', 'torque');

            % Check inputs arguments
            assert(nargin > 1 & mod(nargin - 1, 2) == 0, 'BaseCatalogData:select:WrongSignature', ...
                ['Call method with one or more name-value pairs, e.g. Obj.select(''label'', ''M42'') or ', ...
                'Obj.select(''label'', ''M42'', ''tighteningMethod'', ''tension'').']);

            names = varargin(1:2:end);
            isFound = ismember(names, Obj(1).REQUIRED_FIELDS);
            assert(all(isFound), 'BaseCatalogData:select:NameArgNotFound', ...
                ['One or more names in input name-value pairs not recognized: %s.\n', ...
                'Choose from: %s'], strjoin(names(~isFound), ', '), strjoin(Obj(1).REQUIRED_FIELDS, ', '));

            isMatch = true(1, length(Obj));
            values = varargin(2:2:end);
            for iPair = 1:length(names)
                isMatch = isMatch & string({Obj.(names{iPair})}) == values{iPair};
            end
            assert(nnz(isMatch) == 1, 'BaseCatalogData:select:NoUniqueMatch', ...
                '%i matches for %s, expected exactly 1.', nnz(isMatch), ...
                strjoin(cellfun(@(x, y) sprintf('%s=%s', x, y), names, values, 'uni', 0), ', '));
            Inp = Obj(isMatch);
        end

    end

    methods (Static)

        function validate_input(inpVals, expectedLength, expectedValues, varName)
            % Helper for input validations
            % Checks if length and value of input is as expected.
            % Combines all input validation functions and, if any fail, gracefully exits

            pass = true;
            msg = {};

            % Check type
            assert(ischar(inpVals) | iscellstr(inpVals) | isstring(inpVals), ...
                'BaseCatalogData:validate_input:WrongType', ...
                '\tExpected input "%s" to be a (cell of) string(s).', varName);

            % Convert to cellstr for uniform processing
            inpVals = cellstr(inpVals);

            % Check length
            pass = pass & any(length(inpVals) == [0 1 expectedLength]);
            if ~pass
                msg{end + 1} = sprintf(['\tExpected input "%s" to be either empty, ', ...
                    'a single value or %i values (i.e. one for each input "boltOptions").'], varName, expectedLength);
            end

            % Check values
            pass = pass & all(ismember(inpVals, expectedValues));
            if ~pass
                msg{end + 1} = sprintf('\tInvalid value(s) for "%s". Valid options are: %s', ...
                    varName, strjoin(expectedValues, ', '));
            end

            % Throw all error message at once
            assert(pass, 'BaseCatalogData:validate_input:ValidationError', '%s', strjoin(msg, '\n\n'));
        end

    end

    methods (Abstract, Static)
        % Constructs catalog from a struct from the CatalogLibrary
        %
        % S: struct with fastener component (e.g. washer) data from the bolts catalog file
        % Objs: array of catalog data objects
        Objs = from_struct(S)
    end
end
