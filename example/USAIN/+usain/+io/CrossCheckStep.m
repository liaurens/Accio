classdef CrossCheckStep < runner.BaseStep & logging.Loggable

    methods

        function Obj = CrossCheckStep()
            Obj.InputKeys.Inputs = usain.DataKeys.Inputs;
            Obj.InputKeys.StructuralModel = usain.DataKeys.StructuralModel;
            Obj.InputKeys.ExternalFlsLoadsData = usain.DataKeys.ExternalFlsLoadsData;
            Obj.InputKeys.ExternalS1LoadsData = usain.DataKeys.ExternalS1LoadsData;
            Obj.InputKeys.ExternalUlsLoadsData = usain.DataKeys.ExternalUlsLoadsData;
            Obj.InputKeys.hasFeasibleDesign = usain.DataKeys.hasFeasibleDesign;

            % Some of the cross-checks modify the inputs, so we need to define this output key
            Obj.OutputKeys.Inputs = usain.DataKeys.Inputs;
        end

        function str = print_label(~)
            str = 'Cross checks on input data';
        end

        function pass = is_active(Obj)
            passSuperclass = is_active@runner.BaseStep(Obj);
            hasFeasibleDesign = Obj.get(Obj.InputKeys.hasFeasibleDesign);
            pass = passSuperclass && ~hasFeasibleDesign;
        end

        function run(Obj)
            Inputs = Obj.get(usain.DataKeys.Inputs);
            Inputs.StrMdl = Obj.get(usain.DataKeys.StructuralModel);
            Inputs.Milk.Fls = Obj.get_optional(usain.DataKeys.ExternalFlsLoadsData);
            Inputs.Milk.S1 = Obj.get_optional(usain.DataKeys.ExternalS1LoadsData);
            Inputs.Milk.Uls = Obj.get_optional(usain.DataKeys.ExternalUlsLoadsData);

            Inputs = Obj.convert_scaling_levels(Inputs);

            % Perform manipulations after loading files
            % NOTE: This class should gradually replace all the data set after loading performed in this class.
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Inputs = Manipulator.run();

            Inputs = Obj.do_post_load_checks(Inputs);

            % Run PostLoadChecks
            % NOTE: This class should gradually replace the checks in this class.
            PostLoadChecks = usain.inputs.PostLoadChecks(Inputs = Inputs, iElem = Manipulator.iElem);
            PostLoadChecks.run();

            Obj.set(usain.DataKeys.Inputs, Inputs);
        end

        function Inputs = do_post_load_checks(Obj, Inputs)
            % Performs cross checks on parsed inputs and loaded tool data

            % TODO: WPSSD-5647 Split this method into testable units

            assertFuncs = {}; % To present all errors at once

            isRequiredUls = usain.loads.Loads.check_is_required_uls(Inputs);
            if isRequiredUls

                nLoadSets = 0;
                if ~isa(Inputs.Milk.Uls, 'runner.NullData')
                    nLoadSets = numel(Inputs.Loads.ulsFilePath);
                end

                for iLoadSet = 1:nLoadSets
                    % Error if inclination loads are added twice (once in MEATLOAF,
                    % and then again in SEAGUL loads)
                    ThisMilk = Inputs.Milk.Uls(iLoadSet);
                    isAddedTwice = abs(ThisMilk.inherentInclinationAngle) > 1e-6 && ...
                        abs(Inputs.Loads.inclinationValue(iLoadSet)) > 1e-6;
                    assertFuncs{end + 1} = @() assert(~isAddedTwice, ...
                        ['Inclination moments inherent in input ''%s'' ULS loads found, ', ...
                        'while input ''inclinationValue'' is non-zero as well.\n', ...
                        '- ULS load file #%i: %s\n', ...
                        '- Inclination angle inherent in file: %g deg\n', ...
                        '- Inclination angle input to USAIN:  %g deg\n\n', ...
                        'This will doubly add inclination load to the service loads!\n', ...
                        '\t==> Please revise your inputs\n\n'], ...
                        ThisMilk.srcType, iLoadSet, ThisMilk.srcPath, ...
                        rad2deg(ThisMilk.inherentInclinationAngle), ...
                        rad2deg(Inputs.Loads.inclinationValue(iLoadSet))); %#ok

                    % Throw warning if PSF is non-unity while tag indicates a
                    % robustnes check
                    [pass, msg] = Milk.ExtremeLoads.check_loads_psf_for_robustness_check( ...
                        Inputs.Loads.tag{iLoadSet}, ThisMilk.psf);
                    if ~pass
                        Obj.Logger.warning(msg);
                    end
                end

                % When ULS_BENDING_MOMENT is provided ensure all ULS related items in the "Loads." block are not
                % provided
                hasUlsOverride = Inputs.ULS_BENDING_MOMENT > 1e-6;
                hasInclinationOverride = Inputs.INCLINATION_MOMENT > 1e-6;

                hasUlsLoadsFile = any(~cellfun(@isempty, Inputs.Loads.ulsFilePath));
                hasLoadsInclination = any(~isnan(Inputs.Loads.inclinationValue));
                hasUlsScaling = any(~isnan([Inputs.Loads.ulsScalingFactor{:}]));
                hasUlsScalingLevel = any(~isnan([Inputs.Loads.ulsScalingLevel{:}]));
                hasUlsLoadsBlockInputs = hasUlsLoadsFile || hasLoadsInclination || hasUlsScaling || hasUlsScalingLevel;

                hasUlsInput = hasUlsLoadsFile || hasUlsOverride;
                hasInclinationInput = hasInclinationOverride || hasLoadsInclination;

                assertFuncs{end + 1} =  @() assert(~(hasUlsOverride && hasUlsLoadsBlockInputs), ...
                    ['Expert input "ULS_BENDING_MOMENT" is set in combination with (some) ULS ', ...
                    'related inputs in the "Loads" input block. This is not allowed.']);

                assertFuncs{end + 1} =  @() assert(~(hasInclinationOverride && hasLoadsInclination), ...
                    ['Expert input "INCLINATION_MOMENT" is set in combination with "Loads.inclinationValue". ', ...
                    'This is not allowed.']);

                assertFuncs{end + 1} = @() assert(hasUlsInput, ...
                    ['Input block "Loads" or "ULS_BENDING_MOMENT" must be specified in order ', ...
                    'to assess ULS (related) design criteria.']);

                if ~hasInclinationInput
                    Obj.Logger.warning(['Insufficient inputs to compute inclination loads ', ...
                        '(empty input "Loads.inclinationValue" or "INCLINATION_MOMENT").\n', ...
                        '\t==> Continuing without inclination loads.']);
                end

            end

            hasStrMdl = ~isempty(Inputs.structureInpFilePath);
            if hasStrMdl
                % Check USAIN inputs with StructuralModel inputs
                StrMdl = Inputs.StrMdl;
                Levels = Inputs.StrMdl.Levels;
                TOL_Z = 1e-3;
                Comp = CompareToolInputsToStructuralModel(USAIN.TOOL_NAME, Inputs, StrMdl);

                % zFlange; Verify zFlange is covered by plate z-levels in input
                % StrMdl file (if provided)
                isInRange = Inputs.zFlange >= (min(Levels.zRange) - TOL_Z) && ...
                    Inputs.zFlange <= (max(Levels.zRange) + TOL_Z);
                isTop = abs(Inputs.zFlange - min(Levels.zRange)) < TOL_Z;
                isBot = abs(Inputs.zFlange - max(Levels.zRange)) < TOL_Z;
                assertFuncs{end + 1} = @() assert(isInRange, ...
                    ['Input "zFlange" is %gm%s, ', ...
                    'while structure bounds from input StructuralModel are [%g, %g]m%s.\n', ...
                    'Make sure the flange''s elevation level is covered ', ...
                    'by the input StructuralModel file:\n\t%s'], ...
                    Inputs.zFlange, Levels.refName, Levels.zRange, Levels.refName, ...
                    Inputs.structureInpFilePath);

                % Get indices of element(s) that can be linked to this flange
                iElem = find(Inputs.zFlange >= (StrMdl.Inp.Plate.Parsed.zCoordTop - TOL_Z) & ...
                             Inputs.zFlange <= (StrMdl.Inp.Plate.zCoordBot + TOL_Z));

                % Expect 1 match for flanges at structure ends, 2 matches
                % otherwise
                isAtEnd = isTop || isBot;
                assertFuncs{end + 1} = @() assert(numel(iElem) == iif(isAtEnd, 1, 2), ...
                    ['Expected %i "flange" element(s) within %gmm from input "zFlange" (=%gm%s) ', ...
                    'in input StructuralModel file''s PlateInput table:\n\t%s'], ...
                    iif(isAtEnd, 1, 2), 1e3 * TOL_Z, Inputs.zFlange, Levels.refName, ...
                    Inputs.structureInpFilePath);

                % Warn if no flange element is found in vicinity of zFlange
                if ~isempty(iElem) && ~all(contains(StrMdl.Inp.Plate.fTab('elemType', iElem), 'flange'))
                    warnStr = arrayfun(@(i) ...
                        sprintf('\t- %s (type: %s)', StrMdl.Inp.Plate.fTab('elemLabel', i), ...
                        StrMdl.Inp.Plate.fTab('elemType', i)), ...
                        iElem, 'uni', 0);
                    Obj.Logger.warning([ ...
                        'Input "zFlange" (=%gm) is not matching with a "flange" element in PlateInput ', ...
                        'table in StructuralModel file:\n\t%s\n\n', ...
                        'Matching plate element(s):\n%s'], ...
                        Inputs.zFlange, Inputs.structureInpFilePath, strjoin(warnStr, '\n'));
                end

                % Warn if input thicknNose(Up|Lo) does not match thickness of
                % corresponding flange element in StrMdl
                for iEl = 1:numel(iElem)
                    varName = sprintf('thicknNose%s', iif(iEl == 1, 'Up', 'Lo'));
                    varInpUnit = '[mm]';
                    thisMdlVar = 'wallThickn';

                    [pass, msg] = Comp.compare(varName, varInpUnit, thisMdlVar, iElem(iEl));
                    if ~pass
                        Obj.Logger.warning(msg{:});
                    end
                end

                % Warn if input total length (nose + flange) does not match
                % elemLength of corresponding flange element in StrMdl (only in
                % case minFlangeThickn == maxFlangeThickn)
                if abs(Inputs.minFlangeThickn - Inputs.maxFlangeThickn) < 1e-6

                    upperFlangeNominalThickness = Inputs.minFlangeThickn + Inputs.ALW_UPPER_FLANGE_THICKNESS;
                    lenTotUp = upperFlangeNominalThickness + Inputs.heightNoseUp;

                    if abs(StrMdl.Inp.Plate.Parsed.elemLength(iElem(1)) - lenTotUp) > 1e-6
                        Obj.Logger.warning(['Input heightNoseUp + nominal flange thickness ', ...
                            'not equal to StructuralModel %s length'], ...
                            StrMdl.Inp.Plate.Parsed.elemLabel{iElem(1)});
                    end

                    if ~isnan(Inputs.heightNoseLo) && ~isscalar(iElem)
                        lowerFlangeNominalThickness = Inputs.minFlangeThickn + Inputs.ALW_LOWER_FLANGE_THICKNESS;
                        lenTotLo = lowerFlangeNominalThickness + Inputs.heightNoseLo;
                        if abs(StrMdl.Inp.Plate.Parsed.elemLength(iElem(2)) - lenTotLo) > 1e-6
                            Obj.Logger.warning(['Input heightNoseLo + nominal flange thickness ', ...
                                'not equal to StructuralModel %s length'], ...
                                StrMdl.Inp.Plate.Parsed.elemLabel{iElem(2)});
                        end
                    end
                end

                % Warn if linked StructuralModel plate/flange element is not
                % cylindrical
                for iEl = 1:numel(iElem)
                    if abs(StrMdl.Inp.Plate.fTab('diamTop', iElem(iEl)) - ...
                        StrMdl.Inp.Plate.fTab('diamBot', iElem(iEl))) > 1e-4
                        Obj.Logger.warning(['The matching "flange" element in StructuralModel''s ', ...
                            'PlateInput table (%s) is not cylindrical.\n', ...
                            '\t==> additional FE analyses need to be conducted to verify the ', ...
                            'structural integrity of conical flanges!'], ...
                            StrMdl.Inp.Plate.fTab('elemLabel', iElem(iEl)));
                    end
                end

                % Warn if material inputs do not match with StrMdl data
                varMap = containers.Map({'E_FLANGE', 'RHO_FLANGE', 'FLANGE_STEEL_TYPE'}, ...
                                        {'eModulus', 'density', 'steelType'});
                varMapUnits = containers.Map({'E_FLANGE', 'RHO_FLANGE', 'FLANGE_STEEL_TYPE'}, ...
                                              {'[GPa]', '[kg/m3]', '[-]'});
                for var = varMap.keys
                    thisMdlVar = sprintf('Material.%s', varMap(var{1}));
                    thisInpVarUnit = varMapUnits(var{1});

                    for iEl = 1:numel(iElem)
                        [pass, msg] = Comp.compare(var{1}, thisInpVarUnit, thisMdlVar, iElem(iEl));
                        if ~pass
                            Obj.Logger.warning(msg{:});
                        end
                    end
                    % No need to take NaN values from StrMdl as these inputs are
                    % optional and have default values
                end

                % Check if door segment is defined in both StrMdl and USAIN. USAIN should not account for the door
                % segment in bcd calculations if there is an extra plate between the door segment and flange.
                if isfield(StrMdl.Inp.General.Parsed, 'doorSegmentLabels') % Backward compatibel for StrMdl.
                    strMdlHasDoorSegment = ~isempty(StrMdl.Inp.General.Parsed.doorSegmentLabels);
                    strMdlHasPlateBetweenDoorAndFlange = any(StrMdl.Inp.Plate.isPlateBetweenDoorSegmentAndFlange);
                else
                    strMdlHasDoorSegment = false;
                    strMdlHasPlateBetweenDoorAndFlange = false;
                end

                strMdlIndicatesToAccountForDoor = strMdlHasDoorSegment && ~strMdlHasPlateBetweenDoorAndFlange;
                if Inputs.DOOR_SEGMENT.DO_INCLUDE && ~strMdlIndicatesToAccountForDoor
                    Obj.Logger.warning([ ...
                        'Input DOOR_SEGMENT.DO_INCLUDE is set to true, but the StructuralModel indicates ', ...
                        'that either there is no door segment or that there is a plate defined between the door ', ...
                        'segment and the flange, so USAIN should not account for it in the BCD calculation.']);
                elseif ~Inputs.DOOR_SEGMENT.DO_INCLUDE && strMdlIndicatesToAccountForDoor
                    Obj.Logger.warning([ ...
                        'The StructuralModel indicates that USAIN should consider the door segment for ', ...
                        'BCD calculations, but DOOR_SEGMENT.DO_INCLUDE is set to false.']);
                end

                % Check requirements of tool-to-wall clash check
                zRange = StrMdl.Levels.zRange;
                for iBoltOption = 1:length(Inputs.boltOptions)
                    msg = UsainUtils.ToolToWallClashCheck.post_load_checks( ...
                        Inputs.site, ...
                        Inputs.boltOptions{iBoltOption}, ...
                        Inputs.tighteningMethod{iBoltOption}, ...
                        Inputs.TIGHTENING_SIDE_INSTALLATION{iBoltOption}, ...
                        Inputs.NUT_TYPE{iBoltOption}, ...
                        Inputs.zFlange, zRange);
                    if msg
                        Obj.Logger.warning(msg);
                    end
                end

                % Log error if non-negative DEAD_WEIGHT input is provided as well as a StructuralModel
                assertFuncs{end + 1} =  @() assert(~(Inputs.DEAD_WEIGHT > 1e-6 && hasStrMdl), ...
                  'Both inputs DEAD_WEIGHT and structureInpFilePath are set. This is not allowed.');

            else
                % No structureInpFilePath provided;

                % Assert that nose thicknesses and diameter are input as they
                % cannot be grabbed from StructuralModel
                chkVar = {'thicknNoseUp', 'thicknNoseLo', 'diameter'};
                for var = chkVar
                    assertFuncs{end + 1} = @() assert(~isnan(Inputs.(var{1})), ...
                        ['Either define input "%s" in input file, or define "structureInpFilePath" ', ...
                        'so that value can be grabbed from the input StructuralModel file.'], ...
                        var{1}); %#ok<AGROW>
                end

                % Assert if flangeType is given as input or can be obtained from
                % StructuralModel
                chkVar = 'flangeType';
                assertFuncs{end + 1} = @() assert(~isempty(Inputs.(chkVar)), ...
                    ['Either define input "%s" in input file, or define "structureInpFilePath" ', ...
                    'so that value can be grabbed from the input StructuralModel file.'], ...
                    chkVar);

                % Throw warning if inclinationValue is nonzero. This check is only
                % needed if conditions using ULS loads are enabled
                if isRequiredUls && Inputs.INCLINATION_MOMENT > 1e-6
                    % This is ok, no need to check for Loads.inclinationValue, since an error is already thrown if both
                    % Loads.inclinationValue and INCLINATION_MOMENT are set.
                elseif isRequiredUls && any(abs(Inputs.Loads.inclinationValue) > 1e-6)
                    Obj.Logger.warning(['Insufficient inputs to compute inclination loads ', ...
                        '(empty input "structureInpFilePath").\n', ...
                        '\t==> Continuing without inclination loads.']);
                end

                Obj.Logger.info('Input "structureInpFilePath" is not defined; skipping related input checks.');
            end

            % In case of flange assymmetry with a larger neck thickness on the lower flange, the temporary stages tools
            % could drive the BCD. However, for an interface flange the lower flange needs not be assessed for this BCD
            % rule.
            if isempty(Inputs.structureInpFilePath) && (Inputs.thicknNoseLo > Inputs.thicknNoseUp + 0.0001)
                Obj.Logger.warning(['Lower flange neck thickness exceeds upper flange neck thickness.\n', ...
                    'If the BCD is driven by the distance of temporary stages tool to structure wall ', ...
                    'and this is an interface flange, the resulting BCD is not optimal.\n', ...
                    'To solve this, please provide a StructuralModel or override the BCD ', ...
                    '(after agreement with topic owners).']);
            end

            % Verify that diameter > diamBoltCircle
            assertFuncs{end + 1} = @() assert( ...
                all(~(Inputs.diameter <= Inputs.diamBoltCircle)), ...
                'Input "diameter" must be > input "diamBoltCircle".');

            isTFlange = strcmp(Inputs.flangeType, 'T');
            isSymmetric = abs(Inputs.thicknNoseLo - Inputs.thicknNoseUp) < 1e-6;
            if isTFlange && ~isSymmetric
                Obj.Logger.warning(['Inputs for nose thickness on both sides of the T-flange are unequal.\n', ...
                    'This is not allowed, T-flanges should be symmetric!']);
            end

            % Check for presence of Markov matrices
            isRequiredFls = usain.loads.Loads.check_is_required_fls(Inputs);
            if isRequiredFls
                assertFuncs{end + 1} = @() assert(all([Inputs.Milk.Fls.hasMarkov]), ...
                    sprintf(['Imported FLS loads do not contain Markov matrices. ', ...
                    'These are required for bolt fatigue assessment.\n', ...
                    '\t==> Either provide FLS loads with Markov matrices ', ...
                    'or set input "DO_ASSESS_FLS" and "DO_ASSESS_GAPPING" to false']));
            end

            % If DOOR_SEGMENT.DO_INCLUDE is true but the thickness was not provided (nan), use logic to assign
            % a value. If StrMdl is given use the actual plate as reference rather than the nose thickness
            % of the flange.
            if Inputs.DOOR_SEGMENT.DO_INCLUDE
                % Determine ref thickn to either assign or validate input thickness.
                if hasStrMdl
                    refThicknDoorSeg = 1e-3 * StrMdl.Inp.Plate.fTab('wallThickn', iElem(1) - 1);
                else
                    refThicknDoorSeg = 1e-3 * Inputs.thicknNoseUp;
                end

                % Assign or check value
                if isnan(Inputs.DOOR_SEGMENT.THICKNESS)
                    assignThickn = max(Inputs.DOOR_SEGMENT.MIN_CAN_TO_DOOR_DELTA_THICKNESS + refThicknDoorSeg, ...
                        Inputs.DOOR_SEGMENT.FACTOR_CAN_TO_DOOR_THICKNESS * refThicknDoorSeg);
                    % Thickness of door segment should be rounded up to nearest 0.1mm
                    assignThickn = ceil(1e4 * assignThickn) / 1e4;
                    Inputs.DOOR_SEGMENT.THICKNESS = assignThickn;
                    Obj.Logger.warning(['The input "DOOR_SEGMENT.THICKNESS" is not provided, the value: %.4fmm ', ...
                        'is set based on a minimum thickness jump of %.1fmm and factor %.2f.\nFor certification ' ...
                        'the actual value should be determined with FEA.'], assignThickn, ...
                        Inputs.DOOR_SEGMENT.MIN_CAN_TO_DOOR_DELTA_THICKNESS, ...
                        Inputs.DOOR_SEGMENT.FACTOR_CAN_TO_DOOR_THICKNESS);
                else
                    doorSegThicknIsValid = Inputs.DOOR_SEGMENT.THICKNESS >= ...
                        refThicknDoorSeg + Inputs.DOOR_SEGMENT.MIN_CAN_TO_DOOR_DELTA_THICKNESS;
                    if ~doorSegThicknIsValid
                        Obj.Logger.warning(['The thickness of the door segment is %.4fmm while the reference ', ...
                            'plate or nose thickness is %.4fmm.\nIt is expected that the door segment ', ...
                            'is at least %.2fmm thicker.'], Inputs.DOOR_SEGMENT.THICKNESS, refThicknDoorSeg, ...
                            1e3 * Inputs.DOOR_SEGMENT.MIN_CAN_TO_DOOR_DELTA_THICKNESS);
                    end
                end
            end

            if any([Inputs.BoltFls.BOLT_FORCE_MODEL] == "sgre2") && ...
                strcmp(Inputs.SGRE2.SHELL_STIFFNESS_METHOD, 'interpolated')

                % Throw error if the neck thicknesses are outside range [10, 150]mm, in combination with interpolated
                % shell stiffness.
                minNeckThickness = min(Inputs.thicknNoseLo, Inputs.thicknNoseUp);
                maxNeckThickness = max(Inputs.thicknNoseLo, Inputs.thicknNoseUp);
                assertFuncs{end + 1} = @() assert(minNeckThickness >= 10e-3 && maxNeckThickness <= 150e-3, ...
                    ['Neck thickness must be in range [10, 150]mm for interpolating shell stiffness. ', ...
                    'Use the `simplified` shell stiffness method instead (input SGRE2.SHELL_STIFFNESS_METHOD).']);

                % Throw error if the flange diameter is outside range [3, 10]m, in combination with interpolated
                % shell stiffness.
                assertFuncs{end + 1} = @() assert(Inputs.diameter >= 3 && Inputs.diameter <= 10, ...
                    ['Flange neck outer diameter must be in range [3, 10]m for interpolating shell stiffness. ', ...
                    'Use the `simplified` shell stiffness method instead (input SGRE2.SHELL_STIFFNESS_METHOD).']);
            end

            % Evaluate assert functions and throw all errors at once
            Obj.evaluate_assertfuncs(assertFuncs);
            Obj.Logger.info('Finished post-parse checks successfully!');
        end

        function Inputs = convert_scaling_levels(~, Inputs)
            if isempty(Inputs.StrMdl)
                f = @(x) cell2mat(x);
            else
                f = @(x) Inputs.StrMdl.Levels.level2num(x);
            end

            Inputs.Loads.ulsScalingLevel = cellfun(@(x) f(x), Inputs.Loads.ulsScalingLevel, 'UniformOutput', false);
            Inputs.Loads.flsScalingLevel = cellfun(@(x) f(x), Inputs.Loads.flsScalingLevel, 'UniformOutput', false);
            Inputs.Loads.S1ScalingLevel = cellfun(@(x) f(x), Inputs.Loads.S1ScalingLevel, 'UniformOutput', false);
        end

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
                allErrMsgs = cellfun(@(x) ...
                    regexprep(x.message, {'\n', '(\\)'}, {'\n\t', '\\\'}), ...
                    ME, 'uni', 0);

                % Create the print string
                errPrintStr = sprintf(['One or more input validations failed. See below for results:\n\n', ...
                    repmat('-', 1, 60), '\n\n'...
                    sprintf(['\t%s\n', '\t', repmat('-', 1, 40), '\n'], allErrMsgs{:})]);

                % Make a new exception and throw it
                Obj.Logger.error(sprintf('USAIN:FailedInputVal'), regexprep(errPrintStr, '(\\)', '\\\'));
            end
        end

    end
end
