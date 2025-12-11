classdef (SharedTestFixtures = {fixtures.SilentlyLogFixture(logging.Level.ERROR)}) ...
        PostLoadChecks_Test < Unittest.TestCase

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

        function check_flange_type__happy(Obj)
            % GIVEN no StructuralModel, hence skipping check
            Inputs.flangeType = 'L';
            Inputs.structureInpFilePath = '';

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_flange_type();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);

            % NEXT GIVEN a StructuralModel for which the flangeType matches the user input
            Inputs.structureInpFilePath = 'somePath';
            Inputs.StrMdl = usain.inputs.test.PostLoadManipulations_Test().setup_test_structural_model();

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs, iElem = [6, 7]);
            PostLoadChecks.check_flange_type();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);
        end

        function check_flange_type__sad(Obj)
            % GIVEN a StructuralModel and provide mismatching user input
            Inputs.structureInpFilePath = 'somePath';
            Inputs.StrMdl = usain.inputs.test.PostLoadManipulations_Test().setup_test_structural_model();
            Inputs.flangeType = 'T';

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs, iElem = [6, 7]);
            PostLoadChecks.check_flange_type();

            % THEN expect a warning to be logged
            Obj.assertNotEmpty(PostLoadChecks.LogHandler.buffer);
            expectedMsg = "Mismatch between input 'flangeType' and corresponding value in StructuralModel " +  ...
                        "input file:" + newline + ...
                        "   - StructuralModel file: somePath" + newline +  ...
                        "   - Element label:        FL08" + newline + ...
                        "   - Element value:        L-flange" + newline + ...
                        "   - Input value:          T-flange" + newline + ...
                        "   ==> Continuing with input value" + newline + newline;

            Obj.verifyWarningMessage(PostLoadChecks.LogHandler.buffer{1}, expectedMsg);
        end

        function check_diameter__happy(Obj)
            % GIVEN no StructuralModel, hence skipping check
            Inputs.structureInpFilePath = '';

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_diameter();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);

            % NEXT GIVEN a StructuralModel and valid diameter input
            Inputs.structureInpFilePath = 'somePath';
            Inputs.StrMdl = usain.inputs.test.PostLoadManipulations_Test().setup_test_structural_model();
            Inputs.flangeType = 'L';
            Inputs.diameter = 7;
            Inputs.diameterReference = 'outneck';

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs, iElem = [6, 7]);
            PostLoadChecks.check_diameter();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);

            % NEXT GIVEN similar inputs, only change the diameterReference
            Inputs.diameterReference = 'outermost';

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs, iElem = [6, 7]);
            PostLoadChecks.check_diameter();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);

            % NEXT GIVEN similar inputs, modify flangeType and diameterReference
            Inputs.flangeType = 'T';
            Inputs.diameterReference = 'outneck';

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs, iElem = [6, 7]);
            PostLoadChecks.check_diameter();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);
        end

        function check_diameter__sad(Obj)
            % GIVEN a StructuralModel and invalid diameter input
            Inputs.structureInpFilePath = 'somePath';
            Inputs.StrMdl = usain.inputs.test.PostLoadManipulations_Test().setup_test_structural_model();
            Inputs.flangeType = 'L';
            Inputs.diameter = 7.5;
            Inputs.diameterReference = 'outneck';

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs, iElem = [6, 7]);
            PostLoadChecks.check_diameter();

            % THEN a warning should be logged
            Obj.verifyNotEmpty(PostLoadChecks.LogHandler.buffer);

            % NEXT GIVEN similar inputs, but change flangeType, diameter and diameterReference
            Inputs.flangeType = 'T';
            Inputs.diameter = 7;
            Inputs.diameterReference = 'outermost';

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs, iElem = [6, 7]);
            PostLoadChecks.check_diameter();

            % THEN a warning should be logged
            Obj.verifyNotEmpty(PostLoadChecks.LogHandler.buffer);
        end

        function check_input_bolt_circle_diameter__happy(Obj)
            % GIVEN no user provided "diamBoltCircle"; check should be skipped
            Inputs.diamBoltCircle = nan;

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_input_bolt_circle_diameter();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);

            % NEXT GIVEN user provided input "diamBoltCircle" plus minimal inputs needed to run method.
            Inputs.diamBoltCircle = [7.66, 7.66];
            Inputs.diameter = 8;
            Inputs.diameterReference = 'outneck';
            Inputs.flangeType = 'L';
            Inputs.maxFlangeWidth = [0.5, 0.5];
            Inputs.thicknNoseUp = 0.070;

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_input_bolt_circle_diameter();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);

            % NEXT GIVEN similar inputs but no "maxFlangeWidth" such that it will be calculated internally
            Inputs.maxFlangeWidth = nan(1, 2);
            Inputs.boltOptions = {'ISO_M56', 'ISO_M64'};

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_input_bolt_circle_diameter();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);
        end

        function check_input_bolt_circle_diameter__sad(Obj)
            % GIVEN user provided "diamBoltCircle" which will not fit geometrically
            Inputs.diamBoltCircle = [2, 10];
            Inputs.diameter = 8;
            Inputs.flangeType = 'L';
            Inputs.diameterReference = 'outneck';
            Inputs.maxFlangeWidth = [0.5, 0.5];
            Inputs.thicknNoseUp = 0.070;

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_input_bolt_circle_diameter();

            % THEN
            expectedMsg = sprintf(['Input "diamBoltCircle" is not within a feasible flange width range ', ...
                    '(user input or calculated).\nPlease revise the inputs.']);
            Obj.verifyErrorMessage(PostLoadChecks.LogHandler.buffer{1}, expectedMsg);
        end

        function check_boltfls_petersen_for_t_flange__happy(Obj)
            % GIVEN valid/expected inputs
            Inputs.BoltFls.BOLT_FORCE_MODEL = "petersen";
            Inputs.flangeType = 'T';
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);

            % WHEN
            PostLoadChecks.check_boltfls_petersen_for_t_flange();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);

            % NEXT GIVEN other set of valid/expected inputs
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            Inputs.flangeType = 'L';
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);

            % WHEN
            PostLoadChecks.check_boltfls_petersen_for_t_flange();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);
        end

        function check_boltfls_petersen_for_t_flange__sad(Obj)
            % GIVEN invalid input combination
            Inputs.BoltFls.BOLT_FORCE_MODEL = "petersen";
            Inputs.flangeType = 'L';
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);

            % WHEN
            PostLoadChecks.check_boltfls_petersen_for_t_flange();

            % THEN
            expectedMsg = sprintf(['An FLS assessment with the "petersen" model is requested for an L-flange.\n', ...
                    'Petersen is expected only to be used for T-flanges!']);
            Obj.verifyWarningMessage(PostLoadChecks.LogHandler.buffer{1}, expectedMsg);

            % NEXT GIVEN other set of invalid input combination
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            Inputs.flangeType = 'T';
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);

            % WHEN
            PostLoadChecks.check_boltfls_petersen_for_t_flange();

            % THEN
            expectedMsg = sprintf(['A design for T-flange is requested, but not using the "petersen" model.\n', ...
                    'For T-flanges it is expected to use the "petersen" model for FLS.\n', ...
                    'Note: the design must adhere to the (current) applicable design brief, if that indicates a ', ...
                    'different model for T-flanges, that one should be used for certification.']);
            Obj.verifyWarningMessage(PostLoadChecks.LogHandler.buffer{1}, expectedMsg);
        end

        function check_boltfls_sgre2_expected_assessments__happy(Obj)
            % GIVEN valid/expected inputs, not using sgre2 as BOLT_FORCE_MODEL
            Inputs.BoltFls.BOLT_FORCE_MODEL = "schmidtneuper";
            Inputs.flangeType = 'L';
            Inputs.DO_ASSESS_ULS = true;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = true;
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);

            % WHEN
            PostLoadChecks.check_boltfls_sgre2_expected_assessments();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);

            % NEXT GIVEN valid/expected inputs, using sgre2 as BOLT_FORCE_MODEL
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);

            % WHEN
            PostLoadChecks.check_boltfls_sgre2_expected_assessments();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);
        end

        function check_boltfls_sgre2_expected_assessments__no_uls(Obj)
            % GIVEN inputs for using sgre2 without assessing ULS
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            Inputs.flangeType = 'L';
            Inputs.DO_ASSESS_ULS = false;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = true;
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);

            % WHEN, THEN
            PostLoadChecks.check_boltfls_sgre2_expected_assessments();
            expectedMessage = ...
                sprintf(['An FLS assessment with "sgre2" is requested, but no ULS will be assessed.\n', ...
                'The precondition for SGRE2.0, that failure mode A (T-flange) or B (L-flange) is governing, ', ...
                'will not be checked.']);
            Obj.verifyWarningMessage(PostLoadChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_boltfls_sgre2_expected_assessments__no_bolt_plasticity(Obj)
            % GIVEN inputs for using sgre2 without assessing bolt plasticity
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            Inputs.flangeType = 'L';
            Inputs.DO_ASSESS_ULS = true;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = false;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = true;
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);

            % WHEN, THEN
            PostLoadChecks.check_boltfls_sgre2_expected_assessments();
            expectedMessage = sprintf(['An FLS assessment with "sgre2" is requested, ', ...
                'while input DO_ASSESS_BOLT_PLASTICITY is set to false.\n', ...
                'This precondition for SGRE2.0 will not be checked.']);
            Obj.verifyWarningMessage(PostLoadChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_boltfls_sgre2_expected_assessments__no_flange_plasticity(Obj)
            % GIVEN inputs for using sgre2 without assessing flange plasticity
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";
            Inputs.flangeType = 'T';
            Inputs.DO_ASSESS_ULS = true;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = false;
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);

            % WHEN checking for a T-flange
            % THEN expect no warning
            Obj.verifyEmpty(PostLoadChecks.LogHandler.buffer);

            % WHEN checking for an L-flange
            % THEN
            PostLoadChecks.Inputs.flangeType = 'L';
            PostLoadChecks.check_boltfls_sgre2_expected_assessments();
            expectedMessage = sprintf(['An FLS assessment with "sgre2" for an L-flange is requested, ', ...
                'while input DO_ASSESS_FLANGE_PLASTICITY is set to false.\n', ...
                'This precondition for SGRE2.0 will not be checked.']);
            Obj.verifyWarningMessage(PostLoadChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_fillet_radius__happy(Obj)
            % GIVEN
            Inputs.FILLET_RADIUS = 10e-3;
            Inputs.flangeType = 'L';
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);

            % WHEN
            PostLoadChecks.check_fillet_radius();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);

            % NEXT GIVEN
            Inputs.FILLET_RADIUS = 15e-3;
            Inputs.flangeType = 'T';
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);

            % WHEN
            PostLoadChecks.check_fillet_radius();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);
        end

        function check_fillet_radius__sad(Obj)
            % GIVEN
            Inputs.FILLET_RADIUS = 5e-3;
            Inputs.flangeType = 'L';
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);

            % WHEN
            PostLoadChecks.check_fillet_radius();

            % THEN
            expectedMessage = sprintf(['Input "FILLET_RADIUS" is set to a too low value.\n', ...
                    'The expected minimum is 10mm for an L-flange and 15mm for a T-flange.\n', ...
                    'A lower value is unexpected and requires a seperate damage assessment by FEA!']);
            Obj.verifyWarningMessage(PostLoadChecks.LogHandler.buffer{1}, expectedMessage);
        end

        function check_tilt_angle_for_flange_type__lflange_no_tilt(Obj)
            % GIVEN an L-flange with 0 tilt
            Inputs.SGRE2.FLANGE_TILT_VALUE = 0;
            Inputs.flangeType = 'L';
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_tilt_angle_for_flange_type();

            % THEN expect no warning
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);
        end

        function check_tilt_angle_for_flange_type__tflange_positive_tilt(Obj)
            % GIVEN an T-flange with > 0 tilt
            Inputs.SGRE2.FLANGE_TILT_VALUE = 2;
            Inputs.flangeType = 'T';
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_tilt_angle_for_flange_type();

            % THEN expect no warning
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);
        end

        function check_tilt_angle_for_flange_type__tflange_no_tilt(Obj)
            % GIVEN an T-flange with 0 tilt
            Inputs.SGRE2.FLANGE_TILT_VALUE = 0;
            Inputs.flangeType = 'T';
            Inputs.BoltFls.BOLT_FORCE_MODEL = "sgre2";

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_tilt_angle_for_flange_type();

            % THEN
            expectedMessage = 'For T-flanges, a positive value for input SGRE2.FLANGE_TILT_VALUE is expected.';
            Obj.verifyWarningMessage(PostLoadChecks.LogHandler.buffer{1}, expectedMessage);

            % WHEN the bolt force model is not `sgre2`
            % THEN the check is expected to be skipped
            Inputs.BoltFls.BOLT_FORCE_MODEL = "petersen";
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_tilt_angle_for_flange_type();
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);
        end

        function check_scaling_levels_increasing__not_increasing(Obj)
            % GIVEN Inputs with decreasing scaling levels
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.Loads.ulsScalingLevel = {[123, 4]};
            Inputs.Loads.flsScalingLevel = {[123, 12.3]};
            Inputs.Loads.S1ScalingLevel = {[-1, -1.00001]};

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_scaling_levels_increasing();

            % THEN
            Obj.verifyErrorMessage(PostLoadChecks.LogHandler.buffer{1}, 'Loads(1).ulsScalingLevel must be increasing.');
            Obj.verifyErrorMessage(PostLoadChecks.LogHandler.buffer{2}, 'Loads(1).flsScalingLevel must be increasing.');
            Obj.verifyErrorMessage(PostLoadChecks.LogHandler.buffer{3}, 'Loads(1).S1ScalingLevel must be increasing.');
        end

        function check_s1_load_scaling_levels_range__inside_range(Obj)
            % GIVEN Inputs with at least 1 activated S1 condition, and S1 scaling levels within range
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.zFlange = 10;
            Inputs.Loads.S1ScalingLevel = {[0, 20]};

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_s1_load_scaling_levels_range();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);
        end

        function check_s1_load_scaling_levels_range__outside_range(Obj)
            % GIVEN Inputs with at least 1 activated S1 condition, and S1 scaling levels outside range
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.zFlange = 123;
            Inputs.Loads.S1ScalingLevel = {[0, 20]};

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_s1_load_scaling_levels_range();

            % THEN
            Obj.verifyWarningMessage(PostLoadChecks.LogHandler.buffer{1}, ...
                ['Input "zFlange" is not covered by "Loads.S1ScalingLevel", for load set #1. ', ...
                'Extrapolation will be applied.']);
        end

        function check_s1_load_scaling_levels_range__skip_check(Obj)
            % GIVEN Inputs without activated S1 conditions, and S1 scaling levels outside range
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = false;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = false;
            Inputs.zFlange = 123;
            Inputs.S1ScalingLevel = {[0, 20]};

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_s1_load_scaling_levels_range();

            % THEN
            Obj.assertEmpty(PostLoadChecks.LogHandler.buffer);
        end

        function check_s1_load_scaling_levels_range__multiple_load_sets(Obj)
            % GIVEN Inputs with at least 1 activated S1 condition, and:
            % - S1 scaling levels within range for load set #1
            % - No S1 loads for load set #2
            % - S1 scaling levels outside range for load set #3
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.zFlange = 10;
            Inputs.S1ScalingLevel = {[0, 20]};
            Inputs.Loads.S1FilePath = {'s1/loads/set1.mat', '', 's1/loads/set3.mat'}';
            Inputs.Loads.S1ScalingFactor = {[1, 1], [1, 1], [1, 1]}';
            Inputs.Loads.S1ScalingLevel = {[-200, 200], [-200, 200], [-200, -199]}';

            % WHEN
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs);
            PostLoadChecks.check_s1_load_scaling_levels_range();

            % THEN
            Obj.verifyWarningMessage(PostLoadChecks.LogHandler.buffer{1}, ...
                ['Input "zFlange" is not covered by "Loads.S1ScalingLevel", for load set #3. ', ...
                'Extrapolation will be applied.']);
        end

    end

end
