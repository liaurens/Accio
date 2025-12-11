classdef FastenerData < usain.fastener.BaseCatalogData

    properties
        label char  % Fastener label
        type char  % Type of fastener (hex = head bolt, stud = stud bolt)
        diam double  % Metric size (approximate shaft diameter)
        pitch double  % Pitch of thread
        areaStress double  % Stress area
        diamHead double  % Diameter of head, (0 for studs). Equal to width across corners (symbol: e)
        ultStrength double  % Characteristic ultimate strength
        yieldStrengthMinimum double  % Yield strength, minimum value
        yieldStrengthNominal double  % Yield strength, nominal value
        propClass char  % Property class label (e.g. '10.9')
        lengthTolerance char  % Tolerance class on length (as per ISO 4759-1 and ISO 286-1)
        defaults = struct()

        len double = nan  % Nominal bolt length
        lenThread double  % Length of thread. For studs, this is the thread length on one side!
    end
    properties (Dependent)
        ftRc double  % Characteristic value for tension resistance
        minorDiameter double  % Minor diameter of external thread, design profile (symbol: d3)
        pitchDiameter double  % Pitch diameter of external thread (symbol: d2)
    end
    properties (Constant)
        REQUIRED_FIELDS = {'label', 'type', 'diam', 'pitch', 'areaStress', 'diamHead', ...
            'ultStrength', 'yieldStrengthMinimum', 'yieldStrengthNominal', 'propClass', 'lengthTolerance', 'defaults'}
        EXPORT_FIELDS = [setdiff(usain.fastener.FastenerData.REQUIRED_FIELDS, 'defaults'), ...
            'len', 'lenThread', 'ftRc', 'minorDiameter', 'pitchDiameter']
    end

    methods

        function validate(Obj)
            Validator = usain.fastener.CatalogDataValidator('fastener');
            for iObj = 1:length(Obj)
                This = Obj(iObj);

                % Label reflects diameter
                metricSizeFromLabel = str2double(regexp(This.label, '(\d+)', 'match', 'once'));
                metricSizeFromDiam = 1e3 * This.diam;
                Validator.validate(@() assert(abs(metricSizeFromLabel - metricSizeFromDiam) < 1e-6, ...
                    '%-10s: expected metric size from label (=%g) to be equal to diameter (=%g)', ...
                    This.label, metricSizeFromLabel, metricSizeFromDiam));

                % Property class check
                isJisBolt = startsWith(This.label, 'JIS');
                Validator.validate(@() assert(iif(isJisBolt, strcmp(This.propClass, 'F10T'), true), ...
                    '%-10s: expected property class for JIS bolts to be F10T', This.label));
                Validator.validate(@() assert(iif(~isJisBolt, strcmp(This.propClass, '10.9'), true), ...
                    '%-10s: expected property class to be 10.9', This.label));

                % Non-zero bolt head only for head bolts, not for studs
                isBoltWithHead = strcmp(This.type, 'stud') | This.diamHead > 0;
                isStudWithoutHead = strcmp(This.type, 'hex') | abs(This.diamHead) < 1e-10;
                Validator.validate(@() assert(isBoltWithHead, ...
                    '%-10s: expected bolt head diameter > 0 for head bolt', This.label));
                Validator.validate(@() assert(isStudWithoutHead, ...
                    '%-10s: expected zero bolt head diameter for stud bolt', This.label));

                % Defaults contain expected fields
                expectDefaults = {'lengthThread', 'boltHoleDiam', 'standardLengths'};
                isDefaultPresent = ismember(expectDefaults, fieldnames(This.defaults));
                Validator.validate(@() assert(all(isDefaultPresent), ...
                    '%-10s: missing one or more defaults: %s', This.label, ...
                    strjoin(expectDefaults(~isDefaultPresent), ', ')));

            end
            Validator.report();
        end

        function value = get_default(Obj, prop)
            % Returns default value for given fastener property
            % Arg 'prop' must exist in the 'defaults' struct
            assert(isfield(Obj.defaults, prop), 'FastenerData:get_default:PropNotFound', ...
                'No defaults found for fastener property: %s.', prop);
            value = Obj.defaults.(prop);
        end

        function value = get.ftRc(Obj)
            % Return characteristic value for bolt's tension resistance
            value = Obj.ultStrength * Obj.areaStress;
        end

        function value = get.minorDiameter(Obj)
            % Compute minor diameter of _design_ profile (according to ISO 898-1)
            % NOTE: Not to be confused with the basic minor diameter (according to ISO 724)
            heightFundamentalTriangle = (sqrt(3) / 2) * Obj.pitch;
            value = Obj.diam - (5 / 4 * heightFundamentalTriangle) - (1 / 6) * heightFundamentalTriangle;
        end

        function value = get.pitchDiameter(Obj)
            value = Obj.diam - (3 / 4 * sqrt(3) / 2) * Obj.pitch;
        end

    end

    methods (Static)

        function Objs = from_struct(S)
            % See usain.fastener.BaseCatalogData.from_struct

            assert(isfield(S, 'data'), 'FastenerData:from_struct:InvalidStruct', ...
                'Expected struct with "data" field.');

            nInputSets = length(S.data);
            Objs(nInputSets, 1) = usain.fastener.FastenerData();
            for iInp = 1:nInputSets
                Objs(iInp) = usain.fastener.FastenerData(S.data(iInp));
            end
        end

        function length = get_length_options(lengthFromInputs, label)
            % Returns array with bolt length options
            %
            % input: Input value `boltLength`
            % label: Fastener label, e.g. 'ISO_M42'

            if isnan(lengthFromInputs)
                % No input was provided, return all standard lengths
                length = usain.fastener.FastenerData.get_standard_bolt_lengths(label);
            else
                % Return what user provided as input
                length = lengthFromInputs;
            end
        end

        function len = get_standard_bolt_lengths(label)
            % Returns default bolt lengths for input bolt label
            Lib = usain.fastener.CatalogLibrary.get_library();
            Bolt = Lib.Fasteners.select('label', label);
            len = Bolt.get_default('standardLengths');
        end

        function len = get_standard_thread_length(label)
            % Returns default thread lengths for input bolt label
            Lib = usain.fastener.CatalogLibrary.get_library();
            Bolt = Lib.Fasteners.select('label', label);
            len = Bolt.get_default('lengthThread');
        end

        function mass = calc_mass(label, len)
            % Returns mass of fastener
            %
            % label: Bolt label, e.g. ISO_M42
            % len: Nominal length

            Lib = usain.fastener.CatalogLibrary.get_library();
            Bolt = Lib.Fasteners.select('label', char(label));
            switch lower(Bolt.type)
                case 'hex'
                    % JIS or HV bolts; mass is computed with same formulas (even though the bolt head height
                    % of larger JIS bolts is slightly larger)
                    mass = usain.fastener.calc_mass_hv_bolt(Bolt.diam, len);
                case 'stud'
                    mass = usain.fastener.calc_mass_iso_stud(Bolt.pitchDiameter, len);
                otherwise
                    error('Unknown bolt type: %s', Bolt.type);
            end
        end

        function range = calc_expected_range_preload(label)
            % Helper function to calculate expected preload range (50% - 100% of bolt yield strength)
            % NOTE: This is a temporary path for sanity checks on `*.CUSTOM_PRELOAD` inputs
            %
            % label: Fastener label, e.g. ISO_M72

            Lib = usain.fastener.CatalogLibrary.get_library();
            Bolt = Lib.Fasteners.select('label', label);
            range = [0.5, 1] .* 940 * 1e6 * Bolt.areaStress;
        end

    end
end
