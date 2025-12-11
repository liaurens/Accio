classdef LoadExternalFilesStep < runner.BaseStep & logging.Loggable
    % Step class for loading external files

    methods

        function Obj = LoadExternalFilesStep(varargin)

            Obj = assign_varargin_2_classprop(Obj, varargin{:});

            Obj.InputKeys.Inputs = usain.DataKeys.Inputs;
            Obj.OutputKeys.StructuralModel = usain.DataKeys.StructuralModel;
            Obj.OutputKeys.ExternalFlsLoadsData = usain.DataKeys.ExternalFlsLoadsData;
            Obj.OutputKeys.ExternalS1LoadsData = usain.DataKeys.ExternalS1LoadsData;
            Obj.OutputKeys.ExternalUlsLoadsData = usain.DataKeys.ExternalUlsLoadsData;
        end

        function str = print_label(~)
            str = 'Load external files';
        end

        function run(Obj)
            Inputs = Obj.get(usain.DataKeys.Inputs);

            % Load and set StructuralModel
            StructuralModelPath = pathlib.Path(Inputs.structureInpFilePath);
            StructuralModelObj = Obj.load_structural_model(StructuralModelPath);
            Obj.set(usain.DataKeys.StructuralModel, StructuralModelObj);

            if isempty(StructuralModelObj)
                Levels = Fe.LevelsContainer.empty();
            else
                Levels = StructuralModelObj.Levels;
            end

            % Optionally, load FLS load files and set data-key
            if usain.loads.Loads.check_is_required_fls(Inputs)
                ExternalFlsLoadsData = Obj.load_fls_files(Levels, Inputs);
                Obj.set(usain.DataKeys.ExternalFlsLoadsData, ExternalFlsLoadsData);
            end

            % Optionally, load ULS load files and set data-key
            if usain.loads.Loads.check_is_required_uls(Inputs) && isnan(Inputs.ULS_BENDING_MOMENT)
                ExternalUlsLoadsData = Obj.load_uls_files(Levels, Inputs);
                Obj.set(usain.DataKeys.ExternalUlsLoadsData, ExternalUlsLoadsData);
            end

            % Optionally, load S1 load files and set data-key
            if usain.loads.Loads.check_is_required_s1(Inputs) && isnan(Inputs.S1_BENDING_MOMENT)
                ExternalS1LoadsData = Obj.load_s1_files(Levels, Inputs);
                Obj.set(usain.DataKeys.ExternalS1LoadsData, ExternalS1LoadsData);
            end
        end

        function StructuralModelObj = load_structural_model(Obj, StructuralModelPath)
            if StructuralModelPath.is_file()
                Obj.Logger.info('Loading input StructuralModel file: %s', StructuralModelPath);
                try
                    StructuralModelObj = StructuralModel(char(StructuralModelPath));
                catch ME
                    Obj.Logger.error(['Error caught while loading StructuralModel ', ...
                        'from input "structureInpFilePath":\n%s\n\nOriginal error message:\n%s'], ...
                        StructuralModelPath, ME.message);
                end
            else
                StructuralModelObj = [];
            end
        end

        function UlsLoadsData = load_uls_files(Obj, Levels, Inputs)
            % Load ULS loads files and filter for DLCs
            if usain.loads.Loads.check_is_required_uls(Inputs)

                UlsLoadsData = Milk.ExtremeLoads.load_unique(Inputs.Loads.ulsFilePath);
                for iUls = 1:numel(UlsLoadsData)
                    UlsLoadsData(iUls).apply_zlevel_offset(Levels, Inputs.Loads.ALIGN_AT{iUls});
                end

                for file = string(Inputs.Loads.ulsFilePath(:)')
                    Obj.log_success('ULS loads', file);
                end

                for iFile = 1:numel(UlsLoadsData)
                    UlsLoadsData(iFile) = UlsLoadsData(iFile).select_uls_subsets( ...
                        Inputs.Loads.dlcFilter{iFile}, Inputs.Loads.tag{iFile});
                end
            else
                UlsLoadsData = [];
            end
        end

        function FlsLoadsData = load_fls_files(Obj, Levels, Inputs)
            % Load FLS loads files
            if usain.loads.Loads.check_is_required_fls(Inputs)
                FlsLoadsData = Milk.FatigueLoads.import_from_file(Inputs.Loads.flsFilePath);
                for iFls = 1:numel(FlsLoadsData)
                    % Ignore setting the offset if the flsFilePath is Markov file as we are not storing channel
                    % information. Please see the Milk.FatigueLoads.import_from_file
                    if ~strcmp(pathlib.Path(FlsLoadsData(iFls).sourceFilePath).suffix, '.mkv')
                        FlsLoadsData(iFls).apply_zlevel_offset(Levels, Inputs.Loads.ALIGN_AT{iFls});
                    end
                end

                for file = string(Inputs.Loads.flsFilePath(:))'
                    Obj.log_success('FLS loads', file);
                end
            else
                FlsLoadsData = [];
            end
        end

        function S1LoadsData = load_s1_files(Obj, Levels, Inputs)
            % Load ULS loads files and filter for DLCs
            if usain.loads.Loads.check_is_required_s1(Inputs)

                for e = enumerate(Inputs.Loads.S1FilePath(:)')
                    if isempty(e.value)
                        S1LoadsData(e.count) = Milk.ServiceAbilityLoads();  %#ok
                    else
                        S1LoadsData(e.count) = Milk.ServiceAbilityLoads.import_from_file(e.value);  %#ok
                        S1LoadsData(e.count).apply_zlevel_offset(Levels, Inputs.Loads.ALIGN_AT{e.count});
                    end
                end

                for file = string(Inputs.Loads.S1FilePath(:)')
                    Obj.log_success('S1 loads', file);
                end
            else
                S1LoadsData = [];
            end
        end

        function log_success(Obj, fileDescription, filePath)
            Obj.Logger.info('Successfully loaded %s from file: %s', fileDescription, filePath);
        end

    end
end
