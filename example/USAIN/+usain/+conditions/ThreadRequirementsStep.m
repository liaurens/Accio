classdef ThreadRequirementsStep < usain.conditions.BaseConditionStep

    properties
        DESCRIPTION = "Bolt thread requirements"
    end

    methods

        function Condition = get_conditions(~)
            Condition = UsainUtils.ThreadRequirements();
        end

    end
end
