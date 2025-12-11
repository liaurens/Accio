classdef UltimateLimitStateJapanStep < usain.conditions.BaseConditionStep

    properties
        DESCRIPTION = "Ultimate limit state (Japan)"
    end

    methods

        function Condition = get_conditions(~)
            Condition = UsainUtils.UltimateLimitStateJpn();
        end

        function post_run_actions(Obj, Condition)
            % Note, this is a direct copy-paste of `UltimateLimitStateStep.post_run_actions`
            Inputs = Obj.get(usain.DataKeys.Inputs);

            if ~Condition.doAssess || ~Inputs.DO_UPDATE_DESIGN_SPACE || Obj.doRunOnSelectedModel
                % This if-clause is added for robustness, but not that the same is in
                % `usain.conditions.BaseConditionStep/run()`
                return
            end

            % Get smallest bolt size in feasible design space
            feasibleBoltOptions = string(Condition.Mdl.Inputs.boltOptions);

            % Construct based on unique entries
            feasibleBoltOptionsUnique = unique(feasibleBoltOptions);
            BoltOptionsUnique = usain.fastener.BoltOptionsParser(feasibleBoltOptionsUnique);

            % Get unique diameters, sorted in ascending order. Based on the lowest feasible diameter and N_DIAMETERS
            % larger, create an index mask for design space reduction.
            N_DIAMETERS = 3;
            [~, iUnique] = unique(BoltOptionsUnique.diameter);
            if length(iUnique) >= (N_DIAMETERS + 1)
                % Design space reduction is only relevant if the number of unique diameters in the feasible design
                % space is larger than N_DIAMETERS, because otherwise there will be no design space reduction
                labelsToKeep = string(BoltOptionsUnique.label(iUnique(1:N_DIAMETERS)));
                doKeepDesignPoints = contains(feasibleBoltOptions, labelsToKeep);

                Obj.Logger.info('Reducing design space for ULS-based bolt diameter selection.');
                Obj.Logger.info('Continuing with: %18s.         %8i / %-i', ...
                    labelsToKeep.join(', '), nnz(doKeepDesignPoints), Condition.Mdl.Space.nPoints);

                % Only continue with those indices
                Condition.Mdl.reduce_design_space(doKeepDesignPoints);
                Obj.set(usain.DataKeys.FlangeModel, Condition.Mdl);
            else
                Obj.Logger.info('No design space reduction (ULS-based bolt diameter selection) possible.');
            end

        end

        function update_design_space(Obj, Condition)
            % Note, this is a direct copy-paste of `UltimateLimitStateStep.update_design_space`
            update_design_space@usain.conditions.BaseConditionStep(Obj, Condition);

            Inputs = Obj.get(usain.DataKeys.Inputs);
            if strcmpi(Inputs.BOLT_DIAMETER_SELECTION, 'uls')
                Obj.post_run_actions(Condition);
            end
        end

    end
end
