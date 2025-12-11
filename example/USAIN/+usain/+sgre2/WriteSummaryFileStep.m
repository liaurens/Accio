classdef WriteSummaryFileStep < runner.BaseStep & logging.Loggable

    methods

        function Obj = WriteSummaryFileStep(varargin)

            Obj = assign_varargin_2_classprop(Obj, varargin{:});

            Obj.InputKeys.Inputs = usain.DataKeys.Inputs;
            Obj.InputKeys.SelectedConditionCollection = usain.DataKeys.SelectedConditionCollection;
            Obj.InputKeys.TimeStamp = usain.DataKeys.TimeStamp;

            Obj.OutputKeys.Sgre2SummaryFilePath = usain.DataKeys.Sgre2SummaryFilePath;
        end

        function str = print_label(~)
            str = 'Write SGRE2.0 summary file';
        end

        function run(Obj)
            AllConditions = Obj.get(Obj.InputKeys.SelectedConditionCollection);
            Conditions = AllConditions.get_condition_from_classname('usain.sgre2.FatigueLimitStateWithSgre2_0');
            Inputs = Obj.get(Obj.InputKeys.Inputs);
            timeStamp = Obj.get(usain.DataKeys.TimeStamp);

            Sgre2SummaryFilePath = Obj.get_summary_file_path(Inputs, timeStamp);

            SummaryFile = usain.sgre2.ExcelSummaryFile(Sgre2SummaryFilePath);
            SummaryFile.open_excel_file();
            SummaryFile.create_sheets(Inputs.SGRE2.GAP_ANGLE);

            for iAngle = 1:length(Inputs.SGRE2.GAP_ANGLE)
                % NOTE: This for-loop ensures that only results for the the first `sgre` block are reported.
                SummaryFile.fill_sheet(iAngle, Conditions(iAngle), Inputs);
            end

            SummaryFile.save_excel_file();
            Obj.Logger.info('Written SGRE2.0 summary file: %s', char(Sgre2SummaryFilePath));
            Obj.set(Obj.OutputKeys.Sgre2SummaryFilePath, Sgre2SummaryFilePath);
        end

        function Path = get_summary_file_path(~, Inputs, timeStamp)
            Path = pathlib.Path(Inputs.targetDir) / [timeStamp, '_USAIN_', Inputs.runName, '_sgre2_summary.xlsx'];
        end

        function pass = is_active(Obj)
            Inputs = Obj.get(Obj.InputKeys.Inputs);
            pass = Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS && ...
                Inputs.DO_ASSESS_FLS && ...
                any([Inputs.BoltFls.BOLT_FORCE_MODEL] == "sgre2");
        end

    end
end
