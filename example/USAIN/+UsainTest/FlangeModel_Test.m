classdef (SharedTestFixtures = {Unittest.fixtures.SilentlyLogWarningsFixture}) ...
        FlangeModel_Test < Unittest.TestCase

    properties
        TestObj UsainUtils.FlangeModel
    end
    properties (TestParameter)
        % thkNose, minNoseHeightExpect - Expected min. nose height values
        % (minNoseHeightExpect) for a given nose thickness (thkNose) (applicable
        % for a double-V bevel cut) for default bevel angle and root face.
        thkNose             = {20e-3 50e-3 80e-3}
        minNoseHeightExpect = {40e-3 51e-3 65e-3}
    end

    methods (TestMethodSetup)

        function init_test_object(Obj)
            Obj.TestObj = UsainUtils.FlangeModel();
        end

    end

    methods (Test, ParameterCombination = 'sequential', TestTags = {'unit'})

        function calc_min_nose_height__benchmark(Obj, thkNose, minNoseHeightExpect)
            % GIVEN inputs from fixture, hence defaults for expert inputs and ensure defaults for bevel
            % Benchmark results from calc_min_nose_height using default inputs
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Obj.TestObj.Inputs = Inputs;
            Obj.TestObj.Inputs.BEVEL_ANGLE = Unit.deg.to_si(42);
            Obj.TestObj.Inputs.BEVEL_ROOT_FACE = 4e-3;

            % WHEN THEN
            minNoseHeightActual = Obj.TestObj.calc_min_nose_height(thkNose);
            Obj.verifyEqual(minNoseHeightActual, minNoseHeightExpect, 'AbsTol', 1e-4);
        end

        function typeset_material_designation__row_market(Obj)
            % GIVEN an FlangeModel object with inputs for a ROW market design
            Test = UsainUtils.FlangeModel();
            Test.Inputs.FLANGE_STEEL_TYPE = 'S355';
            Test.Inputs.countryCode = 'ROW';

            % WHEN
            actual = Test.typeset_material_designation();

            % THEN
            Obj.verifyEqual(actual, 'S355NL');
        end

        function typeset_material_designation__jpn_market(Obj)
            % GIVEN an FlangeModel object with inputs for a Japanese market design
            Test = UsainUtils.FlangeModel();
            Test.Inputs.FLANGE_STEEL_TYPE = 'SF520';
            Test.Inputs.countryCode = 'JPN';

            % WHEN
            actual = Test.typeset_material_designation();

            % THEN
            Obj.verifyEqual(actual, 'SF520');
        end

        function calc_b_for_door_segment_clearance__no_door_segment(Obj)
            % GIVEN an FlangeModel object with inputs required for this scenario's calculation of "b" i.e., without a
            % door segment
            FlangeModel = Obj.setup_benchmark();
            FlangeModel.Inputs.DOOR_SEGMENT.DO_INCLUDE = false;
            FlangeModel.Inputs.DOOR_SEGMENT.THICKNESS = nan;

            % WHEN calculating minimum "b" with respect to doorsegment and tool and/or bolt extender (this
            % depends on the fastener configuration, if tool is at the top than verify the tool, if the
            % extender is at the top than use the extender.
            actual = FlangeModel.calc_b_for_door_segment_clearance();

            % THEN verify all nan, since the check does not apply (and will not impact the b determination).
            expect = nan(1, 2);
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-5);
        end

        function calc_b_for_door_segment_clearance__with_segment(Obj)
            % GIVEN a FlangeModel object with inputs required for this scenario's calculation of "b" i.e., including a
            % door segment
            FlangeModel = Obj.setup_benchmark();
            FlangeModel.Inputs.DOOR_SEGMENT.DO_INCLUDE = true;
            FlangeModel.Inputs.DOOR_SEGMENT.THICKNESS = 80e-3;

            % WHEN calculating minimum b with respect to doorsegment and tool and/or bolt extender (this
            % depends on the fastener configuration; if tool is at the top than verify the tool, if the
            % extender is at the top than use the extender).
            actual = FlangeModel.calc_b_for_door_segment_clearance();

            % THEN verify with expected value. Note that for M56 the tool is 'Up' while for M72 the tool is
            % 'Lo', so for M72 the extender will be driving the bcd calc!
            expected = [0.1090, 0.1090];
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);
        end

        function calc_b_for_tool_weld_clearance_installation__lflange(Obj)
            % GIVEN inputs required for this scenario's calculation of "b"
            FlangeModel = UsainUtils.FlangeModel('flangeType', 'L');
            FlangeModel.Inputs.TOL_BCD = 0.002;
            FlangeModel.Inputs.TOOL_DIMENSION_RADIAL_DIR = [nan, nan];
            FlangeModel.Inputs.thicknNoseUp = 0.061;
            FlangeModel.thicknWeldBulgeUp = 0.005;
            FlangeModel.Inputs.thicknNoseLo = 0.065;
            FlangeModel.thicknWeldBulgeLo = 0.005;
            FlangeModel.Inputs.diamBoltHole = [0.061, 0.090];
            FlangeModel.Bolt.diam = [0.056, 0.080];
            FlangeModel.Tool.dimRadialDir = [0.0625, 0.086];
            FlangeModel.Inputs.TIGHTENING_SIDE_INSTALLATION = {'upper', 'upper'};

            % WHEN
            actual = FlangeModel.calc_b_for_tool_weld_clearance_installation();

            % THEN
            expected = [0.1015, 0.1275];
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);

            % NEXT WHEN using an override for the M56 option (the first one)
            FlangeModel.Inputs.TOOL_DIMENSION_RADIAL_DIR = [0.060, nan];

            actual = FlangeModel.calc_b_for_tool_weld_clearance_installation();

            % THEN
            expected(1) = 0.0990;
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);

            % NEXT WHEN setting different requirements for the TIGHTENING_SIDE_INSTALLATION
            FlangeModel.Inputs.TIGHTENING_SIDE_INSTALLATION = {'lower', 'upper'};
            FlangeModel.Inputs.TOOL_DIMENSION_RADIAL_DIR = [nan, nan];

            actual = FlangeModel.calc_b_for_tool_weld_clearance_installation();

            % THEN
            expected(1) = 0.1055;
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);
        end

        function calc_b_for_tool_weld_clearance_installation__tflange(Obj)
            % GIVEN inputs required for this scenario's calculation of parameter "b" on a T-flange
            FlangeModel = UsainUtils.FlangeModel('flangeType', 'T');
            FlangeModel.Inputs.TOL_BCD = 0.002;
            FlangeModel.Inputs.TOOL_DIMENSION_RADIAL_DIR = [nan, nan];
            FlangeModel.Inputs.thicknNoseUp = 0.061;
            FlangeModel.thicknWeldBulgeUp = 0.005;
            FlangeModel.Inputs.thicknNoseLo = 0.065;
            FlangeModel.thicknWeldBulgeLo = 0.005;
            FlangeModel.Inputs.diamBoltHole = [0.061, 0.090];
            FlangeModel.Bolt.diam = [0.056, 0.080];
            FlangeModel.Tool.dimRadialDir = [0.0625, 0.086];
            FlangeModel.Inputs.TIGHTENING_SIDE_INSTALLATION = {'upper', 'upper'};

            % WHEN, THEN
            actual = FlangeModel.calc_b_for_tool_weld_clearance_installation();

            % THEN
            expected = [0.1015, 0.1275];
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);

            % WHEN setting different requirements for the TIGHTENING_SIDE_INSTALLATION
            FlangeModel.Inputs.TIGHTENING_SIDE_INSTALLATION = {'lower', 'lower'};

            actual = FlangeModel.calc_b_for_tool_weld_clearance_installation();

            % THEN
            expected = [0.1035, 0.1295];
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);
        end

        function calc_b_for_tool_weld_clearance_installation__tool_side__happy(Obj)
            % GIVEN inputs required for this scenario's calculation of parameter "b", notice different nose thicknesses
            % are applied.
            FlangeModel = UsainUtils.FlangeModel('flangeType', 'L');
            FlangeModel.Inputs.TOL_BCD = 0.002;
            FlangeModel.Inputs.TOOL_DIMENSION_RADIAL_DIR = [nan, nan];
            FlangeModel.Inputs.thicknNoseUp = 0.061;
            FlangeModel.thicknWeldBulgeUp = 0.005;
            FlangeModel.Inputs.thicknNoseLo = 0.065;
            FlangeModel.thicknWeldBulgeLo = 0.005;
            FlangeModel.Inputs.diamBoltHole = [0.061, 0.061];
            FlangeModel.Bolt.diam = [0.056, 0.056];
            FlangeModel.Tool.dimRadialDir = [0.0625, 0.0625];
            FlangeModel.Inputs.TIGHTENING_SIDE_INSTALLATION = {'upper', 'upper'};

            % WHEN
            actualBothUp = FlangeModel.calc_b_for_tool_weld_clearance_installation();

            % THEN
            expected = [0.1015, 0.1015];
            Obj.verifyEqual(actualBothUp, expected, 'AbsTol', 1e-5);

            % NEXT WHEN setting different requirements for the TIGHTENING_SIDE_INSTALLATION
            FlangeModel.Inputs.TIGHTENING_SIDE_INSTALLATION = {'lower', 'upper'};

            % THEN
            actual = FlangeModel.calc_b_for_tool_weld_clearance_installation();

            % THEN
            Obj.verifyGreaterThan(actual(1), actualBothUp(1));
            Obj.verifyEqual(actual(2), actualBothUp(2), 'AbsTol', 1e-5);
        end

        function calc_b_for_tool_weld_clearance_temp_stages__lflange(Obj)
            % GIVEN inputs required for this BCD calculation
            FlangeModel = UsainUtils.FlangeModel('flangeType', 'L');
            FlangeModel.Inputs.site = usain.inputs.Site.OFFSHORE;
            FlangeModel.Inputs.boltOptions = {'ISO_M56', 'ISO_M80'};
            FlangeModel.Inputs.TOOL_DIMENSION_RADIAL_DIR = [nan, nan];
            FlangeModel.Inputs.TEMP_STAGES_TOOL_TYPE = 'thin';
            FlangeModel.Inputs.TOL_BCD = 0.002;
            FlangeModel.Inputs.diamBoltHole = [0.061, 0.090];
            FlangeModel.Bolt.diam = [0.056, 0.080];
            FlangeModel.Inputs.thicknNoseUp = 0.061;
            FlangeModel.thicknWeldBulgeUp = 0.005;
            FlangeModel.Inputs.thicknNoseLo = 0.061;
            FlangeModel.thicknWeldBulgeLo = 0.005;
            FlangeModel.diameterOutNeck = 8;
            FlangeModel.Inputs.TIGHTENING_SIDE_TEMP_STAGES = {'both', 'both'};

            % WHEN
            actual = FlangeModel.calc_b_for_tool_weld_clearance_temp_stages();

            % THEN
            expected = [0.0948, 0.1176];
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);

            % NEXT WHEN using an override for the M56 option
            FlangeModel.Inputs.TOOL_DIMENSION_RADIAL_DIR = [0.060, nan];

            actual = FlangeModel.calc_b_for_tool_weld_clearance_temp_stages();

            % THEN
            expected(1) = 0.0990;
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);

            % NEXT WHEN setting temp stages tool to be 'none'
            FlangeModel.Inputs.TEMP_STAGES_TOOL_TYPE = 'none';

            % THEN
            expected = [nan, nan];
            actual = FlangeModel.calc_b_for_tool_weld_clearance_temp_stages();
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-5);
        end

        function calc_b_for_tool_weld_clearance_temp_stages__tflange(Obj)
            % GIVEN inputs required for this BCD calculation on a T-flange
            FlangeModel = UsainUtils.FlangeModel('flangeType', 'T');
            FlangeModel.Inputs.site = usain.inputs.Site.OFFSHORE;
            FlangeModel.Inputs.boltOptions = {'ISO_M56', 'ISO_M80'};
            FlangeModel.Inputs.TOOL_DIMENSION_RADIAL_DIR = [nan, nan];
            FlangeModel.Inputs.TEMP_STAGES_TOOL_TYPE = 'thin';
            FlangeModel.Inputs.TOL_BCD = 0.002;
            FlangeModel.Inputs.diamBoltHole = [0.061, 0.090];
            FlangeModel.Bolt.diam = [0.056, 0.080];
            FlangeModel.Inputs.thicknNoseUp = 0.061;
            FlangeModel.thicknWeldBulgeUp = 0.005;
            FlangeModel.Inputs.thicknNoseLo = 0.080;
            FlangeModel.thicknWeldBulgeLo = 0.005;
            FlangeModel.Inputs.TIGHTENING_SIDE_TEMP_STAGES = {'both', 'both'};

            % WHEN
            actual = FlangeModel.calc_b_for_tool_weld_clearance_temp_stages();

            % THEN
            expected = [0.1043, 0.1271];
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);

            % WHEN using an override for the M56 option
            FlangeModel.Inputs.TOOL_DIMENSION_RADIAL_DIR = [0.060, nan];
            actual = FlangeModel.calc_b_for_tool_weld_clearance_temp_stages();

            % THEN
            expected(1) = 0.1085;
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);

            % WHEN setting temp stages tool to be 'none'
            FlangeModel.Inputs.TEMP_STAGES_TOOL_TYPE = 'none';

            % THEN
            expected = [nan, nan];
            actual = FlangeModel.calc_b_for_tool_weld_clearance_temp_stages();
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-3);
        end

        function calc_b_for_washer_fillet_clearance__benchmark(Obj)
            % GIVEN an FlangeModel object with inputs required for bcd calcs (asymmetric L-flange)
            FlangeModel = Obj.setup_benchmark();
            FlangeModel.flangeType = 'L';
            FlangeModel.Inputs.thicknNoseUp = 50e-3;
            FlangeModel.Inputs.thicknNoseLo = 60e-3;

            % WHEN calculating minimum "b" with respect to washer and fillet
            actual = FlangeModel.calc_b_for_washer_fillet_clearance();

            % THEN verify with expected value
            expected = [0.1020, 0.1125];
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);

            % WHEN calculating minimum "b" with respect to washer and fillet for an L-flange
            actual_L = FlangeModel.calc_b_for_washer_fillet_clearance();
            % ... and then change to a T-flange
            FlangeModel.flangeType = 'T';
            actual_T = FlangeModel.calc_b_for_washer_fillet_clearance();

            % THEN verify we computed different values
            Obj.verifyNotEqual(actual_L, actual_T);
            Obj.verifyGreaterThan(actual_L, actual_T);
        end

        function calc_b_for_extender_fillet_clearance__benchmark(Obj)
            % GIVEN a FlangeModel object with inputs required for bcd calcs
            FlangeModel = Obj.setup_benchmark();

            % WHEN calculating maximum bcd with respect to extender and fillet
            actual = FlangeModel.calc_b_for_extender_fillet_clearance();

            % THEN verify with expected value
            expected = [0.1045, 0.1050];
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);

            % NEXT WHEN doing the same with lengthBoltExtender is nan
            FlangeModel.Inputs.lengthBoltExtender = nan;
            actual = FlangeModel.calc_b_for_extender_fillet_clearance();

            % THEN verify with expected value
            expected = [nan, nan];
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);

            % NEXT WHEN doing the same with lengthBoltExtender is set to zero
            FlangeModel.Inputs.lengthBoltExtender = 0;
            actual = FlangeModel.calc_b_for_extender_fillet_clearance();

            % THEN verify with expected value
            expected = [nan, nan];
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-5);
        end

        function calc_b_for_extender_fillet_clearance__l_vs_t(Obj)
            % GIVEN a FlangeModel object with inputs required for bcd calcs (asymmetric L-flange)
            FlangeModel = Obj.setup_benchmark();
            FlangeModel.flangeType = 'L';
            FlangeModel.Inputs.thicknNoseUp = 50e-3;
            FlangeModel.Inputs.thicknNoseLo = 60e-3;
            FlangeModel.Inputs.TIGHTENING_SIDE_INSTALLATION = {'upper', 'lower'};

            % WHEN calculating maximum bcd with respect to extender and fillet
            actual_L = FlangeModel.calc_b_for_extender_fillet_clearance();

            % ... and then change to a T-flange
            FlangeModel.flangeType = 'T';
            actual_T = FlangeModel.calc_b_for_extender_fillet_clearance();

            % THEN verify we computed different values for the 1st design point (where the extender is on the lower
            % side)
            Obj.verifyNotEqual(actual_L(1), actual_T(1));
            Obj.verifyEqual(actual_L(2), actual_T(2));
        end

        function calc_bcd_from_parameter_b__happy(Obj)
            % GIVEN
            diameterOutNeck = 6;
            thicknessNoseUp = 60e-3;
            b = 120e-3;

            % WHEN THEN
            actual = UsainUtils.FlangeModel.calc_bcd_from_parameter_b(diameterOutNeck, thicknessNoseUp, b);
            expected = 5.7;
            Obj.assertEqual(actual, expected);
        end

        function determine_and_round_driving_parameter_b__happy(Obj)
            % GIVEN single scalar value
            b1 = 1.4e-3;

            % WHEN THEN
            [actual, index] = UsainUtils.FlangeModel.determine_and_round_driving_parameter_b(b1);
            Obj.verifyEqual(actual, 1.5e-3);
            Obj.verifyEqual(index, 1);

            % NEXT GIVEN an extra scalar value
            b2 = 1.6e-3;

            % WHEN THEN
            [actual, index] = UsainUtils.FlangeModel.determine_and_round_driving_parameter_b(b1, b2);
            Obj.verifyEqual(actual, 2e-3);
            Obj.verifyEqual(index, 2);

            % NEXT GIVEN one vector as input
            b3 = [b1, b2];

            % WHEN THEN
            [actual, index] = UsainUtils.FlangeModel.determine_and_round_driving_parameter_b(b3);
            Obj.verifyEqual(actual, [1.5e-3, 2e-3]);
            Obj.verifyEqual(index, [1, 1]);

            % NEXT GIVEN two vectors as input
            b4 = [b2, b1];

            % WHEN THEN
            [actual, index] = UsainUtils.FlangeModel.determine_and_round_driving_parameter_b(b3, b4);
            Obj.verifyEqual(actual, [2e-3, 2e-3]);
            Obj.verifyEqual(index, [2, 1]);

            % NEXT GIVEN an extra vectors with nan
            b5 = [nan, nan];

            % WHEN THEN
            [actual, index] = UsainUtils.FlangeModel.determine_and_round_driving_parameter_b(b5, b3, b4);
            Obj.verifyEqual(actual, [2e-3, 2e-3]);
            Obj.verifyEqual(index, [3, 2]);
        end

        function determine_and_round_driving_parameter_b__unequal_input_size(Obj)
            % GIVEN inputs with inconsistent dimensions
            b1 = 1.4e-3;
            b2 = 1.6e-3;
            b3 = [b1, b2];

            % % WHEN THEN
            f = @() UsainUtils.FlangeModel.determine_and_round_driving_parameter_b(b1, b2, b3);
            Obj.assertError(f, 'FlangeModel:InconsistentInputSize');
        end

        function get_outer_diameter_neck_lower_flange__lflange(Obj)
            % GIVEN a FlangeModel object with necessary inputs for a symmetric L-flange
            FlangeModel = UsainUtils.FlangeModel('flangeType', 'L');
            FlangeModel.diameterOutNeck = 8;
            FlangeModel.Inputs.thicknNoseLo = 0.100;
            FlangeModel.Inputs.thicknNoseUp = 0.100;

            % WHEN, THEN
            Obj.verifyEqual(FlangeModel.get_outer_diameter_neck_lower_flange(), FlangeModel.diameterOutNeck);

            % WHEN adding asymmetry
            FlangeModel.Inputs.thicknNoseLo = 0.120;
            Obj.verifyEqual(FlangeModel.get_outer_diameter_neck_lower_flange(), FlangeModel.diameterOutNeck);

            FlangeModel.Inputs.thicknNoseLo = 0.080;
            Obj.verifyEqual(FlangeModel.get_outer_diameter_neck_lower_flange(), FlangeModel.diameterOutNeck);
        end

        function get_outer_diameter_neck_lower_flange__tflange(Obj)
            % GIVEN a FlangeModel object with necessary inputs for a symmetric T-flange
            FlangeModel = UsainUtils.FlangeModel('flangeType', 'T');
            FlangeModel.diameterOutNeck = 8;
            FlangeModel.Inputs.thicknNoseLo = 0.100;
            FlangeModel.Inputs.thicknNoseUp = 0.100;

            % WHEN, THEN
            Obj.verifyEqual(FlangeModel.get_outer_diameter_neck_lower_flange(), FlangeModel.diameterOutNeck);

            % WHEN adding asymmetry
            FlangeModel.Inputs.thicknNoseLo = 0.120;
            expected = 8 + 0.02;
            Obj.verifyEqual(FlangeModel.get_outer_diameter_neck_lower_flange(), expected);

            FlangeModel.Inputs.thicknNoseLo = 0.080;
            expected = 8 - 0.02;
            Obj.verifyEqual(FlangeModel.get_outer_diameter_neck_lower_flange(), expected);
        end

        function check_bolt_circle_diam__happy(Obj)
            % GIVEN
            FlangeModel = UsainUtils.FlangeModel();
            FlangeModel.bcdMin = 6e3;
            FlangeModel.bcdMax = 6.5e3;
            FlangeModel.diameterBoltCircle = 6.25e3;

            % WHEN, THEN
            actual = FlangeModel.check_bolt_circle_diam();
            Obj.verifyTrue(actual);
        end

        function check_bolt_circle_diam__min_gt_max__sad(Obj)
            % GIVEN
            FlangeModel = UsainUtils.FlangeModel();
            FlangeModel.bcdMin = 7e3;
            FlangeModel.bcdMax = 6.5e3;

            % WHEN, THEN
            f = @() FlangeModel.check_bolt_circle_diam();
            Obj.verifyError(f, 'FlangeModel:bcdMinGtbcdMax');
        end

        function check_bolt_circle_diam__partly_infeasible(Obj)
            % GIVEN
            FlangeModel = UsainUtils.FlangeModel();
            FlangeModel.bcdMin = 6e3 * ones(100, 1);
            FlangeModel.bcdMax = 6.5e3 * ones(100, 1);
            FlangeModel.diameterBoltCircle = 6.25e3 * ones(100, 1);
            FlangeModel.diameterBoltCircle(1) = 5e3; % too small
            FlangeModel.diameterBoltCircle(2) = 7e3; % too large

            % WHEN, THEN
            actual = FlangeModel.check_bolt_circle_diam();
            Obj.verifyTrue(all(actual(3:end)));
            Obj.verifyFalse(all(actual(1:2)));
        end

        function check_bolt_circle_diam__none_feasible(Obj)
            % GIVEN
            FlangeModel = UsainUtils.FlangeModel();
            FlangeModel.bcdMin = 6e3 * ones(100, 1);
            FlangeModel.bcdMax = 6.5e3 * ones(100, 1);
            FlangeModel.diameterBoltCircle = 6.25e3 * ones(100, 1);
            FlangeModel.diameterBoltCircle(1:50) = 5e3; % too small
            FlangeModel.diameterBoltCircle(51:100) = 7e3; % too large

            % WHEN, THEN
            f = @() FlangeModel.check_bolt_circle_diam();
            Obj.verifyError(f, 'FlangeModel:noFeasibleBcd');
        end

        function massStubUp__check_values(Obj)
            % GIVEN Flange Model object and Allowed flange thickness as zero
            FlangeModel = UsainTest.FlangeModel_Test.setup_benchmark();
            FlangeModel.diameterOutNeck = 7;
            FlangeModel.Inputs.ALW_UPPER_FLANGE_THICKNESS = 0;
            FlangeModel.Inputs.RHO_FLANGE = 7850;
            FlangeModel.Space.thickness = 5;
            FlangeModel.Space.width = 2;
            FlangeModel.flangeType = 'T';
            FlangeModel.Space.nBolts = 1;
            FlangeModel.diameterBoltHole = 61e-3;

            % WHEN
            designMass = FlangeModel.massStubUp;

            % GIVEN Allowed flange thickness as 2
            FlangeModel.Inputs.ALW_UPPER_FLANGE_THICKNESS = 2;

            % WHEN
            nominalMassUp = FlangeModel.massStubUp;

            % THEN nominal mass should not be equal to design mass
            Obj.verifyNotEqual(designMass, nominalMassUp);
            Obj.verifyGreaterThan(nominalMassUp, designMass);
        end

        function massStubLo__check_values(Obj)
            % GIVEN Flange Model object and Allowed flange thickness as zero
            FlangeModel = UsainTest.FlangeModel_Test.setup_benchmark();
            FlangeModel.diameterOutNeck = 7;
            FlangeModel.Inputs.ALW_LOWER_FLANGE_THICKNESS = 0;
            FlangeModel.Inputs.RHO_FLANGE = 7850;
            FlangeModel.Space.thickness = 5;
            FlangeModel.Space.width = 2;
            FlangeModel.flangeType = 'T';
            FlangeModel.Space.nBolts = 1;
            FlangeModel.diameterBoltHole = 61e-3;

            % WHEN
            designMass = FlangeModel.massStubLo;

            % GIVEN Allowed flange thickness as 2
            FlangeModel.Inputs.ALW_LOWER_FLANGE_THICKNESS = 2;

            % WHEN
            nominalMass = FlangeModel.massStubLo;

            % THEN nominal mass should not be equal to design mass
            Obj.verifyNotEqual(designMass, nominalMass);
            Obj.verifyGreaterThan(nominalMass, designMass);
        end

        function massFlangeUp__expected_tflange(Obj)
            % GIVEN some flange geometry to compute the flange mass
            FlangeModel = UsainTest.FlangeModel_Test.setup_benchmark();
            FlangeModel.diameterOutNeck = 2;
            FlangeModel.flangeType = 'T';
            FlangeModel.Inputs.ALW_UPPER_FLANGE_THICKNESS = 0;
            FlangeModel.Inputs.RHO_FLANGE = 7850;
            FlangeModel.Inputs.thicknNoseUp = 20e-3;
            FlangeModel.Space.thickness = 100e-3;
            FlangeModel.Space.width = 200e-3;
            FlangeModel.Space.nBolts = 100;
            FlangeModel.Inputs.heightNoseUp = 40e-3;
            FlangeModel.diameterBoltHole = 20e-3;

            % WHEN, THEN
            expected = 966.34;
            Obj.verifyEqual(FlangeModel.massFlangeUp, expected, 'AbsTol', 0.1);
        end

        function massFlangeUp__expected_lflange(Obj)
            % GIVEN some flange geometry to compute the flange mass
            FlangeModel = UsainTest.FlangeModel_Test.setup_benchmark();
            FlangeModel.diameterOutNeck = 2;
            FlangeModel.flangeType = 'L';
            FlangeModel.Inputs.ALW_UPPER_FLANGE_THICKNESS = 0;
            FlangeModel.Inputs.RHO_FLANGE = 7850;
            FlangeModel.Inputs.thicknNoseUp = 20e-3;
            FlangeModel.Space.thickness = 100e-3;
            FlangeModel.Space.width = 200e-3;
            FlangeModel.Space.nBolts = 100;
            FlangeModel.Inputs.heightNoseUp = 40e-3;
            FlangeModel.diameterBoltHole = 20e-3;

            % WHEN, THEN
            expected = 902.22;
            Obj.verifyEqual(FlangeModel.massFlangeUp, expected, 'AbsTol', 0.1);
        end

        function massFlangeLo__expected_tflange(Obj)
            % GIVEN some flange geometry to compute the flange mass
            FlangeModel = UsainTest.FlangeModel_Test.setup_benchmark();
            FlangeModel.diameterOutNeck = 2;
            FlangeModel.flangeType = 'T';
            FlangeModel.Inputs.ALW_LOWER_FLANGE_THICKNESS = 0;
            FlangeModel.Inputs.RHO_FLANGE = 7850;
            FlangeModel.Inputs.thicknNoseUp = 20e-3;  % needed to compute diamOutFlange
            FlangeModel.Inputs.thicknNoseLo = 20e-3;
            FlangeModel.Space.thickness = 100e-3;
            FlangeModel.Space.width = 200e-3;
            FlangeModel.Space.nBolts = 100;
            FlangeModel.Inputs.heightNoseLo = 40e-3;
            FlangeModel.diameterBoltHole = 20e-3;

            % WHEN, THEN
            expected = 966.34;
            Obj.verifyEqual(FlangeModel.massFlangeLo, expected, 'AbsTol', 0.1);
        end

        function massFlangeLo__expected_lflange(Obj)
            % GIVEN some flange geometry to compute the flange mass
            FlangeModel = UsainTest.FlangeModel_Test.setup_benchmark();
            FlangeModel.diameterOutNeck = 2;
            FlangeModel.flangeType = 'L';
            FlangeModel.Inputs.ALW_LOWER_FLANGE_THICKNESS = 0;
            FlangeModel.Inputs.RHO_FLANGE = 7850;
            FlangeModel.Inputs.thicknNoseLo = 20e-3;
            FlangeModel.Space.thickness = 100e-3;
            FlangeModel.Space.width = 200e-3;
            FlangeModel.Space.nBolts = 100;
            FlangeModel.Inputs.heightNoseLo = 40e-3;
            FlangeModel.diameterBoltHole = 20e-3;

            % WHEN, THEN
            expected = 902.22;
            Obj.verifyEqual(FlangeModel.massFlangeLo, expected, 'AbsTol', 0.1);
        end

    end

    methods (Test, TestTags = {'integration'})

        function setup_obj__happy(Obj)
            % GIVEN all required inputs to build a FlangeModel, without importing loads
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;
            Inputs.DO_ASSESS_FLS = false;
            Inputs.DO_ASSESS_ULS = false;

            % WHEN, THEN
            f = @() UsainUtils.FlangeModel.setup_obj('Inputs', Inputs);
            Obj.verify_error_free(f);
        end

        function reduce_design_space__happy(Obj)
            % GIVEN a constructed FlangeModel, where importing loads is being skipped (not needed for this test)
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;
            Inputs.DO_ASSESS_FLS = false;
            Inputs.DO_ASSESS_ULS = false;
            Mdl = UsainUtils.FlangeModel.setup_obj('Inputs', Inputs);

            % WHEN reducing the design space to only have 2 feasible points left.
            isSelection = false(Mdl.Space.nPoints, 1);
            isSelection([1, 2]) = true;
            Mdl.reduce_design_space(isSelection);

            % THEN
            Obj.assertEqual(Mdl.Space.nPoints, 2);
            Obj.assertEqual(numel(Mdl.Segment.resilFlanges), 2);
            Obj.assertEqual(numel(Mdl.Bolt.type), 2);

            % WHEN reducing further to 1 feasible point.
            isSelection(2) = false;
            Mdl.reduce_design_space(isSelection);

            % THEN
            Obj.assertEqual(Mdl.Space.nPoints, 1);
            Obj.assertEqual(numel(Mdl.Segment.resilFlanges), 1);
            Obj.assertEqual(numel(Mdl.Bolt.type), 1);
        end

    end

    methods (Static)

        function Test = setup_benchmark()
            Test = UsainUtils.FlangeModel('flangeType', 'L');
            Test.diameterOutNeck = [7; 7];
            Test.Inputs.thicknNoseUp = 50e-3;
            Test.Inputs.thicknNoseLo = 60e-3;
            Test.Inputs.MAX_WELD_BULGE_SIZE = 5e-3;
            Test.Inputs.BEVEL_ANGLE = Unit.deg.to_si(42);
            Test.Inputs.BEVEL_ROOT_FACE = 4e-3;
            Test.Inputs.FILLET_RADIUS = 10e-3;
            Test.Inputs.TOL_BCD = 2e-3;
            Test.Inputs.TOL_FILLET_RADIUS_PLUS = 1e-3;
            Test.Inputs.TOOL_DIMENSION_RADIAL_DIR = [0.0655 0.0830];
            Test.Inputs.TIGHTENING_SIDE_INSTALLATION = {'upper', 'lower'};
            Test.Inputs.TIGHTENING_SIDE_TEMP_STAGES = {'both', 'both'};
            Test.Inputs.TEMP_STAGES_TOOL_TYPE = {'normal'};
            Test.Inputs.diamBoltHole = 1e-3 .* [61 78];
            Test.Inputs.lengthBoltExtender = 20e-3;
            Test.Inputs.boltOptions = {'HV_M56', 'ISO_M72'};
            Test.Inputs.structureInpFilePath = '';

            Test.thicknWeldBulgeUp = Test.calc_weld_bulge_size(Test.Inputs.thicknNoseUp);
            Test.thicknWeldBulgeLo = Test.calc_weld_bulge_size(Test.Inputs.thicknNoseLo);
            Test.Bolt.diam = 1e-3 .* [56 72];
            Test.Tool.tighteningMethod = {'torque', 'tension'};
            Test.Tool.dimRadialDir = [0.0625, 0.0750];

            Test.Wash.diamOut = 1e-3 .* [105 125];
            Test.Wash.len = 1e-3 .* [0 10];
            Test.Nut.diam = 1e-3 .* [105 125];
            Test.Extr.diamOut = 1e-3 .* [110 130];

        end

    end
end
