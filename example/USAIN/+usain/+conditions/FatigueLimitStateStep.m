classdef FatigueLimitStateStep < usain.conditions.BaseConditionStep

    properties
        DESCRIPTION = "Fatigue limit state"
    end

    methods

        function identifiers = get_warning_identifiers(~)
            identifiers = "USAIN:GapCloseModel:ExcessiveGapClosingForce";
            % This warning needs to be suppressed because it is only relevant during the design check (and contaminates
            % the console during design optimization)
        end

        function Conditions = get_conditions(Obj)
            % Return array of Conditions based on inputs:
            % For 'sgre2' FLS assessments, one Condition per GAP_ANGLE
            % Otherwise, one Condition per BoltFls.BoltForceModel

            if Obj.doRunOnSelectedModel
                FlangeModel = Obj.get(usain.DataKeys.SelectedModel);
            else
                FlangeModel = Obj.get(usain.DataKeys.FlangeModel);
            end
            nBoltFls = length(FlangeModel.Inputs.BoltFls);

            for iBoltFls = 1:nBoltFls

                % Set up Petersen, Schmidt-Neuper or SGRE2.0 bolt force model
                modelType = FlangeModel.Inputs.BoltFls(iBoltFls).BOLT_FORCE_MODEL;
                switch lower(modelType)
                    case "sgre2"
                        % Construct a FatigueLimitStateWithSgre2_0 instance for each gap angle that is set in inputs
                        for iAngle = 1:length(FlangeModel.Inputs.SGRE2.GAP_ANGLE)
                            % The `sgre2` model will perform `setup_condition` to set up the BoltForceModel internally.
                            % This as the separate assessments per angle might cause a design space reduction which in
                            % turn also require the BoltForceModel to reflect that reduction. Therefore it can't be set
                            % up in a single step here.
                            Conditions{iBoltFls}(iAngle) = usain.sgre2.FatigueLimitStateWithSgre2_0(iBoltFls, iAngle);
                        end

                    otherwise
                        Conditions{iBoltFls} = UsainUtils.FatigueLimitState(iBoltFls);
                end
            end

            % Convert to 1-by-N Condition array
            Conditions = [Conditions{:}];
        end

    end
end
