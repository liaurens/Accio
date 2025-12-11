classdef TighteningToolData < usain.fastener.BaseCatalogData

    properties
        label char  % Label of tightening tool (for printing)
        tighteningMethod char  % Either 'torque' or 'tension'
        dimRadialDir double  % Size (radius) of tool in radial direction, in [m]
        dimCircDir double  % Size (radius) of tool in circumferential direction, in [m]
        dimHeight double  % Size of tool in height direction, in [m]
        assemblyValue double  % Applied torque or tension value for installation, in [Nm] or [N]
        defaultPreload double  % Assumed pretension value in fastener after tool is released, in [N]
    end
    properties (Constant)
        REQUIRED_FIELDS = {'label', 'tighteningMethod', 'dimRadialDir', 'dimCircDir', 'dimHeight', ...
            'assemblyValue', 'defaultPreload'}
        EXPORT_FIELDS = [usain.fastener.TighteningToolData.REQUIRED_FIELDS]

        VALID_TIGHTENING_METHOD = {'torque', 'tension'}
        TEMP_STAGES_TOOL_TYPES = ["normal", "thin", "none"]
    end

    methods

        function validate(Obj)
            Validator = usain.fastener.CatalogDataValidator('tightening tool');
            for iObj = 1:length(Obj)
                This = Obj(iObj);

                % If tension, expect assemblyValue > defaultPreload
                if strcmp(This.tighteningMethod, 'tension')
                    Validator.validate(@() assert(This.assemblyValue > This.defaultPreload, ...
                        '%-10s: expected reference value > defaultPreload', This.label));

                    % If tension, expect dimHeight > 0
                    Validator.validate(@() assert(This.dimHeight > 1e-6, ...
                        '%-10s: expected nonzero height to be set for tensioning tool', This.label));
                end

                % If torque, expect dimHeight == 0
                if strcmp(This.tighteningMethod, 'torque')
                    Validator.validate(@() assert(This.dimHeight < 1e-6, ...
                        '%-10s: expected no height to be set for torque socket', This.label));
                end

            end
            Validator.report();
        end

    end

    methods (Static)

        function Objs = from_struct(S)
            % See usain.fastener.BaseCatalogData.from_struct

            assert(isfield(S, 'data'), 'TighteningToolData:from_struct:InvalidStruct', ...
                'Expected struct with "data" field.');

            nInputSets = length(S.data);
            Objs(nInputSets, 1) = usain.fastener.TighteningToolData();
            for iInp = 1:nInputSets
                Objs(iInp) = usain.fastener.TighteningToolData(S.data(iInp));
            end
        end

        function assertFn = verify_temp_stages_tools(site, boltLabels, toolType)
            % site: Site where tool is used, e.g. usain.inputs.Site.OFFSHORE
            % boltLabel: (array of) bolt labels
            % toolType: tool type label

            % Try to get a TighteningToolData for a bolt label and temporary tool type. If this fails, the combination
            % is invalid
            msg = string.empty;
            for iBolt = 1:numel(boltLabels)
                try
                    usain.fastener.TighteningToolData.get_temp_stages_tool_obj(site, boltLabels{iBolt}, toolType);
                catch Exception
                    if strcmp(Exception.identifier, 'BaseCatalogData:select:NoUniqueMatch')
                        % Store this combination; we'll compose a single error message later
                        msg(end + 1) = sprintf('site=%s, label=%s, temp. tool=%s\n', ...
                            site, boltLabels{iBolt}, toolType);  %#ok
                    else
                        rethrow(Exception);
                    end
                end
            end

            % Compose error message with all failing combinations (if any)
            assertFn = @() assert(isempty(msg), 'TighteningToolData:verify_temp_stages_tools:InvalidCombination', ...
                "Invalid combination(s) of bolt option and temporary stages tool type:\n" + join(msg, ''));

            if ~nargout
                assertFn();
            end
        end

        function Tool = get_temp_stages_tool_obj(site, boltLabel, toolType)
            % Returns object for temporary tool
            %
            % site: Site where tool is used, e.g. usain.inputs.Site.OFFSHORE
            % boltLabel: fastener label, e.g. 'ISO_M42'
            % toolType: tool type for temporary stages, e.g. 'normal' or 'thin'

            switch toolType
                case 'normal'
                    toolCatalogLabel = "torque";
                case 'thin'
                    toolCatalogLabel = "torqueThin";
                case 'none'
                    return % No checks to be performed for temporary stages
                otherwise
                    error('Implementation error');
            end
            temporaryToolLabel = string(boltLabel) + "_" + toolCatalogLabel + "_" + string(site).lower;
            Lib = usain.fastener.CatalogLibrary.get_library();
            Tool = Lib.Tools.select('label', temporaryToolLabel);
        end

        function toolSizeCircDir = get_tool_size_for_bolt_distance(site, boltLabel, tighteningMethod, nutType, temporaryTool, override)  % mh:ignore_style
            % Get maximum tool size in circumferential direction, from both the installation and temporary tool
            %
            % site: Site where tool is used, e.g. usain.inputs.Site.OFFSHORE
            % boltLabel: fastener label, e.g. 'ISO_M42'
            % tighteningMethod: installation method, e.g. 'tension'
            % nutType: Nut type, e.g. 'ISR'
            % temporaryTool: tool for temporary stages, e.g. 'normal'
            % override: value(s) for input override

            % Check inputs, for uniform processing later on
            boltLabel = string(boltLabel);
            tighteningMethod = string(tighteningMethod);
            nutType = string(nutType);
            assert(all(length(boltLabel) == [length(tighteningMethod), length(nutType), length(override)]), ...
                'TighteningToolData:get_tool_size:WrongSizeArgsIn', ...
                'Input arguments must have the same size.');

            % Find maximum tool size(s)
            nLabel = length(boltLabel);
            toolSizeCircDir = nan(1, nLabel);
            for iLabel = 1:nLabel
                if ~isnan(override(iLabel))
                    toolSizeCircDir(iLabel) = override(iLabel);
                else
                    thisLabel = boltLabel(iLabel);
                    thisMethod = tighteningMethod(iLabel);
                    thisNut = nutType(iLabel);
                    InstallTool = usain.fastener.CatalogLibrary.select_assemblies( ...
                        site, thisLabel, thisMethod, thisNut).Tool;
                    if strcmp(temporaryTool, 'none')
                        tempToolDimCircDir = nan;
                    else
                        TempTool = usain.fastener.TighteningToolData.get_temp_stages_tool_obj( ...
                            site, thisLabel, temporaryTool);
                        tempToolDimCircDir = TempTool.dimCircDir;
                    end
                    toolSizeCircDir(iLabel) = max(InstallTool.dimCircDir, tempToolDimCircDir);
                end
            end
        end

    end

end
