classdef ConditionCollection
    % Collection of concrete UsainUtils.ICondition objects

    properties
        ConditionArray cell = {}
    end

    methods

        function Obj = append(Obj, Condition)
            assert(isscalar(Condition) && isa(Condition, 'UsainUtils.ICondition'), ...
                'Appending must be done with scalar UsainUtils.ICondition objects.');
            Obj.ConditionArray{end + 1} = Condition;
        end

        function Conditions = get_assessed_conditions(Obj)
            % Filters skipped conditions from ConditionArray
            Conditions = Obj.ConditionArray(cellfun(@(x) x.doAssess, Obj.ConditionArray));
        end

        function Conditions = get_condition_from_classname(Obj, className)
            % Returns Conditions array with all `className` Conditions in Collection
            ConditionsCell = Obj.ConditionArray(cellfun(@(x) isa(x, className), Obj.ConditionArray));
            Conditions = [ConditionsCell{:}];
        end

        function penalty = calc_total_penalty(Obj)
            % Returns combined/total penalty function of evaluated conditions
            % The logic in this method covers both the scenarios where input DO_UPDATE_DESIGN_SPACE is true and false.
            % Only the conditions that have a size equal to the last evaluated condition are considered when calculating
            % the total penalty:
            % - For DO_UPDATE_DESIGN_SPACE = false, this means ALL conditions are considered.
            % - For DO_UPDATE_DESIGN_SPACE = true, this means a subset of all conditions are considered. Only the
            %   conditions with size equal to the current design space size are relevant and considered.

            AssessedConditions = Obj.get_assessed_conditions();
            conditionSizes = cellfun(@(C) size(C.utilRatio, 1), AssessedConditions);
            isSizeEqualToLast = conditionSizes == conditionSizes(end);
            fPenaltyPerCondition = cellfun(@(C) C.calc_penalty(), AssessedConditions(isSizeEqualToLast), 'uni', 0);
            penalty = sum([fPenaltyPerCondition{:}], 2);
            if isempty(penalty)
                penalty = 0;
            end
        end

        function isFeasible = is_feasible_for_all_conditions(Obj)
            % Returns boolean array indicating design points that are feasible for ALL evaluated conditions
            % The logic is the same as for method `calc_total_penalty`.

            AssessedConditions = Obj.get_assessed_conditions();
            conditionSizes = cellfun(@(C) size(C.utilRatio, 1), AssessedConditions);
            isSizeEqualToLast = conditionSizes == conditionSizes(end);
            isFeasiblePerCondition = cellfun(@(C) C.isFeasible, AssessedConditions(isSizeEqualToLast), 'uni', 0);
            isFeasible = all([isFeasiblePerCondition{:}], 2);

            if isempty(isFeasible)
                isFeasible = false;
            end
        end

        function Conditions = iter_conditions(Obj)
            % Constructs 1xN array of all individual conditions, in order of evaluation
            %
            % NOTE: A condition that is not to be assessed (do_assess() returns false) is still included in the returned
            % Conditions array.

            % Convert ConditionArray from cell to a heterogenous array of UsainUtils.ICondition objects
            Conditions = UsainUtils.ICondition.empty;
            for e = enumerate(Obj.ConditionArray)
                Conditions(e.count) = e.value;
            end
        end

        function ConditContainer = to_conditcontainer(Obj)
            % Converts this object to a `UsainUtils.ConditContainer` object
            % NOTE: This is a temporary solution to simplify the first implementation of SequentialRunner in USAIN. For
            % that reason it is not tested.

            % Inline function to extract instances of `clsName` from Obj.ConditionArray
            fGetCondition = @(clsName) Obj.ConditionArray{cellfun(@(x) isa(x, clsName), Obj.ConditionArray)};

            % Fill UsainUtils.ConditContainer object
            ConditContainer = UsainUtils.ConditContainer();
            ConditContainer.Thread = fGetCondition('UsainUtils.ThreadRequirements');
            ConditContainer.MdlAppl = fGetCondition('UsainUtils.BoltForceModelApplicability');
            ConditContainer.Uls = fGetCondition('UsainUtils.UltimateLimitState');
            ConditContainer.UlsJpn = fGetCondition('UsainUtils.UltimateLimitStateJpn');
            ConditContainer.PreloadLoss = fGetCondition('UsainUtils.SlsPretensionLoss');
            ConditContainer.Gapping = fGetCondition('UsainUtils.FlangeGapping');
            ConditContainer.NeckScf = fGetCondition('UsainUtils.FlangeNeckScf');

            isFls = cellfun(@(x) isa(x, 'UsainUtils.FatigueLimitState'), Obj.ConditionArray);
            ConditContainer.Fls = cat(2, Obj.ConditionArray{isFls});

        end

    end
end
