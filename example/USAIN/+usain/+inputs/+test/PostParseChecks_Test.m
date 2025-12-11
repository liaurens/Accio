classdef (SharedTestFixtures = {fixtures.SilentlyLogFixture(logging.Level.ERROR)}) ...
        PostParseChecks_Test < Unittest.TestCase

    methods

        function verifyErrorMessage(Obj, logRecord, message)
            Obj.verifyEqual(logRecord.level, logging.Level.ERROR);
            Obj.verifySubstring(logRecord.message, message);
        end

        function verifyWarningMessage(Obj, logRecord, message)
            Obj.verifyEqual(logRecord.level, logging.Level.WARNING);
            Obj.verifySubstring(logRecord.message, message);
        end

    end

    methods (Test, TestTags = {'unit'})

        function throw_error__print_error__happy(Obj)
            % GIVEN a custom logger where we attach a CellArrayHandler
            CustomLogger = logging.Logger.get_logger('test');
            LogHandler = logging.CellArrayHandler();
            CustomLogger.add_handler(LogHandler);

            % we also assign the cellArrayHandler to the PostParseChecks
            PostParseChecks = usain.inputs.PostParseChecks();
            PostParseChecks.LogHandler = LogHandler;

            % WHEN we emit some messages
            % THEN no exceptions are raised
            CustomLogger.error("error1", abortOnError = false);
            CustomLogger.error("error2", abortOnError = false);

            % THEN an exception is raised
            f = @() PostParseChecks.throw_error();
            Obj.assertRaisesMessageRegex(f, ['One or more post-parse checks failed. ', ...
                'Please read the above error message\(s\)']);
        end

        function throw_error__do_not_print_error__happy(Obj)
            % GIVEN a custom logger where we attach a CellArrayHandler
            CustomLogger = logging.Logger.get_logger('test');
            LogHandler = logging.CellArrayHandler();
            CustomLogger.add_handler(LogHandler);

            % we also assign the cellArrayHandler to the PostParseChecks
            PostParseChecks = usain.inputs.PostParseChecks();
            PostParseChecks.LogHandler = LogHandler;

            % WHEN we emit some warning messages
            CustomLogger.warning("warning");
            CustomLogger.warning("warning");

            % THEN no exception is raised
            f = @() PostParseChecks.throw_error();
            Obj.verify_error_free(f);
        end

        function check_flange_type_for_switch_to_t_flange__error(Obj)
            % GIVEN
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.flangeType = 'T';
            Inputs.DO_ALLOW_SWITCH_L_TO_T = true;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_flange_type_for_switch_to_t_flange();

            % THEN
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, ...
                ['Input DO_ALLOW_SWITCH_L_TO_T is set to true, while input flangeType is not ', ...
                'set to ''L''. This is not allowed.']);
            Obj.verifyLength(PostParseChecks.LogHandler.buffer, 1);
        end

        function check_amount_of_bolt_options__happy(Obj)
            % GIVEN
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_amount_of_bolt_options();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN 3 bolt options, 3 tightening methods and leave the rest of the inputs as in the case for a
            % single bolt option. That is a valid scenario and the corresponding inputs would be expanded internally.
            Inputs.boltOptions = {'HV_M42', 'ISO_M64', 'ISO_M72'};
            Inputs.tighteningMethod = {'tension', 'tension', 'torque'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_amount_of_bolt_options();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN two BoltFls blocks and manipulate them using the inpfilehelper.split_input_blocks
            Inputs.BoltFls.BOLT_FORCE_MODEL = ["schmidtneuper"; "sgre2"];
            Inputs.BoltFls.CUSTOM_PRELOAD = {nan; [1234 5678 9123]};
            Inputs.BoltFls.PRELOAD_LOSS_FACTOR_FLS = [0.90; 0.09];
            Inputs.BoltFls.PSF_BOLT_MATERIAL_FLS = [1.25; 1.1];
            Inputs.BoltFls.SN_CURVE_BOLT = ["EC3_DC36*"; "EC3_DC50"];
            Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = [0.25; 0.10];
            Inputs.BoltFls.TARGET_PM_SUM = [0.9; 1.0];
            Inputs.BoltFls = inpfilehelper.split_input_blocks(Inputs.BoltFls);

            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_amount_of_bolt_options();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_amount_of_bolt_options__sad(Obj)
            % GIVEN data from fixture representing 2 bolt options and altering the input boltOptions to actually
            % contain 3 bolt options
            % GIVEN
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.boltOptions = {'HV_M42', 'ISO_M64', 'ISO_M72'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_amount_of_bolt_options();

            % THEN we check the first error message and in addition expect every field to drop the bomb
            expectedMessage = ['Expected input ''minFlangeWidth'' to be either ', ...
                'empty, a single value or 3 values (i.e. one for each input ''boltOptions'').'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
            Obj.verifyLength(PostParseChecks.LogHandler.buffer, 21);
        end

        function check_valid_amount__happy(Obj)
            % GIVEN
            nBoltOptions = 3;
            oneInput = 1;
            oneInputName = "aSingleInputIsValid";
            threeInputs = [1 2 3];
            threeInputsName = "threeInputsAreValid";

            PostParseChecks = usain.inputs.PostParseChecks();

            % WHEN
            PostParseChecks.check_valid_amount(oneInput, oneInputName, nBoltOptions);
            PostParseChecks.check_valid_amount(threeInputs, threeInputsName, nBoltOptions);

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_valid_amount__sad(Obj)
            % GIVEN
            nBoltOptions = 3;
            twoInputs = [1 2];
            twoInputsName = "twoInputsAreNotValid";

            PostParseChecks = usain.inputs.PostParseChecks();

            % WHEN
            PostParseChecks.check_valid_amount(twoInputs, twoInputsName, nBoltOptions);

            % THEN
            expectedMessage = ['Expected input ''twoInputsAreNotValid'' to be either empty, a single value or 3 ', ...
                'values (i.e. one for each input ''boltOptions'').'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_expected_bolt_length__happy(Obj)
            % GIVEN some bolt options without specifying their lenghts, such that it's always valid.
            Inputs.boltOptions = {'ISO_M42', 'HV_M56'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_expected_bolt_length();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_expected_bolt_length__sad(Obj)
            % GIVEN some bolt options and providing unexpected lenghts
            Inputs.boltOptions = {'ISO_M42x123', 'HV_M56x456'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_expected_bolt_length();

            % THEN
            expectedMessage = sprintf([ ...
                    'One or more inputs for "boltOptions" define non-standard bolt length(s):', ...
                    '\n\n\t%s\n\n', ...
                    '\tStandard bolt lengths are listed in the design rules.'], ...
                    strjoin(Inputs.boltOptions, ', '));
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_expected_thread_length__happy(Obj)
            % GIVEN some bolt options without specifying their lenghts, such that it's always valid.
            Inputs.boltOptions = {'ISO_M42', 'HV_M56'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_expected_thread_length();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_expected_thread_length__sad(Obj)
            % GIVEN some bolt options and providing unexpected lenghts
            Inputs.boltOptions = {'ISO_M42x400x123', 'HV_M56x400x456'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_expected_thread_length();

            % THEN
            expectedMessage = sprintf([ ...
                    'One or more inputs for "boltOptions" define non-standard thread length(s):', ...
                    '\n\n\t%s\n\n', ...
                    '\tStandard thread lengths are listed in the design rules.'], ...
                    strjoin(Inputs.boltOptions, ', '));
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_min_max_design_variables__happy(Obj)
            % GIVEN
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            Inputs.minFlangeWidth = 100;
            Inputs.maxFlangeWidth = 200;

            % WHEN
            PostParseChecks.check_min_max_design_variables();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN check for multiple fasteners
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.minNBolts = [60 70];
            Inputs.maxNBolts = [60 70];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_min_max_design_variables();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN check for min=max
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.minNBolts = [60 80];
            Inputs.maxNBolts = [60 80];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_min_max_design_variables();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_min_max_design_variables__sad(Obj)
            % GIVEN variables where the min is greater than the max
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.minNBolts = 20;
            Inputs.maxNBolts = 10;
            Inputs.minFlangeThickn = 20;
            Inputs.maxFlangeThickn = 10;
            Inputs.minFlangeWidth = 20;
            Inputs.maxFlangeWidth = 10;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_min_max_design_variables();

            % THEN
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1},  ...
                'Input "maxFlangeWidth" must be >= input "minFlangeWidth"');
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{2}, ...
                'Input "maxFlangeThickn" must be >= input "minFlangeThickn"');
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{3}, ...
                'Input "maxNBolts" must be >= input "minNBolts"');

            % NEXT GIVEN check for multiple fasteners
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.minNBolts = [70 70];
            Inputs.maxNBolts = [60 70];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_min_max_design_variables();

            % THEN
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1},  ...
                'Input "maxNBolts" must be >= input "minNBolts"');
        end

        function check_design_variables_step_size__happy(Obj)
            % GIVEN happy case
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_design_variables_step_size();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_design_variables_step_size__happy_same_min_max(Obj)
            % GIVEN design space inputs where are the min/max are the same. The stepsize is incompatible. But because
            % the min/max is the same, we skip the check.
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.minNBolts = 7;
            Inputs.maxNBolts = 7;
            Inputs.STEPSIZE_N_BOLTS = 2;
            Inputs.minFlangeThickn = 7;
            Inputs.maxFlangeThickn = 7;
            Inputs.STEPSIZE_THICKN = 2;
            Inputs.minFlangeWidth = 7;
            Inputs.maxFlangeWidth = 7;
            Inputs.STEPSIZE_WIDTH = 2;

            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_design_variables_step_size();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_design_variables_step_size__sad(Obj)
            % GIVEN
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.minNBolts = 7;
            Inputs.maxNBolts = 9;
            Inputs.STEPSIZE_N_BOLTS = 2;
            Inputs.minFlangeThickn = 7;
            Inputs.maxFlangeThickn = 9;
            Inputs.STEPSIZE_THICKN = 2;
            Inputs.minFlangeWidth = 7;
            Inputs.maxFlangeWidth = 9;
            Inputs.STEPSIZE_WIDTH = 2;

            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_design_variables_step_size();

            % THEN
            % We dont care about the specific message, that is already tested in design_space.is_multiple
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, ...
                'minNBolts: Input must be a multiple of');
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{2}, ...
                'maxNBolts: Input must be a multiple of');
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{3}, ...
                'minFlangeThickn: Input must be a multiple of');
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{4}, ...
                'maxFlangeThickn: Input must be a multiple of');
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{5}, ...
                'minFlangeWidth: Input must be a multiple of');
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{6}, ...
                'maxFlangeWidth: Input must be a multiple of');
        end

        function check_secondary_holes__happy(Obj)
            % GIVEN valid inputs with and without (i.e. nan values) SECONDARY holes data
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.SECONDARY_HOLES_BCD = [7.500, NaN];
            Inputs.SECONDARY_HOLES_DIAMETER = [0.020, NaN];
            Inputs.diamBoltCircle = [7.9, 7.9];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_secondary_holes();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_secondary_holes__sad(Obj)
            % GIVEN incorrect inputs
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.SECONDARY_HOLES_BCD = [8.1, NaN];
            Inputs.SECONDARY_HOLES_DIAMETER = [NaN, 0.020];
            Inputs.diamBoltCircle = [7.9, 7.9];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_secondary_holes();

            % THEN
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, ...
                'Input "diameter" must be > input "SECONDARY_HOLES_BCD".');
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{2}, ...
                'Input "diamBoltCircle" must be > input "SECONDARY_HOLES_BCD".');
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{3}, ...
                'Inputs "SECONDARY_HOLES_BCD" and "SECONDARY_HOLES_DIAMETER" should both be either defined or left blank.'); % mh:ignore_style
        end

        function check_boltfls_first_block_not_sgre2__happy(Obj)
            % GIVEN valid inputs with defaults to the BoltFls block
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_first_block_not_sgre2();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_boltfls_first_block_not_sgre2__sad(Obj)
            % GIVEN inputs and set the first BoltFls block to use SGRE2.0, which is not allowed.
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_first_block_not_sgre2();

            % THEN
            expectedMessage = ['The first BoltFls input block is not allowed to define the "sgre2" ', ...
                   'bolt force model since this is not supported in DOCTOR.'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_custom_washers__happy(Obj)
            % GIVEN inputs from fixture where there is no CUSTOM_WASHER defined, i.e. all nan.
            % This should pass all separate related checks for custom washers.
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_custom_washers_uniformly_defined__happy(Obj)
            % GIVEN inputs from fixture where there is no CUSTOM_WASHER defined, i.e. all nan
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_uniformly_defined();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN one bolt option with custom washers, for the other all nan
            Inputs.CUSTOM_WASHER_DIAM_INNER = [123, nan];
            Inputs.CUSTOM_WASHER_DIAM_OUTER = [123, nan];
            Inputs.CUSTOM_WASHER_THICKNESS = [12, nan];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_uniformly_defined();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_custom_washers_uniformly_defined__sad(Obj)
            % GIVEN inputs  one option has CUSTOM_WASHER partly defined, hence insuffictient input
            Inputs.CUSTOM_WASHER_DIAM_INNER = [123, nan];
            Inputs.CUSTOM_WASHER_DIAM_OUTER = [123, nan];
            Inputs.CUSTOM_WASHER_THICKNESS = [nan, nan];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_uniformly_defined();

            % THEN
            expectedMessage = ['The inputs CUSTOM_WASHER_DIAM_INNER, CUSTOM_WASHER_DIAM_OUTER, ', ...
                'CUSTOM_WASHER_THICKNESS should be either all defined or all left blank.'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_custom_washers_bolt_fits__happy(Obj)
            % GIVEN multiple bolt options and use custom washers which would fit the bolt
            Inputs.boltOptions = {'ISO_M42', 'HV_M56'};
            Inputs.CUSTOM_WASHER_DIAM_INNER = [0.045, 0.060];
            Inputs.CUSTOM_WASHER_DIAM_OUTER = [0.060, 0.080];
            Inputs.CUSTOM_WASHER_THICKNESS = [0.01, 0.01];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_bolt_fits();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_custom_washers_bolt_fits__sad(Obj)
            % GIVEN multiple bolt options and use custom washers which won't fit the bolt
            Inputs.boltOptions = {'ISO_M42', 'HV_M56'};
            Inputs.CUSTOM_WASHER_DIAM_INNER = [0.035, 0.05];
            Inputs.CUSTOM_WASHER_DIAM_OUTER = [0.060, 0.080];
            Inputs.CUSTOM_WASHER_THICKNESS = [0.01, 0.01];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_bolt_fits();

            % THEN
            expectedMessage = ['One or more values for input "CUSTOM_WASHER_DIAM_INNER" ', ...
                    'is too small to fit the bolts.'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_custom_washers_diameter__happy(Obj)
            % GIVEN
            Inputs.CUSTOM_WASHER_DIAM_INNER = [120, 230];
            Inputs.CUSTOM_WASHER_DIAM_OUTER = [125, 235];

            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_diameters();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_custom_washers_diameter__sad(Obj)
            % GIVEN
            Inputs.CUSTOM_WASHER_DIAM_INNER = [120, 230];
            Inputs.CUSTOM_WASHER_DIAM_OUTER = [115, 220];

            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_diameters();

            % THEN
            expectedMessage = 'Input "CUSTOM_WASHER_DIAM_OUTER" must be > input "CUSTOM_WASHER_DIAM_INNER".';
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_custom_washers_tightening_method__happy(Obj)
            % GIVEN tighteningMethod as tension and no custom washers, i.e. all related inputs are nan.
            Inputs.tighteningMethod = {'tension'};
            Inputs.CUSTOM_WASHER_DIAM_INNER = nan;
            Inputs.CUSTOM_WASHER_DIAM_OUTER = nan;
            Inputs.CUSTOM_WASHER_THICKNESS = nan;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_tightening_method();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN tighteningMethod as torque; still no custom washers
            Inputs.tighteningMethod = {'torque'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_tightening_method();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN tighteningMethod as torque, but with custom washers
            Inputs.tighteningMethod = {'torque'};
            Inputs.CUSTOM_WASHER_DIAM_INNER = 123;
            Inputs.CUSTOM_WASHER_DIAM_OUTER = 125;
            Inputs.CUSTOM_WASHER_THICKNESS = 12;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_tightening_method();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN multiple boltOptions, for one using tighteningMethod as tension; no custom washers.
            Inputs.tighteningMethod = {'tension', 'torque'};
            Inputs.CUSTOM_WASHER_DIAM_INNER = [nan, nan];
            Inputs.CUSTOM_WASHER_DIAM_OUTER = [nan, nan];
            Inputs.CUSTOM_WASHER_THICKNESS = [nan, nan];

            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_tightening_method();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_custom_washers_tightening_method__sad(Obj)
            % GIVEN tighteningMethod as tension and defining custom washers
            Inputs.tighteningMethod = {'tension'};
            Inputs.CUSTOM_WASHER_DIAM_INNER = 123;
            Inputs.CUSTOM_WASHER_DIAM_OUTER = 125;
            Inputs.CUSTOM_WASHER_THICKNESS = 12;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_tightening_method();

            % THEN
            expectedMessage = ['The input tighteningMethod should not be tension if any '...
                    'of the custom washer inputs are defined'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);

            % NEXT GIVEN multiple boltOptions, for one using tighteningMethod as tension; no custom washers.
            Inputs.tighteningMethod = {'tension', 'torque'};
            Inputs.CUSTOM_WASHER_DIAM_INNER = [123, nan];
            Inputs.CUSTOM_WASHER_DIAM_OUTER = [125, nan];
            Inputs.CUSTOM_WASHER_THICKNESS = [12, nan];

            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_custom_washers_tightening_method();

            % THEN
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_emodulus_for_interpolated_shell_stiffness__happy(Obj)
            % GIVEN inputs for sgre2, interpolated shell stiffness, and E = 210MPa
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "sgre2";
            Inputs.SGRE2.SHELL_STIFFNESS_METHOD = 'interpolated';
            Inputs.E_FLANGE = 210e9;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_emodulus_for_interpolated_shell_stiffness();

            % THEN
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);

            % WHEN changing the E-modulus while using the simplified shell stiffness method
            % THEN expect no error
            Inputs.SGRE2.SHELL_STIFFNESS_METHOD = 'simplified';
            Inputs.E_FLANGE = 123;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_emodulus_for_interpolated_shell_stiffness();
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);

            % WHEN changing the E-modulus while disabling sgre2
            % THEN expect no error
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.SGRE2.SHELL_STIFFNESS_METHOD = "interpolated";
            Inputs.E_FLANGE = 123;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_emodulus_for_interpolated_shell_stiffness();
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_emodulus_for_interpolated_shell_stiffness__sad(Obj)
            % GIVEN inputs for sgre2, interpolated shell stiffness, but E ~= 210MPa
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "sgre2";
            Inputs.SGRE2.SHELL_STIFFNESS_METHOD = 'interpolated';
            Inputs.E_FLANGE = 123;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_emodulus_for_interpolated_shell_stiffness();

            % THEN
            expectedMessage = [ ...
                'Modulus of elasticity of flange must be 210 MPa for interpolating shell stiffness. ', ...
                'Use the `simplified` shell stiffness method instead (input SGRE2.SHELL_STIFFNESS_METHOD).'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_gap_angles_for_interpolated_shell_stiffness__happy(Obj)
            % GIVEN inputs for sgre2, interpolated shell stiffness, and gap angles within [10, 180]deg
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "sgre2";
            Inputs.SGRE2.SHELL_STIFFNESS_METHOD = 'interpolated';
            Inputs.SGRE2.GAP_ANGLE = deg2rad([30 60 90 120]);

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_gap_angles_for_interpolated_shell_stiffness();

            % THEN
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);

            % WHEN changing the gap angles while using the simplified shell stiffness method
            % THEN expect no error
            Inputs.SGRE2.SHELL_STIFFNESS_METHOD = 'simplified';
            Inputs.SGRE2.GAP_ANGLE = deg2rad([9 30 60 181]);
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_gap_angles_for_interpolated_shell_stiffness();
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);

            % WHEN changing the gap angles while disabling sgre2
            % THEN expect no error
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.SGRE2.SHELL_STIFFNESS_METHOD = 'interpolated';
            Inputs.SGRE2.GAP_ANGLE = deg2rad([9 30 60 181]);
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_gap_angles_for_interpolated_shell_stiffness();
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_gap_angles_for_interpolated_shell_stiffness__sad(Obj)
            % GIVEN inputs for sgre2, interpolated shell stiffness, but gap angles outside [10, 180]deg
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "sgre2";
            Inputs.SGRE2.SHELL_STIFFNESS_METHOD = 'interpolated';
            Inputs.SGRE2.GAP_ANGLE = deg2rad([9 30 60 181]);

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_gap_angles_for_interpolated_shell_stiffness();

            % THEN
            expectedMessage = [ ...
                'Gap angles selected for SGRE2.0 must be in range [10, 180]deg for interpolating shell stiffness. ', ...
                'Use the `simplified` shell stiffness method instead (input SGRE2.SHELL_STIFFNESS_METHOD).'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_boltfls_custom_preload_across_assessments__happy(Obj)
            % TODO this method calls a seperate function `usain.inputs.validate_custom_preload_combinations` and has
            % tests corresponding to it. Suggested to join this check and the tests in a separate PR.

            % GIVEN
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_custom_preload_across_assessments();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_boltfls_no_custom_preload_for_hv_bolts__happy(Obj)
            % GIVEN multiple boltOptions, including an HV bolt and ensuring it does not have any *.CUSTOM_PRELOAD
            % defined
            Inputs.boltOptions = {'ISO_M42', 'HV_M56'};
            Inputs.BoltFls(1).CUSTOM_PRELOAD = [1234, nan];
            Inputs.BoltFls(2).CUSTOM_PRELOAD = [4321, nan];
            Inputs.FlangeGapping.CUSTOM_PRELOAD = [1234, nan];
            Inputs.SlsPretension.CUSTOM_PRELOAD = [1234, nan];
            Inputs.FlangeNeckScf.CUSTOM_PRELOAD = [1234, nan];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_no_custom_preload_for_hv_bolts();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_boltfls_no_custom_preload_for_hv_bolts__sad(Obj)
            % GIVEN multiple boltOptions, including an HV bolt and ensuring it does have a *.CUSTOM_PRELOAD
            % defined
            Inputs.boltOptions = {'ISO_M42', 'HV_M56'};
            Inputs.BoltFls(1).CUSTOM_PRELOAD = [1234, 1234];
            Inputs.BoltFls(2).CUSTOM_PRELOAD = [4321, nan];
            Inputs.FlangeGapping.CUSTOM_PRELOAD = [1234, nan];
            Inputs.SlsPretension.CUSTOM_PRELOAD = [1234, nan];
            Inputs.FlangeNeckScf.CUSTOM_PRELOAD = [1234, nan];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_no_custom_preload_for_hv_bolts();

            % THEN
            expectedMessage = 'One or more "*.CUSTOM_PRELOAD" inputs used for HV bolts. This is not expected.';
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_boltfls_number_of_sgre2_blocks__with_sgre2_blocks(Obj)
            % GIVEN inputs with 2 BoltFls blocks that both set `sgre2`; note the blocks are already parsed and
            % manipulated
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "sgre2";
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "sgre2";

            % WHEN not reporting the results
            Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS = false;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % THEN nothing
            PostParseChecks.check_boltfls_number_of_sgre2_blocks();
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % WHEN reporting the results
            Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS = true;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % THEN expect a warning
            PostParseChecks.check_boltfls_number_of_sgre2_blocks();
            expectedMessage = ['More than one "sgre2" analyses are defined. ', ...
                    'Only the first will be reported in the SGRE2.0 Excel summary file.'];
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_boltfls_number_of_sgre2_blocks__without_sgre2_blocks(Obj)
            % GIVEN inputs with 2 BoltFls blocks that both not set to `sgre2`; note the blocks are already parsed and
            % manipulated
            % WHEN there are no blocks with sgre2
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS = true;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % THEN nothing
            PostParseChecks.check_boltfls_number_of_sgre2_blocks();
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_boltfls_sgre2_required_reaction_distance_method__happy(Obj)
            % GIVEN valid combination of inputs, unrelated to sgre2
            Inputs.BoltFls.BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.REACTION_DISTANCE_METHOD = 'seidel';
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_sgre2_required_reaction_distance_method();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN valid combination of inputs, unrelated to sgre2
            Inputs.BoltFls.BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.REACTION_DISTANCE_METHOD = 'tobinaga';
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_sgre2_required_reaction_distance_method();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN valid combination of inputs related to sgre2
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            Inputs.REACTION_DISTANCE_METHOD = 'tobinaga';
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_sgre2_required_reaction_distance_method();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_boltfls_sgre2_required_reaction_distance_method__sad(Obj)
            % GIVEN invalid combination of inputs
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            Inputs.REACTION_DISTANCE_METHOD = 'seidel';
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_sgre2_required_reaction_distance_method();

            % THEN
            expectedMessage = ['An FLS assessment with "sgre2" is requested, ', ...
                    'while input REACTION_DISTANCE_METHOD is not set to "tobinaga". This is not allowed.'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_boltfls_petersen_required_reaction_distance_method__happy(Obj)
            % GIVEN valid combination of inputs, unrelated to petersen
            Inputs.BoltFls.BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.REACTION_DISTANCE_METHOD = 'seidel';
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_petersen_required_reaction_distance_method();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN valid combination of inputs, unrelated to petersen
            Inputs.BoltFls.BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.REACTION_DISTANCE_METHOD = 'tobinaga';
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_petersen_required_reaction_distance_method();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN valid combination of inputs related to petersen
            Inputs.BoltFls.BOLT_FORCE_MODEL = "petersen";
            Inputs.REACTION_DISTANCE_METHOD = 'tobinaga';
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_petersen_required_reaction_distance_method();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_boltfls_petersen_required_reaction_distance_method__sad(Obj)
            % GIVEN invalid combination of inputs
            Inputs.BoltFls.BOLT_FORCE_MODEL = "petersen";
            Inputs.REACTION_DISTANCE_METHOD = 'seidel';
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_petersen_required_reaction_distance_method();

            % THEN
            expectedMessage = ['An FLS assessment with "petersen" is requested, ', ...
                    'while input REACTION_DISTANCE_METHOD is not set to "tobinaga". This is not allowed.'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_boltfls_expected_thickness_exponent__schmidtneuper(Obj)
            % GIVEN correct input combinations for THICKNESS_EXPONENT_BOLT and BOLT_FORCE_MODEL
            Inputs.DO_ASSESS_FLS = true;
            Inputs.BoltFls(1).THICKNESS_EXPONENT_BOLT = 0.25;
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.BoltFls(2).THICKNESS_EXPONENT_BOLT = 0.25;
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "petersen";
            Inputs.BoltFls(3).THICKNESS_EXPONENT_BOLT = NaN;
            Inputs.BoltFls(3).BOLT_FORCE_MODEL = "sgre2";

            % WHEN checking, THEN assume no log messages
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_boltfls_expected_thickness_exponent();
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % WHEN setting the "schmidtneuper" exponent to a non-default value
            Inputs.BoltFls(1).THICKNESS_EXPONENT_BOLT = 0.10;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_boltfls_expected_thickness_exponent();

            % THEN
            expectedMessage = [ ...
                'A value of 0.25 for input BoltFls.THICKNESS_EXPONENT_BOLT is expected for analyses ', ...
                'where "schmidtneuper" and/or "petersen" is used for input BoltFls.BOLT_FORCE_MODEL.'];
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);

            % WHEN setting the "schmidtneuper" exponent to a NaN value
            Inputs.BoltFls(1).THICKNESS_EXPONENT_BOLT = NaN;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_boltfls_expected_thickness_exponent();

            % THEN
            expectedMessage = [ ...
                'Input BoltFls.THICKNESS_EXPONENT_BOLT must be defined for analyses ', ...
                'where input BoltFls.BOLT_FORCE_MODEL is not "sgre2".'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_boltfls_expected_thickness_exponent__petersen(Obj)
            % GIVEN correct input combinations for THICKNESS_EXPONENT_BOLT and BOLT_FORCE_MODEL
            Inputs.DO_ASSESS_FLS = true;
            Inputs.BoltFls(1).THICKNESS_EXPONENT_BOLT = 0.25;
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.BoltFls(2).THICKNESS_EXPONENT_BOLT = 0.25;
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "petersen";
            Inputs.BoltFls(3).THICKNESS_EXPONENT_BOLT = NaN;
            Inputs.BoltFls(3).BOLT_FORCE_MODEL = "sgre2";

            % WHEN checking, THEN assume no log messages
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_boltfls_expected_thickness_exponent();
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % WHEN setting the "petersen" exponent to a non-default value
            Inputs.BoltFls(2).THICKNESS_EXPONENT_BOLT = 0.10;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_boltfls_expected_thickness_exponent();

            % THEN
            expectedMessage = [ ...
                'A value of 0.25 for input BoltFls.THICKNESS_EXPONENT_BOLT is expected for analyses ', ...
                'where "schmidtneuper" and/or "petersen" is used for input BoltFls.BOLT_FORCE_MODEL.'];
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);

            % WHEN setting the "schmidtneuper" exponent to a NaN value
            Inputs.BoltFls(2).THICKNESS_EXPONENT_BOLT = NaN;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_boltfls_expected_thickness_exponent();

            % THEN
            expectedMessage = [ ...
                'Input BoltFls.THICKNESS_EXPONENT_BOLT must be defined for analyses ', ...
                'where input BoltFls.BOLT_FORCE_MODEL is not "sgre2".'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_boltfls_expected_thickness_exponent__sgre2(Obj)
            % GIVEN correct input combinations for THICKNESS_EXPONENT_BOLT and BOLT_FORCE_MODEL
            Inputs.DO_ASSESS_FLS = true;
            Inputs.BoltFls(1).THICKNESS_EXPONENT_BOLT = 0.25;
            Inputs.BoltFls(1).BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.BoltFls(2).THICKNESS_EXPONENT_BOLT = 0.25;
            Inputs.BoltFls(2).BOLT_FORCE_MODEL = "petersen";
            Inputs.BoltFls(3).THICKNESS_EXPONENT_BOLT = NaN;
            Inputs.BoltFls(3).BOLT_FORCE_MODEL = "sgre2";

            % WHEN checking, THEN assume no log messages
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_boltfls_expected_thickness_exponent();
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % WHEN setting the "sgre2" exponent to a non-default value
            Inputs.BoltFls(3).THICKNESS_EXPONENT_BOLT = 0.10;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_boltfls_expected_thickness_exponent();

            % THEN
            expectedMessage = ['Input BoltFls.THICKNESS_EXPONENT_BOLT is expected to be empty for analyses ', ...
                'where "sgre2" is used for input BoltFls.BOLT_FORCE_MODEL.'];
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_flangeneckscf_preload_loss_factor_fls__error(Obj)
            % GIVEN factor for FlangeNeckScf DOES NOT correspond to one of the factors in BoltFls
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = true;
            Inputs.BoltFls(1).PRELOAD_LOSS_FACTOR_FLS = 0.8;
            Inputs.BoltFls(2).PRELOAD_LOSS_FACTOR_FLS = 0.9;
            Inputs.FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS = 0.7;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_flangeneckscf_preload_loss_factor_fls();

            % THEN
            expectedMessage = ['FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS should correspond to one of the values for ', ...
                'BoltFls.PRELOAD_LOSS_FACTOR_FLS'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_flangeneckscf_preload_loss_factor_fls__skip(Obj)
            % GIVEN wrong preload loss factors, but we dont run FLS assessments
            Inputs.DO_ASSESS_FLS = false;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = true;
            Inputs.BoltFls(1).PRELOAD_LOSS_FACTOR_FLS = 0.8;
            Inputs.BoltFls(2).PRELOAD_LOSS_FACTOR_FLS = 0.9;
            Inputs.FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS = 0.7;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_flangeneckscf_preload_loss_factor_fls();

            % THEN the check is skipped
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN still wrong preload loss factors, we run FLS assessments, but not the flange neck scf
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_flangeneckscf_preload_loss_factor_fls();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_flangeneckscf_write_intermediate_results__warning(Obj)
            % GIVEN FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS = true, but DO_ASSESS_FLANGE_NECK_SCF = false
            Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS = true;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;

            % WHEN, THEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_flangeneckscf_write_intermediate_results();

            % THEN
            expectedMessage = ['Input FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS is set to true, ', ...
                'while input DO_ASSESS_FLANGE_NECK_SCF is set to false. ', ...
                'FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS will be ingored.'];
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_flangeneckscf_write_scf_output__warning(Obj)
            % GIVEN StructuralModel is empty, but DO_ASSESS_FLANGE_NECK_SCF = true
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = true;
            Inputs.structureInpFilePath = '';

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_flangeneckscf_write_scf_output();

            % THEN
            expectedMessage = ...
                'Equivalent SCFs for STIFT can not be output, because no StructuralModel is provided in inputs.';
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_loads_scaling_equal_length__happy(Obj)
            % GIVEN happy case
            Inputs.Loads.ulsScalingFactor = {1.05};
            Inputs.Loads.ulsScalingLevel = {200};
            Inputs.Loads.flsScalingFactor = {1.05};
            Inputs.Loads.flsScalingLevel = {100};
            Inputs.Loads.S1ScalingFactor = {1.05};
            Inputs.Loads.S1ScalingLevel = {100};

            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_loads_scaling_equal_length();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_loads_scaling_equal_length__sad(Obj)
            % GIVEN incorrect fastener height for the fastener type
            Inputs.Loads.ulsScalingFactor = {1.05};
            Inputs.Loads.ulsScalingLevel = {[0 200]};
            Inputs.Loads.flsScalingFactor = {[1.05 1.04]};
            Inputs.Loads.flsScalingLevel = {100};
            Inputs.Loads.S1ScalingFactor = {[1.05 1.04]};
            Inputs.Loads.S1ScalingLevel = {[0 50 100]};

            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_loads_scaling_equal_length();

            % THEN
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, ...
                'Vector sizes for inputs "Loads.ulsScalingFactor" and "Loads.ulsScalingLevel" must be the same.');
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{2}, ...
                'Vector sizes for inputs "Loads.flsScalingFactor" and "Loads.flsScalingLevel" must be the same.');
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{3}, ...
                'Vector sizes for inputs "Loads.S1ScalingFactor" and "Loads.S1ScalingLevel" must be the same.');
        end

        function check_dead_weight_structural_model__happy(Obj)
            % GIVEN a StructuralModel and no DEAD_WEIGHT
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.structureInpFilePath = 'C:\lala';
            Inputs.DEAD_WEIGHT = nan;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_dead_weight_structural_model();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN no StructuralModel but DEAD_WEIGHT
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.structureInpFilePath = '';
            Inputs.DEAD_WEIGHT = 1e5;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_dead_weight_structural_model();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_dead_weight_structural_model__sad(Obj)
            % GIVEN StructuralModel and DEAD_WEIGHT
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.structureInpFilePath = 'C:\lala';
            Inputs.DEAD_WEIGHT = 1e5;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_dead_weight_structural_model();

            % THEN
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, ...
                'Both inputs DEAD_WEIGHT and structureInpFilePath are set. This is not allowed.');
        end

        function check_s1_load_input_combinations__skipped(Obj)
            % GIVEN Inputs that deactivate the S1 loads conditions, and no S1 loads provided
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = false;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = false;
            Inputs.Loads.S1FilePath = {''};
            Inputs.S1_BENDING_MOMENT = nan;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_s1_load_input_combinations();

            % THEN
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_s1_load_input_combinations__no_loads_file(Obj)
            % GIVEN Inputs that activate the S1 loads conditions, and no S1, FLS loads file or override provided
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = true;
            Inputs.Loads.S1FilePath = {''};
            Inputs.Loads.flsFilePath = {''};
            Inputs.S1_BENDING_MOMENT = nan;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_s1_load_input_combinations();

            % THEN
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, ...
                ['Input "Loads.S1FilePath", "S1_BENDING_MOMENT" or "Loads.flsFilePath" must be specified ', ...
                'to assess S1 (related) design criteria.']);
        end

        function check_s1_load_input_combinations__fls_loads_used(Obj)
            % GIVEN Inputs that activate the S1 loads conditions, and no S1 loads or override provided
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = true;
            Inputs.Loads.S1FilePath = {''};
            Inputs.Loads.flsFilePath = {'foo/bar'};
            Inputs.S1_BENDING_MOMENT = nan;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_s1_load_input_combinations();

            % THEN
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, ...
                sprintf(['For loads set(s) #1, neither "Loads.S1FilePath" nor "S1_BENDING_MOMENT" are specified.\n', ...
                    '\t==> Maximum FLS moment will be used for load set(s) #1.']));
        end

        function check_s1_load_input_combinations__happy(Obj)
            % GIVEN Inputs that activate the S1 loads conditions, and S1 loads provided via Loads.S1FilePath
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = true;
            Inputs.Loads.S1FilePath = {'c:/foo/bar.mat'};
            Inputs.S1_BENDING_MOMENT = nan;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_s1_load_input_combinations();

            % THEN
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);

            % WHEN S1 loads are provided via S1_BENDING_MOMENT
            Inputs.Loads.S1FilePath = {''};
            Inputs.S1_BENDING_MOMENT = 123;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_s1_load_input_combinations();

            % THEN
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_s1_load_input_combinations__override_used(Obj)
            % GIVEN Inputs that activate the S1 loads conditions, and S1 loads provided through both Loads.S1FilePath
            % and S1_BENDING_MOMENT
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = true;
            Inputs.Loads.S1FilePath = {'foo/bar.mat', ''};   % one set, one empty
            Inputs.S1_BENDING_MOMENT = 123;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_s1_load_input_combinations();

            % THEN
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, ...
                sprintf(['For loads set(s) #1, both "Loads.S1FilePath" and "S1_BENDING_MOMENT" are specified.\n', ...
                '\t==> Value for "S1_BENDING_MOMENT" will be used for all load sets.']));
        end

        function check_uls_load_input_combination__happy(Obj)
            % GIVEN Loads.uls inputs, no ULS_BENDING_MOMENT and no INCLINATION_MOMENT (hence both nan)
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_ULS = true;
            Inputs.ULS_BENDING_MOMENT = nan;
            Inputs.INCLINATION_MOMENT = nan;
            Inputs.Loads.ulsFilePath = {'C:\lala'};
            Inputs.Loads.inclinationValue = 5;
            Inputs.Loads.ulsScalingFactor = {1.05};
            Inputs.Loads.ulsScalingLevel = {{120}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_uls_load_input_combination();

            % THEN
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN a ULS_BENDING_MOMENT and INCLINATION_MOMENT, no Loads.uls inputs
            Inputs.ULS_BENDING_MOMENT = 1e5;
            Inputs.INCLINATION_MOMENT = 1.1e-6;
            Inputs.Loads.ulsFilePath = {''};
            Inputs.Loads.inclinationValue = '';
            Inputs.Loads.ulsScalingFactor = {};
            Inputs.Loads.ulsScalingLevel = {{}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_uls_load_input_combination();

            % THEN
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN an INCLINATION_MOMENT, no Loads.inclinationValue input
            Inputs.ULS_BENDING_MOMENT = 1e5;
            Inputs.INCLINATION_MOMENT = 1234;
            Inputs.Loads.ulsFilePath = {''};
            Inputs.Loads.inclinationValue = '';
            Inputs.Loads.ulsScalingFactor = {};
            Inputs.Loads.ulsScalingLevel = {{}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_uls_load_input_combination();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN zero INCLINATION_MOMENT, no Loads.inclinationValue input
            Inputs.ULS_BENDING_MOMENT = 1e5;
            Inputs.INCLINATION_MOMENT = 0;
            Inputs.Loads.ulsFilePath = {''};
            Inputs.Loads.inclinationValue = '';
            Inputs.Loads.ulsScalingFactor = {};
            Inputs.Loads.ulsScalingLevel = {{}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_uls_load_input_combination();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_uls_load_input_combination__moment_override(Obj)
            % GIVEN a ULS_BENDING_MOMENT and one of the Loads.uls* inputs
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_ULS = true;
            Inputs.ULS_BENDING_MOMENT = 1e5;
            Inputs.INCLINATION_MOMENT = 1.1e-6;
            Inputs.Loads.ulsFilePath = {'C:\lala'};
            Inputs.Loads.inclinationValue = NaN;
            Inputs.Loads.ulsScalingFactor = {};
            Inputs.Loads.ulsScalingLevel = {{}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_uls_load_input_combination();

            % THEN
            expectedMessage = ['Expert input "ULS_BENDING_MOMENT" is set in combination with (some) ULS related ', ...
                'inputs in the "Loads." input block. This is not allowed.'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_uls_load_input_combination__bad_inclination_override(Obj)
            % GIVEN ICLINATION_MOMENT and Loads.inclinationValue
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_ULS = true;
            Inputs.ULS_BENDING_MOMENT = 1e5;
            Inputs.INCLINATION_MOMENT = 1234;
            Inputs.Loads.ulsFilePath = {''};
            Inputs.Loads.inclinationValue = 1;
            Inputs.Loads.ulsScalingFactor = {};
            Inputs.Loads.ulsScalingLevel = {{}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_uls_load_input_combination();

            % THEN
            expectedMessage = ['Expert input "INCLINATION_MOMENT" is set in combination with ', ...
                '"Loads.inclinationValue". This is not allowed.'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{2}, expectedMessage);
        end

        function check_uls_load_input_combination__no_uls_inputs_set(Obj)
            % GIVEN DO_ASSESS_ULS set as true but dont specify any loads inputs
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_ULS = true;
            Inputs.ULS_BENDING_MOMENT = nan;
            Inputs.INCLINATION_MOMENT = nan;
            Inputs.Loads.ulsFilePath = {''};
            Inputs.Loads.inclinationValue = nan;
            Inputs.Loads.ulsScalingFactor = {nan};
            Inputs.Loads.ulsScalingLevel = {{nan}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_uls_load_input_combination();

            % THEN
            expectedMessage = ['Input block "Loads." or "ULS_BENDING_MOMENT" must be specified in order to ', ...
                'assess ULS (related) design criteria.'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_uls_load_input_combination__unnecessary_uls_inputs_set(Obj)
            % GIVEN DO_ASSESS_ULS false but also give ULS loads inputs
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_ULS = false;
            Inputs.ULS_BENDING_MOMENT = 5e5;
            Inputs.INCLINATION_MOMENT = 0;
            Inputs.Loads.ulsFilePath = {''};
            Inputs.Loads.inclinationValue = nan;
            Inputs.Loads.ulsScalingFactor = {nan};
            Inputs.Loads.ulsScalingLevel = {{nan}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_uls_load_input_combination();

            % THEN
            expectedMessage = ['Input "Loads.ulsFilePath" or "ULS_BENDING_MOMENT" is specified, but expert input ', ...
                '"DO_ASSESS_ULS" is set to false.'];
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_uls_load_input_combination__no_inclination_set(Obj)
            % GIVEN neither the Loads,inclinationValue nor INCLINATION_MOMENT is set
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_ULS = true;
            Inputs.ULS_BENDING_MOMENT = nan;
            Inputs.INCLINATION_MOMENT = nan;
            Inputs.Loads.ulsFilePath = {'C:\lala'};
            Inputs.Loads.inclinationValue = nan;
            Inputs.Loads.ulsScalingFactor = {nan};
            Inputs.Loads.ulsScalingLevel = {{nan}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_uls_load_input_combination();

            % THEN expect no message to be logged
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_uls_load_input_combination__unnecessary_inclination_set(Obj)
            % NEXT GIVEN set DO_ASSESS_ULS to false
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_ULS = false;
            Inputs.ULS_BENDING_MOMENT = nan;
            Inputs.INCLINATION_MOMENT = nan;
            Inputs.Loads.ulsFilePath = {''};
            Inputs.Loads.inclinationValue = 5;
            Inputs.Loads.ulsScalingFactor = {nan};
            Inputs.Loads.ulsScalingLevel = {{nan}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_uls_load_input_combination();

            % THEN
            expectedMessage = ['Input "Loads.inclinationValue" is specified, but no ULS (related) design ', ...
                'criteria are enabled'];
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_strmdl_inclination_angle__happy(Obj)
            % GIVEN a StructuralModel and an inclinationValue
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.structureInpFilePath = 'C:\strmdl.mat';
            Inputs.Loads.inclinationValue = 1.05;
            Inputs.Loads.inclinationValueFls = 1.05;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_strmdl_inclination_angle();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN no StructuralModel but also no inclinationValue
            Inputs.structureInpFilePath = '';
            Inputs.Loads.inclinationValue = nan;
            Inputs.Loads.inclinationValueFls = nan;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_strmdl_inclination_angle();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_strmdl_inclination_angle__no_strmdl_and_value_set(Obj)
            % GIVEN no StructuralModel but an inclination value is given
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.structureInpFilePath = '';
            Inputs.Loads.inclinationValue = 1.05;
            Inputs.Loads.inclinationValueFls = nan;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_strmdl_inclination_angle();

            % THEN
            expectedMessage = sprintf(['Insufficient inputs to compute inclination loads ', ...
                '(empty input "structureInpFilePath").\n', ...
                '\t==> Continuing without inclination loads.']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_strmdl_inclination_angle__no_strmdl_and_fls_value_set(Obj)
            % GIVEN no StructuralModel but an FLS inclination value is given
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.structureInpFilePath = '';
            Inputs.Loads.inclinationValue = nan;
            Inputs.Loads.inclinationValueFls = 123;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_strmdl_inclination_angle();

            % THEN
            expectedMessage = sprintf(['Insufficient inputs to compute inclination loads ', ...
                '(empty input "structureInpFilePath").\n', ...
                '\t==> Continuing without inclination loads.']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_inclination_moment_fls_override__no_override(Obj)
            % GIVEN no INCLINATION_MOMENT_FLS in combination with values for Loads.inclinationValueFls
            Inputs.INCLINATION_MOMENT_FLS = nan;
            Inputs.Loads.inclinationValueFls = 0.125;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_inclination_moment_fls_override();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_inclination_moment_fls_override__both_set(Obj)
            % GIVEN both INCLINATION_MOMENT_FLS and Loads.inclinationValueFls set
            Inputs.INCLINATION_MOMENT_FLS = 0.125;
            Inputs.Loads.inclinationValueFls = 0;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_inclination_moment_fls_override();

            % THEN
            expectedMessage = ['Expert input "INCLINATION_MOMENT_FLS" is set in combination with ', ...
                '"Loads.inclinationValueFls". This is not allowed.'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_inclination_values_expected__expected_values(Obj)
            % GIVEN expected values for Loads.inclinationValueFls
            Inputs.Loads.inclinationValueFls = deg2rad([0; 0.125]);

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_inclination_values_expected();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_inclination_values_expected__unexpected_values(Obj)
            % GIVEN values for Loads.inclinationValueFls that are other than the options from IEC 61400-6/AMD1
            Inputs.Loads.inclinationValueFls = [0.1; deg2rad(0.125); 0.125];

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_inclination_values_expected();

            % THEN
            expectedMessage = sprintf([ ...
                'For load set(s) #1 and #3, an unexpected value for "Loads.inclinationValueFls" is input.\n', ...
                'Expected values are either 0.125 deg, or 0.']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_inclination_values_order__happy(Obj)
            % GIVEN values for Loads.inclinationValueFls <= values for Loads.inclinationValue
            Inputs.Loads.inclinationValueFls = [0; 0.125];
            Inputs.Loads.inclinationValue    = [0; 0.75];

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_inclination_values_order();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_inclination_values_order__wrong_order(Obj)
            % GIVEN values for Loads.inclinationValueFls > values for Loads.inclinationValue
            Inputs.Loads.inclinationValueFls = [0.125; 0.125; 0; 0.125];
            Inputs.Loads.inclinationValue    = [0;     0.75;  0; 0.125];

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_inclination_values_order();

            % THEN
            expectedMessage = sprintf([ ...
                'For load set(s) #1, "Loads.inclinationValueFls" is greater than "Loads.inclinationValue".\n', ...
                'This is unexpected.']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_check_nose_heights_ge_min_height__happy(Obj)
            % GIVEN happy case
            Inputs.heightNoseLo = 0.40;
            Inputs.heightNoseUp = 0.45;
            Inputs.MIN_NOSE_HEIGHT = 0.3;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_nose_heights_ge_min_height();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_check_nose_heights_ge_min_height__sad(Obj)
            % GIVEN happy case
            Inputs.heightNoseLo = 0.40;
            Inputs.heightNoseUp = 0.45;
            Inputs.MIN_NOSE_HEIGHT = 0.6;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_nose_heights_ge_min_height();

            % THEN
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, ...
                'Input "heightNoseLo" must be >= input "MIN_NOSE_HEIGHT".');
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{2}, ...
                'Input "heightNoseUp" must be >= input "MIN_NOSE_HEIGHT".');
        end

        function check_bolt_holes__happy(Obj)
            % GIVEN default inputs from fixture
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_bolt_holes();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_default_hole_diameter__happy(Obj)
            % GIVEN multiple bolt options and don't specify diamBoltHole, i.e. all NaN.
            Inputs.boltOptions = {'ISO_M42', 'HV_M56'};
            Inputs.diamBoltHole = [NaN, NaN];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_default_hole_diameter();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_default_hole_diameter__sad(Obj)
            % GIVEN multiple bolt options and specify non-default diamBoltHole
            Inputs.boltOptions = {'ISO_M42', 'HV_M56'};
            Inputs.diamBoltHole = [0.0422, 0.0562];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_default_hole_diameter();

            % THEN
            defaultVals = [0.046, 0.061];
            warnStr = arrayfun(@(opt, def, inp) sprintf(['\n\t- For bolt option %s, ', ....
                    'default value is %gmm (input is %gmm)'], opt{1}, 1e3 * def, 1e3 * inp), ...
                    Inputs.boltOptions, defaultVals, Inputs.diamBoltHole, 'uni', 0);
            expectedMessage = sprintf(['Non-default values for input "diamBoltHole" found:', ...
                    warnStr{:}, '\n\n']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_bolt_holes_bolts_fit__happy(Obj)
            % GIVEN multiple bolt options and don't specify diamBoltHole, i.e. all NaN.
            Inputs.boltOptions = {'ISO_M42', 'HV_M56'};
            Inputs.diamBoltHole = [NaN, NaN];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_bolt_holes_bolts_fit();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_bolt_holes_bolts_fit__sad(Obj)
            % GIVEN multiple bolt options and specify too small diamBoltHole
            Inputs.boltOptions = {'ISO_M42', 'HV_M56'};
            Inputs.diamBoltHole = [0.040, 0.056];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_bolt_holes_bolts_fit();

            % THEN
            warnStr = arrayfun(@(opt, inp) sprintf(['\n\t- For bolt option %s, ', ....
                    'the input value is too small (%gmm).'], opt{1}, 1e3 * inp), ...
                    Inputs.boltOptions, Inputs.diamBoltHole, 'uni', 0);
            expectedMessage = sprintf(['One or more values for input "diamBoltHole" seem incorrect:', ...
                    warnStr{:}, '\n\n']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_hv_bolts_provided__happy(Obj)
            % GIVEN multiple "preferred" bolt options, i.e. not containing HV bolts
            Inputs.boltOptions = {'ISO_M42', 'ISO_M56', 'JIS_M48'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_hv_bolts_provided();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_hv_bolts_provided__sad(Obj)
            % GIVEN multiple bolt options, including HV bolts
            Inputs.boltOptions = {'ISO_M42', 'ISO_M56', 'HV_M48'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_hv_bolts_provided();

            % THEN
            expectedMessage = sprintf(['One or more inputs for "boltOptions" define HV bolts.\n', ...
                  '\tISO studs are the preferred solution!']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);

            % NEXT GIVEN HV_M36
            Inputs.boltOptions = {'ISO_M42', 'ISO_M56', 'HV_M36'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_hv_bolts_provided();

            % THEN
            expectedMessage = sprintf(['HV_M36 bolts detected!\n\n', ...
                    'Note that HV bolts are not a preferred option!\n', ...
                    '\tISO studs are the preferred solution!\n', ...
                    '\t==> Only use HV_M36 to check old (onshore) flange designs.\n\n']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_valid_hv_bolt_length__happy(Obj)
            % GIVEN multiple bolt options, not containing HV bolts
            Inputs.boltOptions = {'ISO_M42', 'ISO_M56'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_valid_hv_bolt_length();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN multiple HV bolt options, but without length
            Inputs.boltOptions = {'HV_M42', 'HV_M56'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_valid_hv_bolt_length();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN multiple HV bolt options with valid length
            Inputs.boltOptions = {'HV_M42x280', 'HV_M56x350'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_valid_hv_bolt_length();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_valid_hv_bolt_length__sad(Obj)
            % GIVEN multiple HV bolt options with invalid length
            Inputs.boltOptions = {'HV_M42x282', 'HV_M56x353'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_valid_hv_bolt_length();

            % THEN
            expectedMessage = ['One or more inputs for HV bolt length is not an option according to ', ...
                            'the table 3a in DASt. This is not allowed'];
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_hv_bolts_do_assess_thread_requirement_combination__happy(Obj)
            % GIVEN expected input combination for HV bolts
            Inputs.boltOptions = {'HV_M48', 'HV_M64'};
            Inputs.DO_ASSESS_BOLT_THREAD_REQ = false;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_hv_bolts_do_assess_thread_requirement_combination();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_hv_bolts_do_assess_thread_requirement_combination__sad(Obj)
            % GIVEN inputs containing HV and other bolts.
            Inputs.boltOptions = {'HV_M48', 'ISO_M64'};
            Inputs.DO_ASSESS_BOLT_THREAD_REQ = true;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_hv_bolts_do_assess_thread_requirement_combination();

            % THEN
            expectedMsg = sprintf(['HV bolts provided in inputs and DO_ASSESS_BOLT_THREAD_REQ is set to true.\n', ...
                    'These requirements are not representative for HV bolts, since they are selected and/or ', ...
                    'checked according to DASt Ri 021 Table 3a.']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMsg);
        end

        function check_hv_bolts_bolt_extenders_combination__happy(Obj)
            % GIVEN expected input combination for HV bolts
            Inputs.boltOptions = {'HV_M48', 'HV_M64'};
            Inputs.lengthBoltExtender = [0, 0];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_hv_bolts_bolt_extenders_combination();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_hv_bolts_bolt_extenders_combination__sad(Obj)
            % GIVEN inputs containing HV and other bolts.
            Inputs.boltOptions = {'HV_M48', 'ISO_M64'};
            Inputs.lengthBoltExtender = [10, 10];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_hv_bolts_bolt_extenders_combination();

            % THEN
            expectedMsg = sprintf(['HV bolts provided in inputs and bolt extenders are enable.\n', ...
                   'This configuration is not recommended for HV bolts.\n', ...
                   'Only use HV bolts with bolt extenders to check old (onshore) flange designs.']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMsg);

            % NEXT given input containing nan as input
            Inputs.lengthBoltExtender = [nan, nan];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_hv_bolts_bolt_extenders_combination();

            % THEN
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMsg);

        end

        function check_iso_m36_provided__happy(Obj)
            % GIVEN multiple "preferred" bolt options, i.e. not containing ISO_M36
            Inputs.boltOptions = {'ISO_M42', 'ISO_M56', 'JIS_M48'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_iso_m36_provided();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_iso_m36_provided__sad(Obj)
            % GIVEN multiple bolt options, including ISO_M36
            Inputs.boltOptions = {'ISO_M42', 'ISO_M36', 'JIS_M48'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_iso_m36_provided();

            % THEN
            expectedMessage = sprintf([ ...
                    'ISO_M36 studs detected!\n\n', ...
                    'Note that the properties of M36 fastener components are not finalized and may contain rough assumptions.\n', ...  % mh:ignore_style
                    'The known assumptions/limitations are:\n', ...
                    '- Thin-walled socket dimensions are extrapolated from smaller sizes.\n', ...
                    '- The tensioner tool dimensions are not finalized.\n', ...
                    '- The assembly value and preload are not finalized.', ...
                    '- Cost and mass of ISO_M36 based on extrapolation\n', ...
                    '- This list is not complete!\n\n', ...
                    '\t==> Only use ISO_M36 if this has been discussed with topic owners\n\n']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_iso_m39_provided__happy(Obj)
            % GIVEN multiple "preferred" bolt options, i.e. not containing ISO_M39
            Inputs.boltOptions = {'ISO_M42', 'ISO_M56', 'JIS_M48'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_iso_m39_provided();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_iso_m39_provided__sad(Obj)
            % GIVEN multiple bolt options, including ISO_M39
            Inputs.boltOptions = {'ISO_M42', 'ISO_M39', 'JIS_M48'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_iso_m39_provided();

            % THEN
            expectedMessage = sprintf([ ...
                    'ISO_M39 studs detected!\n\n', ...
                    'Note that the properties of M39 fastener components are not finalized and may contain rough assumptions.\n', ...  % mh:ignore_style
                    'The known assumptions/limitations are:\n', ...
                    '- Thin-walled socket dimensions are extrapolated from smaller sizes.\n', ...
                    '- The tensioner tool dimensions are not finalized.\n', ...
                    '- The assembly value and preload are not finalized.', ...
                    '- Cost and mass of ISO_M39 based on extrapolation\n', ...
                    '- This list is not complete!\n\n', ...
                    '\t==> Only use ISO_M39 if this has been discussed with topic owners\n\n']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_iso_m90_provided__happy(Obj)
            % GIVEN multiple "preferred" bolt options, i.e. not containing ISO_M90
            Inputs.boltOptions = {'ISO_M42', 'ISO_M56', 'JIS_M48'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_iso_m90_provided();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_iso_m90_provided__sad(Obj)
            % GIVEN multiple bolt options, including ISO_M90
            Inputs.boltOptions = {'ISO_M42', 'ISO_M90', 'JIS_M48'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_iso_m90_provided();

            % THEN
            Obj.assertNotEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_iso_m100_provided__happy(Obj)
            % GIVEN multiple "preferred" bolt options, i.e. not containing ISO_M90
            Inputs.boltOptions = {'ISO_M42', 'ISO_M56', 'JIS_M48'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_iso_m100_provided();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_iso_m100_provided__sad(Obj)
            % GIVEN multiple bolt options, including ISO_M90
            Inputs.boltOptions = {'ISO_M42', 'ISO_M100', 'JIS_M48'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_iso_m100_provided();

            % THEN
            Obj.assertNotEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_iso_tightening_method_site_combination__happy(Obj)
            % GIVEN multiple bolt options WITHOUT torque tightening for ISO studs
            Inputs.site = 'onshore';
            Inputs.boltOptions = {'HV_M42', 'ISO_M64', 'ISO_M72'};
            Inputs.tighteningMethod = {'torque', 'tension', 'tension'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_iso_tightening_method_site_combination();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_iso_tightening_method_site_combination__sad(Obj)
            % GIVEN multiple bolt options WITH torque tightening for ISO studs
            Inputs.site = 'onshore';
            Inputs.boltOptions = {'HV_M42', 'ISO_M64', 'ISO_M72'};
            Inputs.tighteningMethod = {'torque', 'torque', 'torque'};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_iso_tightening_method_site_combination();

            % THEN
            Obj.assertEqual(length(PostParseChecks.LogHandler.buffer), 2);
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, ...
                ['Input site is set to "onshhore" and TIGHTENING_METHOD is set to "torque" for ISO_M64 studs. ', ...
                'This combination is not allowed.']);
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{2}, ...
                ['Input site is set to "onshhore" and TIGHTENING_METHOD is set to "torque" for ISO_M72 studs. ', ...
                'This combination is not allowed.']);
        end

        function check_thickness_tolerance_allowance_combination__happy(Obj)
            % GIVEN expected inputs for offshore designs
            Inputs.TOL_FLANGE_THICKNESS_MINUS = 2e-3;
            Inputs.ALW_UPPER_FLANGE_THICKNESS = 2e-3;
            Inputs.ALW_LOWER_FLANGE_THICKNESS = 2e-3;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_thickness_tolerance_allowance_combination();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN expected inputs for onshore designs
            Inputs.TOL_FLANGE_THICKNESS_MINUS = 0;
            Inputs.ALW_UPPER_FLANGE_THICKNESS = 0;
            Inputs.ALW_LOWER_FLANGE_THICKNESS = 0;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_thickness_tolerance_allowance_combination();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_thickness_tolerance_allowance_combination__sad(Obj)
            % GIVEN expected inputs for offshore designs
            Inputs.TOL_FLANGE_THICKNESS_MINUS = 2e-3;
            Inputs.ALW_UPPER_FLANGE_THICKNESS = 0;
            Inputs.ALW_LOWER_FLANGE_THICKNESS = 2e-3;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_thickness_tolerance_allowance_combination();

            % THEN
            expectedMessage = sprintf(['Input "TOL_FLANGE_THICKNESS_MINUS" is larger than the allowance(s).\n', ...
                    'This is not allowed!']);
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_active_design_conditions__happy(Obj)
            % GIVEN data from fixture which has most design conditions set to true.
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_active_design_conditions();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

        end

        function check_active_design_conditions__sad(Obj)
            % GIVEN all design conditions set to false
            Inputs.DO_ASSESS_BOLT_PLASTICITY = 0;
            Inputs.DO_ASSESS_BOLT_THREAD_REQ = 0;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = 0;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = 0;
            Inputs.DO_ASSESS_FLS = 0;
            Inputs.DO_ASSESS_GAPPING = 0;
            Inputs.DO_ASSESS_SCHMIDTNEUPER_APT = 0;
            Inputs.DO_ASSESS_SLS_PRETENSION = 0;
            Inputs.DO_ASSESS_ULS = 0;
            Inputs.DO_ASSESS_ULS_JPN = 0;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_active_design_conditions();

            % THEN
            expectedMessage = ['None of the condition toggles (i.e. the DO_ASSESS_* inputs) are enabled. ', ...
                    'USAIN will run, but the results will not guarantee a feasible flange design.'];
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_fls_schmidtneuper_model_combination__happy(Obj)
            % GIVEN valid input combination to assess FLS with SchmidtNeuper
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_ASSESS_SCHMIDTNEUPER_APT = true;
            Inputs.BoltFls.BOLT_FORCE_MODEL = "schmidtneuper";
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_fls_schmidtneuper_model_combination();

            % THEN
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN next valid input combination to assess FLS without SchmidtNeuper
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_ASSESS_SCHMIDTNEUPER_APT = false;
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_fls_schmidtneuper_model_combination();

            % THEN
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN last valid input combination not assessing FLS also no SchmidtNeuper
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_ASSESS_SCHMIDTNEUPER_APT = false;
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_fls_schmidtneuper_model_combination();

            % THEN
            Obj.verifyEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_fls_schmidtneuper_model_combination__sad(Obj)
            % GIVEN unexpected input combination, assess FLS and SchmidtNeuper applicability but no SchmidtNeuper bolt
            % force model.
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_ASSESS_SCHMIDTNEUPER_APT = true;
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_fls_schmidtneuper_model_combination();

            % THEN
            expectedMessage = sprintf(['FLS will be assessed. The provided inputs indicate that SchmidtNeuper ', ...
                        'is applicable.\nIn that case it is expected that both DO_ASSESS_SCHMIDTNEUPER_APT = true ', ...
                        'and at least one BoltFls.BOLT_FORCE_MODEL = schmidtneuper']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);

            % NEXT GIVEN unexpected input combination, assess FLS with SchmidtNeuper bolt force model but not the
            % applicability assessment.
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_ASSESS_SCHMIDTNEUPER_APT = false;
            Inputs.BoltFls.BOLT_FORCE_MODEL = "schmidtneuper";
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_fls_schmidtneuper_model_combination();

            % THEN
            expectedMessage = sprintf(['FLS will be assessed. The provided inputs indicate that SchmidtNeuper ', ...
                        'is applicable.\nIn that case it is expected that both DO_ASSESS_SCHMIDTNEUPER_APT = true ', ...
                        'and at least one BoltFls.BOLT_FORCE_MODEL = schmidtneuper']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);

            % NEXT GIVEN unexpected input combination, do not assess FLS but with SchmidtNeuper bolt force model and the
            % applicability assessment.
            Inputs.DO_ASSESS_FLS = false;
            Inputs.DO_ASSESS_SCHMIDTNEUPER_APT = true;
            Inputs.BoltFls.BOLT_FORCE_MODEL = "schmidtneuper";
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_fls_schmidtneuper_model_combination();

            % THEN
            expectedMessage = sprintf(['FLS will not be assessed. In that case it is expected that input ', ...
                        'DO_ASSESS_SCHMIDTNEUPER_APT = false and that there is no BoltFls.BOLT_FORCE_MODEL defined.']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);

            % NEXT GIVEN unexpected input combination, do not assess FLS but with SchmidtNeuper bolt force model not
            % applicability assessment.
            Inputs.DO_ASSESS_FLS = false;
            Inputs.DO_ASSESS_SCHMIDTNEUPER_APT = false;
            Inputs.BoltFls.BOLT_FORCE_MODEL = "schmidtneuper";
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_fls_schmidtneuper_model_combination();

            % THEN
            expectedMessage = sprintf(['FLS will not be assessed. In that case it is expected that input ', ...
                        'DO_ASSESS_SCHMIDTNEUPER_APT = false and that there is no BoltFls.BOLT_FORCE_MODEL defined.']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);

            % NEXT GIVEN unexpected input combination, do not assess FLS nor applicability but with SchmidtNeuper bolt
            % force model.
            Inputs.DO_ASSESS_FLS = false;
            Inputs.DO_ASSESS_SCHMIDTNEUPER_APT = true;
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_fls_schmidtneuper_model_combination();

            % THEN
            expectedMessage = sprintf(['FLS will not be assessed. In that case it is expected that input ', ...
                        'DO_ASSESS_SCHMIDTNEUPER_APT = false and that there is no BoltFls.BOLT_FORCE_MODEL defined.']);
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_diam_bolt_circle_b_min_combination__no_warning(Obj)
            % GIVEN
            Inputs.diamBoltCircle = nan;
            Inputs.B_MIN = nan;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_diam_bolt_circle_b_min_combination();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN
            Inputs.diamBoltCircle = [1234, 4321];
            Inputs.B_MIN = [nan, nan];

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_diam_bolt_circle_b_min_combination();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);

            % NEXT GIVEN
            Inputs.diamBoltCircle = [nan, nan];
            Inputs.B_MIN = [123, 321];

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_diam_bolt_circle_b_min_combination();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_diam_bolt_circle_b_min_combination__warning(Obj)
            % GIVEN
            Inputs.diamBoltCircle = 1234;
            Inputs.B_MIN = 123;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_diam_bolt_circle_b_min_combination();

            % THEN
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, sprintf([ ...
                'Both inputs "diamBoltCircle" and "B_MIN" are set.\n', ...
                'USAIN will design the flange with the provided value for "diamBoltCircle"!\n', ...
                'Potentially violating the criteria from "B_MIN".']));
        end

    end

    methods (Test, TestTags = {'integration'})

        function run__single__happy(Obj)
            % GIVEN happy case
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.Loads.ulsScalingLevel = {{-200, 200}};
            Inputs.Loads.flsScalingLevel = {{-200, 200}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.run();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_boltfls_custom_preload_wrt_bolt_yield_strength__happy(Obj)
            % GIVEN inputs from fixture, hence all nan for CUSTOM_PRELOAD
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_custom_preload_wrt_bolt_yield_strength();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_boltfls_custom_preload_wrt_bolt_yield_strength__sad(Obj)
            % GIVEN inputs from fixture, setting one CUSTOM_PRELOAD with really low value
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.BoltFls.CUSTOM_PRELOAD = [1, 1];
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_boltfls_custom_preload_wrt_bolt_yield_strength();

            % THEN
            expectedMessage = ['One or more "*.CUSTOM_PRELOAD" inputs found with a value <50% or >100% of yield. ', ...
                        'This is not expected.'];
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_bolt_sn_curves__happy(Obj)
            % GIVEN inputs from fixture, where multiple BoltFls blocks with S-N curves are defined
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.BoltFls(2) = Inputs.BoltFls(1);
            Inputs.BoltFls(2).SN_CURVE_BOLT = "EC3_DC50";
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN, THEN
            PostParseChecks.check_bolt_sn_curves();
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_bolt_sn_curves__sad(Obj)
            % GIVEN inputs from fixture, where a DNV S-N curve is defined for the bolts
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.BoltFls(1).SN_CURVE_BOLT = "DNV_A";
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN, THEN
            PostParseChecks.check_bolt_sn_curves();
            expectedMessage = 'All S-N curves defined for bolts must be Eurocode S-N curves, i.e. in format EC3_DC**.';
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_scaling_reference_levels__numbers_no_strmdl__happy(Obj)
            % GIVEN
            Inputs.structureInpFilePath = '';
            Inputs.Loads.ulsScalingLevel = {{4, 5}, {6, 7}};
            Inputs.Loads.flsScalingLevel =  {{40, 50}, {60, 70}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_scaling_reference_levels();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_scaling_reference_levels__numbers_strmdl__happy(Obj)
            % GIVEN
            Inputs.structureInpFilePath = 'C:\temp\lala.mat';
            Inputs.Loads.ulsScalingLevel = {{4, 5}, {6, 7}};
            Inputs.Loads.flsScalingLevel =  {{40, 50}, {60, 70}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_scaling_reference_levels();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_scaling_reference_levels__reference_levels_strmdl__happy(Obj)
            % GIVEN
            Inputs.structureInpFilePath = 'C:\temp\lala.mat';
            Inputs.Loads.ulsScalingLevel = {{'interface', 5}, {6, 7}};
            Inputs.Loads.flsScalingLevel =  {{40, 50}, {60, 70}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_scaling_reference_levels();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_scaling_reference_levels__reference_levels_no_strmdl__sad(Obj)
            % GIVEN
            Inputs.structureInpFilePath = '';
            Inputs.Loads.ulsScalingLevel = {{'interface', 5}, {6, 7}};
            Inputs.Loads.flsScalingLevel =  {{40, 50}, {60, 70}};
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);

            % WHEN
            PostParseChecks.check_scaling_reference_levels();

            % THEN
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, ['Loads(1).ulsScalingLevel are not ', ...
                'all numbers. If you want to input reference levels (like "towerTop"), you need to provide a ', ...
                'Structural Model.']);
        end

        function check_uls_bolt_diameter_selection_requirement__no_warning_1(Obj)
            % GIVEN inputs such that no bolt diameter selection is done, without a ULS failure mode assessment
            Inputs.BOLT_DIAMETER_SELECTION = 'all';
            Inputs.DO_ASSESS_ULS = false;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_uls_bolt_diameter_selection_requirement();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_uls_bolt_diameter_selection_requirement__no_warning_2(Obj)
            % GIVEN inputs such that ULS-based bolt diameter selection is done, with a ULS failure mode assessment
            Inputs.BOLT_DIAMETER_SELECTION = 'uls';
            Inputs.DO_ASSESS_ULS = true;
            Inputs.DO_UPDATE_DESIGN_SPACE = true;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_uls_bolt_diameter_selection_requirement();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_uls_bolt_diameter_selection_requirement__warning(Obj)
            % GIVEN
            Inputs.BOLT_DIAMETER_SELECTION = 'uls';
            Inputs.DO_ASSESS_ULS = false;
            Inputs.DO_UPDATE_DESIGN_SPACE = false;

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_uls_bolt_diameter_selection_requirement();

            % THEN
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{1}, sprintf([ ...
                'Input "BOLT_DIAMETER_SELECTION" is set to "uls", but "DO_ASSESS_ULS" is disabled.\n', ...
                '\t==> Input will be ignored.']));
            Obj.verifyWarningMessage(PostParseChecks.LogHandler.buffer{2}, sprintf([ ...
                'Input "BOLT_DIAMETER_SELECTION" is set to "uls", but "DO_UPDATE_DESIGN_SPACE" is disabled.\n', ...
                '\t==> Input will be ignored.']));
        end

        function check_mixed_bolt_series__no_warning(Obj)
            % GIVEN boltOptions of only one series
            Inputs.boltOptions = {'ISO_M42', 'ISO_M56x123'};
            Inputs.BOLT_DIAMETER_SELECTION = 'uls';

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_mixed_bolt_series();

            % THEN
            Obj.assertEmpty(PostParseChecks.LogHandler.buffer);
        end

        function check_mixed_bolt_series__warning(Obj)
            % GIVEN boltOptions of > 1 series
            Inputs.boltOptions = {'ISO_M42', 'HV_M42', 'HV_M56x123'};
            Inputs.BOLT_DIAMETER_SELECTION = 'uls';

            % WHEN
            PostParseChecks = usain.inputs.PostParseChecks(Inputs = Inputs);
            PostParseChecks.check_mixed_bolt_series();

            % THEN
            Obj.verifyErrorMessage(PostParseChecks.LogHandler.buffer{1}, sprintf([ ...
                'It is not allowed to set input "BOLT_DIAMETER_SELECTION" to "uls" and ', ...
                'select multiple bolt series (HV, ISO).']));
        end

    end

end
