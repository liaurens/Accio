classdef Site

    enumeration
        ONSHORE
        OFFSHORE
    end

    methods

        function out = isnan(~)
            % This method allows to use isnan() on a member of the enumeration. Will always return false, since
            % enumeration members are not NaN.
            out = false;
        end

    end
end
