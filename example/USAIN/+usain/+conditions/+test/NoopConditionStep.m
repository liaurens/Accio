classdef NoopConditionStep < usain.conditions.BaseConditionStep
    % NOOP implementation of a BaseConditionStep, for testing purposes

    properties
        DESCRIPTION = "NOOP condition for testing"
    end

    methods

        function Condition = get_conditions(~)
            Condition = usain.conditions.test.NoopCondition();
        end

    end
end
