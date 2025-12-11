classdef WriteSelectedModelInputFileStep < runner.BaseStep & logging.Loggable

    methods

        function Obj = WriteSelectedModelInputFileStep()
            Obj.InputKeys.SelectedModel = usain.DataKeys.SelectedModel;
            Obj.InputKeys.SourceInputFilePath = usain.DataKeys.SourceInputFilePath;
            Obj.InputKeys.TimeStamp = usain.DataKeys.TimeStamp;

            Obj.OutputKeys.SelectedModelInputFilePath = usain.DataKeys.SelectedModelInputFilePath;
        end

        function str = print_label(~)
            str = 'Write input file for re-running selected model';
        end

        function run(Obj)

            % Get inputs from SelectedModel property because that one is guaranteed to be up-to-date
            % TODO: Get inputs from Inputs data-key when removing SelectedModel (WPSSD-5639)
            Inputs = Obj.get(usain.DataKeys.SelectedModel).Inputs;
            sourceInputFilePath = Obj.get(usain.DataKeys.SourceInputFilePath);
            timeStamp = Obj.get(usain.DataKeys.TimeStamp);

            SelectedModelInputs = usain.io.SelectedModelInputs(Inputs = Inputs, timeStamp = timeStamp);
            InputFileObj = SelectedModelInputs.create_filecontent(sourceInputFilePath);
            InputFilePath = SelectedModelInputs.write_file(InputFileObj);
            Obj.Logger.info('Written selectedMdl.inp file: %s', InputFilePath.full_path);

            Obj.set(usain.DataKeys.SelectedModelInputFilePath, InputFilePath);
        end

    end
end
