classdef NoopCondition < UsainUtils.ICondition
    % NOOP implementation of a condition, for testing purposes

    properties
        description = "Just a NOOP condition"
    end
    properties (Constant)
        TOGGLE_NAME = "DO_ASSESS_NOOP_CONDITION"
    end

    methods

        function evaluate_condition(Obj)
            % Set `utilRatio` to 0.99, which can be used in tests to verify that this method was called.
            Obj.utilRatio = 0.99;
        end

    end
end
