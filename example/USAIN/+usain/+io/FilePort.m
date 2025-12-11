classdef FilePort < matlab.mixin.SetGet & logging.Config
    % Contains consolidated data for the use in other tools, including type description.
    % See `$ENGINEERING_CODEBASE_HOME/guides/fileport-matlab.md` for developer notes on FilePort formatting.

    properties (Constant)
        FILE_VERSION char = '1.8.0' % Version of file port
    end

    properties
        toolName char  % Name of tool
        toolVersion char  % Version of tool (at time of saving)

        data struct = struct() % Values. Optional fields are not present in this structure.
        TYPES struct = usain.io.FilePort.get_types()  % Type descriptions. All fields always present.
    end

    methods

        function Obj = FilePort(UsainObj)

            Obj.toolName = USAIN.TOOL_NAME;
            Obj.toolVersion = USAIN.VERSION;

            if nargin
                Obj.data = usain.io.FilePort.get_data(UsainObj);
            end
        end

        function save_file(Obj, file, force)
            % Save object, converted to basic types, to HDF5 file
            %
            % file: File path to non-existing file
            % force: Toggle to allow overwriting existing files (default: false)

            if nargin < 3
                force = false;
            end

            FilePath = pathlib.Path(file);

            assert(~FilePath.is_dir(), 'FilePort:FilePath', 'Input must be a file path.');
            assert(force || ~FilePath.exists(), 'FilePort:ExistingPath', 'File already exists.');

            FilePath.parent.mkdir(true);
            UsainPort = Obj.get_object_to_save();
            save(FilePath.full_path(), 'UsainPort', '-v7');
        end

        function StaticObj = get_object_to_save(Obj)
            % Returns static object (with basic data types only), for saving to file
            StaticObj = Convert.to_basic_type(Obj);
        end

        function data = load_file(~, file)
            Loader = usain.io.BaseLoader();
            Loader.check_and_load_file(file);
            data = Loader.data;
        end

    end

    methods (Static)

        function data = get_data(UsainObj)

            Export = ExportLayer(UsainObj);

            Export.add_field("bolt.boltOptionLabel",                              "Mdl.Inputs.boltOptions");
            Export.add_field("bolt.diameter",                                     "Mdl.Bolt.diam");
            Export.add_field("bolt.eModulus",                                     "Mdl.Inputs.E_BOLT");
            Export.add_field("bolt.length",                                       "Mdl.Bolt.len");
            Export.add_field("bolt.propertyClass",                                "Mdl.Bolt.propClass");
            Export.add_field("bolt.threadLength",                                 "Mdl.Bolt.lenThread");
            Export.add_field("bolt.ultimateStrength",                             "Mdl.Bolt.ultStrength");
            % TODO: Add in next version
            % Export.add_field("bolt.yieldStrengthMinimum", "Mdl.Bolt.yieldStrengthMinimum");
            % Export.add_field("bolt.yieldStrengthNominal", "Mdl.Bolt.yieldStrengthNominal");
            Export.add_field("conditions.boltForceModelApplicability.utilRatio",  "Mdl.Condit.MdlAppl.utilRatio",                'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.boltForceModelApplicability.isAssessed", "Mdl.Condit.MdlAppl.doAssess");
            Export.add_field("conditions.neckYield.forceDesign",                  "Mdl.Condit.NeckYield.fDesign",                'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.neckYield.isAssessed",                   "Mdl.Condit.NeckYield.doAssess");
            Export.add_field("conditions.neckYield.utilRatio",                    "Mdl.Condit.NeckYield.utilRatio",              'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.thread.grippedThreadLengthLowerFlange",  "Mdl.Condit.Thread.grippedThreadLowerFlange",  'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.thread.grippedThreadLengthUpperFlange",  "Mdl.Condit.Thread.grippedThreadUpperFlange",  'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.thread.visibleThreadLengthLowerFlange",  "Mdl.Condit.Thread.visibleThreadLowerFlange",  'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.thread.visibleThreadLengthUpperFlange",  "Mdl.Condit.Thread.visibleThreadUpperFlange",  'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.thread.isAssessed",                      "Mdl.Condit.Thread.doAssess");
            Export.add_field("conditions.uls.failureModeA",                       "Mdl.Condit.Uls.failModeA",                    'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.uls.failureModeB",                       "Mdl.Condit.Uls.failModeB",                    'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.uls.failureModeD",                       "Mdl.Condit.Uls.failModeD",                    'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.uls.failureModeCritical",                "Mdl.Condit.Uls.failModeCrit",                 'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.uls.failureModeE",                       "Mdl.Condit.Uls.failModeE",                    'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.uls.forceDesign",                        "Mdl.Condit.Uls.fDesign",                      'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.uls.isAssessed",                         "Mdl.Condit.Uls.doAssess");
            Export.add_field("conditions.uls.utilRatio",                          "Mdl.Condit.Uls.utilRatio",                    'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.uls.yieldStrengthDesign",                "Mdl.Condit.Uls.yieldStrengthDes",             'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.ulsJapan.failureModeA",                  "Mdl.Condit.UlsJpn.failModeA",                 'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.ulsJapan.failureModeB",                  "Mdl.Condit.UlsJpn.failModeB",                 'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.ulsJapan.failureModeC",                  "Mdl.Condit.UlsJpn.failModeC",                 'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.ulsJapan.failureModeCritical",           "Mdl.Condit.UlsJpn.failModeCrit",              'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.ulsJapan.forceDesign",                   "Mdl.Condit.UlsJpn.fDesign",                   'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.ulsJapan.isAssessed",                    "Mdl.Condit.UlsJpn.doAssess");
            Export.add_field("conditions.ulsJapan.utilRatio",                     "Mdl.Condit.UlsJpn.utilRatio",                 'skipEmpty', true); % mh:ignore_style
            Export.add_field("conditions.ulsJapan.yieldStrengthDesign",           "Mdl.Condit.UlsJpn.yieldStrengthDes",          'skipEmpty', true); % mh:ignore_style

            NumBolts = usain.space.NumberOfBolts.from_inputs(UsainObj.Mdl.Inputs, ...
                UsainObj.Mdl.diameterBoltCircle, UsainObj.Mdl.diameterBoltCircle);
            Thickness = usain.space.FlangeThickness.from_inputs(UsainObj.Mdl.Inputs);
            Width = usain.space.FlangeWidth.from_inputs(UsainObj.Mdl.Inputs, ...
                [Thickness.CalculatedBounds.max_], UsainObj.Mdl.Segment.distForce);
            Export.add_value("designspace.numberOfBoltsMin",                      NumBolts.CalculatedBounds.min_);
            Export.add_value("designspace.numberOfBoltsMax",                      NumBolts.CalculatedBounds.max_);
            Export.add_value("designspace.thicknessFlangeMin",                    Thickness.CalculatedBounds.min_);
            Export.add_value("designspace.thicknessFlangeMax",                    Thickness.CalculatedBounds.max_);
            Export.add_value("designspace.widthFlangeMin",                        Width.CalculatedBounds.min_);
            Export.add_value("designspace.widthFlangeMax",                        Width.CalculatedBounds.max_);

            Export.add_field("extender.diameterIn",                               "Mdl.Extr.diamIn");
            Export.add_field("extender.diameterOut",                              "Mdl.Extr.diamOut");
            Export.add_field("extender.length",                                   "Mdl.Extr.len");
            Export.add_field("flange.bevelAngle",                                 "Mdl.Inputs.BEVEL_ANGLE");
            Export.add_field("flange.bevelRootFace",                              "Mdl.Inputs.BEVEL_ROOT_FACE");
            Export.add_field("flange.boltDistance",                               "Mdl.Segment.distBolt");
            Export.add_field("flange.boltCircleDiameter",                         "Mdl.Inputs.diamBoltCircle");
            Export.add_field("flange.boltCircleDiameterMin",                      "Mdl.bcdMin");
            Export.add_field("flange.boltCircleDiameterMax",                      "Mdl.bcdMax");
            Export.add_field("flange.boltHoleDiameter",                           "Mdl.Inputs.diamBoltHole");
            Export.add_field("flange.clearanceExtenderToFillet",                  "Mdl.clearExtrFil");
            Export.add_field("flange.clearanceToolToWeld",                        "Mdl.clearToolWeld");
            Export.add_field("flange.clearanceWasherToLowerFillet",               "Mdl.clearWashFilLo");
            Export.add_field("flange.clearanceWasherToUpperFillet",               "Mdl.clearWashFilUp");
            Export.add_field("flange.clearanceWeldToLowerFillet",                 "Mdl.clearWeldFilLo");
            Export.add_field("flange.clearanceWeldToUpperFillet",                 "Mdl.clearWeldFilUp");
            Export.add_field("flange.density",                                    "Mdl.Inputs.RHO_FLANGE");
            Export.add_field("flange.eModulus",                                   "Mdl.Inputs.E_FLANGE");
            Export.add_field("flange.filletRadius",                               "Mdl.Inputs.FILLET_RADIUS");
            Export.add_field("flange.lowerFlangeThicknessAllowance",              "Mdl.Inputs.ALW_LOWER_FLANGE_THICKNESS"); % mh:ignore_style
            Export.add_field("flange.upperFlangeThicknessAllowance",              "Mdl.Inputs.ALW_UPPER_FLANGE_THICKNESS"); % mh:ignore_style
            Export.add_field("flange.flangeType",                                 "Mdl.flangeType");
            Export.add_field("flange.materialDesignation",                        "Mdl.Inputs.flangeMatrDesignation");
            Export.add_field("flange.massBoltAssembly",                           "Mdl.massBoltAssm");
            Export.add_field("flange.massFlangeLower",                            "Mdl.massFlangeLo");
            Export.add_field("flange.massFlangeUpper",                            "Mdl.massFlangeUp");
            Export.add_field("flange.massStubLower",                              "Mdl.massStubLo");
            Export.add_field("flange.massStubUpper",                              "Mdl.massStubUp");
            Export.add_field("flange.minNoseHeight",                              "Mdl.Inputs.MIN_NOSE_HEIGHT");
            Export.add_field("flange.minNoseHeightLower",                         "Mdl.minHeightNoseLo");
            Export.add_field("flange.minNoseHeightUpper",                         "Mdl.minHeightNoseUp");
            Export.add_field("flange.neckHeightLower",                            "Mdl.Inputs.heightNoseLo");
            Export.add_field("flange.neckHeightUpper",                            "Mdl.Inputs.heightNoseUp");
            Export.add_field("flange.neckThicknessLower",                         "Mdl.Inputs.thicknNoseLo");
            Export.add_field("flange.neckThicknessUpper",                         "Mdl.Inputs.thicknNoseUp");
            Export.add_field("flange.outerBoltCircleDiameter",                    "Mdl.bcdOut",                               'skipEmpty', true); % mh:ignore_style
            Export.add_field("flange.outerNeckDiameter",                          "Mdl.diameterOutNeck");
            Export.add_field("flange.outerStubDiameter",                          "Mdl.diamOutFlange");
            Export.add_field("flange.segment.loadFactor",                         "Mdl.Segment.loadFactor");
            Export.add_field("flange.segment.parameterA",                         "Mdl.Segment.distRim");
            Export.add_field("flange.segment.parameterB",                         "Mdl.Segment.distForce");
            Export.add_field("flange.segment.resilienceBolt",                     "Mdl.Segment.resilBolt");
            Export.add_field("flange.segment.resilienceClampedParts",             "Mdl.Segment.resilClampedPkg");
            Export.add_field("flange.segment.resilienceFlanges",                  "Mdl.Segment.resilFlanges");
            Export.add_field("flange.space.nBolts",                               "Mdl.Space.nBolts");
            Export.add_field("flange.space.thickness",                            "Mdl.Space.thickness");
            Export.add_field("flange.space.width",                                "Mdl.Space.width");
            Export.add_field("flange.totalHeightLower",                           "Mdl.heightTotLo");
            Export.add_field("flange.totalHeightUpper",                           "Mdl.heightTotUp");
            Export.add_field("flange.yieldStrengthCharacteristic",                "Mdl.Inputs.yieldStrengthChar");
            Export.add_field("flange.zCoordinate",                                "Mdl.Inputs.zFlange");
            Export.add_field("general.site",                                      "Mdl.Inputs.site");
            Export.add_field("general.countryCode",                               "Mdl.Inputs.countryCode");
            Export.add_field("general.delReferenceCycles",                        "Mdl.Inputs.DEL_REF_CYCLES");
            Export.add_field("general.delWohlerSlope",                            "Mdl.Inputs.DEL_WOHLER_SLOPE");
            Export.add_field("general.doAssessFls",                               "Mdl.Inputs.DO_ASSESS_FLS");
            Export.add_field("general.structuralModelInputPath",                  "Mdl.Inputs.structureInpFilePath",          'skipEmpty', true); % mh:ignore_style
            Export.add_field("general.structuralModelOutputPath",                 "mdlOutFilePath",                           'skipEmpty', true); % mh:ignore_style);
            Export.add_field("loads.deadWeightFavorDesign",                       "Mdl.Loads.deadWeightFavorDesign");
            Export.add_field("loads.delDesign",                                   "Mdl.Loads.delDesign",                      'skipEmpty', true); % mh:ignore_style
            Export.add_field("loads.flsLoadsPath",                                "Mdl.Loads.Fls.sourceFilePath",             'skipEmpty', true, 'castToCell', true); % mh:ignore_style
            Export.add_field("loads.inclinationValue",                            "Mdl.Inputs.Loads.inclinationValue"); % TODO check what happens when it is empty... should be possible to not use this, but directly a bending moment. % mh:ignore_style
            Export.add_field("loads.inclinationUnit",                             "Mdl.Inputs.Loads.inclinationUnit");
            Export.add_field("loads.inclinationMomentDesign",                     "Mdl.Loads.inclinMomentDesign");
            % TODO: Add in next version
            % Export.add_field("loads.inclinationMomentFlsDesign", ....

            if UsainObj.Mdl.Inputs.DO_ASSESS_FLS
                markovFolder = arrayfun(@(x) x.Markov.srcPath, UsainObj.Mdl.Loads.Fls, 'UniformOutput', false);
                Export.add_value("loads.markovFolder", markovFolder);
            end

            Export.add_field("loads.maxFlsMoment",                                "Mdl.Loads.maxFlsMxy",                      'skipEmpty', true); % mh:ignore_style
            % TODO: Add in next version
            % Export.add_field("loads.maxS1MomentDesign",                           "Mdl.Loads.maxS1MomentDesign",              'skipEmpty', true); % mh:ignore_style
            Export.add_field("loads.nLoadSets",                                   "Mdl.Loads.nLoadSets",                      'skipEmpty', true); % mh:ignore_style
            Export.add_field("loads.tag",                                         "Mdl.Inputs.Loads.tag");
            Export.add_field("loads.ulsLoadsPath",                                "Mdl.Loads.Uls.srcPath",                    'skipEmpty', true, 'castToCell', true); % mh:ignore_style
            Export.add_field("loads.ulsMomentDesign",                             "Mdl.Loads.ulsMxyDesign",                   'skipEmpty', true); % mh:ignore_style
            Export.add_field("loads.ulsMomentDlc",                                "Mdl.Loads.ulsMxyDlc",                      'skipEmpty', true); % mh:ignore_style
            Export.add_field("nut.label",                                         "Mdl.Nut.label");
            Export.add_field("nut.height",                                        "Mdl.Nut.len");
            Export.add_field("partialSafetyFactor.boltResistance",                "Mdl.Inputs.PSF_BOLT_RESISTANCE");
            Export.add_field("partialSafetyFactor.componentClassFls",             "Mdl.Inputs.PSF_CMPCLASS2_FLS");
            Export.add_field("partialSafetyFactor.componentClassUls",             "Mdl.Inputs.PSF_CMPCLASS2_ULS");
            Export.add_field("partialSafetyFactor.favorableLoads",                "Mdl.Inputs.PSF_FAVORABLE_LOADS");
            Export.add_field("partialSafetyFactor.materialUls",                   "Mdl.Inputs.PSF_MATERIAL_ULS");
            Export.add_field("tolerance.boltCircleDiameter",                      "Mdl.Inputs.TOL_BCD");
            Export.add_field("tolerance.boltHole",                                "Mdl.Inputs.TOL_BOLT_HOLE");
            Export.add_field("tolerance.extenderLength",                          "Mdl.Inputs.TOL_EXTENDER_LENGTH");
            Export.add_field("tolerance.filletRadiusPlus",                        "Mdl.Inputs.TOL_FILLET_RADIUS_PLUS");
            Export.add_field("tolerance.flangeThicknessMinus",                    "Mdl.Inputs.TOL_FLANGE_THICKNESS_MINUS"); % mh:ignore_style
            Export.add_field("tolerance.flangeThicknessPlus",                     "Mdl.Inputs.TOL_FLANGE_THICKNESS_PLUS"); % mh:ignore_style
            Export.add_field("tolerance.flangeWidth",                             "Mdl.Inputs.TOL_FLANGE_WIDTH");
            Export.add_field("tool.assemblyValue",                                "Mdl.Tool.assemblyValue");
            Export.add_field("tool.tighteningMethod",                             "Mdl.Tool.tighteningMethod");
            Export.add_field("tool.tighteningSideInstallation",                   "Mdl.Inputs.TIGHTENING_SIDE_INSTALLATION");  % mh:ignore_style
            Export.add_field("washer.customWasherDiameterIn",                     "Mdl.Inputs.CUSTOM_WASHER_DIAM_INNER",      'skipEmpty', true); % mh:ignore_style
            Export.add_field("washer.customWasherDiameterOut",                    "Mdl.Inputs.CUSTOM_WASHER_DIAM_OUTER",      'skipEmpty', true); % mh:ignore_style
            Export.add_field("washer.customWasherThickness",                      "Mdl.Inputs.CUSTOM_WASHER_THICKNESS",       'skipEmpty', true); % mh:ignore_style
            Export.add_field("washer.diameterIn",                                 "Mdl.Wash.diamIn");
            Export.add_field("washer.diameterOut",                                "Mdl.Wash.diamOut");
            Export.add_field("washer.thickness",                                  "Mdl.Wash.len");

            % Export data pertaining to the first BoltFls input block only, by temporarily changing `FullObj` in the
            % ExportLayer
            Export.FullObj = UsainObj.Mdl.Inputs.BoltFls(1);
            Export.add_field("partialSafetyFactor.boltMaterialFls",        "PSF_BOLT_MATERIAL_FLS");
            Export.add_field("conditions.fls.boltForceModelName",          "BOLT_FORCE_MODEL");
            Export.add_field("conditions.fls.targetPmSum",                 "TARGET_PM_SUM");
            Export.FullObj = UsainObj;

            Export.add_field("conditions.fls.additionalScf",               "Mdl.Inputs.ADDITIONAL_SCF_FLS");
            Export.add_field("conditions.fls.macroGeometricScf",           "Mdl.Inputs.MACRO_GEOMETRIC_SCF");
            % Export data pertaining to the first FLS assessment only
            % Temporarily change `FullObj` in the ExportLayer to the first defined FLS condition in USAIN (subsequent
            % FLS conditions are for internal checking only)
            Export.FullObj = UsainObj.Mdl.Condit.Fls(1);
            Export.add_field("conditions.fls.pmSum",                       "pmSum",                                'skipEmpty', true);  % mh:ignore_style
            Export.add_field("conditions.fls.pmSumInverse",                "pmSumInv",                             'skipEmpty', true);  % mh:ignore_style
            Export.add_field("conditions.fls.pmSumNorm",                   "pmSumNorm",                            'skipEmpty', true);  % mh:ignore_style
            Export.add_field("conditions.fls.pmSumNormInverse",            "pmSumNormInv",                         'skipEmpty', true);  % mh:ignore_style
            Export.add_field("conditions.fls.sizeEffect",                  "sizeEffect",                           'skipEmpty', true);  % mh:ignore_style
            Export.add_field("conditions.fls.snCurveLabel",                "SnCurve.label",                        'skipEmpty', true);  % mh:ignore_style
            Export.add_field("conditions.fls.utilRatio",                   "utilRatio",                            'skipEmpty', true);  % mh:ignore_style
            Export.add_field("conditions.fls.utilRatioGeometry",           "utilRatioGeomConstraint",              'skipEmpty', true);  % mh:ignore_style
            Export.add_field("conditions.fls.isAssessed",                  "doAssess");
            Export.add_field("boltForceModel.petersen.zCr",                "BoltForceModel.zCr",                   'skipEmpty', true);  % mh:ignore_style
            Export.add_field("boltForceModel.schmidtNeuper.z1",            "BoltForceModel.z1",                    'skipEmpty', true);  % mh:ignore_style
            Export.add_field("boltForceModel.schmidtNeuper.z2",            "BoltForceModel.z2",                    'skipEmpty', true);  % mh:ignore_style
            Export.add_field("tool.preloadFls",                            "BoltForceModel.preload",               'skipEmpty', true);  % mh:ignore_style
            Export.FullObj = UsainObj;

            % Assign nominal preload (nowhere stored in USAIN, so compute on-the-fly)
            preload = usain.fastener.get_preload(UsainObj.Mdl.Tool.defaultPreload, UsainObj.Mdl.Inputs.BoltFls(1).CUSTOM_PRELOAD, 1.0);  % mh:ignore_style
            Export.add_value("tool.preload", preload);

            % Based on input BOLT_FORCE_MODEL, map the right properties to a uniform data structure
            plotData = struct();
            if UsainObj.Mdl.Inputs.DO_ASSESS_FLS
                switch lower(UsainObj.Mdl.Inputs.BoltFls(1).BOLT_FORCE_MODEL)
                    case {'petersen', 'schmidtneuper'}
                        BoltForceModel = UsainObj.Mdl.Condit.Fls(1).BoltForceModel;
                        plotData.line.x = BoltForceModel.boltCurveXy(:, 1);
                        plotData.line.y = BoltForceModel.boltCurveXy(:, 2);
                        plotData.marker.x = [BoltForceModel.boltCurveMrks.fls(1), BoltForceModel.boltCurveMrks.uls(1)];
                        plotData.marker.y = [BoltForceModel.boltCurveMrks.fls(2), BoltForceModel.boltCurveMrks.uls(2)];
                    otherwise
                        error('Only bolt force models `schmidtneuper` and `petersen` are supported for exporting with FilePort.');  % mh:ignore_style
                end
                plotData.marker.legendEntries = { ...
                    sprintf('max. FLS (Z=%.0fkN)', 1e-3 * plotData.marker.x(1)), ...
                    sprintf('max. ULS (Z=%.0fkN)', 1e-3 * plotData.marker.x(2))};

                Export.add_value("boltForceModel.preloadLossFactor",             UsainObj.Mdl.Inputs.BoltFls(1).PRELOAD_LOSS_FACTOR_FLS, 'skipEmpty', true);  % mh:ignore_style
                Export.add_value("boltForceModel.plotData.line.x",               plotData.line.x,               'skipEmpty', true); % mh:ignore_style
                Export.add_value("boltForceModel.plotData.line.y",               plotData.line.y,               'skipEmpty', true); % mh:ignore_style
                Export.add_value("boltForceModel.plotData.marker.legendEntries", plotData.marker.legendEntries, 'skipEmpty', true); % mh:ignore_style
                Export.add_value("boltForceModel.plotData.marker.x",             plotData.marker.x,             'skipEmpty', true); % mh:ignore_style
                Export.add_value("boltForceModel.plotData.marker.y",             plotData.marker.y,             'skipEmpty', true); % mh:ignore_style
            end

            % For the TowerCalc output _FLANGES_OVERVIEW.txt, we need parameters from the second BoltForceModel
            if UsainObj.Mdl.Inputs.DO_ASSESS_FLS && numel(UsainObj.Mdl.Inputs.BoltFls) > 1
                secondBoltForceModel = UsainObj.Mdl.Inputs.BoltFls(2);
                if any(strcmpi(secondBoltForceModel.BOLT_FORCE_MODEL, {'petersen', 'schmidtneuper'}))

                    Export.add_value("boltForceModelSecond.preloadLossFactor",    secondBoltForceModel.PRELOAD_LOSS_FACTOR_FLS, 'skipEmpty', true);  % mh:ignore_style
                    Export.add_value("boltForceModelSecond.boltMaterialFls",      secondBoltForceModel.PSF_BOLT_MATERIAL_FLS, 'skipEmpty', true);  % mh:ignore_style

                    Export.FullObj = UsainObj.Mdl.Condit.Fls(2);
                    Export.add_field("conditions.flsSecond.pmSum",               "pmSum",                'skipEmpty', true);  % mh:ignore_style
                    Export.add_field("conditions.flsSecond.pmSumInverse",        "pmSumInv",             'skipEmpty', true);  % mh:ignore_style
                    Export.add_field("boltForceModelSecond.petersen.zCr",        "BoltForceModel.zCr",   'skipEmpty', true);  % mh:ignore_style
                    Export.add_field("boltForceModelSecond.schmidtNeuper.z1",    "BoltForceModel.z1",    'skipEmpty', true);  % mh:ignore_style
                    Export.add_field("boltForceModelSecond.schmidtNeuper.z2",    "BoltForceModel.z2",    'skipEmpty', true);  % mh:ignore_style
                    Export.FullObj = UsainObj;

                end
            end

            data = Export.data;
        end

        function types = get_types()
            % Returns FilePort data structure with type descriptions

            types.bolt.boltOptionLabel = "str";
            types.bolt.diameter = "float";
            types.bolt.eModulus = "float";
            types.bolt.length = "float";
            types.bolt.threadLength = "float";
            types.bolt.propertyClass = "str";
            types.bolt.ultimateStrength = "float";
            % TODO: Add in next version
            % types.bolt.yieldStrengthMinimum = "float";
            % types.bolt.yieldStrengthNominal = "float";
            types.conditions.boltForceModelApplicability.utilRatio = "Optional[float]";
            types.conditions.boltForceModelApplicability.isAssessed = "bool";
            types.conditions.fls.boltForceModelName = "Enum(schmidtneuper, petersen)";
            types.conditions.fls.targetPmSum = "float";
            types.conditions.fls.additionalScf = "float";
            types.conditions.fls.macroGeometricScf = "float";
            types.conditions.fls.pmSum = "Optional[List[float]]";
            types.conditions.fls.pmSumInverse = "Optional[List[float]]";
            types.conditions.fls.pmSumNorm = "Optional[List[float]]";
            types.conditions.fls.pmSumNormInverse = "Optional[List[float]]";
            types.conditions.fls.sizeEffect = "Optional[float]";
            types.conditions.fls.snCurveLabel = "Optional[str]";
            types.conditions.fls.utilRatio = "Optional[NumpyArray[float]]";
            types.conditions.fls.utilRatioGeometry = "Optional[float]";
            types.conditions.fls.isAssessed = "bool";
            types.conditions.thread.grippedThreadLengthLowerFlange = "Optional[float]";
            types.conditions.thread.grippedThreadLengthUpperFlange = "Optional[float]";
            types.conditions.thread.visibleThreadLengthLowerFlange = "Optional[float]";
            types.conditions.thread.visibleThreadLengthUpperFlange = "Optional[float]";
            types.conditions.thread.isAssessed = "bool";
            types.conditions.uls.failureModeA = "Optional[NumpyArray[float]]";
            types.conditions.uls.failureModeB = "Optional[NumpyArray[float]]";
            types.conditions.uls.failureModeD = "Optional[NumpyArray[float]]";
            types.conditions.uls.failureModeCritical = "Optional[NumpyArray[float]]";
            types.conditions.uls.failureModeE = "Optional[NumpyArray[float]]";
            types.conditions.uls.forceDesign = "Optional[NumpyArray[float]]";
            types.conditions.uls.isAssessed = "bool";
            types.conditions.uls.utilRatio = "Optional[NumpyArray[float]]";
            types.conditions.uls.yieldStrengthDesign = "Optional[NumpyArray[float]]";
            types.conditions.ulsJapan.failureModeA = "Optional[NumpyArray[float]]";
            types.conditions.ulsJapan.failureModeB = "Optional[NumpyArray[float]]";
            types.conditions.ulsJapan.failureModeC = "Optional[NumpyArray[float]]";
            types.conditions.ulsJapan.failureModeCritical = "Optional[NumpyArray[float]]";
            types.conditions.ulsJapan.forceDesign = "Optional[NumpyArray[float]]";
            types.conditions.ulsJapan.isAssessed = "bool";
            types.conditions.ulsJapan.utilRatio = "Optional[NumpyArray[float]]";
            types.conditions.ulsJapan.yieldStrengthDesign = "Optional[NumpyArray[float]]";
            types.designspace.numberOfBoltsMin = "int";
            types.designspace.numberOfBoltsMax = "int";
            types.designspace.thicknessFlangeMin = "float";
            types.designspace.thicknessFlangeMax = "float";
            types.designspace.widthFlangeMin = "float";
            types.designspace.widthFlangeMax = "float";
            types.extender.diameterIn = "float";
            types.extender.diameterOut = "float";
            types.extender.length = "float";
            types.flange.bevelAngle = "float";
            types.flange.bevelRootFace = "float";
            types.flange.boltCircleDiameter = "float";
            types.flange.boltCircleDiameterMin = "float";
            types.flange.boltCircleDiameterMax = "float";
            types.flange.boltHoleDiameter = "float";
            types.flange.boltDistance = "float";
            types.flange.clearanceExtenderToFillet = "float";
            types.flange.clearanceToolToWeld = "float";
            types.flange.clearanceWasherToLowerFillet = "float";
            types.flange.clearanceWasherToUpperFillet = "float";
            types.flange.clearanceWeldToLowerFillet = "float";
            types.flange.clearanceWeldToUpperFillet = "float";
            types.flange.density = "float";
            types.flange.eModulus = "float";
            types.flange.filletRadius = "float";
            types.flange.lowerFlangeThicknessAllowance = "float";
            types.flange.upperFlangeThicknessAllowance = "float";
            types.flange.flangeType = "Enum(L, T)";
            types.flange.materialDesignation = "str";
            types.flange.massBoltAssembly = "float";
            types.flange.massFlangeLower = "float";
            types.flange.massFlangeUpper = "float";
            types.flange.massStubLower = "float";
            types.flange.massStubUpper = "float";
            types.flange.minNoseHeight = "float";
            types.flange.minNoseHeightLower = "float";
            types.flange.minNoseHeightUpper = "float";
            types.flange.neckHeightLower = "float";
            types.flange.neckHeightUpper = "float";
            types.flange.neckThicknessLower = "float";
            types.flange.neckThicknessUpper = "float";
            types.flange.outerBoltCircleDiameter = "Optional[float]";
            types.flange.outerNeckDiameter = "float";
            types.flange.outerStubDiameter = "float";
            types.flange.segment.loadFactor = "float";
            types.flange.segment.parameterA = "float";
            types.flange.segment.parameterB = "float";
            types.flange.segment.resilienceBolt = "float";
            types.flange.segment.resilienceClampedParts = "float";
            types.flange.segment.resilienceFlanges = "float";
            types.flange.space.nBolts = "float";
            types.flange.space.thickness = "float";
            types.flange.space.width = "float";
            types.flange.totalHeightLower = "float";
            types.flange.totalHeightUpper = "float";
            types.flange.yieldStrengthCharacteristic = "float";
            types.flange.zCoordinate = "float";
            types.general.site = "Enum(ONSHORE, OFFSHORE)";
            types.general.countryCode = "Enum(ROW, JPN)";
            types.general.delReferenceCycles = "float";
            types.general.delWohlerSlope = "float";
            types.general.doAssessFls = "bool";
            types.general.structuralModelInputPath = "Optional[str]";
            types.general.structuralModelOutputPath = "Optional[str]";
            types.loads.deadWeightFavorDesign = "float";
            types.loads.delDesign = "Optional[NumpyArray[float]]";
            types.loads.flsLoadsPath = "Optional[List[str]]";
            types.loads.inclinationValue = "Optional[NumpyArray[float]]";
            types.loads.inclinationUnit = "List[Enum(deg, mm_m)]";
            types.loads.inclinationMomentDesign = "NumpyArray[float]";
            % TODO: Add in next version
            % types.loads.inclinationMomentFlsDesign = "NumpyArray[float]";
            types.loads.maxFlsMoment = "Optional[NumpyArray[float]]";
            types.loads.markovFolder = "Optional[List[str]]";
            % TODO: Add in next version
            % types.loads.maxS1MomentDesign = "Optional[NumpyArray[float]]";
            types.loads.nLoadSets = "Optional[int]";
            types.loads.tag = "List[str]";
            types.loads.ulsLoadsPath = "Optional[List[str]]";
            types.loads.ulsMomentDesign = "Optional[NumpyArray[float]]";
            types.loads.ulsMomentDlc = "Optional[List[str]]";
            types.nut.label = "str";
            types.nut.height = "float";
            types.partialSafetyFactor.boltMaterialFls = "float";
            types.partialSafetyFactor.boltResistance = "float";
            types.partialSafetyFactor.componentClassFls = "float";
            types.partialSafetyFactor.componentClassUls = "float";
            types.partialSafetyFactor.favorableLoads = "float";
            types.partialSafetyFactor.materialUls = "float";
            types.tolerance.boltCircleDiameter = "float";
            types.tolerance.boltHole = "float";
            types.tolerance.extenderLength = "float";
            types.tolerance.filletRadiusPlus = "float";
            types.tolerance.flangeThicknessMinus = "float";
            types.tolerance.flangeThicknessPlus = "float";
            types.tolerance.flangeWidth = "float";
            types.tool.assemblyValue = "float";
            types.tool.preload = "float";
            types.tool.preloadFls = "Optional[float]";
            types.tool.tighteningMethod = "Enum(torque, tension)";
            types.tool.tighteningSideInstallation = "Enum(lower, upper)";
            types.washer.customWasherDiameterIn = "Optional[float]";
            types.washer.customWasherDiameterOut = "Optional[float]";
            types.washer.customWasherThickness = "Optional[float]";
            types.washer.diameterIn = "float";
            types.washer.diameterOut = "float";
            types.washer.thickness = "float";
            types.boltForceModel.SELF = "Optional";
            types.boltForceModel.petersen.SELF = "Optional";
            types.boltForceModel.petersen.zCr = "float";
            types.boltForceModel.preloadLossFactor = "float";
            types.boltForceModel.plotData.line.x = "NumpyArray[float]";
            types.boltForceModel.plotData.line.y = "NumpyArray[float]";
            types.boltForceModel.plotData.marker.legendEntries = "List[str]";
            types.boltForceModel.plotData.marker.x = "NumpyArray[float]";
            types.boltForceModel.plotData.marker.y = "NumpyArray[float]";
            types.boltForceModel.schmidtNeuper.SELF = "Optional";
            types.boltForceModel.schmidtNeuper.z1 = "float";
            types.boltForceModel.schmidtNeuper.z2 = "float";
            types.boltForceModelSecond.SELF = "Optional";
            types.boltForceModelSecond.petersen.SELF = "Optional";
            types.boltForceModelSecond.petersen.zCr = "float";
            types.boltForceModelSecond.preloadLossFactor = "float";
            types.boltForceModelSecond.boltMaterialFls = "float";
            types.boltForceModelSecond.schmidtNeuper.SELF = "Optional";
            types.boltForceModelSecond.schmidtNeuper.z1 = "float";
            types.boltForceModelSecond.schmidtNeuper.z2 = "float";
        end

    end

end
