classdef FlangeGappingStep < usain.conditions.BaseConditionStep

    properties
        DESCRIPTION = "Flange gapping under max. fatigue loads"
    end

    methods

        function identifiers = get_warning_identifiers(~)
            identifiers = "USAIN:FlangeGapping:InfeasibleDesign";
            % This warning needs to be suppressed because it is only relevant during the design check (and contaminates
            % the console during design optimization)
        end

        function Condition = get_conditions(~)
            Condition = UsainUtils.FlangeGapping();
        end

    end
end
