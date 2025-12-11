classdef FlangeNeckScfStep < usain.conditions.BaseConditionStep

    properties
        DESCRIPTION = "Flange neck bending stresses"
    end

    methods

        function Condition = get_conditions(~)
            Condition = UsainUtils.FlangeNeckScf();
        end

    end
end
