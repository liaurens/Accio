classdef DummyCatalogData < usain.fastener.BaseCatalogData
    % Implementation of usain.fastener.BaseCatalogData, for testing purposes

    properties
        some char
        thing double
        test char
    end
    properties (Constant)
        REQUIRED_FIELDS = {'some', 'thing', 'test'}
        EXPORT_FIELDS = usain.fastener.test.DummyCatalogData.REQUIRED_FIELDS
    end

    methods (Static)

        function Objs = from_struct(S)
            % See usain.fastener.BaseCatalogData.from_struct

            assert(isfield(S, 'data'), 'DummyCatalogData:from_struct:InvalidStruct', ...
                'Expected struct with "data" field.');

            nInputSets = length(S.data);
            Objs(nInputSets, 1) = usain.fastener.test.DummyCatalogData();
            for iInp = 1:nInputSets
                Objs(iInp) = usain.fastener.test.DummyCatalogData(S.data(iInp));
            end
        end

    end
end
