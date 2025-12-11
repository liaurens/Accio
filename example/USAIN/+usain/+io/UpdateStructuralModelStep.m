classdef UpdateStructuralModelStep < runner.BaseStep & logging.Loggable

    methods

        function Obj = UpdateStructuralModelStep()
            Obj.InputKeys.Inputs = usain.DataKeys.Inputs;
            Obj.InputKeys.StructuralModel = usain.DataKeys.StructuralModel;
            Obj.InputKeys.SelectedModel = usain.DataKeys.SelectedModel;

            Obj.OutputKeys.StructuralModelOutputPath = usain.DataKeys.StructuralModelOutputPath;
        end

        function str = print_label(~)
            str = 'Update StructuralModel';
        end

        function pass = is_active(Obj)
            % First check if get() succeeds on all non-optional input data-keys
            pass = is_active@runner.BaseStep(Obj);

            % If parent `is_active()` succeeds, verify that data-key `StructuralModel` is not empty
            if pass
                StructuralModelObj = Obj.get(usain.DataKeys.StructuralModel);
                pass = ~isempty(StructuralModelObj);
            end
        end

        function run(Obj)
            Inputs = Obj.get(usain.DataKeys.Inputs);
            StructuralModelObj = Obj.get(usain.DataKeys.StructuralModel);
            SelectedModel = Obj.get(usain.DataKeys.SelectedModel);

            StructuralModelObj = Obj.update_structural_model(StructuralModelObj, SelectedModel, Inputs);
            StructuralModelOutputPath = Obj.save_structural_model(StructuralModelObj, Inputs);

            Obj.set(usain.DataKeys.StructuralModelOutputPath, StructuralModelOutputPath);
        end

        function StructuralModelObj = update_structural_model(Obj, StructuralModelObj, SelectedModel, Inputs)
            % Updates plate element length and pointMass value in StructuralModel

            % Update length of flange(s) in PlateInput table. Include allowance on thickness as this reflects the flange
            % thickness that will be ordered.
            PlateTable = StructuralModelObj.Inp.Plate;
            newThickness = [Inputs.ALW_UPPER_FLANGE_THICKNESS, Inputs.ALW_LOWER_FLANGE_THICKNESS] + ...
                SelectedModel.Space.thickness + ...
                [SelectedModel.Inputs.heightNoseUp, SelectedModel.Inputs.heightNoseLo];
            % TODO: Use heightNoseUp/Lo directly from Inputs (WPSSD-5639). Currently not possible because only
            % SelectedModel.Inputs is up-to-date
            PlateTable.update_flange_connection_len(Inputs.zFlange, newThickness);

            % Update flangeType in PlateInput table
            PlateTable.update_flange_type(Inputs.zFlange, SelectedModel.flangeType);

            % Update pointMass element of flange in ElemInput table
            ElemTable = StructuralModelObj.Inp.Elem;
            doIncludeFlange = ~(abs(Inputs.zFlange - StructuralModelObj.Levels.zRange) < 1e-6);
            addedMass = round( ...
                [SelectedModel.massStubUp, SelectedModel.massStubLo] + (0.5 * SelectedModel.massBoltAssm));
            ElemTable.update_flange_connection_mass(Inputs.zFlange, addedMass(doIncludeFlange));

            % If the design is for a T-flange with outermost reference diameter, fix the diameters of the cans to ensure
            % they align properly with the outer diameter at the flange nose.
            doUpdateCans = SelectedModel.flangeType == "T" && Inputs.diameterReference == "outermost";
            if doUpdateCans

                PlateAlignment = PlateAlignmentHandler.setup_from_plate_table(PlateTable);
                iPlate = PlateTable.find_flange_at_zlevel(Inputs.zFlange);
                diameterOutNeck = SelectedModel.diameterOutNeck;
                if isscalar(iPlate)
                    newDiameter = diameterOutNeck;
                elseif numel(iPlate) == 2
                    newDiameter = [diameterOutNeck; diameterOutNeck + Inputs.thicknNoseLo - Inputs.thicknNoseUp];
                else
                    % Oh-oh, shit happened!
                end

                msg = PlateAlignment.update_diameters_for_l_to_t_flange_switch(iPlate, newDiameter);
                Obj.Logger.info(msg);

                % Assign the new diameters to the PlateTable in StructuralModel and enforce alignment to be "center"
                PlateTable.Parsed.diamTop = PlateAlignment.diamOut(:, PlateAlignment.I_COL_TOP);
                PlateTable.Parsed.diamBot = PlateAlignment.diamOut(:, PlateAlignment.I_COL_BOT);
                PlateTable.Parsed.plateAlignment = PlateAlignment.algnType(:, PlateAlignment.I_COL_TOP);
            end

        end

        function StructuralModelOutputPath = save_structural_model(Obj, StructuralModelObj, Inputs)

            [TargetDir, fileName] = Obj.get_target_path_info(Inputs);

            % Only save a StructuralModel Excel file if the input StructuralModel was an Excel file as well. Save .mat
            % otherwise. Do so while suppressing <= INFO logs from StructuralModel because it gives a different look &
            % feel than USAIN's log messages
            if pathlib.Path(Inputs.structureInpFilePath).suffix().startsWith(".xls")
                originalLogLevel = StructuralModelObj.Inp.Logger.level;
                StructuralModelObj.Inp.Logger.level = logging.Level.WARNING;

                TargetFilePath = TargetDir / [fileName '.xlsm'];
                outputFile = StructuralModelObj.Inp.save_to_xls(char(TargetFilePath));
                Obj.Logger.info('Written StructuralModel .xlsm file: %s', outputFile);

                StructuralModelObj.Inp.Logger.level = originalLogLevel;
            else
                originalLogLevel = StructuralModelObj.Logger.level;
                StructuralModelObj.Logger.level = logging.Level.WARNING;

                TargetFilePath = TargetDir / [fileName '.mat'];
                outputFile = StructuralModelObj.save2mat(char(TargetFilePath));
                Obj.Logger.info('Written StructuralModel .mat file: %s', outputFile);

                StructuralModelObj.Logger.level = originalLogLevel;
            end

            StructuralModelOutputPath = pathlib.Path(outputFile);
        end

        function [TargetDir, fileName] = get_target_path_info(~, Inputs)
            TargetDir = pathlib.Path(Inputs.targetDir, 'StrucMod');
            fileName = sprintf('InputTable_StrMdl_%s', Inputs.runName);
        end

    end
end
