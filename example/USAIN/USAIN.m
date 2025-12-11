classdef USAIN < ToolBasis % mh:ignore_style

    properties (Constant)
        VERSION = '5.5.0'
    end
    properties
        Mdl     UsainUtils.FlangeModel
        SelMdl  UsainUtils.SelectedModel
    end
    properties (Constant, Hidden)
        TOOL_NAME = 'USAIN'

        VALID_COUNTRY_CODES = {'ROW', 'JPN'} % Valid options for input countryCode
    end

    methods

        function Obj = USAIN(varargin)  % mh:ignore_style
            if nargin
                Obj = assign_varargin_2_classprop(Obj, varargin{:});
            end
        end

        %%%%% == INPUT PROCESSING == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function read_parse_validate_inputfile(Obj, inputFilePath, doSkipVoid)
            % Reads input file and applies validation functions

            if nargin == 2
                % By default, don't skip <VOID> variables
                doSkipVoid = false;
            end
            Obj.info('Parsing and validating input file %s ... ', inputFilePath);

            % Load the input file
            Obj.Inp = InputFile(inputFilePath);
            Obj.Inp.targetFilePath = inputFilePath;
            Obj.Inp.skipVoid = doSkipVoid;

            % Check for presence of input var "usainBaseInpFilePath", to catch
            % users that are feeding a batch input file to USAIN.run().
            isBatchInpFile = isfield(Obj.Inp.Vars, 'usainBaseInpFilePath');
            Obj.assert(~isBatchInpFile, ...
                ['This input file provided seems to be for USAIN''s batch runner.\n', ...
                'Did you intend to use the USAIN.run_batch(...) command?']);

            % Check completeness of BoltFls input block
            % NOTE: Only check for completeness of the `BoltFls` input block, when there is data provided in the
            % original input file (prior to mapping deprecated fields). This since it only contains expert inputs that
            % do not have to be present in the input file.
            if any(contains(Obj.Inp.VarListStruct.varName, 'BoltFls'))
                Obj.check_completeness_input_blocks({'BoltFls'});
            end

            % Expand and resolve paths for the following input fields
            varNames = [
                "structureInpFilePath", ...
                "targetDir", ...
                "Loads.flsFilePath", ...
                "Loads.S1FilePath", ...
                "Loads.ulsFilePath"];
            inpfilehelper.expand_and_resolve_paths(Obj.Inp, varNames);

            % Check for deprecated inputs
            map = Obj.define_deprecated_mapping();
            Obj.Inp = Deprecated.check_for_deprecate_inputs(map, Obj.Inp);

            % Skip completeness check for optional / expert inputs
            skipVars = "ALIGN_AT";
            Obj.check_completeness_input_blocks({'Loads'}, skipVars);

            Schema = usain.inputs.get_schema();

            % Check inputs with template
            fieldNamesWithDefault = Schema.get_field_names_with_default();
            Obj.check_inputlist_with_latest_template(fieldNamesWithDefault, []);

            % Load defaults and shortcuts for attribute definitions
            fAssignAs = @(varName) ['Inps.', varName];

            Obj.Inp = validate.apply_schema_to_inputfile(Schema, Obj.Inp, fAssignAs);

            % Parse rest of inputs
            Obj.parse_and_assign_inputs();

            % Check for unknown inputs
            Obj.check_for_unknown_inputs();

            Obj.info('Finished input validation successfully!\n\n');
        end

        function do_post_parse_manipulations(Obj)
            % overwrite default value for targetDir
            if strcmp(Obj.Inputs.targetDir, '')
                Obj.Inputs.targetDir = char(pathlib.Path(Obj.Inp.sourceFilePath).parent / 'Res');
            end

            Manipulator = usain.inputs.PostParseManipulations(Inputs = Obj.Inputs);
            Obj.Inputs = Manipulator.run();

            Obj.create_target_dir();
            Obj.move_log_file();
        end

        function do_post_parse_checks(Obj)
            % Performs checks on parsed inputs
            assertFuncs = {}; % To present all errors at once
            warnMsgs = {};

            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Obj.Inputs);
            PostParseChecks.run();

            doJpnDesign = strcmp(Obj.Inputs.countryCode, 'JPN');

            % Check validity of lengthBoltExtender

            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);

            assertFuncs{end + 1} = usain.fastener.ExtenderData.validate_extender_length( ...
                Obj.Inputs.lengthBoltExtender, BoltOpts.label);

            % Verify thread length <= fastener length
            [pass, msg] = BoltOpts.verify_feasible_thread_length();
            assertFuncs{end + 1} = @() assert(pass, msg);

            % Verify tool for temporary stages with bolt options
            assertFuncs{end + 1} = usain.fastener.TighteningToolData.verify_temp_stages_tools( ...
                Obj.Inputs.site, BoltOpts.label, Obj.Inputs.TEMP_STAGES_TOOL_TYPE);

            % Check whether combinations of bolt options and tightening methods are possible
            assertFuncs{end + 1} = usain.fastener.GarnitureData.validate_bolt_nut_tool_combination( ...
                Obj.Inputs.site, BoltOpts.label, Obj.Inputs.tighteningMethod, Obj.Inputs.NUT_TYPE);

            doChecksForFls = usain.loads.Loads.check_is_required_fls(Obj.Inputs);
            hasFlsLoadsFile = all(~cellfun(@isempty, Obj.Inputs.Loads.flsFilePath));
            if doChecksForFls && ~hasFlsLoadsFile
                assertFuncs{end + 1} = @() error(['Input "Loads.flsFilePath" must be ', ...
                    'specified in order to assess FLS (related) design criteria.']);

            elseif ~doChecksForFls && hasFlsLoadsFile
                warnMsgs{end + 1} = sprintf(['Input "Loads.flsFilePath" is specified, ', ...
                    'but no FLS (related) design criteria are enabled\n\n\t', ...
                    '==> FLS loads will not be loaded.']);
            end

            % Sanity check Loads.dlcFilter in case Loads.tag is 'seismic' (i.e.
            % an APAC robustness check)
            doChecksForUls = usain.loads.Loads.check_is_required_uls(Obj.Inputs);
            if doChecksForUls
                [pass, msg] = Milk.ExtremeLoads.sanity_check_dlc_filter( ...
                    Obj.Inputs.Loads, 'seismic', 'DLCS');
                if ~pass
                    warnMsgs{end + 1} = msg;
                end
            end

            % Sanity check Loads.dlcFilter in case Loads.tag is 'hurricane'
            % (i.e. an US robustness check)
            if doChecksForUls
                [pass, msg] = Milk.ExtremeLoads.sanity_check_dlc_filter( ...
                    Obj.Inputs.Loads, 'hurricane', 'DLCI');
                if ~pass
                    warnMsgs{end + 1} = msg;
                end
            end

            % Check steel type (log warning if steel type leads to yield strength values for plates, not for flanges)
            [message, level] = usain.model.FlangeYieldStrength(Obj.Inputs.FLANGE_STEEL_TYPE).check_steel_type();
            if level > logging.Level.NOTSET
                Obj.Logger.log(level, message);
            end

            % Perform Japan specific checks.
            if doJpnDesign

                % Ultimate limit state should be assessed to Japanese code
                assertFuncs{end + 1} = @() assert(Obj.Inputs.DO_ASSESS_ULS_JPN, ...
                    'Input "DO_ASSESS_ULS_JPN" must be set to true for designs in Japan.');

                % Ultimate limit state calculation only support the
                % Tobinaga method for calculation of reaction distance
                isValidName = strcmp(Obj.Inputs.REACTION_DISTANCE_METHOD, ...
                    UsainUtils.UltimateLimitStateJpn.VALID_REACTION_DIST_METHODS);
                assertFuncs{end + 1} = @() assert(isValidName, ...
                    'Input "REACTION_DISTANCE_METHOD" must be set to "tobinaga" for designs in Japan.');

                % Bolt extenders are not to be used in Japanese designs
                assertFuncs{end + 1} = @() assert(all(Obj.Inputs.lengthBoltExtender == 0), ...
                    'Bolt extender length must be set to zero(s) for Japanese designs.');

                % Verify that PSF_TAG is uniquely defined.
                isPsfUniquelyDefined = numel(unique(Obj.Inputs.PSF_BOLT_RESISTANCE_JPN_TAG)) == ...
                    numel(Obj.Inputs.PSF_BOLT_RESISTANCE_JPN_TAG);
                assertFuncs{end + 1} = @() assert(isPsfUniquelyDefined, ...
                    'Input "PSF_BOLT_RESISTANCE_JPN_TAG" contains duplicates, this is not allowed.');

                % Check if all tags as provided in Loads.tag have also been specified as tag for
                % PSF_BOLT_RESISTANCE_JPN_TAG
                validTags = Milk.ExtremeLoads.EVENT_TAGS_JPN;
                for iTag = 1:numel(Obj.Inputs.Loads.tag)
                    % Pseudo-code:
                    %   - Var strippedTag reduces 'some-longTerm-tag' to 'longTerm'
                    %   - A single match between strippedTag and PSF_BOLT_RESISTANCE_JPN_TAG is then asserted
                    strippedTag = validTags(cellfun(@(x) contains(Obj.Inputs.Loads.tag{iTag}, x), validTags));
                    iMatch = contains(Obj.Inputs.PSF_BOLT_RESISTANCE_JPN_TAG, strippedTag);
                    assertFuncs{end + 1} = @() assert(nnz(iMatch) == 1, ...
                        ['Expected exactly 1 match between loads tag "%s" and tags from input ', ...
                        'PSF_BOLT_RESISTANCE_JPN_TAG ("%s"), but instead found %i.\n', ...
                        'Partial, case sensitive, matches allowed ', ...
                        '(e.g. "longTerm" is recognized in loads tag "DS01_deepsoft_longTerm".'], ...
                        Obj.Inputs.Loads.tag{iTag}, ...
                        strjoin(Obj.Inputs.PSF_BOLT_RESISTANCE_JPN_TAG, '", "'), nnz(iMatch));  %#ok
                end

                % Warn if this is a JPN design and there's no DLC filtering
                if any(cellfun(@isempty, Obj.Inputs.Loads.dlcFilter))
                    warnMsgs{end + 1} = ['For runs where input "countryCode" is "JPN", ', ...
                        'non-empty entries for "Loads.dlcFilter" are expected.'];
                end

                if ~all(cellfun(@any, cellfun(@(x) regexp(x, 'JIS'), Obj.Inputs.boltOptions, 'uni', 0)))
                    warnMsgs{end + 1} = ['For runs where input "countryCode" is "JPN", ', ...
                        'bolt options are expected to be according to "JIS".'];
                end

            end

            % Present warnings all at once
            if ~isempty(warnMsgs)
                warnPrintStr = sprintf( ...
                    ['One or more input sanity checks failed. See below for results:\n\n', ...
                    repmat('-', 1, 60), '\n\n'...
                    sprintf(['\t%s\n', '\t', repmat('-', 1, 40), '\n'], warnMsgs{:})]);
                Obj.warning(sprintf('%s:FailedSanityChk', Obj.TOOL_NAME), warnPrintStr);
            end

            % Present errors all at once
            Obj.evaluate_assertfuncs(assertFuncs);

            % Check requirements of tool-to-wall clash check. Do this after calling evaluate_assertfuncs(), because the
            % check assumes valid bolt/nut/tool combinations
            msg = UsainUtils.ToolToWallClashCheck.post_parse_checks( ...
                Obj.Inputs.site, Obj.Inputs.boltOptions, Obj.Inputs.tighteningMethod, Obj.Inputs.NUT_TYPE, ...
                Obj.Inputs.structureInpFilePath);
            if msg
                Obj.warning(msg);
            end
        end

        %%%%% == EXECUTE == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function varargout = execute_tool(Obj, varargin)
            % Execution of main functionality

            % Parse and check inputs
            % TODO: Move process_inputs (ToolBasis requirement) to sequential runner steps
            Obj.process_inputs(varargin{1}, false);

            ConditionsOnFlangeModel = usain.conditions.get_condition_steps("flangemodel");
            ConditionsOnSelectedModel = usain.conditions.get_condition_steps("selectedmodel");
            % NOTE: conditions are added twice, once for evaluation with FlangeModel and once with SelectedModel. The
            % latter is done to make our developer lives easier when requesting results for the selected design at the
            % end of the run. The time penalty is very low, because in the SelectedModel we only do calculations with
            % scalars (single point design space).
            Runner = runner.SequentialRunner();
            Runner.set(usain.DataKeys.SourceInputFilePath, varargin{1});
            Runner.set(usain.DataKeys.ConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.Inputs, Obj.Inputs);
            Runner.set(usain.DataKeys.SelectedConditionCollection, usain.conditions.ConditionCollection());
            Runner.set(usain.DataKeys.TimeStamp, Obj.TARGET_FILES_DATE);
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);

            Runner.add( ...
                usain.io.LoadExternalFilesStep(), ...
                usain.io.CrossCheckStep(), ...
                usain.model.FlangeModelStep(), ...
                ConditionsOnFlangeModel{:}, ...
                usain.model.SelectBestDesignStep(), ...
                ConditionsOnSelectedModel{:}, ...
                usain.io.DesignSummaryStep(), ...
                usain.model.DetermineFeasibleDesignStep() ...
              );

            if ~strcmp(Obj.Inputs.flangeType, 'T') && Obj.Inputs.DO_ALLOW_SWITCH_L_TO_T
                % User allows switching from L to T flange model, so we need to run all the steps again for the
                % T-flange up untill the Design Summary. These steps will be skipped if a feasible design was already
                % found in the first run, so we can safely add them here.

                % NOTE: we need to construct new condition steps, since the runner does not allow adding the same Step
                % object multiple times.
                ConditionsOnFlangeModel = usain.conditions.get_condition_steps("flangemodel");
                ConditionsOnSelectedModel = usain.conditions.get_condition_steps("selectedmodel");

                % TODO: When process_inputs is moved into a step (see comment above) add that step here and remove
                % do_post_parse_manipulations, do_post_parse_checks and do_post_load_checks from
                % usain.io.UpdateInputsForTFlangeStep
                Runner.add( ...
                    usain.io.UpdateInputsForTFlangeStep(), ...
                    usain.conditions.ClearConditionCollectionStep(), ...
                    usain.io.CrossCheckStep(), ...
                    usain.model.FlangeModelStep(), ...
                    ConditionsOnFlangeModel{:}, ...
                    usain.model.SelectBestDesignStep(), ...
                    ConditionsOnSelectedModel{:}, ...
                    usain.io.DesignSummaryStep() ...
                  );
            end
            Runner.add( ...
                usain.io.UpdateStructuralModelStep(), ...
                usain.sgre2.WriteSummaryFileStep(), ...
                usain.neck_scf.WriteSummaryFileStep(), ...
                usain.neck_scf.EquivalentScfOutputStep(), ...
                usain.io.WriteFilesStep(), ...
                usain.io.WriteSelectedModelInputFileStep() ...
              );

            Runner.run();

            % Prepare data for TEXACO
            OutDataStruct = struct();
            OutDataStruct.didAdjustStrMdl = Runner.is_gettable(usain.DataKeys.StructuralModelOutputPath);
            if Runner.is_gettable(usain.DataKeys.StructuralModelOutputPath)
                OutDataStruct.strucModFilePath = char(Runner.get(usain.DataKeys.StructuralModelOutputPath));
            end

            OutDataStruct.usnFilePath = char(Runner.get(usain.DataKeys.UsnFilePath));
            OutDataStruct.selectedModelInputFilePath = char(Runner.get(usain.DataKeys.SelectedModelInputFilePath));
            OutDataStruct.logFilePath = char(Runner.get(usain.DataKeys.SelectedModelInputFilePath));

            if Runner.is_gettable(usain.DataKeys.FlangeNeckScfOutputData)
                OutDataStruct.FlangeNeckScf = Runner.get(usain.DataKeys.FlangeNeckScfOutputData);
            end

            OutData = usain.io.RunOutputData(OutDataStruct);

            % Store SelectedModel
            Obj.SelMdl = Runner.get(usain.DataKeys.SelectedModel);

            if nargout > 0
                varargout = {Obj OutData};
            end
        end

    end

    methods (Static, Hidden)

        function templFilePaths = get_template_path()
            % This method extends ToolBasis.get_template_path by providing that
            % method with a tool name string

            % Extend superclass method
            templFilePaths = get_template_path@ToolBasis(USAIN.TOOL_NAME);
        end

        function map = define_units_mapping()
            % Not used; see overloaded method `usain.PostParseManipulations.convert_inputs_to_si_units`
            map = containers.Map();
        end

        function map = define_deprecated_mapping()

            keyValues = {
                % Deprecated               Actual
                'diamOutNeck'              'diameter'};

            map = containers.Map(keyValues(:, 1), keyValues(:, 2));
        end

    end

    methods (Static)

        function varargout = copy_inputfiles(targetDir)
            % COPY_INPUTFILES Copy empty USAIN inputfile to specified directory
            %
            % SYNTAX:
            % - targetFilePath = USAIN.COPY_INPUTFILES(*targetDir)
            %       (* = optional)
            %
            % INPUTS:
            % - targetDir:      [char, *optional] Target directory for the input
            %                   file If not specified, the user will be prompt
            %                   to specify one.
            %
            % OUTPUTS:
            % - targetFilePath: [cellstr] Cell array of strings containing
            %                   the full file paths of the created input
            %                   file(s).
            %
            % SEE ALSO:
            %     USAIN
            %
            % =============================================================
            %

            % Check i/o
            narginchk(0, 1);
            nargoutchk(0, 1);

            % Get class name to derive tool name without constructing class
            toolName = mfilename('class');

            % Prompt user to specify target directory
            if nargin < 1
                targetDir = input('Please specify a target directory to put your input files:\n', 's');
            end
            validateattributes(targetDir, {'char'}, {'nonempty'}, mfilename, 'targetDir');

            fprintf('\nCreating input file for %s ...\n', toolName);

            % Invoke superclass (ToolBasis method) to execute common code
            targetFilePath = copy_inputfiles@ToolBasis(toolName, targetDir);
            overridesFilePath = copy_inputfiles@ToolBasis(usain.batch.Runner.RUNNER_NAME, targetDir);

            % Present user with hyperlink
            fprintf('\nCreated %s input file here:\n%s', toolName, ...
                sprintf('\t<a href="matlab: winopen(''%s'')">%s</a>\n', targetFilePath, targetFilePath));

            if nargout
                varargout{1} = {targetFilePath; overridesFilePath};
            end
        end

        function do_input_checks(inputFilePath, doSkipVoid, doSkipPostLoadChecks)
            % DO_INPUT_CHECKS Check USAIN input file without running the tool
            %
            % SYNTAX:
            % - USAIN.do_input_checks(inputFilePath, *doSkipVoid, *doSkipPostLoadChecks)
            %       * = optional
            %
            % INPUTS:
            % - inputFilePath:        [char] Full path to USAIN input file
            % - doSkipVoid:           [logical] Flag to skip variables that have
            %                         a value "<VOID>"
            % - doSkipPostLoadChecks: [logical] Flag to skip loading files and
            %                         performing corresponding post-load input
            %                         checks
            %
            % SEE ALSO:
            % - USAIN
            %
            % =============================================================
            %

            % Check i/o
            narginchk(1, 3);

            if nargin < 2
                % By default, don't skip <VOID> variables
                doSkipVoid = false;
            end

            if nargin < 3
                doSkipPostLoadChecks = false;
            end

            % Construct object
            Obj = USAIN();
            Obj.config_logger();

            % Show awesome ASCII art - print static art to log files
            msg = UsainUtils.message();
            oldLevel = logging.Manager.edit_console_log_level(logging.Level.WARNING);
            Obj.info(msg);
            logging.Manager.edit_console_log_level(oldLevel);

            % Validate input checks
            Obj.process_inputs(inputFilePath, doSkipVoid);

            if ~doSkipPostLoadChecks
                % Skip these steps during TEXACO pre-run checking due to dependencies with preceding tools like
                % StructuralModel, MEATLOAF, FUEL etc
                Runner = runner.SequentialRunner().add( ...
                    usain.io.LoadExternalFilesStep(), ...
                    usain.io.CrossCheckStep());

                Runner.set(usain.DataKeys.Inputs, Obj.Inputs);
                Runner.run();
            end

            % Inform user
            fprintf('\nFinished input checks for %s ...\n', Obj.TOOL_NAME);
        end

        function do_input_checks_batch(inputFilePath, doSkipVoid)
            % DO_INPUT_CHECKS_BATCH Batch check USAIN overrides input file without running the tool
            %
            % SYNTAX:
            % - USAIN.do_input_checks_batch(inputFilePath, *doSkipVoid)
            %       * = optional
            %
            % INPUTS:
            % - inputFilePath:  [char] Full path to BatchRunner input file
            % - doSkipVoid:     [logical, *optional] Flag to skip variables that
            %                   have a value "<VOID>".
            %
            % SEE ALSO:
            % - USAIN, USAIN.BATCH.RUNNER
            %
            % =============================================================
            %

            narginchk(1, 2);

            if nargin < 2
                % By default, don't skip <VOID> variables
                doSkipVoid = false;
            end

            usain.batch.Runner.do_input_checks(inputFilePath, doSkipVoid);
        end

        function varargout = run(inputFilePath)
            % RUN Run USAIN from a given input file
            %
            % SYNTAX:
            % - USAIN.run(inputFilePath)
            %
            % INPUTS:
            % - inputFilePath: [char] Full path to USAIN input file
            %
            % SEE ALSO:
            % - USAIN
            %
            % ==================================================================
            %

            narginchk(1, 1);
            nargoutchk(0, 2);

            % Construct object
            Obj = USAIN();
            Obj.config_logger();

            % Show awesome ASCII art - print static art to log files
            msg = UsainUtils.message();
            oldLevel = logging.Manager.edit_console_log_level(logging.Level.WARNING);
            Obj.info(msg);
            logging.Manager.edit_console_log_level(oldLevel);

            % Run main functionality
            [Obj, OutData] = Obj.execute(inputFilePath);

            % Print message to prompt that analysis is finished
            Obj.info(['%s run finished. Results are stored in:\n', ...
                '\t<a href="matlab: winopen(''%s'');">%s</a>\n\n'], ...
                Obj.TOOL_NAME, Obj.Inputs.targetDir, Obj.Inputs.targetDir);

            if nargout > 0
                % Return OutData (for TEXACO) and Obj (for developers)
                varargout = {OutData Obj};
            end
        end

        function varargout = run_batch(inputFilePath)
            % RUN_BATCH Batch run USAIN from a given overrides input file
            %
            % SYNTAX:
            % - USAIN.run_batch(inputFilePath)
            %
            % INPUTS:
            % - inputFilePath: [char] Full path to BatchRunner input file
            %
            % SEE ALSO:
            % - USAIN, USAIN.BATCH.RUNNER
            %
            % ==================================================================
            %

            narginchk(1, 1);
            nargoutchk(0, 2);

            [OutData, BatchObj] = usain.batch.Runner.run(inputFilePath);

            if nargout > 0
                % Return OutData (for TEXACO) and Obj (for developers)
                varargout = {OutData BatchObj};
            end
        end

        function changelog()
            % Prints changes for specific version
            %
            % SYNTAX
            % USAIN.changelog  % Prints all changes between current and previous deploy
            %
            % SEE ALSO:
            % - USAIN
            %
            % =============================================================
            %

            toolName = mfilename('class');
            ToolBasis.pprint_changelog(toolName);
        end

    end

    methods (Static, Hidden)

        function varargout = run_from_towercalc(inputFilePath)

            narginchk(1, 1);
            nargoutchk(0, 2);

            % Construct object
            Obj = USAIN();
            Obj.config_logger();

            % Supress messages below `error` level, note that the log file will contain full details.
            oldLevel = logging.Manager.edit_console_log_level(logging.Level.ERROR);

            % Run main functionality
            [Obj, OutData] = Obj.execute(inputFilePath);

            % Print message to prompt that analysis is finished
            logging.Manager.edit_console_log_level(oldLevel);
            Obj.info(['%s run finished. Results are stored in:\n', ...
                '\t<a href="matlab: winopen(''%s'');">%s</a>\n\n'], ...
                Obj.TOOL_NAME, Obj.Inputs.targetDir, Obj.Inputs.targetDir);

            if nargout > 0
                % Return OutData (for TEXACO) and Obj (for developers)
                varargout = {OutData Obj};
            end
        end

        function bMin = calc_bmin_from_inputs(InputsBMin)
            arguments
                InputsBMin usain.inputs.run_dataclass.InputsBMin
            end

            Inputs = InputsBMin.get_all_inputs();

            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);
            Inputs = Manipulator.run();

            Runner = runner.SequentialRunner();
            Runner.set(usain.DataKeys.Inputs, Inputs);
            Runner.set(usain.DataKeys.hasFeasibleDesign, false);
            Runner.add(usain.model.FlangeModelStep(false));
            Runner.run();

            % Set up a FlangeModel, note that it will set up a full design space
            FlangeModel = Runner.get(usain.DataKeys.FlangeModel);

            % Extract the bMin value(s) per requested input boltOptions
            [~, index, ~] = unique(FlangeModel.Space.boltId);
            bMin = FlangeModel.bMinimum(index);

        end

    end
end
