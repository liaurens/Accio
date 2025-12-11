classdef CatalogLibrary < Singleton
    % Fastener catalog library keeper (Singleton)
    % Only one usain.fastener.CatalogLibrary instance can exist in memory. This pattern is used because it allows to
    % only load the standard fastener catalogs (time consuming).
    %
    % USAGE
    %
    % To get handle to global usain.fastener.CatalogLibrary instance:
    %   usain.fastener.CatalogLibrary.get_library()
    %
    % To get fastener assembly data for a specific fastener label (e.g. ISO_M48) and tightening method:
    %   Assy = usain.fastener.CatalogLibrary.select_assemblies('onshore', 'ISO_M48', 'tension', 'ISR')
    %   Assy = usain.fastener.CatalogLibrary.select_assemblies('offshore', {'ISO_M48', 'ISO_M72'}, {'torque', 'tension'}, {'ISO', 'ISR'})   % mh:ignore_style

    properties
        Garnitures usain.fastener.GarnitureData
        Fasteners usain.fastener.FastenerData
        Nuts usain.fastener.NutData
        Washers usain.fastener.WasherData
        Extenders usain.fastener.ExtenderData
        Tools usain.fastener.TighteningToolData
    end
    properties (SetAccess = private, Hidden)
        CleanCatalogData struct % Set of clean/raw/untouched catalog data
    end
    properties (Constant)
        CATALOG_PATH = fullfile(fileparts(mfilename('fullpath')), 'bolts_catalog.yml')
    end

    methods (Access = private)

        function Obj = CatalogLibrary()
            % Constructor is not directly accessible (Singleton design pattern)
        end

    end

    methods

        function load_clean_data(Obj)
            % Read data from standard catalog into CleanCatalogData

            RawCatalog = usain.fastener.CatalogReader('sourcePath', usain.fastener.CatalogLibrary.CATALOG_PATH);
            RawCatalogData = RawCatalog.parsed.data;

            Obj.CleanCatalogData = struct();
            Obj.CleanCatalogData.Garnitures = usain.fastener.GarnitureData.from_struct(RawCatalogData.garnitures);
            Obj.CleanCatalogData.Fasteners = usain.fastener.FastenerData.from_struct(RawCatalogData.bolts);
            Obj.CleanCatalogData.Nuts = usain.fastener.NutData.from_struct(RawCatalogData.nuts);
            Obj.CleanCatalogData.Washers = usain.fastener.WasherData.from_struct(RawCatalogData.washers);
            Obj.CleanCatalogData.Extenders = usain.fastener.ExtenderData.from_struct(RawCatalogData.extenders);
            Obj.CleanCatalogData.Tools = usain.fastener.TighteningToolData.from_struct(RawCatalogData.tools);
        end

        function set_clean_data(Obj)
            % Assing clean catalog data to public properties, overwriting any dirty data
            Obj.Garnitures = Obj.CleanCatalogData.Garnitures.copy();
            Obj.Fasteners = Obj.CleanCatalogData.Fasteners.copy();
            Obj.Nuts = Obj.CleanCatalogData.Nuts.copy();
            Obj.Washers = Obj.CleanCatalogData.Washers.copy();
            Obj.Extenders = Obj.CleanCatalogData.Extenders.copy();
            Obj.Tools = Obj.CleanCatalogData.Tools.copy();
        end

    end

    methods (Static)

        function Obj = instance()
            % Returns singleton
            % - If object is present in memory, return handle to existing object
            % - Otherwise, create persistent object

            persistent singleInstance

            if isempty(singleInstance) || ~isvalid(singleInstance)
                % First call; construct empty instance
                Obj = usain.fastener.CatalogLibrary();
                % Assign to persistent var singleInstance to ensure only one instance will ever exist in
                % memory
                singleInstance = Obj;

                % Load library data
                Obj.load_clean_data();
                Obj.set_clean_data();
            else
                % Return handle to previously constructed library instance
                Obj = singleInstance;
            end
        end

        function Obj = get_library()
            % Decorator for usain.fastener.CatalogLibrary.instance()
            Obj = usain.fastener.CatalogLibrary.instance();
        end

        function Assy = select_assemblies(site, boltLabel, tighteningMethod, nutType)
            % Select fastener assembly components from inputs
            %
            % site: Site where the garniture is used, e.g. usain.inputs.Site.OFFSHORE
            % label: Fastener label (array), e.g. 'ISO_M42'
            % tighteningMethod: Tightening method (array), e.g. 'tension'
            % nutType: Nut type (array), e.g. 'ISR'
            % Assy: struct with assembly component data

            % Check inputs, for uniform processing later on
            boltLabel = string(boltLabel);
            tighteningMethod = string(tighteningMethod);
            nutType = string(nutType);
            assert(all(length(boltLabel) == [length(tighteningMethod), length(nutType)]), ...
                'CatalogLibrary:select_assemblies:WrongSizeArgsIn', ...
                'Input arguments must have the same size.');

            % Initialize selection routine
            Lib = usain.fastener.CatalogLibrary.get_library();

            % Compose list of nut labels, from scalar input nutType
            nutLabel = usain.fastener.NutData.compose_nut_labels(boltLabel, nutType);

            % Get fastener component data objects
            nAssy = length(boltLabel);
            Assy(nAssy) = struct();
            for iAssy = 1:nAssy
                label = boltLabel{iAssy};
                method = tighteningMethod{iAssy};
                nut = nutLabel{iAssy};

                Garniture = Lib.Garnitures.select( ...
                    'site', site, 'label', label, 'tighteningMethod', method, 'nut', nut);
                Assy(iAssy).Bolt = Lib.Fasteners.select('label', Garniture.bolt);
                Assy(iAssy).Washer = Lib.Washers.select('label', Garniture.washer);
                Assy(iAssy).Extender = Lib.Extenders.select('label', label);
                Assy(iAssy).Nut = Lib.Nuts.select('label', Garniture.nut);
                Assy(iAssy).Tool = Lib.Tools.select('label', Garniture.tighteningTool);
            end
        end

        function labels = get_all_fastener_labels()
            Lib = usain.fastener.CatalogLibrary.get_library();
            labels = {Lib.Fasteners.label};
        end

    end
end
