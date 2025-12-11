classdef Runner < Batch.Runner & logging.Config
    % USAIN input file batch runner
    %
    %   Get a copy of a USAIN overrides input file (for batch running):
    %   >> <a href="matlab: home; help USAIN.copy_inputfiles">USAIN.copy_inputfiles</a>
    %
    %   INSTRUCTIONS:
    %   - Define jobs by specifying zFlange(i) inputs in the overrides input
    %     file. For example, to define jobs for flange connection #2 and #5:
    %
    %       zFlange(2)              : -50
    %       zFlange(5)              :  12.4
    %
    %   - Specifically for TEXACO runs, define the input StructuralModel in the
    %     overrides input file:
    %
    %       structureInpFilePath    : 'c:\some\path\to\strmdl.mat'
    %
    %   - Specifically for TEXACO runs INCLUDING a MEATLOAF run, define the
    %     input ulsMeatloafFilePath:
    %
    %       ulsMeatloafFilePath : <VOID>
    %
    %     For situations where ULS loads are not obtained via MEATLOAF in
    %     the same TEXACO run, provide the ULS load files (.dat / .meat) in the
    %     USAIN baseInpFile.
    %
    %   - Define input file overrides that will be used to replace input
    %     variables in the base USAIN input file.
    %     For example, to override the minimum number of bolts for flange
    %     connection #2 and to override the the bolt options for #2 and #5:
    %
    %       minNBolts(2)            : 110
    %
    %       boltOptions(2)          : ISO_M42 ISO_M48x380
    %       boltOptions(5)          : ISO_M56 ISO_M64 ISO_M72
    %
    %   - Similarly nested inputs can be used as overrides as well.
    %     For example, to include inputs to account for a door segment at
    %     the interface flange (e.g. #5):
    %
    %       DOOR_SEGMENT.DO_INCLUDE(5) : true
    %       DOOR_SEGMENT.THICKNESS(5) : 100
    %
    %   - Run USAIN in batch mode
    %       >> <a href="matlab: home; help USAIN.run_batch">USAIN.run_batch</a>
    %

    properties
        Parsed struct           % Parsed inputs
        Overrides struct        % Overrides for USAIN input file
    end
    properties (Dependent)
        iJob                    % Job indices (based on indices of parsed input "zFlange")
        jobNames                % Job names

        baseInpFilePath         % USAIN base input file
    end
    properties (Constant)
        RUNNER_NAME = 'USAIN_BatchRunner'
    end

    methods

        function Obj = Runner(varargin)

            % Pass inputs on to superclass constructor
            Obj@Batch.Runner(varargin{:});
        end

        %%% == BATCH INPUT FILE PROCESSING == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function read_parse_validate_inputfile(Obj, inputFilePath, doSkipVoid)

            if nargin < 3
                doSkipVoid = false;
            end

            % Load the input file
            Obj.Inp = InputFile(inputFilePath);
            Obj.Inp.targetFilePath = inputFilePath;
            Obj.Inp.skipVoid = doSkipVoid;

            % Expand and resolve paths for the following input fields
            varNames = [
                "usainBaseInpFilePath", ...
                "structureInpFilePath", ...
                "ulsMeatloafFilePath", ...
                "targetDir", ...
                "JOB_BASE_DIR"];
            inpfilehelper.expand_and_resolve_paths(Obj.Inp, varNames);

            % Fix indexing in the InputFile object in case no varName(1) is defined
            inpfilehelper.keep_index_order(Obj.Inp);

            % Load defaults / shortcuts for attribute definitions
            IA = InputAttributes();
            fAssign = @(varName) ['Inps.' varName];

            % First, parse JOB_BASE_DIR because other inputs depend on it
            varName = 'JOB_BASE_DIR';
            valFun = IA.make_path_valfun(varName, 'mustExist', false);
            Obj.Inp.add_optional(varName, char(pathlib.Path(inputFilePath).parent), valFun, fAssign(varName));

            try
                Obj.Inp.parse();
            catch ME
                if strcmpi(ME.identifier, 'InputFile:parse:MultipleFailedValidations')
                    error(regexprep(ME.message, '(\\)', '\\\'));
                end
                rethrow(ME);
            end

            % Parse required inputs
            varName = 'usainBaseInpFilePath';
            valFun = IA.make_filepath_valfun(varName, '.inp');
            Obj.Inp.add_required(varName, valFun, fAssign(varName));

            varName = 'zFlange';
            valFun = {@(x, ~) validateattributes(x, IA.CLS_NUM, IA.ATTR_NUM_SC, '', varName)};
            Obj.Inp.add_required(varName, valFun, fAssign(varName));

            varName = 'structureInpFilePath';
            valFun = IA.make_filepath_valfun(varName, {'.mat', '.xlsm'});
            Obj.Inp.add_optional(varName, '', valFun, fAssign(varName));

            varName = 'targetDir';
            DefaultTargetDir = pathlib.Path(Obj.Inp.Vars.JOB_BASE_DIR.value) / 'Res';
            valFun = IA.make_path_valfun(varName, 'mustExist', false);
            Obj.Inp.add_optional(varName, char(DefaultTargetDir), valFun, fAssign(varName));

            varName = 'runName';
            valFun = @(x, ~) validateattributes(x, IA.CLS_CHAR, IA.ATTR_CHAR, '', varName);
            Obj.Inp.add_optional(varName, '', valFun, fAssign(varName));

            varName = 'ulsMeatloafFilePath';
            valFun = @(x, ~) validateattributes(x, IA.CLS_CHAR, IA.ATTR_CHAR, '', varName);
            Obj.Inp.add_optional(varName, '', valFun, fAssign(varName));

            try
                Obj.Inp.parse();
            catch ME
                if strcmpi(ME.identifier, 'InputFile:parse:MultipleFailedValidations')
                    error(regexprep(ME.message, '(\\)', '\\\'));
                end
                rethrow(ME);
            end

            % Assign to Overrides
            Obj.Overrides = Obj.Inp.assign2caller('all');
        end

        function do_post_parse_manipulations(Obj)

            % Convert everything to cells for uniform processing
            Obj.Overrides = Obj.convert_struct_fields_to_cell(Obj.Overrides);

            % Move explicitly parsed inputs to property Overrides
            Obj.Parsed = Obj.Overrides.Inps;
            Obj.Overrides = rmfield(Obj.Overrides, 'Inps');

            % Replace whitespace in certain inputs by underscores
            Obj.Parsed.runName = regexprep(Obj.Parsed.runName, '\s', '_');

            % Make targetDir and subfolders
            Obj.create_target_dir(Obj.Parsed.targetDir{1});

            % Move log file
            Obj.move_log_file();
        end

        function do_post_parse_checks(Obj)
            % TODO: Write unit tests

            assertFuncs = {}; % To present all errors at once

            % Error if overrides exists for job indices that have no zFlange (=
            % Obj.iJob) defined
            isOvrdWithoutJob = ~ismember(Obj.overrideIndices, Obj.iJob);
            assertFuncs{end + 1} = @() assert(~any(isOvrdWithoutJob), ...
                ['One or more overrides found for jobs that have no ''zFlange'' defined:', ...
                '\n\n\t%s\n\n', ...
                '\t==> Make sure that every ''override(i)'' input has a ''zFlange(i)'' defined'], ...
                strjoin(Obj.overrideNamesWithIdx(isOvrdWithoutJob), '\n\t'));

            % Error if required inputs are input more than once
            for var = {'usainBaseInpFilePath' 'targetDir' 'runName' 'structureInpFilePath'}
                assertFuncs{end + 1} = @() assert(numel(Obj.Parsed.(var{1})) == 1, ...
                    ['Multiple occurences of input ''%s'' found. ', ...
                    'This input may be defined only once.'], var{1}); %#ok<AGROW>
            end

            % Evaluate assert functions to catch any errors prior to doing the
            % rest of the "soft" checks
            Obj.evaluate_assertfuncs(assertFuncs);

            % Warn if overrides exists that are not recognized USAIN inputs
            usainTemplateInpFilePath = USAIN.get_template_path();
            validVars = Obj.list_variable_in_inputfile(usainTemplateInpFilePath);
            isUsainVar = ismember(Obj.overrideNames, validVars);
            if ~all(isUsainVar)
                Obj.warning(['One or more overrides refer to non-existing USAIN input variables:', ...
                    '\n\n\t%s\n\n', ...
                    '\t==> These overrides will be ignored'], ...
                    strjoin(unique(Obj.overrideNames(~isUsainVar)), '\n\t'));
            end

            % Warn if a varName(i) exists multiple times in the input file. An exception are the `BoltFls` input blocks,
            % for which duplicates are expected
            [~, iUnqOvrd] = unique(Obj.overrideNamesWithIdx);
            duplOvrd = unique(Obj.overrideNamesWithIdx(setdiff(1:end, iUnqOvrd)));
            duplOvrd = duplOvrd(~startsWith(duplOvrd, 'BoltFls.'));
            if numel(duplOvrd) > 0
                Obj.warning(['One or more duplicate overrides (variable + index) found:', ...
                    '\n\n\t%s\n\n', ...
                    '\t==> Last entry of duplicate overrides will be used'], ...
                    strjoin(duplOvrd, '\n\t'));
            end

            % Log if overrides exist that are not explicitly defined in the base
            % USAIN input file
            defVars = Obj.list_variable_in_inputfile(Obj.baseInpFilePath);
            isDefinedVar = ismember(Obj.overrideNames, defVars) & isUsainVar;
            if ~all(isDefinedVar)
                Obj.info(['One or more overrides are not explicitly defined in ', ...
                    '''usainBaseInpFilePath'' and will be added to the job ', ...
                    'specific input files:\n\n\t%s\n'], ...
                    strjoin(unique(Obj.overrideNamesWithIdx(~isDefinedVar)), '\n\t'));
            end

            % Provide error if there is an override for ulsMeatloaf loads
            % while there are loads provided in the base input file
            ulsDefBaseInp = Obj.is_parameter_data_provided_in_inputfile(Obj.baseInpFilePath, ...
                'Loads.ulsFilePath');
            if ulsDefBaseInp && ~isempty(Obj.Parsed.ulsMeatloafFilePath{1})
                Obj.error(['Both the USAIN batch runner input file and USAIN base input file ', ...
                    'contain paths to ULS loads files.\n', ...
                    'This is not allowed: it can only be specified in one of the input files.']);
            end

            % Error if a Loads input block field is defined as override. This is currently not supported (but can be
            % supported similar to how BoltFls input blocks are supported).
            Obj.assert(~any(startsWith(Obj.overrideNames, 'Loads.')), [ ...
                'One or more ''Loads.*'' overrides for are defined. ', ...
                'This is not supported for USAIN.run_batch. ', ...
                'These inputs must be defined in the USAIN base input file.']);

            fprintf('\n');
        end

        %%% == JOB PROCESSING == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function print_job_overview(Obj)

            printTxt = {sprintf('\n\n\t\tJ O B   O V E R V I E W\n')};

            % Print base input file path
            baseStr = 'BASE INPUT FILE:';
            printTxt{end + 1} = strcat(trailing_dots(baseStr), Obj.baseInpFilePath);

            % Print job specs
            for jobNo = Obj.iJob(:)'
                jobStr = sprintf('JOB #%02i:', jobNo);
                printTxt{end + 1} = strcat(trailing_dots(jobStr), Obj.jobNames{Obj.iJob == jobNo}); %#ok
            end
            printTxt{end + 1} = '';
            Obj.info('%s\n', printTxt{:});
        end

        function write_job_specific_input_files(Obj)

            for jobNo = Obj.iJob(:)'

                % Copy base input file to make a job-specific input file
                thisJobInpFilePath = Obj.copy_base_input_file(jobNo);
                Obj.jobInputFilePaths{jobNo} = thisJobInpFilePath;

                % Add/append overrides to job specific input file
                JobInp = InputFile(thisJobInpFilePath);
                Obj.modify_job_input_file(JobInp, jobNo);

                Obj.mark_input_file(JobInp);

                JobInp.write_inputfile(thisJobInpFilePath);
            end
        end

        function jobInpFilePath = copy_base_input_file(Obj, jobNo)

            % Typeset job input file path
            jobInpFileName = sprintf('InputFile_USAIN_%s.inp', Obj.jobNames{Obj.iJob == jobNo});
            jobInpFilePath = char(pathlib.Path(Obj.Parsed.JOB_BASE_DIR{1}) / jobInpFileName);
            jobInpFilePath = check_existence_and_update_filename(jobInpFilePath);

            BaseJobInp = InputFile(char(Obj.baseInpFilePath));

            % Expand and resolve paths for the following input fields
            varNames = [
                "structureInpFilePath", ...
                "targetDir", ...
                "Loads.flsFilePath", ...
                "Loads.ulsFilePath"];
            inpfilehelper.expand_and_resolve_paths(BaseJobInp, varNames);
            BaseJobInp.update_filecontent();

            try
                BaseJobInp.write_inputfile(jobInpFilePath);
            catch ME
                Obj.error('Error caught while creating job specific input file:\n\t%s', jobInpFilePath);
                throw(ME);
            end

        end

        function jobSuffix = typeset_job_suffix(Obj, jobNo)
            jobSuffix = sprintf('FC%i_Z%+08.3fm', jobNo, Obj.Parsed.zFlange{jobNo});
        end

        function modify_job_input_file(Obj, JobInp, jobNo)
            % Add or append overrides to job specific input file
            %
            % This methods distinguishes between 'normal' overrides and input block overrides. The former are overrides
            % for simple input fields (e.g. maxFlangeWidth), the latter are overrides for entire input blocks (e.g.
            % BoltFls.*). Because these input blocks can be repeated (e.g. to define multiple bolt FLS assessments in
            % one run), special care needs to be taken. Input blocks that exist only once in an input file, like
            % DOOR_SEGMENT.*, are considered 'normal' overrides.

            % List job overrides and isolate overrides for input blocks that can be repeated (currently only `BoltFls`)
            allOverrides = Obj.overrideNames(Obj.overrideIndices == jobNo);
            jobBlockOverrides = allOverrides(startsWith(allOverrides, "BoltFls."));
            jobOverrides = setdiff(allOverrides, jobBlockOverrides);

            % Add or append overrides
            for ovrd = jobOverrides(:)'
                overrideValues = getsubfield(Obj.Overrides, ovrd{1});
                overrideValue = overrideValues{jobNo};
                Obj.add_or_replace_input_var(JobInp, ovrd{1}, overrideValue);
            end

            maxFlangeNo = numel(Obj.Parsed.zFlange);
            blockRoots = string(unique(extractBefore(jobBlockOverrides, '.')));
            for block = blockRoots(:)'

                % If input block overrides are defined, delete the fields of that block from the base input file. This
                % is needed to ensure repeated input block overrides all end up in the job input file, and that the job
                % input file does not contain remnants from the base input file
                hasBlockInBase = isfield(JobInp.Vars, block);
                if hasBlockInBase
                    for subfield = fieldnames(JobInp.Vars.(block))'
                        JobInp.delete_variable(char(string(block) + '.' + subfield{1}));
                        % NOTE: This deletes vars from all blocks
                    end
                end

                % Extract input block overrides from BatchRunner input file. This results in a struct
                % `ThisBlockOverrides` where each field has an Nx1 cell array as value, for N = max(job number).
                % Each entry in the Nx1 cell array is a 1xM cell array, for M blocks for that particular job
                ThisBlockOverrides = struct();

                % Check for missing or repeated fields in the override input blocks
                % TODO Jira WPSSD-7947 refactor to post_parse_checks
                isOverRideBlockInput = contains(Obj.Inp.VarListStruct.varName, block + '.');
                overrideBlockInput = Obj.Inp.VarListStruct.varName(isOverRideBlockInput);
                countOverrideBlockInput = groupcounts(overrideBlockInput);
                isValid = all(diff(countOverrideBlockInput) == 0);
                if ~isValid
                    Obj.error(['There are missing or repeated fields in the %s override input block(s).\n', ...
                        'Please verify both the base file and the overrides!'], block);
                end

                % For each line in the BatchRunner input file that defines a block override, extract the index and
                % assign the input value to the right index in the Nx1 cell array.
                iLines = Obj.Inp.VarListStruct.lineNumber(contains(Obj.Inp.VarListStruct.varName, block + '.'));
                for line = Obj.Inp.fileContent(iLines)'

                    % Parse line
                    [fullName, ~, ~, valueExpression] = InputFile.parse_inputfile_string(line{1});
                    if isempty(valueExpression)
                        valueExpression = ' ';
                    end

                    % Extract index from input file string to get the flange/job number
                    flangeNo = str2double(cell2mat(extractBetween(fullName, '(', ')')));

                    % Add to ThisBlockOverrides struct
                    subfieldName = cell2mat(extractBetween(fullName, block + '.', '('));
                    if ~isfield(ThisBlockOverrides, subfieldName)
                        ThisBlockOverrides.(subfieldName) = cell(maxFlangeNo, 1);
                    end

                    subfieldValueSubset = ThisBlockOverrides.(subfieldName)(flangeNo);
                    subfieldValueContent = ThisBlockOverrides.(subfieldName){flangeNo};
                    if isempty(subfieldValueContent)
                        newSubFieldContent = valueExpression;
                    elseif iscell(subfieldValueContent)
                        % concatenate cell and valueExpression, result is cell
                        newSubFieldContent = [subfieldValueContent, valueExpression];
                    else
                        % concatenate cell and valueExpression, result is cell
                        newSubFieldContent = [subfieldValueSubset, valueExpression];
                    end
                    ThisBlockOverrides.(subfieldName){flangeNo} = newSubFieldContent;
                end

                % Make use of existing BatchRunner functionality to add input blocks to the job input file
                ThisJobBlock = structfun(@(x) x{jobNo}, ThisBlockOverrides, 'uni', 0);
                ThisJobBlock = structfun(@(x) cellstr(x), ThisJobBlock, 'uni', 0);  % force cellstr for uniform handling
                nBlocks = max(structfun(@length, ThisJobBlock));
                for iBlock = 1:nBlocks
                    for subfield = fieldnames(ThisJobBlock)'
                        % Always use index 1; then `Batch.Runner.insert_indexed_variable()` will not explicitly add an
                        % index
                        index = 1;
                        fullField = ['BoltFls.', subfield{1}];
                        Obj.add_input_var(JobInp, fullField, ThisJobBlock.(subfield{1}){iBlock}, index);
                    end
                end
            end

            % Force replace zFlange
            Obj.add_or_replace_input_var(JobInp, 'zFlange', Obj.Parsed.zFlange{jobNo});

            % Force replace structureInpFilePath and ulsMeatloafFilePath if provided in batch runner's
            % input file
            varName = 'structureInpFilePath';
            if ~isempty(Obj.Parsed.(varName){1})
                Obj.add_or_replace_input_var(JobInp, 'structureInpFilePath', ...
                    TexacoUtils.data_to_inputstring(Obj.Parsed.structureInpFilePath{1}));
            end

            varName = 'ulsMeatloafFilePath';
            if ~isempty(Obj.Parsed.(varName){1})
                Obj.add_or_replace_input_var(JobInp, 'Loads.ulsFilePath', ...
                    TexacoUtils.data_to_inputstring(Obj.Parsed.ulsMeatloafFilePath{1}));
            end

            % Force replace (or append) runName and targetDir
            Obj.add_or_replace_input_var(JobInp, 'runName', Obj.jobNames{Obj.iJob == jobNo});
            Obj.add_or_replace_input_var(JobInp, 'targetDir', TexacoUtils.data_to_inputstring(Obj.Parsed.targetDir{1}));
        end

        function add_or_replace_input_var(Obj, InpObj, varName, value, varargin)

            doReplaceValue = isfield(InpObj.Vars, varName) && ~isempty(InpObj.Vars.(varName).value);
            if doReplaceValue
                if isequal(InpObj.Vars.(varName).value, value)
                    % Don't report if values are equal
                    return
                end

                [~, fileName, fileExt] = fileparts(InpObj.sourceFilePath);

                Obj.warning(['Input override "%s" is already set in the base input file path.\n\n', ...
                    '\t - Original value: %s\n', ...
                    '\t - Override value: %s\n\n', ...
                    '==> Overriding "%s" in file: %s\n\n'], ...
                    varName, strtrim(evalc('disp(InpObj.Vars.(varName).value)')), ...
                    strtrim(evalc('disp(value)')), varName, [fileName, fileExt]);
            end

            % Call superclass method
            add_or_replace_input_var@Batch.Runner(Obj, InpObj, varName, value, varargin{:});
        end

        %%% == JOB EXECUTION == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function do_input_checks_jobs(Obj, doSkipVoid, doSkipPostLoadChecks)
            for jobNo = Obj.iJob(:)'
                USAIN.do_input_checks(Obj.jobInputFilePaths{jobNo}, doSkipVoid, doSkipPostLoadChecks);
            end
        end

        function varargout = run_jobs(Obj)
            % RUN_JOBS Sequentially runs jobs (USAIN.run commands)
            %
            % SYNTAX:
            %   [OutData, JobObj] = run_jobs(Obj)
            %
            % OUTPUT:
            % - *OutData: [struct] Data for TEXACO
            % - *JobObj:  [USAIN] Array with job (USAIN) instances
            %

            JobOutData = [];
            JobObj = [];
            for jobNo = Obj.iJob(:)'

                % Update input "structureInpFilePath" with the one from the previous job (if any), because that
                % StructuralModel is updated with the flange height and mass found in the previous job.
                if jobNo > Obj.iJob(1)
                    JobInputFile = InputFile(Obj.jobInputFilePaths{jobNo});
                    updatedStructuralModelPath = char(pathlib.Path(ThisOutData.strucModFilePath).expandvars());
                    Obj.add_or_replace_input_var(JobInputFile, ...
                        'structureInpFilePath', TexacoUtils.data_to_inputstring(updatedStructuralModelPath));
                    JobInputFile.write_inputfile(Obj.jobInputFilePaths{jobNo});
                end

                [ThisOutData, ThisObj] = USAIN.run(Obj.jobInputFilePaths{jobNo});

                % Detach the file handler registered to the logger of this job
                % NOTE: Do not delete the handler, as this handler is also
                % logging to the BatchRunner's log file
                % - Find handler by looking at the log file path
                JobLogHandlers = ThisObj.Logger.get_handlers('logging.FileHandler');
                jobLogFilePath = regexprep(ThisOutData.usnFilePath, '\.usn$', '.log');
                isJobHandler = cellfun(@(x) strcmpi(x.filePath, jobLogFilePath), JobLogHandlers);
                % - Remove handler from logger object
                for Hndlr = JobLogHandlers(isJobHandler)'
                    ThisObj.Logger.remove_handler(Hndlr{1});
                    Hndlr{1}.close();
                end

                % Append USAIN output to this method's output args
                JobObj = [JobObj; ThisObj]; %#ok<AGROW>
                JobOutData = [JobOutData; ThisOutData]; %#ok<AGROW>
                Obj.jobOutputFilePaths{jobNo} = ThisOutData.usnFilePath;
            end

            if nargout > 0
                varargout = {JobOutData, JobObj};
            end
        end

        %%% == OUTPUT PROCESSING == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function move_log_file(Obj, targetFilePath)

            if nargin < 2
                % Check inputs
                chkFields = {'targetDir' 'runName'};
                Obj.assert(all(isfield(Obj.Parsed, chkFields)), ...
                    ['Cannot determine log file target filepath.\n' ...
                    'One or more of the required input fields could not be found:\n' ...
                    sprintf('\n\t-%s', chkFields{:})]);

                % Construct log file target file path
                targetFilePath = fullfile(Obj.Parsed.targetDir{1}, sprintf('%s_%s_%s.log', ...
                    Obj.TARGET_FILES_DATE, Obj.RUNNER_NAME, Obj.Parsed.runName{1}));
            end

            if Obj.hasLogFile
                % Move log file; Setting filePath property will close, move and
                % re-open the log file
                FileHdlr = Obj.Logger.handlerList(cellfun(@(x) isa(x, 'logging.FileHandler'), ...
                    Obj.Logger.handlerList));
                FileHdlr{end}.filePath = targetFilePath;
            end
        end

        function create_target_dir(Obj, targetDir)

            [isCreated, msg] = mkdir(targetDir);
            Obj.assert(isCreated, 'Error caught during making of dir:%s\n\n%s', ...
                targetDir, msg);
        end

        %%% == GETTERS / SETTERS == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function value = get.iJob(Obj)
            isZFlange = strcmp(Obj.Inp.VarListStruct.varName, 'zFlange');
            value = unique(Obj.Inp.VarListStruct.index(isZFlange));
        end

        function value = get.baseInpFilePath(Obj)
            value = Obj.Parsed.usainBaseInpFilePath{1};
        end

        function value = get.jobNames(Obj)
            value = arrayfun(@(x) ...
                sprintf('%s_%s', Obj.Parsed.runName{1}, Obj.typeset_job_suffix(x)), ...
                Obj.iJob, 'uni', 0);
        end

    end

    methods (Hidden)

        function evaluate_assertfuncs(Obj, assertFuncs)
            % TODO WPSSD-8738 remove here and use new generic function

            ME = {};
            for iAssert = 1:length(assertFuncs)
                % Try to evaluate the assert function. If errored,
                % catch the error and append to the MException cell array.
                try
                    % Read the value
                    assertFuncs{iAssert}();

                catch thisME
                    % An error was thrown, catch it and append
                    ME = [ME; {thisME}]; %#ok
                end
            end

            % If errors were thrown, create a MException with all error messages
            if ~isempty(ME)
                % Load all thrown error messages
                allErrMsgs = cellfun(@(x) regexprep(x.message, '\n', '\n\t'), ME, 'uni', 0);

                % Create the print string
                errPrintStr = sprintf(['One or more input validations failed. See below for results:\n\n', ...
                    repmat('-', 1, 60), '\n\n'...
                    sprintf(['\t%s\n', '\t', repmat('-', 1, 40), '\n'], allErrMsgs{:})]);

                % Make a new exception and throw it
                Obj.error('USAIN:FailedInputVal', errPrintStr);
            end
        end

    end

    methods (Static)

        function do_input_checks(inputFilePath, doSkipVoid, doSkipPostLoadChecks)

            narginchk(1, 3);

            if nargin < 2
                % By default, don't skip <VOID> variables
                doSkipVoid = false;
            end

            if nargin < 3
                doSkipPostLoadChecks = false;
            end

            Obj = usain.batch.Runner();
            Obj.config_logger();

            Obj.read_parse_validate_inputfile(inputFilePath, doSkipVoid);
            Obj.do_post_parse_manipulations();
            Obj.do_post_parse_checks();

            Obj.print_job_overview();
            Obj.write_job_specific_input_files();

            Obj.do_input_checks_jobs(doSkipVoid, doSkipPostLoadChecks);
        end

        function varargout = run(inputFilePath)

            Obj = usain.batch.Runner();
            Obj.config_logger();

            Obj.read_parse_validate_inputfile(inputFilePath);
            Obj.do_post_parse_manipulations();
            Obj.do_post_parse_checks();

            Obj.print_job_overview();
            Obj.write_job_specific_input_files();

            [OutData, UsainObjs] = Obj.run_jobs();

            if nargout > 0
                % Return OutData (for TEXACO) and Obj (for developers)
                varargout = {OutData UsainObjs};
            end
        end

    end
end
