classdef ClearConditionCollectionStep < runner.BaseStep & logging.Loggable

    methods

        function Obj = ClearConditionCollectionStep(varargin)
            Obj.InputKeys.hasFeasibleDesign = usain.DataKeys.hasFeasibleDesign;

            Obj.OutputKeys.ConditionCollection = usain.DataKeys.ConditionCollection;
            Obj.OutputKeys.SelectedConditionCollection = usain.DataKeys.SelectedConditionCollection;
        end

        function str = print_label(~)
            str = 'Clear condition collection';
        end

        function pass = is_active(Obj)
            passSuperclass = is_active@runner.BaseStep(Obj);
            hasFeasibleDesign = Obj.get(Obj.InputKeys.hasFeasibleDesign);
            pass = passSuperclass && ~hasFeasibleDesign;
        end

        function run(Obj)
            Obj.set(usain.DataKeys.ConditionCollection, usain.conditions.ConditionCollection());
            Obj.set(usain.DataKeys.SelectedConditionCollection, usain.conditions.ConditionCollection());
        end

    end
end
