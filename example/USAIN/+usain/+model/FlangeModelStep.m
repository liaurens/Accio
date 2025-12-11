classdef FlangeModelStep < runner.BaseStep & logging.Loggable
    % Step to set up FlangeModel

    % TODO: This step is temporary, until we ditch FlangeModel (WPSSD-5639)

    properties
        doSetupLoads logical = true
    end

    methods

        function Obj = FlangeModelStep(doSetupLoads)
            arguments
                doSetupLoads logical = true
            end

            Obj.InputKeys.Inputs = usain.DataKeys.Inputs;
            Obj.InputKeys.hasFeasibleDesign = usain.DataKeys.hasFeasibleDesign;

            Obj.doSetupLoads = doSetupLoads;

            Obj.OutputKeys.FlangeModel = usain.DataKeys.FlangeModel;
        end

        function str = print_label(~)
            str = 'Build flange data model';
        end

        function pass = is_active(Obj)
            passSuperclass = is_active@runner.BaseStep(Obj);
            hasFeasibleDesign = Obj.get(Obj.InputKeys.hasFeasibleDesign);
            pass = passSuperclass && ~hasFeasibleDesign;
        end

        function run(Obj)
            Inputs = Obj.get(usain.DataKeys.Inputs);

            FlangeModel = UsainUtils.FlangeModel.setup_obj('Inputs', Inputs, 'doSetupLoads', Obj.doSetupLoads);

            Obj.set(usain.DataKeys.FlangeModel, FlangeModel);
        end

    end
end
