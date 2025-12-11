classdef DetermineFeasibleDesignStep < runner.BaseStep & logging.Loggable

    methods

        function Obj = DetermineFeasibleDesignStep(varargin)
            Obj.InputKeys.SelectedConditionCollection = usain.DataKeys.SelectedConditionCollection;
            Obj.InputKeys.Inputs = usain.DataKeys.Inputs;

            Obj.OutputKeys.hasFeasibleDesign = usain.DataKeys.hasFeasibleDesign;
            Obj.OutputKeys.doSwitchLtoT = usain.DataKeys.doSwitchLtoT;
        end

        function str = print_label(~)
            str = 'Determine if current selected design is feasible';
        end

        function run(Obj)
            SelectedConditionCollection = Obj.get(usain.DataKeys.SelectedConditionCollection);

            hasFeasibleDesign = SelectedConditionCollection.is_feasible_for_all_conditions();

            Obj.set(usain.DataKeys.hasFeasibleDesign, hasFeasibleDesign);

            Inputs = Obj.get(usain.DataKeys.Inputs);
            allowSwitch = Inputs.DO_ALLOW_SWITCH_L_TO_T;
            doSwitchLtoT = allowSwitch & ~hasFeasibleDesign;
            Obj.set(usain.DataKeys.doSwitchLtoT, doSwitchLtoT);

        end

    end
end
