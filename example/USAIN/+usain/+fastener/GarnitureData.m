classdef GarnitureData < usain.fastener.BaseCatalogData
    % Data model for garnitures (i.e. assemblies of bolt, washer, nut and tool)

    properties
        label char  % Garniture label
        site usain.inputs.Site % Site where the garniture is used, e.g. 'ONSHORE' or 'OFFSHORE'
        tighteningMethod char  % Either 'torque' or 'tension'
        bolt char  % Bolt label
        nut char  % Nut label
        washer char  % Washer label
        tighteningTool char  % Label for tightening tool during installation
    end
    properties (Constant)
        REQUIRED_FIELDS = {'label', 'site', 'tighteningMethod', 'bolt', 'nut', 'washer', 'tighteningTool'}
        EXPORT_FIELDS = usain.fastener.GarnitureData.REQUIRED_FIELDS
    end

    methods

        function validate(Obj)
            Validator = usain.fastener.CatalogDataValidator('garniture');
            for iObj = 1:length(Obj)
                This = Obj(iObj);

                % Expect bolt label to be present in FastenerData
                Lib = usain.fastener.CatalogLibrary.get_library();
                allBoltLabels = {Lib.Fasteners.label};
                Validator.validate(@() assert(contains(This.bolt, allBoltLabels), ...
                    '%-10s: label not present in fasteners catalog data', This.label));

                % Expect washer label to be present in WasherData
                allWasherLabels = {Lib.Washers.label};
                Validator.validate(@() assert(contains(This.washer, allWasherLabels), ...
                    '%-10s: label not present in washers catalog data', This.label));

                % Expect nut label to be present in NutData
                allNutLabels = {Lib.Nuts.label};
                Validator.validate(@() assert(contains(This.nut, allNutLabels), ...
                    '%-10s: label not present in nut catalog data', This.label));

                % Expect tool labels to be present in TighteningToolData
                allToolLabels = {Lib.Tools.label};
                Validator.validate(@() assert(contains(This.tighteningTool, allToolLabels), ...
                    '%-10s: label not present in tightening tool catalog data', This.label));
            end
            Validator.report();
        end

    end

    methods (Static)

        function Objs = from_struct(S)
            % See usain.fastener.BaseCatalogData.from_struct

            assert(isfield(S, 'data'), 'GarnitureData:from_struct:InvalidStruct', ...
                'Expected struct with "data" field.');

            nInputSets = length(S.data);
            Objs(nInputSets, 1) = usain.fastener.GarnitureData();
            for iInp = 1:nInputSets
                Objs(iInp) = usain.fastener.GarnitureData(S.data(iInp));
            end
        end

        function assertFn = validate_bolt_nut_tool_combination(site, boltLabel, tighteningMethod, nutType)
            % Check whether combination of site ,bolt, nut and tightening method is possible.
            % Returns assert function if argout, otherwise evaluates directly.
            %
            % site: Site where the garniture is used, e.g. usain.inputs.Site.OFFSHORE
            % boltLabel: Bolt label(s) as cellstr, e.g. {'HV_M72', 'ISO_M42'}
            % tighteningMethod: Tightening method for each bolt/nut label, e.g. {'torque', 'tension'}
            % nutType: Nut types for each bolt/nut label, e.g. {'HV', 'ISR'}

            nutLabel = usain.fastener.NutData.compose_nut_labels(boltLabel, nutType);

            msg = {};
            Lib = usain.fastener.CatalogLibrary.get_library();
            for iOpt = 1:length(boltLabel)
                try
                    Lib.Garnitures.select( ...
                        'site', site, ...
                        'label', boltLabel{iOpt}, ...
                        'nut', nutLabel(iOpt), ...
                        'tighteningMethod', tighteningMethod{iOpt});
                catch Exc
                    if strcmp(Exc.identifier, 'BaseCatalogData:select:NoUniqueMatch')
                        msg{end + 1} = sprintf( ...
                            ['\tCombination of site=%s, boltLabel=%s, nutLabel=%s and tighteningMethod=%s is not ', ...
                            'allowed.'], site, boltLabel{iOpt}, nutLabel{iOpt}, tighteningMethod{iOpt}); %#ok
                    else
                        rethrow(Exc);
                    end
                end
            end

            % Throw all error messages at once
            errId = 'GarnitureData:validate_bolt_nut_tool_combination:ValidationError';
            assertFn = @() assert(isempty(msg), errId, '%s', strjoin(msg, '\n\n'));
            if ~nargout
                assertFn();
            end
        end

        function validate_bolt_options(boltOptions)
            % Validates input boltOptions
            % The bolt label is the concatenation of bolt system and metric size of the bolt, e.g. HV_M42
            %
            % boltOptions: char, string or cellstr with labels

            % Check type
            assert(ischar(boltOptions) | iscellstr(boltOptions) | isstring(boltOptions), ...
                'GarnitureData:validate_bolt_options:WrongType', ...
                '\tExpected "boltOptions" to be a string (array).');
            boltOptions = string(boltOptions);  % force string for uniform processing

            % Check format
            BoltOpt = usain.fastener.BoltOptionsParser(boltOptions);
            BoltOpt.validate_format();

            % Verify label is present in catalog
            Lib = usain.fastener.CatalogLibrary.get_library();
            validLabels = string({Lib.Garnitures.label});
            isMatch = ismember(BoltOpt.label, validLabels);
            assert(all(isMatch), 'GarnitureData:validate_bolt_options:InvalidLabel', ...
                'Invalid label(s) in "boltOptions": %s', join(boltOptions(~isMatch), ', '));
        end

    end
end
