classdef WriteFilesStep < runner.BaseStep & logging.Loggable

    methods

        function Obj = WriteFilesStep(varargin)

            Obj = assign_varargin_2_classprop(Obj, varargin{:});

            Obj.InputKeys.Inputs = usain.DataKeys.Inputs;
            Obj.InputKeys.TimeStamp = usain.DataKeys.TimeStamp;
            Obj.InputKeys.SelectedConditionCollection = usain.DataKeys.SelectedConditionCollection;
            Obj.InputKeys.SelectedModel = usain.DataKeys.SelectedModel;
            Obj.InputKeys.StructuralModelOutputPath = usain.DataKeys.StructuralModelOutputPath;

            Obj.OutputKeys.UsnFilePath = usain.DataKeys.UsnFilePath;
        end

        function str = print_label(~)
            str = 'Write .usn file';
        end

        function run(Obj)

            Inputs = Obj.get(Obj.InputKeys.Inputs);
            timeStamp = Obj.get(usain.DataKeys.TimeStamp);
            SelectedModel = Obj.get(usain.DataKeys.SelectedModel);

            % Temporary hack: Convert ConditionCollection to legacy ConditContainer and assign to SelectedModel. This is
            % needed for the `store_plot_data` call in `prepare_selectedmodel_for_saving`.
            SelectedModel.Condit = Obj.get(usain.DataKeys.SelectedConditionCollection).to_conditcontainer();

            UsnFilePath = Obj.get_usn_file_path(Inputs, timeStamp);
            UsnFilePath.parent.mkdir(true);

            UsainData = struct();
            UsainData.Inputs = Inputs;
            UsainData.Mdl = Obj.prepare_selectedmodel_for_saving(SelectedModel);
            UsainData.mdlOutFilePath = Obj.get_structural_model_output_path();

            if Inputs.DO_SAVE_FULL_FILE
                FullFilePath = usain.io.save_full_usain_file(UsainData, UsnFilePath);
                Obj.Logger.info('Written .usn_full file: %s', FullFilePath.full_path);
            end

            usain.io.FilePort(UsainData).save_file(UsnFilePath);
            Obj.Logger.info('Written .usn file: %s', char(UsnFilePath));

            Obj.set(Obj.OutputKeys.UsnFilePath, UsnFilePath);
        end

        function Path = get_usn_file_path(~, Inputs, timeStamp)
            Path = pathlib.Path(Inputs.targetDir) / [timeStamp, '_USAIN_', Inputs.runName, '.usn'];
        end

        function StaticData = prepare_selectedmodel_for_saving(~, SelectedModel)

            % Store bolt force model data, linked to first FLS assessment, to use within DOCTOR
            if SelectedModel.Inputs.DO_ASSESS_FLS
                SelectedModel.Condit.Fls(1).BoltForceModel.store_plot_data(SelectedModel);
            end

            % Convert SelectedModel to static data and skip some fields that would give issues/challenges later on in
            % FilePort
            skipNames = {'\.Tab$', '\.Parent$', '\.Mdl$', '\.StrMdl$'};
            StaticData = Convert.to_basic_type(SelectedModel, skipNames);
        end

        function pathStr = get_structural_model_output_path(Obj)
            if Obj.is_gettable(usain.DataKeys.StructuralModelOutputPath)
                pathStr = char(Obj.get(usain.DataKeys.StructuralModelOutputPath));
            else
                pathStr = '';
            end
        end

    end
end
