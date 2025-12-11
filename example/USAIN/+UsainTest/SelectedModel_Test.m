classdef (SharedTestFixtures = {Unittest.fixtures.SilentlyLogWarningsFixture}) ...
        SelectedModel_Test < Unittest.TestCase
    methods (Test, TestTags = {'unit'})

        function select_flange_model__happy(Obj)
            % GIVEN a flange segment model, constructed from inputs that are set such that no loads will be imported
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;
            Inputs.DO_ASSESS_FLS = false;
            Inputs.DO_ASSESS_ULS = false;
            Inputs.boltOptions = {'ISO_M42'};

            % Note that only a small design space will be set up. This since the method call `select_flange_model` will
            % build the design space and operations on the design space make it difficult to "pick" a feasible design
            % for which e.g. the checks on bolt circle diameter will pass.
            Inputs.minFlangeThickn = 0.110;
            Inputs.maxFlangeThickn = 0.120;
            Inputs.minFlangeWidth = 0.340;
            Inputs.maxFlangeWidth = 0.342;
            Inputs.minNBolts = 236;
            Inputs.maxNBolts = 240;

            Inputs.DO_TRIM_DESIGN_SPACE =  true;

            FlangeModel = UsainUtils.FlangeModel.setup_obj('Inputs', Inputs);
            iSel = 1;

            % WHEN THEN
            Obj.verify_error_free(@() UsainUtils.SelectedModel.select_flange_model(FlangeModel, iSel));

            % WHEN THEN the SelectedModel is inherited from FlangeModel
            SelectedModel = UsainUtils.SelectedModel.select_flange_model(FlangeModel, iSel);
            Obj.verifyInstanceOf(SelectedModel, ?UsainUtils.FlangeModel);

            % GIVEN same inputs, only update `DO_TRIM_DESIGN_SPACE`
            Inputs.DO_TRIM_DESIGN_SPACE = false;

            % WHEN THEN
            FlangeModel = UsainUtils.FlangeModel.setup_obj('Inputs', Inputs);
            Obj.verify_error_free(@() UsainUtils.SelectedModel.select_flange_model(FlangeModel, iSel));
        end

        function select_flange_model__pick_multiple_models(Obj)
            % GIVEN a flange segment model, constructed from inputs that are set such that no loads will be imported
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;
            Inputs.DO_ASSESS_FLS = false;
            Inputs.DO_ASSESS_ULS = false;
            FlangeModel = UsainUtils.FlangeModel.setup_obj('Inputs', Inputs);
            iSel = [1 2];

            % WHEN THEN it errors because we can only pick one model
            Obj.verifyError(@() UsainUtils.SelectedModel.select_flange_model(FlangeModel, iSel), ...
                'USAIN:SelectedModel:NonScalar');
        end

    end

end
