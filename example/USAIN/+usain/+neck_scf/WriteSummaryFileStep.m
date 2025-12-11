classdef WriteSummaryFileStep < runner.BaseStep & logging.Loggable

    methods

        function Obj = WriteSummaryFileStep(varargin)

            Obj = assign_varargin_2_classprop(Obj, varargin{:});

            Obj.InputKeys.Inputs = usain.DataKeys.Inputs;
            Obj.InputKeys.SelectedConditionCollection = usain.DataKeys.SelectedConditionCollection;
            Obj.InputKeys.TimeStamp = usain.DataKeys.TimeStamp;

            Obj.OutputKeys.FlangeNeckScfSummaryFile = usain.DataKeys.FlangeNeckScfSummaryFile;
        end

        function str = print_label(~)
            str = 'Write flange neck SCF summary file';
        end

        function run(Obj)
            AllConditions = Obj.get(Obj.InputKeys.SelectedConditionCollection);
            Condition = AllConditions.get_condition_from_classname('UsainUtils.FlangeNeckScf');
            assert(length(Condition) == 1, 'Expected single condition.');
            % TODO: Remove assert if possible?

            Inputs = Obj.get(Obj.InputKeys.Inputs);
            timeStamp = Obj.get(usain.DataKeys.TimeStamp);

            FlangeNeckScfSummaryFile = Obj.get_summary_file_path(Inputs, timeStamp);

            SummaryFile = usain.neck_scf.ExcelSummaryFile(FlangeNeckScfSummaryFile);
            SummaryFile.open_excel_file();
            SummaryFile.fill_sheet(Condition);
            SummaryFile.save_excel_file();
            Obj.Logger.info('Written flange neck SCF summary file: %s', char(FlangeNeckScfSummaryFile));
            Obj.set(Obj.OutputKeys.FlangeNeckScfSummaryFile, FlangeNeckScfSummaryFile);
        end

        function Path = get_summary_file_path(~, Inputs, timeStamp)
            Path = pathlib.Path(Inputs.targetDir) / ...
                [timeStamp, '_USAIN_', Inputs.runName, '_flange_neck_scf_summary.xlsx'];
        end

        function pass = is_active(Obj)
            Inputs = Obj.get(Obj.InputKeys.Inputs);
            pass = Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS && Inputs.DO_ASSESS_FLANGE_NECK_SCF;
        end

    end
end
