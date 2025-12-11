classdef NutData < usain.fastener.BaseCatalogData
    % Data model for hexagon nuts or round nuts

    properties
        label char
        len double  % Nut height (nominal)
        lenMin double  % Min. nut height
        lenMax double  % Max. nut height
        diam double  % Outer diameter of nut (for clash checks, equals width across corners for hexagon nuts)
        mass double  % Mass of single nut
    end
    properties (Constant)
        REQUIRED_FIELDS = {'label', 'len', 'lenMin', 'lenMax', 'diam', 'mass'}
        EXPORT_FIELDS = usain.fastener.NutData.REQUIRED_FIELDS
        NUT_TYPES = ["HV", "JIS", "IHF", "ISO", "ISR"]
    end

    methods

        function validate(Obj)
            Validator = usain.fastener.CatalogDataValidator('nut');
            for iObj = 1:length(Obj)
                This = Obj(iObj);

                % Expect lenMin <= len
                Validator.validate(@() assert(This.lenMin <= This.len, ...
                    '%-10s: expected lenMin <= len', This.label));

                % Expect lenMax >= len
                Validator.validate(@() assert(This.lenMax >= This.len, ...
                    '%-10s: expected lenMax >= len', This.label));
            end
            Validator.report();
        end

    end

    methods (Static)

        function Objs = from_struct(S)
            % See usain.fastener.BaseCatalogData.from_struct

            assert(isfield(S, 'data'), 'NutData:from_struct:InvalidStruct', ...
                'Expected struct with "data" field.');

            nInputSets = length(S.data);
            Objs(nInputSets, 1) = usain.fastener.NutData();
            for iInp = 1:nInputSets
                Objs(iInp) = usain.fastener.NutData(S.data(iInp));
            end
        end

        function labels = compose_nut_labels(boltLabel, nutType)
            % Returns string (array) with nut labels
            %
            % boltLabel: Bolt label(s) as cellstr, e.g. {'HV_M72', 'ISO_M42'}
            % nutType: Nut type(s), e.g. {'HV', 'ISR'}

            % Replace prefix in bolt labels
            labels = nutType + "_" + string(extractAfter(boltLabel, '_'));
        end

    end
end
