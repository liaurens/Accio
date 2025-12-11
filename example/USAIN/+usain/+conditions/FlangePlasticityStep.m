classdef FlangePlasticityStep < usain.conditions.BaseConditionStep

    properties
        DESCRIPTION = "Preload loss from flange plasticity"
    end

    methods

        function identifiers = get_warning_identifiers(~)
            identifiers = "USAIN:FlangePlasticity:InfeasibleDesign";
            % This warning needs to be suppressed because it is only relevant during the design check (and contaminates
            % the console during design optimization)
        end

        function Condition = get_conditions(~)
            Condition = usain.conditions.FlangePlasticity();
        end

    end
end
