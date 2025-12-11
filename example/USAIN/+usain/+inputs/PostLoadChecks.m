classdef PostLoadChecks < logging.Loggable

    properties
        Inputs
        LogHandler logging.CellArrayHandler
        iElem
    end

    properties (Constant)
        EXPECTED_MIN_FILLET_RADIUS_L_FLANGE = 10e-3
        EXPECTED_MIN_FILLET_RADIUS_T_FLANGE = 15e-3
    end

    methods

        function Obj = PostLoadChecks(varargin)
            Obj = assign_varargin_2_classprop(Obj, varargin{:});

            Obj.LogHandler = logging.CellArrayHandler();
            Obj.Logger.add_handler(Obj.LogHandler);
        end

        function throw_error(Obj)
            isErrorMessage = cellfun(@(x) isequal(logging.Level.ERROR, x.level), Obj.LogHandler.buffer);
            if any(isErrorMessage)
                Obj.Logger.error('One or more post-load checks failed. Please read the above error message(s)');
            end
        end

        function run(Obj)

            Obj.check_flange_type();
            Obj.check_diameter();
            Obj.check_input_bolt_circle_diameter();
            Obj.check_boltfls_petersen_for_t_flange();
            Obj.check_boltfls_sgre2_expected_assessments();
            Obj.check_fillet_radius();
            Obj.check_tilt_angle_for_flange_type();
            Obj.check_scaling_levels_increasing();
            Obj.check_z_flange_load_scaling_levels();
            Obj.check_s1_load_scaling_levels_range();

            Obj.throw_error();
        end

        function check_flange_type(Obj)
            % Warn if input flangeType does not match with StructuralModel.
            % Modify the inputs in the CompareToolInputsToStructuralModel object
            % slightly for convenient comparison:
            %   L or T -> L-flange or T-flange
            %   empty  -> still empty

            hasStrMdl = ~isempty(Obj.Inputs.structureInpFilePath);
            if ~hasStrMdl
                return
            end

            Comp = CompareToolInputsToStructuralModel(USAIN.TOOL_NAME, Obj.Inputs, Obj.Inputs.StrMdl);

            varName = 'flangeType';
            varInpUnit = '[-]';
            Comp.ToolInputs.(varName) = replace(Comp.ToolInputs.(varName), {'L', 'T'}, {'L-flange', 'T-flange'});
            for iEl = 1:numel(Obj.iElem)
                [pass, msg] = Comp.compare(varName, varInpUnit, 'elemType', Obj.iElem(iEl));
                if ~pass
                    Obj.Logger.warning(msg{:});
                end
            end
        end

        function check_diameter(Obj)
            % Check diameter with respect to StructuralModel
            % L-flanges and T-flange with reference point `outneck` should have matching diameter.
            % A T-flange with reference point `outermost` should not have matching diameter with StructuralModel, it
            % should be larger!

            hasStrMdl = ~isempty(Obj.Inputs.structureInpFilePath);
            if ~hasStrMdl
                return
            end

            isOutermostTflange = Obj.Inputs.diameterReference == "outermost" && Obj.Inputs.flangeType == "T";
            Comp = CompareToolInputsToStructuralModel(USAIN.TOOL_NAME, Obj.Inputs, Obj.Inputs.StrMdl);

            varName = 'diameter';
            varInpUnit = '[mm]';
            for iEl = 1:numel(Obj.iElem)
                thisMdlVar = sprintf('diam%s', iif(iEl < numel(Obj.iElem), 'Top', 'Bot'));
                [isEqual, msg] = Comp.compare(varName, varInpUnit, thisMdlVar, Obj.iElem(iEl));

                if isOutermostTflange && isEqual
                    msg = {'A T-flange with "outermost" diameterReference should not have a diameter input ', ...
                        'equal to the outer diameter of the adjacent plate in StructuralModel!\n', ...
                        'Proceeding with user input!'};
                    pass = false;
                elseif ~isEqual
                    pass = false;
                else
                    pass = true;
                end

                if ~pass
                    Obj.Logger.warning(msg{:});
                end
            end
        end

        function check_input_bolt_circle_diameter(Obj)
            % Check if user provided bolt circle diameter makes sense with respect to main diameter and width
            if isnan(Obj.Inputs.diamBoltCircle)
                return
            end

            if all(isnan(Obj.Inputs.maxFlangeWidth))
                % Determine max possible width
                Thickness = usain.space.FlangeThickness();
                maxWidth = Thickness.calc_max_flange_thickness(Obj.Inputs);
            else
                maxWidth = Obj.Inputs.maxFlangeWidth;
            end

            diameterOut = usain.space.FlangeWidth.calc_diameter_outer_most(Obj.Inputs.diameter, ...
                Obj.Inputs.diameterReference, maxWidth, Obj.Inputs.thicknNoseUp, Obj.Inputs.flangeType);
            diameterIn = usain.model.SegmentModel.calc_inner_diameter(diameterOut, maxWidth);

            pass = Obj.Inputs.diamBoltCircle > diameterIn & Obj.Inputs.diamBoltCircle < Obj.Inputs.diameter;
            % Note that here Inputs.diameter is used as upper limit. In case of a T-flange with "outermost" as
            % reference, the maximum possible bolt circle diameter is dictated by the minimum flange width. However,
            % to already go that far in the design space calculations is deemed a bit overkill at this point in the run.
            if ~any(pass)
                Obj.Logger.error(['Input "diamBoltCircle" is not within a feasible flange width range ', ...
                    '(user input or calculated).\nPlease revise the inputs.'], ...
                    abortOnError = false);
            end
        end

        function check_boltfls_petersen_for_t_flange(Obj)
            % Verify `petersen` is only used for T-flanges
            isPetersen = any([Obj.Inputs.BoltFls.BOLT_FORCE_MODEL] == "petersen");
            isTflange = strcmp(Obj.Inputs.flangeType, 'T');

            if isPetersen && ~isTflange
                Obj.Logger.warning(['An FLS assessment with the "petersen" model is requested for an L-flange.\n', ...
                    'Petersen is expected only to be used for T-flanges!']);
            end

            if ~isPetersen && isTflange
                Obj.Logger.warning(['A design for T-flange is requested, but not using the "petersen" model.\n', ...
                    'For T-flanges it is expected to use the "petersen" model for FLS.\n', ...
                    'Note: the design must adhere to the (current) applicable design brief, if that indicates a ', ...
                    'different model for T-flanges, that one should be used for certification.']);
            end
        end

        function check_boltfls_sgre2_expected_assessments(Obj)
            % Verify if "sgre2" is used that other expected assessments are performed as well
            isSgre2 = any([Obj.Inputs.BoltFls.BOLT_FORCE_MODEL] == "sgre2");

            if ~isSgre2
                % This check is only relevant for USAIN runs where `sgre2` is used
                return
            end

            if ~Obj.Inputs.DO_ASSESS_ULS
                Obj.Logger.warning(['An FLS assessment with "sgre2" is requested, but no ULS will be assessed.\n', ...
                  'The precondition for SGRE2.0, that failure mode A (T-flange) or B (L-flange) is governing, ', ...
                  'will not be checked.']);
            end

            if ~Obj.Inputs.DO_ASSESS_BOLT_PLASTICITY
                Obj.Logger.warning(['An FLS assessment with "sgre2" is requested, ', ...
                  'while input DO_ASSESS_BOLT_PLASTICITY is set to false.\n', ...
                  'This precondition for SGRE2.0 will not be checked.']);
            end

            isLflange = Obj.Inputs.flangeType == usain.inputs.FlangeType.L;
            if isLflange && ~Obj.Inputs.DO_ASSESS_FLANGE_PLASTICITY
                Obj.Logger.warning(['An FLS assessment with "sgre2" for an L-flange is requested, ', ...
                    'while input DO_ASSESS_FLANGE_PLASTICITY is set to false.\n', ...
                    'This precondition for SGRE2.0 will not be checked.']);
            end
        end

        function check_fillet_radius(Obj)

            if Obj.Inputs.flangeType == 'L'
                expectedMin = Obj.EXPECTED_MIN_FILLET_RADIUS_L_FLANGE;
            else
                expectedMin = Obj.EXPECTED_MIN_FILLET_RADIUS_T_FLANGE;
            end

            if Obj.Inputs.FILLET_RADIUS < expectedMin
                Obj.Logger.warning(['Input "FILLET_RADIUS" is set to a too low value.\n', ...
                    'The expected minimum is 10mm for an L-flange and 15mm for a T-flange.\n', ...
                    'A lower value is unexpected and requires a seperate damage assessment by FEA!']);
            end
        end

        function check_tilt_angle_for_flange_type(Obj)
            % As flange tilt is unfavorable for T-flanges, always expect a value > 0 for T-flanges with `sgre2`

            isSgre2 = any([Obj.Inputs.BoltFls.BOLT_FORCE_MODEL] == "sgre2");
            if ~isSgre2
                % This check is only relevant for USAIN runs where `sgre2` is used
                return
            end

            isTflange = strcmp(Obj.Inputs.flangeType, 'T');
            hasPositiveTilt = Obj.Inputs.SGRE2.FLANGE_TILT_VALUE > 0;
            if isTflange && ~hasPositiveTilt
                Obj.Logger.warning('For T-flanges, a positive value for input SGRE2.FLANGE_TILT_VALUE is expected.');
            end
        end

        function check_scaling_levels_increasing(Obj)
            % Check if the Loads.*scalingLevel are increasing
            % NOTE: This is done as a post-load check, because in the input file the scaling levels may contain
            % reference levels like `towerTop`.

            nLoadSets = length(Obj.Inputs.Loads.ulsScalingLevel);
            varNames = ["ulsScalingLevel", "flsScalingLevel", "S1ScalingLevel"];

            for i = 1:nLoadSets
                for varName = varNames
                    scalingLevel = Obj.Inputs.Loads.(varName){i};

                    if ~all(diff(scalingLevel) >= 0)
                        Obj.Logger.error('Loads(%i).%s must be increasing.', i, varName, ...
                            abortOnError = false);
                    end
                end
            end
        end

        function check_z_flange_load_scaling_levels(Obj)
            % Warn if zFlange is not covered by load scaling levels

            nLoadSets = sum(~cellfun(@isempty, Obj.Inputs.Loads.ulsFilePath));
            doChecksForUls = usain.loads.Loads.check_is_required_uls(Obj.Inputs);
            doChecksForFls = usain.loads.Loads.check_is_required_fls(Obj.Inputs);
            hasUlsOverride = Obj.Inputs.ULS_BENDING_MOMENT > 1e-6;

            for iLoadSet = 1:nLoadSets

                varNames = {'Loads.ulsScalingLevel', 'Loads.flsScalingLevel'};
                checkUlsZlevel = doChecksForUls && ~hasUlsOverride;
                varNames = varNames([checkUlsZlevel doChecksForFls]);

                z = Obj.Inputs.zFlange;
                for var = varNames
                    thisLevels = getsubfield(Obj.Inputs, var{1});

                    if z > max(thisLevels{iLoadSet}) || z < min(thisLevels{iLoadSet})
                        Obj.Logger.warning(['Input "zFlange" is not covered by the extremas in input "%s", ', ...
                          'for Loads.* input block %i. Extrapolation will be applied.'], var{1}, iLoadSet);
                    end
                end
            end
        end

        function check_s1_load_scaling_levels_range(Obj)
            % Warn if zFlange is not covered by S1 load scaling levels

            % Return if this run has no active conditions that require S1 loads
            doChecksForS1 = usain.loads.Loads.check_is_required_s1(Obj.Inputs);
            if ~doChecksForS1
                return
            end

            for iLoadSet = find(~cellfun(@isempty, Obj.Inputs.Loads.S1FilePath(:)'))
                z = Obj.Inputs.zFlange;
                if ~is_overlapping(Obj.Inputs.Loads.S1ScalingLevel{iLoadSet}, [z z])
                    Obj.Logger.warning( ...
                        ['Input "zFlange" is not covered by "Loads.S1ScalingLevel", for load set #%i. ', ...
                        'Extrapolation will be applied.'], ...
                        iLoadSet);
                end
            end
        end

    end

end
