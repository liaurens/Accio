classdef LoadExternalFilesStep_Test < UsainTest.UsainTestCase

    methods (Static)

        function Inputs = get_usain_inputs_for_loads_uls()
            Inputs = struct();
            Inputs.Loads.ALIGN_AT = {'towertop', 'towertop'}; % Align loads at towerTop
            Inputs.Loads.ulsFilePath = ...
                {char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-uls-loads__contemp.mat')};
            Inputs.Loads.dlcFilter = {'^DLC14', '^DLC12'};
            Inputs.Loads.tag = {'DLC14 only', 'DLC12 only'};
            Inputs.DO_ASSESS_ULS = true;
            Inputs.DO_ASSESS_ULS_JPN = false;
        end

        function Inputs = get_usain_inputs_for_loads_fls()
            Inputs = struct();
            Inputs.Loads.ALIGN_AT = {'towertop', 'towertop'}; % Align loads at towerTop
            Inputs.Loads.flsFilePath = ...
                {char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-fls-loads.scm')};
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_ASSESS_GAPPING = false;
            Inputs.DO_ASSESS_SLS_PRETENSION = false;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;
        end

    end

    methods (Test, TestTags = {'integration'})

        function run__happy_load_structural_model(Obj)
            % GIVEN a sequential runner with just the step for this test class and set inputs such that only the
            % StructuralModel file is loaded
            Runner = runner.SequentialRunner().add( ...
                usain.io.LoadExternalFilesStep());

            Inputs.structureInpFilePath = ...
                pathlib.Path(mfilename('fullpath')).parent / 'data' / 'simple_structural_model.mat';

            % Ensure FLS loads are not attempted to be loaded
            Inputs.DO_ASSESS_FLS = false;
            Inputs.DO_ASSESS_GAPPING = false;
            Inputs.DO_ASSESS_SLS_PRETENSION = false;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;

            % Ensure ULS loads are not attempted to be loaded
            Inputs.DO_ASSESS_ULS = false;
            Inputs.DO_ASSESS_ULS_JPN = false;

            % Ensure S1 loads are not attempted to be loaded
            Inputs.DO_ASSESS_BOLT_PLASTICITY = false;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = false;

            Runner.set(usain.DataKeys.Inputs, Inputs);

            % WHEN, THEN
            Obj.verify_error_free(@() Runner.run());
            Obj.verifyEmpty(Runner.SkippedSteps);

            Obj.verifyTrue(Runner.is_gettable(usain.DataKeys.StructuralModel));
            Obj.verifyFalse(Runner.is_gettable(usain.DataKeys.ExternalFlsLoadsData));
            Obj.verifyFalse(Runner.is_gettable(usain.DataKeys.ExternalUlsLoadsData));
        end

        function run__happy_load_all_files(Obj)
            % GIVEN a sequential runner with just the step for this test class and set inputs such all files are loaded
            Runner = runner.SequentialRunner().add( ...
                usain.io.LoadExternalFilesStep());

            Inputs.structureInpFilePath = ...
                pathlib.Path(mfilename('fullpath')).parent / 'data' / 'simple_structural_model.mat';
            Inputs.Loads.flsFilePath = ...
                {char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-fls-loads.scm')};
            Inputs.Loads.S1FilePath = ...
                {char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-s1-loads.mat')};
            Inputs.Loads.ulsFilePath = ...
                {char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-uls-loads__on_circle_tresh.txt')};
            Inputs.Loads.dlcFilter = {'.*'};
            Inputs.Loads.tag = {'team'};
            Inputs.Loads.ALIGN_AT = {'interface'};
            % NOTE: Loads.* field values are converted to cell arrays in USAIN, so done here as well

            Inputs.ULS_BENDING_MOMENT = nan; % If this override value is set(not nan); then ULS files will not be loaded
            Inputs.S1_BENDING_MOMENT = nan; % If this override value is set (not nan); then S1 files will not be loaded

            % Ensure FLS, S1 and ULS loads are loaded
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_ASSESS_GAPPING = false;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = false;
            Inputs.DO_ASSESS_SLS_PRETENSION = false;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;
            Inputs.DO_ASSESS_ULS = true;
            Inputs.DO_ASSESS_ULS_JPN = false;

            Runner.set(usain.DataKeys.Inputs, Inputs);

            % WHEN, THEN
            Obj.verify_error_free(@() Runner.run());
            Obj.verifyEmpty(Runner.SkippedSteps);
            Obj.verifyTrue(Runner.is_gettable(usain.DataKeys.StructuralModel));
            Obj.verifyTrue(Runner.is_gettable(usain.DataKeys.ExternalFlsLoadsData));
            Obj.verifyTrue(Runner.is_gettable(usain.DataKeys.ExternalUlsLoadsData));
        end

    end

    methods (Test, TestTags = {'unit'})

        function load_uls_files__multiple_with_dlc_filtering(Obj)
            % GIVEN inputs that prescribe multiple ULS load files
            Inputs.Loads.ulsFilePath = { ...
                char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-uls-loads__on_circle_tresh.txt'), ...
                char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-uls-loads__on_circle_tresh.txt')};
            Inputs.Loads.dlcFilter = {'^DLC14', '^DLC12'};
            Inputs.Loads.tag = {'DLC14 only', 'DLC12 only'};
            Inputs.DO_ASSESS_ULS = true;
            Inputs.DO_ASSESS_ULS_JPN = false;
            Inputs.Loads.ALIGN_AT = {'interface', 'interface'};
            Levels = Fe.LevelsContainer.empty();

            % WHEN
            Actual = usain.io.LoadExternalFilesStep().load_uls_files(Levels, Inputs);

            % THEN
            Obj.assertNumElements(Actual, 2);
            Obj.verifyTrue(all(startsWith(Actual(1).dlc, 'DLC14')));
            Obj.verifyTrue(all(startsWith(Actual(2).dlc, 'DLC12')));
        end

        function load_uls_files__skipped(Obj)
            % GIVEN inputs that prescribe loading of ULS load files can be skipped
            Inputs.DO_ASSESS_ULS = false;
            Inputs.DO_ASSESS_ULS_JPN = false;
            Levels = Fe.LevelsContainer.empty();

            % WHEN, THEN
            Actual = usain.io.LoadExternalFilesStep().load_uls_files(Levels, Inputs);
            Obj.verifyEmpty(Actual);
        end

        function load_uls_files__happy_align_loads_for_short_tower(Obj)
            % GIVEN inputs that are used to assess the running of ULS load files and
            % expert input Inputs.Loads.ALIGN_AT is present
            % Loads heights here --> -132.414, 0 (TowerTop, Interface)
            % Structural model height --> -105.914
            % After alignment of the loads, the load height will be 26.5(at interface) & -105.9140 at towertop
            Inputs = usain.io.test.LoadExternalFilesStep_Test.get_usain_inputs_for_loads_uls();
            Levels = Fe.LevelsContainer('towerTop', -105.914);
            LoadStep = usain.io.LoadExternalFilesStep();

            % WHEN
            actual = LoadStep.load_uls_files(Levels, Inputs);

            % THEN validate the load levels at interface and towertop
            expectedInterfaceLevel = {26.5000};
            expectedTowerTopLevel = {-105.9140};
            Obj.verifyEqual(actual(1).Channels.zLevels(1), expectedInterfaceLevel, 'RelTol', 1e-5);
            Obj.verifyEqual(actual(1).Channels.zLevels(end), expectedTowerTopLevel, 'RelTol', 1e-5);
        end

        function load_uls_files__happy_align_loads_same_height(Obj)
            % GIVEN inputs that are used to assess the running of ULS load files and
            % expert input Inputs.Loads.ALIGN_AT is present
            % Loads heights here --> -132.414, 0 (TowerTop, Interface)
            % Structural model height --> -132.414
            % After alignment of the loads, the load height will be 0.0(at interface) & -132.414 at towertop
            Inputs = usain.io.test.LoadExternalFilesStep_Test.get_usain_inputs_for_loads_uls();
            Levels = Fe.LevelsContainer('towerTop', -132.414);
            LoadStep = usain.io.LoadExternalFilesStep();

            % WHEN
            actual = LoadStep.load_uls_files(Levels, Inputs);

            % THEN validate the load levels at interface and towertop
            expectedInterfaceLevel = {0.00};
            expectedTowerTopLevel = {-132.4140};
            Obj.verifyEqual(actual(1).Channels.zLevels(1), expectedInterfaceLevel, 'AbsTol', 1e-5);
            Obj.verifyEqual(actual(1).Channels.zLevels(end), expectedTowerTopLevel, 'RelTol', 1e-5);
        end

        function load_uls_files__happy_align_loads_for_longer_tower(Obj)
            % GIVEN inputs that are used to assess the running of ULS load files and
            % expert input Inputs.Loads.ALIGN_AT is present
            % Loads heights here --> -132.414, 0 (TowerTop, Interface)
            % Structural model height --> -150.914
            % After alignment of the loads, the load height will be -18.5(at interface) & -150.914 at towertop
            Inputs = usain.io.test.LoadExternalFilesStep_Test.get_usain_inputs_for_loads_uls();
            Levels = Fe.LevelsContainer('towerTop', -150.914);
            LoadStep = usain.io.LoadExternalFilesStep();

            % WHEN
            actual = LoadStep.load_uls_files(Levels, Inputs);

            % THEN validate the load levels at interface and towertop
            expectedInterfaceLevel = {-18.5000};
            expectedTowerTopLevel = {-150.9140};
            Obj.verifyEqual(actual(1).Channels.zLevels(1), expectedInterfaceLevel, 'RelTol', 1e-5);
            Obj.verifyEqual(actual(1).Channels.zLevels(end), expectedTowerTopLevel, 'RelTol', 1e-5);
        end

        function load_fls_files__multiple_files(Obj)
            % GIVEN inputs that prescribe multiple FLS load files
            Inputs.Loads.flsFilePath = { ...
                char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-fls-loads.scm'), ...
                char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-fls-loads.scm')};
            Inputs.Loads.ALIGN_AT = {'interface', 'interface'};
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_ASSESS_GAPPING = false;
            Inputs.DO_ASSESS_SLS_PRETENSION = false;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;
            Levels = Fe.LevelsContainer.empty();

            % WHEN
            Actual = usain.io.LoadExternalFilesStep().load_fls_files(Levels, Inputs);

            % THEN
            Obj.assertNumElements(Actual, 2);
        end

        function load_fls_files__skipped(Obj)
            % GIVEN inputs that prescribe loading of FLS load files can be skipped
            Inputs.DO_ASSESS_FLS = false;
            Inputs.DO_ASSESS_GAPPING = false;
            Inputs.DO_ASSESS_SLS_PRETENSION = false;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;
            Levels = Fe.LevelsContainer.empty();

            % WHEN, THEN
            Actual = usain.io.LoadExternalFilesStep().load_fls_files(Levels, Inputs);
            Obj.verifyEmpty(Actual);
        end

        function load_fls_files__happy_align_loads_for_short_tower(Obj)
            % GIVEN inputs that are used to assess the running of FLS load files and
            % expert input Inputs.Loads.ALIGN_AT is present
            % Loads heights here --> -99.99, 0 (TowerTop, Interface)
            % Structural model height --> -80.0
            % After alignment of the loads, the load height will be 19.99(at interface) & -80.0 at towertop
            Inputs = usain.io.test.LoadExternalFilesStep_Test.get_usain_inputs_for_loads_fls();
            Levels = Fe.LevelsContainer('towerTop', -80.0);
            LoadStep = usain.io.LoadExternalFilesStep();

            % WHEN
            actual = LoadStep.load_fls_files(Levels, Inputs);

            % THEN validate the load levels at interface and towertop for Markov
            expectedInterfaceLevel = {19.99};
            expectedTowerTopLevel = {-80.0};
            Obj.verifyEqual(actual.Del.Channels.zLevels(end), expectedInterfaceLevel, 'RelTol', 1e-5);
            Obj.verifyEqual(actual.Del.Channels.zLevels(1), expectedTowerTopLevel, 'RelTol', 1e-5);

            Obj.verifyEqual(actual.LoadRange.Channels.zLevels(end), expectedInterfaceLevel, 'RelTol', 1e-5);
            Obj.verifyEqual(actual.LoadRange.Channels.zLevels(1), expectedTowerTopLevel, 'RelTol', 1e-5);

            Obj.verifyEqual(actual.Markov.Channels.zLevels(end), expectedInterfaceLevel, 'RelTol', 1e-5);
            Obj.verifyEqual(actual.Markov.Channels.zLevels(1), expectedTowerTopLevel, 'RelTol', 1e-5);
        end

        function load_fls_files__happy_align_loads_same_height(Obj)
            % GIVEN inputs that are used to assess the running of FLS load files and
            % expert input Inputs.Loads.ALIGN_AT is present
            % Loads heights here --> -99.99, 0 (TowerTop, Interface)
            % Structural model height --> -99.99
            % After alignment of the loads, the load height will be 0.0(at interface) & -99.99 at towertop
            Inputs = usain.io.test.LoadExternalFilesStep_Test.get_usain_inputs_for_loads_fls();
            Levels = Fe.LevelsContainer('towerTop', -99.99);
            LoadStep = usain.io.LoadExternalFilesStep();

            % WHEN
            actual = LoadStep.load_fls_files(Levels, Inputs);

            % THEN validate the load levels at interface and towertop for Markov
            expectedInterfaceLevel = {0.00};
            expectedTowerTopLevel = {-99.99};
            Obj.verifyEqual(actual.Del.Channels.zLevels(end), expectedInterfaceLevel, 'RelTol', 1e-5);
            Obj.verifyEqual(actual.Del.Channels.zLevels(1), expectedTowerTopLevel, 'RelTol', 1e-5);

            Obj.verifyEqual(actual.LoadRange.Channels.zLevels(end), expectedInterfaceLevel, 'RelTol', 1e-5);
            Obj.verifyEqual(actual.LoadRange.Channels.zLevels(1), expectedTowerTopLevel, 'RelTol', 1e-5);

            Obj.verifyEqual(actual.Markov.Channels.zLevels(end), expectedInterfaceLevel, 'RelTol', 1e-5);
            Obj.verifyEqual(actual.Markov.Channels.zLevels(1), expectedTowerTopLevel, 'RelTol', 1e-5);
        end

        function load_fls_files__happy_align_loads_for_longer_tower(Obj)
            % GIVEN inputs that are used to assess the running of FLS load files and
            % expert input Inputs.Loads.ALIGN_AT is present
            % Loads heights here --> -99.99, 0 (TowerTop, Interface)
            % Structural model height --> -150.91
            % After alignment of the loads, the load height will be -50.92(at interface) & -150.91 at towertop
            Inputs = usain.io.test.LoadExternalFilesStep_Test.get_usain_inputs_for_loads_fls();
            Levels = Fe.LevelsContainer('towerTop', -150.91);
            LoadStep = usain.io.LoadExternalFilesStep();

            % WHEN
            actual = LoadStep.load_fls_files(Levels, Inputs);

            % THEN validate the load levels at interface and towertop for Markov
            expectedInterfaceLevel = {-50.92};
            expectedTowerTopLevel = {-150.91};
            Obj.verifyEqual(actual.Del.Channels.zLevels(end), expectedInterfaceLevel, 'RelTol', 1e-5);
            Obj.verifyEqual(actual.Del.Channels.zLevels(1), expectedTowerTopLevel, 'RelTol', 1e-5);

            Obj.verifyEqual(actual.LoadRange.Channels.zLevels(end), expectedInterfaceLevel, 'RelTol', 1e-5);
            Obj.verifyEqual(actual.LoadRange.Channels.zLevels(1), expectedTowerTopLevel, 'RelTol', 1e-5);

            Obj.verifyEqual(actual.Markov.Channels.zLevels(end), expectedInterfaceLevel, 'RelTol', 1e-5);
            Obj.verifyEqual(actual.Markov.Channels.zLevels(1), expectedTowerTopLevel, 'RelTol', 1e-5);
        end

        function load_fls_files__no_zlevel_if_markov_file_provided(Obj)
            % GIVEN inputs that are used to assess the running of FLS load files
            Inputs.Loads.ALIGN_AT = {'towertop'}; % Align loads at towerTop
            Inputs.Loads.flsFilePath = ...
                {char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-markov' / ...
                'dummy-fls-loads_Ch1.mkv')};
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_ASSESS_GAPPING = false;
            Inputs.DO_ASSESS_SLS_PRETENSION = false;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;
            Levels = Fe.LevelsContainer('towerTop', -150.91);
            LoadStep = usain.io.LoadExternalFilesStep();

            % WHEN
            actual = LoadStep.load_fls_files(Levels, Inputs);

            % THEN validate that no channel zLevel information is stored
            Obj.verifyEmpty(actual.Markov.Channels.zLevels);
        end

        function load_s1_files__multiple_files(Obj)
            % GIVEN inputs that prescribe multiple S1 load files
            Inputs.Loads.S1FilePath = { ...
                char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-s1-loads.mat'), ...
                char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-s1-loads.mat')};
            Inputs.Loads.ALIGN_AT = {'interface', 'interface'};
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = true;
            Levels = Fe.LevelsContainer.empty();

            % WHEN
            Actual = usain.io.LoadExternalFilesStep().load_s1_files(Levels, Inputs);

            % THEN
            Obj.assertNumElements(Actual, 2);
        end

        function load_s1_files__skipped(Obj)
            % GIVEN inputs that prescribe loading of S1 load files can be skipped
            Inputs.DO_ASSESS_BOLT_PLASTICITY = false;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = false;
            Levels = Fe.LevelsContainer.empty();

            % WHEN, THEN
            Actual = usain.io.LoadExternalFilesStep().load_s1_files(Levels, Inputs);
            Obj.verifyEmpty(Actual);
        end

        function load_s1_files__multiple_files_with_empties(Obj)
            % GIVEN inputs that prescribe 3 Loads.* input blocks, where block #2 does not set an S1 load files
            Inputs.Loads.S1FilePath = { ...
                char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-s1-loads.mat'), ...
                '', ...
                char(pathlib.Path(mfilename('fullpath')).parent / 'data' / 'dummy-s1-loads.mat')};
            Inputs.Loads.ALIGN_AT = {'interface', 'interface', 'interface'};
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = true;
            Levels = Fe.LevelsContainer.empty();

            % WHEN
            Actual = usain.io.LoadExternalFilesStep().load_s1_files(Levels, Inputs);

            % THEN verify 3 MILK objects are returned, where the 2nd is empty
            Obj.verifyNumElements(Actual, 3);
            Obj.verifyClass(Actual, 'Milk.ServiceAbilityLoads');
            Obj.verifyFalse(Actual(1).isEmpty);
            Obj.verifyTrue(Actual(2).isEmpty);
            Obj.verifyFalse(Actual(3).isEmpty);
        end

        function log_success__message_logged(Obj)
            % GIVEN a LoadExternalFilesStep with custom logger to intercept messages
            CustomLogger = logging.Logger.get_logger('test');
            LogHandler = logging.CellArrayHandler();
            CustomLogger.add_handler(LogHandler);
            CustomLogger.parent = [];  % decouple this logger from the root logger (which emits to the stream)

            Step = usain.io.LoadExternalFilesStep(Logger = CustomLogger);

            % WHEN, THEN
            Step.log_success('dummy file', 'c:/ab.c');
            logMessages = cellfun(@(x) x.message, LogHandler.buffer, 'UniformOutput', false);
            containsCorrectLogMessage = contains(string(logMessages), ...
                'Successfully loaded dummy file from file: c:/ab.c');
            Obj.verifyTrue(any(containsCorrectLogMessage));
        end

    end
end
