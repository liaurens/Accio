classdef ManipulatedInputsFixture < matlab.unittest.fixtures.Fixture
    % Test data fixture describing a parsed and manipulated `Inputs` struct
    % That is, data in `Inputs` after the following has run:
    % - PostParseChecks
    % - PostParseManipulations
    % - CrossCheckStep (also manipulates a few inputs)

    properties
        data struct
        n double = 1  % number of design points in fixture
    end

    methods

        function Obj = ManipulatedInputsFixture(kwargs)
            arguments
                kwargs.n double = 1
            end
            Obj.n = kwargs.n;
        end

        function setup(Obj)
            Inputs.ADDITIONAL_SCF_FLS = 1.0;
            Inputs.ADDITIONAL_SCF_ULS = 1.0;
            Inputs.ALW_LOWER_FLANGE_THICKNESS = 2e-3;
            Inputs.ALW_UPPER_FLANGE_THICKNESS = 2e-3;
            Inputs.B_MIN = Obj.repeat(nan);
            Inputs.BEVEL_ANGLE = Unit.deg.to_si(42);
            Inputs.BEVEL_ROOT_FACE = 4e-3;
            Inputs.BOLT_DIAMETER_SELECTION = 'all';
            Inputs.BoltFls.BOLT_FORCE_MODEL = Obj.repeat("schmidtneuper");
            Inputs.BoltFls.CUSTOM_PRELOAD = Obj.repeat(nan);
            Inputs.BoltFls.PRELOAD_LOSS_FACTOR_FLS = Obj.repeat(0.9);
            Inputs.BoltFls.PSF_BOLT_MATERIAL_FLS = Obj.repeat(1.25);
            Inputs.BoltFls.SN_CURVE_BOLT = Obj.repeat("EC3_DC50");
            Inputs.BoltFls.TARGET_PM_SUM = Obj.repeat(0.9);
            Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = Obj.repeat(0.25);
            Inputs.boltOptions = Obj.repeat({'ISO_M42x380'});
            Inputs.CLEARANCE_FILLET_WELD = 20e-3;
            Inputs.countryCode = 'ROW';
            Inputs.CUSTOM_WASHER_DIAM_INNER = Obj.repeat(nan);
            Inputs.CUSTOM_WASHER_DIAM_OUTER = Obj.repeat(nan);
            Inputs.CUSTOM_WASHER_THICKNESS = Obj.repeat(nan);
            Inputs.DEAD_WEIGHT = nan;
            Inputs.DEL_REF_CYCLES = 1e7;
            Inputs.DEL_WOHLER_SLOPE = 4;
            Inputs.diamBoltCircle = Obj.repeat(7.660);
            Inputs.diamBoltHole = Obj.repeat(0.046);
            Inputs.diameter = 8;
            Inputs.diameterReference = 'outneck';
            Inputs.DO_ALLOW_SWITCH_L_TO_T = false;
            Inputs.DO_ASSESS_BOLT_PLASTICITY = false;
            Inputs.DO_ASSESS_BOLT_THREAD_REQ = true;
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;
            Inputs.DO_ASSESS_FLANGE_PLASTICITY = false;
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_ASSESS_GAPPING = false;
            Inputs.DO_ASSESS_SCHMIDTNEUPER_APT = true;
            Inputs.DO_ASSESS_SLS_PRETENSION = false;
            Inputs.DO_ASSESS_ULS = true;
            Inputs.DO_ASSESS_ULS_JPN = false;
            Inputs.DO_SAVE_FULL_FILE = false;
            Inputs.DO_TRIM_DESIGN_SPACE = false;
            Inputs.DO_UPDATE_DESIGN_SPACE = true;
            Inputs.DOOR_SEGMENT.DO_INCLUDE = false;
            Inputs.DOOR_SEGMENT.FACTOR_CAN_TO_DOOR_THICKNESS = 1.3;
            Inputs.DOOR_SEGMENT.MIN_CAN_TO_DOOR_DELTA_THICKNESS = 0.02;
            Inputs.DOOR_SEGMENT.THICKNESS = nan;
            Inputs.E_BOLT = 210e9;
            Inputs.E_FLANGE = 210e9;
            Inputs.FDI_COEFFICIENT_A1 = 0.1;
            Inputs.FDI_COEFFICIENT_A2 = 0.0003;
            Inputs.FILLET_RADIUS = 10e-3;
            Inputs.FLANGE_STEEL_TYPE = 'S355';
            Inputs.FlangeGapping.CUSTOM_PRELOAD = Obj.repeat(nan);
            Inputs.FlangeNeckScf.CUSTOM_PRELOAD = Obj.repeat(nan);
            Inputs.FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS = Obj.repeat(0.9);
            Inputs.FlangeNeckScf.TARGET_PM_SUM = Obj.repeat(1);
            Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS = false;
            Inputs.flangeType = 'L';
            Inputs.GLOBAL_MAX_BOLT_DISTANCE = 0.180;
            Inputs.GLOBAL_MIN_BOLT_DISTANCE = NaN;
            Inputs.heightNoseLo = 80e-3;
            Inputs.heightNoseUp = 60e-3;
            Inputs.IGNORE_BOLT_EXTENDER = true;
            Inputs.INCLINATION_MOMENT = nan;
            Inputs.INCLINATION_MOMENT_FLS = nan;
            Inputs.lengthBoltExtender = Obj.repeat(0);
            Inputs.Loads.ALIGN_AT = 'interface';
            Inputs.Loads.dlcFilter = {'.*'};
            Inputs.Loads.flsFilePath = {'not\applicable\for\fixture'};
            Inputs.Loads.flsScalingFactor = {[1, 1]};
            Inputs.Loads.flsScalingLevel = {[-200, 200]};
            Inputs.Loads.inclinationUnit = {'deg'};
            Inputs.Loads.inclinationValue = 0;
            Inputs.Loads.inclinationValueFls = 0;
            Inputs.Loads.S1FilePath = {'not\applicable\for\fixture'};
            Inputs.Loads.S1ScalingFactor = {[1, 1]};
            Inputs.Loads.S1ScalingLevel = {[-200, 200]};
            Inputs.Loads.tag = {'test'};
            Inputs.Loads.ulsFilePath = {'not\applicable\for\fixture'};
            Inputs.Loads.ulsScalingFactor = {[1, 1]};
            Inputs.Loads.ulsScalingLevel = {[-200, 200]};
            Inputs.MACRO_GEOMETRIC_SCF = 1.0;
            Inputs.MAX_FAILURE_MODE_D_FLS_UTILIZATION = 5 / 6;
            Inputs.MAX_VISIBLE_THREAD_LENGTH_TENSION = '1.1D';
            Inputs.MAX_VISIBLE_THREAD_LENGTH_TORQUE = '0.4D';
            Inputs.MAX_WELD_BULGE_SIZE = 5e-3;
            Inputs.maxFlangeThickn = Obj.repeat(0.300);
            Inputs.maxFlangeWidth = Obj.repeat(0.500);
            Inputs.maxNBolts = Obj.repeat(260);
            Inputs.Milk.Fls = Milk.FatigueLoads();
            Inputs.Milk.Uls = Milk.ExtremeLoads();
            Inputs.MIN_GRIPPED_THREAD_LENGTH = '4P';
            Inputs.MIN_NOSE_HEIGHT = 40e-3;
            Inputs.MIN_NUMBER_BOLTS_FRACTION = 0.9;
            Inputs.MIN_VISIBLE_THREAD_LENGTH = '3P';
            Inputs.minFlangeThickn = Obj.repeat(0.100);
            Inputs.minFlangeWidth = Obj.repeat(0.200);
            Inputs.minNBolts = Obj.repeat(200);
            Inputs.NUT_TYPE = Obj.repeat({'ISR'});
            Inputs.PLOT_STRESS_PATHS = false;
            Inputs.PLOT_STRESS_TRANSFER_FUNCS = false;
            Inputs.PSF_BOLT_RESISTANCE = 1.25;
            Inputs.PSF_BOLT_RESISTANCE_JPN = NaN;
            Inputs.PSF_BOLT_RESISTANCE_JPN_TAG = '';
            Inputs.PSF_CMPCLASS2_FLS = 1.0;
            Inputs.PSF_CMPCLASS2_ULS = 1.0;
            Inputs.PSF_FAVORABLE_LOADS = 0.9;
            Inputs.PSF_FLANGE_MATERIAL_FLS = 1.25;
            Inputs.PSF_MATERIAL_ULS = 1.10;
            Inputs.RADIUS_SHIFT_FLANGE = 0;
            Inputs.RADIUS_SHIFT_SHELL = 0;
            Inputs.REACTION_DISTANCE_METHOD = 'tobinaga';
            Inputs.RHO_FLANGE = 7850;
            Inputs.runName = 'foo';
            Inputs.S1_BENDING_MOMENT = nan;
            Inputs.SECONDARY_HOLES_BCD = Obj.repeat(7.500);
            Inputs.SECONDARY_HOLES_DIAMETER = Obj.repeat(0.020);
            Inputs.SGRE2.BENDING_CONTRIBUTION = nan;
            Inputs.SGRE2.FLANGE_TILT_UNIT = 'deg';
            Inputs.SGRE2.FLANGE_TILT_VALUE = deg2rad(0.2);
            Inputs.SGRE2.FLATNESS_TOLERANCE = 0.0014;
            Inputs.SGRE2.GAP_ANGLE = [30, 60, 90, 120];
            Inputs.SGRE2.GAP_CLOSE_STIFFNESS_RATIO = 0.5;
            Inputs.SGRE2.INITIAL_POINT_OFFSET = 0.05;
            Inputs.SGRE2.INITIAL_SLOPE_REFERENCE_PRELOAD = 0.2;
            Inputs.SGRE2.SHELL_STIFFNESS_METHOD = 'interpolated';
            Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS = false;
            Inputs.site = usain.inputs.Site.OFFSHORE;
            Inputs.SlsPretension.CUSTOM_PRELOAD = Obj.repeat(nan);
            Inputs.SN_CURVE_NECK = 'EC3_DC90';
            Inputs.STEPSIZE_BOLT_EXT_LEN = 1e-3;
            Inputs.STEPSIZE_NBOLTS = 4;
            Inputs.STEPSIZE_THICKN = 1e-3;
            Inputs.STEPSIZE_WIDTH = 1e-3;
            Inputs.StrMdl = '';
            Inputs.structureInpFilePath = '';
            Inputs.targetDir = 'not\applicable\for\fixture';
            Inputs.TEMP_STAGES_TOOL_TYPE = 'normal';
            Inputs.thicknNoseLo = 0.100;
            Inputs.thicknNoseUp = 0.070;
            Inputs.TIGHTENING_SIDE_INSTALLATION = Obj.repeat({'upper'});
            Inputs.TIGHTENING_SIDE_TEMP_STAGES = Obj.repeat({'both'});
            Inputs.tighteningMethod = Obj.repeat({'tension'});
            Inputs.TOL_BCD = 2e-3;
            Inputs.TOL_BCD_TOOL_WALL = 0.004;
            Inputs.TOL_BOLT_HOLE = 0.5e-3;
            Inputs.TOL_BOLT_HOLE_CENTER = 0.001;
            Inputs.TOL_EXTENDER_LENGTH = 2e-3;
            Inputs.TOL_FILLET_RADIUS_PLUS = 1e-3;
            Inputs.TOL_FLANGE_THICKNESS_MINUS = 0.002;
            Inputs.TOL_FLANGE_THICKNESS_PLUS = 2e-3;
            Inputs.TOL_FLANGE_WIDTH = 0.002;
            Inputs.TOL_TOOL_BOLT = 0.001;
            Inputs.TOOL_DIMENSION_CIRC_DIR = Obj.repeat(nan);
            Inputs.TOOL_DIMENSION_RADIAL_DIR = Obj.repeat(nan);
            Inputs.ULS_BENDING_MOMENT = nan;
            Inputs.zFlange = 0;

            Obj.data = Inputs;
        end

        function arrayValue = repeat(Obj, value)
            % Repeats value to match `Obj.n` design points
            arrayValue = repmat(value, 1, Obj.n);
        end

    end

    methods (Access = protected)

        function bool = isCompatible(Obj, Other)
            bool = strcmp(Obj.n, Other.n);
        end

    end
end
