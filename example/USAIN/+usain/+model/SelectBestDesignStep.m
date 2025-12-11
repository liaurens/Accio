classdef SelectBestDesignStep < runner.BaseStep & logging.Loggable

    methods

        function Obj = SelectBestDesignStep()

            Obj.InputKeys.ConditionCollection = usain.DataKeys.ConditionCollection;
            Obj.InputKeys.FlangeModel = usain.DataKeys.FlangeModel;
            Obj.InputKeys.hasFeasibleDesign = usain.DataKeys.hasFeasibleDesign;

            Obj.OutputKeys.SelectedModel = usain.DataKeys.SelectedModel;
            Obj.OutputKeys.hasFeasibleDesign = usain.DataKeys.hasFeasibleDesign;
        end

        function str = print_label(~)
            str = 'Select best design';
        end

        function pass = is_active(Obj)
            passSuperclass = is_active@runner.BaseStep(Obj);
            hasFeasibleDesign = Obj.get(Obj.InputKeys.hasFeasibleDesign);
            pass = passSuperclass && ~hasFeasibleDesign;
        end

        function run(Obj)

            Conditions = Obj.get(Obj.InputKeys.ConditionCollection);
            FlangeModel = Obj.get(Obj.InputKeys.FlangeModel);

            % Find cheapest, feasible design. If no designs are feasible, select least penalized design
            isFeasible = Conditions.is_feasible_for_all_conditions();
            if any(isFeasible)
                penalty = Conditions.calc_total_penalty();
                cost = usain.model.CostModel.from_flange_model(FlangeModel).calc_cost();
                if FlangeModel.Inputs.DO_UPDATE_DESIGN_SPACE
                    % Cost is computed for feasible points only.
                    costFeasibleDesigns = cost;
                else
                    % Cost is computed for all points, while we only need the feasible ones.
                    costFeasibleDesigns = cost(isFeasible);
                end
                % NOTE: `penalty` is a vector of length M and `cost` of length N, for a design space of size M with N
                % feasible designs.

                % Augment cost such that infeasible design points all have an equal, very high cost, to ensure feasible
                % designs are always favored over infeasible ones
                augmentedCost = 1e3 * ones(size(penalty)) * max(cost);
                augmentedCost(isFeasible) = costFeasibleDesigns;

                % Find best point from Conditions and translate that to the best point in the design space. This logic
                % is needed because the design space may be updated prior to a step that is skipped, resulting in
                % different array sizes in the last assessed condition and the design space.
                [~, iBestInConditions] = min(augmentedCost + penalty);
                iBestInDesignSpace = find(FlangeModel.Space.index == iBestInConditions);  % we need a linear index
                assert(isscalar(iBestInDesignSpace), 'Expected a single best design point.');

            else
                Obj.Logger.warning(['No feasible flange design could be found for the provided inputs.\n', ...
                    '\t==> Selecting solution closest to feasible in evaluated, infeasible solution space.']);

                % Generally the FlangeModel describes a single point (the best infeasible point), determined in
                % BaseConditionStep.update_design_space(). However, in case of `DO_UPDATE_DESIGN_SPACE = false` that
                % method is not called and therefore need to determine that point here.
                if FlangeModel.Space.nPoints == 1
                    iBestInDesignSpace = 1;
                else
                    [~, iBestInDesignSpace] = min(Conditions.calc_total_penalty());
                end
            end

            % Build a SelectedModel based on the best design point
            SelectedModel = UsainUtils.SelectedModel.select_flange_model(FlangeModel, iBestInDesignSpace);
            Obj.set(Obj.OutputKeys.SelectedModel, SelectedModel);
        end

    end
end
