classdef (Abstract) BaseConditionStep < runner.BaseStep & logging.Loggable
    % Abstract base class for step to create and evaluate a condition

    properties
        doRunOnSelectedModel logical = false
    end

    properties (Abstract)
        DESCRIPTION string
    end

    methods

        function Obj = BaseConditionStep(varargin)

            Obj = assign_varargin_2_classprop(Obj, varargin{:});

            Obj.InputKeys.ConditionCollection = usain.DataKeys.ConditionCollection;
            Obj.InputKeys.FlangeModel = usain.DataKeys.FlangeModel;
            Obj.InputKeys.SelectedConditionCollection = usain.DataKeys.SelectedConditionCollection;
            Obj.InputKeys.SelectedModel = usain.DataKeys.SelectedModel;
            Obj.InputKeys.Inputs = usain.DataKeys.Inputs;
            Obj.InputKeys.hasFeasibleDesign = usain.DataKeys.hasFeasibleDesign;

            Obj.OutputKeys.ConditionCollection = usain.DataKeys.ConditionCollection;
            Obj.OutputKeys.SelectedConditionCollection = usain.DataKeys.SelectedConditionCollection;
            Obj.OutputKeys.FlangeModel = usain.DataKeys.FlangeModel;
        end

        function run(Obj)
            % Evaluates condition(s)

            if ~Obj.doRunOnSelectedModel
                Obj.suppress_warnings();
            end

            Inputs = Obj.get(usain.DataKeys.Inputs);

            % Query conditions and loop over them to evaluate sequentially
            Conditions = Obj.get_conditions();
            for Condition = Conditions

                if Obj.doRunOnSelectedModel
                    Condition.Mdl = Obj.get(usain.DataKeys.SelectedModel);
                else
                    Condition.Mdl = Obj.get(usain.DataKeys.FlangeModel);
                end

                if Condition.doAssess
                    % First reset design space index such that it corresponds to the array sizes used in Condition
                    Condition.Mdl.Space.reset_index();

                    Obj.Logger.info('Starting evaluation of %s.', Obj.DESCRIPTION);
                    tStart = tic();
                    Condition.setup_condition();
                    Condition.evaluate_condition();
                    tElapsed = sprintf('%.3f', toc(tStart));
                    Obj.Logger.info('Finished in %7ss. Number of feasible solutions: %8i / %-i', ...
                        tElapsed, Condition.nFeasible, Condition.Mdl.Space.nPoints);
                else
                    Obj.Logger.info('Skipping evaluation of %s.', Obj.DESCRIPTION);
                end

                % Append condition to collection even if it was not assessed, because we want to loop over all
                % conditions in DesignSummaryStep
                Obj.append_condition_collection(Condition);

                % Discard infeasible points if inputs enable this and only for runs on FlangeModel. For checks with
                % SelectedModel this is not relevant (as a SelectedModel describes a single design point).
                if Condition.doAssess && Inputs.DO_UPDATE_DESIGN_SPACE && ~Obj.doRunOnSelectedModel
                    Obj.update_design_space(Condition);
                end
            end

            if ~Obj.doRunOnSelectedModel
                Obj.reset_warnings();
            end
        end

        function update_design_space(Obj, Condition)
            % Updates (reduces) design space by removing infeasible points

            doKeepDesignPoints = Condition.isFeasible;

            if ~any(doKeepDesignPoints)
                % Entire design space is infeasible: continue with the "best infeasible" design
                Collection = Obj.get(usain.DataKeys.ConditionCollection);
                [~, iBest] = min(Collection.calc_total_penalty());
                doKeepDesignPoints(iBest) = true;
            end

            Condition.Mdl.reduce_design_space(doKeepDesignPoints);
            Obj.set(usain.DataKeys.FlangeModel, Condition.Mdl);
        end

        function append_condition_collection(Obj, Condition)
            % Appends this step's condition to the end of the ConditionCollection data-key

            if Obj.doRunOnSelectedModel
                Collection = Obj.get(usain.DataKeys.SelectedConditionCollection);
                Obj.set(usain.DataKeys.SelectedConditionCollection, Collection.append(Condition));
            else
                Collection = Obj.get(usain.DataKeys.ConditionCollection);
                Obj.set(usain.DataKeys.ConditionCollection, Collection.append(Condition));
            end
        end

        function suppress_warnings(Obj)
            % Temporarily suppresses warnings
            WarnState = logging.WarningState.get_instance();
            for id = Obj.get_warning_identifiers()
                WarnState.get_state(char(id));
                WarnState.set_state(char(id), 'off');
            end
        end

        function reset_warnings(Obj)
            % Resets state of suppressed warnings
            WarnState = logging.WarningState.get_instance();
            for id = Obj.get_warning_identifiers()
                WarnState.reset_state(char(id));
            end
        end

        function pass = is_active(Obj)
            % Determines if step is to be run or skipped
            hasFeasibleDesign = Obj.get(Obj.InputKeys.hasFeasibleDesign);
            if hasFeasibleDesign
                pass = false;
                return
            end

            % Query first condition (if multiple)
            % TODO: Move property Condition.TOGGLE_NAME and corresponding logic to this class?
            Conditions = Obj.get_conditions();
            Condition = Conditions(1);

            if Obj.doRunOnSelectedModel
                pass = Obj.get(usain.DataKeys.SelectedModel).Inputs.(Condition.TOGGLE_NAME);
            else
                pass = Obj.get(usain.DataKeys.FlangeModel).Inputs.(Condition.TOGGLE_NAME);
            end

            if ~pass
                Obj.Logger.info('Skipping evaluation of %s.', Obj.DESCRIPTION);
                % Append empty condition because we want to explicitly register that it has not been run, such that we
                % know what to report in the logged summary at the end of a run.
                Obj.append_condition_collection(Condition);
            end

        end

        function str = print_label(Obj)
            str = Obj.DESCRIPTION;
        end

        function identifiers = get_warning_identifiers(~)
            % Overload in subclasses if warnings are to be suppressed during optimization
            % identifiers: String array with warning identifiers
            identifiers = string.empty;
        end

    end

    methods (Abstract)
        % Constructs and returns new condition instance(s) linked to this step
        % Conditions: (Array of) concrete UsainUtils.ICondition instances
        Conditions = get_conditions(Obj)
    end

end
