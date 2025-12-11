classdef BoltForceModelApplicabilityStep < usain.conditions.BaseConditionStep

    properties
        DESCRIPTION = "Schmidt-Neuper applicability"
    end

    methods

        function Condition = get_conditions(~)
            Condition = UsainUtils.BoltForceModelApplicability();
        end

    end
end
