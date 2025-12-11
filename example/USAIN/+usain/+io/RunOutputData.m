classdef RunOutputData < dataclasses.DataClass

    properties
        didAdjustStrMdl (1, 1) logical
        logFilePath (1, 1) string
        selectedModelInputFilePath (1, 1) string
        strucModFilePath (1, 1) string = ""
        usnFilePath (1, 1) string

        FlangeNeckScf (:, :) usain.io.EquivalentScfData = usain.io.EquivalentScfData.empty
    end

    methods

        function set.FlangeNeckScf(Obj, value)
            assert(isscalar(value) || isempty(value), 'Value must be scalar or empty.');
            Obj.FlangeNeckScf = value;
        end

    end

end
