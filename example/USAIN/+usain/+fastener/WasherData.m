classdef WasherData < usain.fastener.BaseCatalogData

    properties
        label char
        diamIn double  % Inner diameter of washer (min)
        diamOut double  % Outer diameter of washer (max)
        len double  % Thickness of washer (nominal)
        lenMin double  % Thickness of washer (min)
        lenMax double  % Thickness of washer (max)
    end
    properties (Dependent)
        mass double  % Mass of single washer
    end
    properties (Constant)
        REQUIRED_FIELDS = {'label', 'diamIn', 'diamOut', 'len', 'lenMin', 'lenMax'}
        EXPORT_FIELDS = [usain.fastener.WasherData.REQUIRED_FIELDS, 'mass']
    end

    methods

        function validate(Obj)
            Validator = usain.fastener.CatalogDataValidator('washer');
            for iObj = 1:length(Obj)
                This = Obj(iObj);

                if strcmp(This.label, 'NO_WASHER')
                    return
                end

                % Expect lenMin <= lenMax
                Validator.validate(@() assert(This.lenMin <= This.lenMax, ...
                    '%-10s: expected minimum thickness <= maximum thickness', This.label));

                % Expect diamIn < diamOut
                Validator.validate(@() assert(This.diamIn < This.diamOut, ...
                  '%-10s: expected inner diameter < outer diameter', This.label));
            end
            Validator.report();
        end

        function make_custom_washer(Obj, diamIn, diamOut, len)
            % Overrides default washer data by custom inputs

            % Skip operation if no custom washers are defined in inputs
            if isnan(diamIn)
                return
            end

            % Store current thickness tolerances; to be applied for new washer as well
            tolLenMax = Obj.lenMax - Obj.len;
            tolLenMin = Obj.lenMin - Obj.len;

            % Update data
            Obj.diamIn = diamIn;
            Obj.diamOut = diamOut;
            Obj.len = len;
            Obj.lenMax = tolLenMax + Obj.len;
            Obj.lenMin = tolLenMin + Obj.len;
        end

        function value = get.mass(Obj)
            rho = 7850;
            value = pi * rho * Obj.len * ((Obj.diamOut / 2)^2 - (Obj.diamIn / 2)^2);
        end

    end

    methods (Static)

        function Objs = from_struct(S)
            % See usain.fastener.BaseCatalogData.from_struct

            assert(isfield(S, 'data'), 'WasherData:from_struct:InvalidStruct', ...
                'Expected struct with "data" field.');

            nInputSets = length(S.data);
            Objs(nInputSets, 1) = usain.fastener.WasherData();
            for iInp = 1:nInputSets
                Objs(iInp) = usain.fastener.WasherData(S.data(iInp));
            end
        end

    end
end
