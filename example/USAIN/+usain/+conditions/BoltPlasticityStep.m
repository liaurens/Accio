classdef BoltPlasticityStep < usain.conditions.BaseConditionStep

    properties
        DESCRIPTION = "Preload loss from bolt plasticity"
    end

    methods

        function identifiers = get_warning_identifiers(~)
            identifiers = ["USAIN:BoltPlasticity:InfeasibleDesign", ...
                "USAIN:GapCloseModel:ExcessiveGapClosingForce"];
            % This warning needs to be suppressed because it is only relevant during the design check (and contaminates
            % the console during design optimization)
        end

        function Conditions = get_conditions(Obj)
            % Return array of Conditions based on inputs:
            % For 'sgre2' FLS assessments, one Condition per GAP_ANGLE
            % Otherwise, no Condition

            Inputs = Obj.get(usain.DataKeys.Inputs);
            isSgre2 = [Inputs.BoltFls.BOLT_FORCE_MODEL] == "sgre2";
            assert(any(isSgre2), ...
                "Expected inactive `BoltPlasticity` condition, as no 'sgre2' assessments are active in this run.");

            for iBoltFls = find(isSgre2)
                for iAngle = 1:length(Inputs.SGRE2.GAP_ANGLE)
                    % The `sgre2` model will perform `setup_condition` to set up the BoltForceModel internally.
                    % This as the separate assessments per angle might cause a design space reduction which in
                    % turn also require the BoltForceModel to reflect that reduction. Therefore it can't be set
                    % up in a single step here.
                    Conditions{iBoltFls}(iAngle) = usain.conditions.BoltPlasticity(iBoltFls, iAngle);
                end
            end

            % Convert to 1-by-N Condition array
            Conditions = [Conditions{:}];
        end

        function pass = is_active(Obj)

            % First, check if assessment is activated in inputs
            pass = Obj.get(usain.DataKeys.Inputs).DO_ASSESS_BOLT_PLASTICITY;

            % Additionally, verify that there's an `sgre2` assessment in this run
            if pass
                Inputs = Obj.get(usain.DataKeys.Inputs);
                isSgre2 = [Inputs.BoltFls.BOLT_FORCE_MODEL] == "sgre2";
                pass = any(isSgre2);
            end

            if ~pass
                % Append empty condition because we want to explicitly register that it has not been run, such that we
                % know what to report in the logged summary at the end of a run.
                Obj.append_condition_collection(usain.conditions.BoltPlasticity(1, 1));
            end
        end

    end
end
