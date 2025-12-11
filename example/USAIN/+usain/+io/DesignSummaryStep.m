classdef DesignSummaryStep < runner.BaseStep & logging.Loggable

    methods

        function Obj = DesignSummaryStep(varargin)

            Obj = assign_varargin_2_classprop(Obj, varargin{:});

            Obj.InputKeys.Inputs = usain.DataKeys.Inputs;
            Obj.InputKeys.SelectedConditionCollection = usain.DataKeys.SelectedConditionCollection;
            Obj.InputKeys.SelectedModel = usain.DataKeys.SelectedModel;
            Obj.InputKeys.hasFeasibleDesign = usain.DataKeys.hasFeasibleDesign;
        end

        function str = print_label(~)
            str = 'Report design summary';
        end

        function pass = is_active(Obj)
            passSuperclass = is_active@runner.BaseStep(Obj);
            hasFeasibleDesign = Obj.get(Obj.InputKeys.hasFeasibleDesign);
            pass = passSuperclass && ~hasFeasibleDesign;
        end

        function run(Obj)

            Inputs = Obj.get(usain.DataKeys.Inputs);
            SelectedConditionCollection = Obj.get(usain.DataKeys.SelectedConditionCollection);
            SelectedModel = Obj.get(usain.DataKeys.SelectedModel);

            fprintf('\n');  % print whitespace before showing header
            Obj.Logger.info('\t\tR E P O R T I N G   D E S I G N   S U M M A R Y\n\n');

            % Report results of tool-wall clash check, if any
            if ~isempty(Inputs.structureInpFilePath)
                ToolWallClash = UsainUtils.ToolToWallClashCheck.from_flange_model(SelectedModel);
                ToolWallClash.report_results();
            end

            % In case the L-flange geometry exceeds the limits of Tobinaga's research, notify the user
            if strcmpi(Inputs.REACTION_DISTANCE_METHOD, 'tobinaga') && SelectedModel.flangeType == 'L'
                SelectedModel.Segment.ReactDist.report_tobinaga_violation();
            end

            % In case the flange diameter at the neck exceeds the limit for which sgre2 gap height calculations are
            % valid, notify the user
            if any([Inputs.BoltFls.BOLT_FORCE_MODEL] == "sgre2")
                usain.sgre2.GapData().check_diameter_limitation(SelectedModel.diameterOutNeck);
            end

            for Condition = SelectedConditionCollection.iter_conditions()

                if isa(Condition, 'UsainUtils.ThreadRequirements') && Condition.doAssess
                    Condition.report_results();

                elseif isa(Condition, 'UsainUtils.FatigueLimitState') && Condition.doAssess
                    Condition.report_results();

                elseif isa(Condition, 'UsainUtils.UlsCondition') && Condition.doAssess
                    Condition.report_results();

                elseif isa(Condition, 'UsainUtils.FlangeNeckScf') && Condition.doAssess
                    % Log flange neck SCF results as this is not a part of DOCTOR
                    Condition.report_results();

                    % Plot stress transfer functions if this is enabled through inputs
                    if Inputs.PLOT_STRESS_TRANSFER_FUNCS
                        Obj.Logger.info('Plotting flange neck stresses vs. load level');
                        Condition.plot_stress_transfer_funcs();
                    end

                    if Inputs.PLOT_STRESS_PATHS
                        Obj.Logger.info('Plotting flange neck stress paths along wall');
                        Condition.plot_stress_paths();
                    end
                end
            end

            Obj.print_design_load_summary(SelectedModel);
            Obj.print_design_space_summary(SelectedModel);
            Obj.print_flange_model_summary(SelectedModel);
            Obj.print_mass_summary(SelectedModel);
            Obj.print_utilization_summary(SelectedConditionCollection);
        end

        function print_design_load_summary(Obj, SelectedModel)

            % Shortcuts
            Loads = SelectedModel.Loads;

            msg = sprintf("\t\tD E S I G N   L O A D   S U M M A R Y\n");
            for iLoadSet = 1:Loads.nLoadSets
                loadSetString = sprintf('LOAD SET #%i', iLoadSet);

                % Extract FLS moment and compute segment force, if FLS loads are loaded
                if isempty(Loads.maxFlsMxy)
                    maxFlsMoment = nan;  % Intentionally printing NaNs in summary in this case
                    segmentForceMaxFls = nan;
                else
                    maxFlsMoment = Loads.maxFlsMxy(iLoadSet);
                    segmentForceMaxFls = SelectedModel.Segment.calc_segment_force( ...
                        maxFlsMoment + Loads.inclinMomentFlsDesign(iLoadSet), -Loads.deadWeightFavorDesign);
                end

                % Extract ULS moment and compute segment force, if ULS loads are loaded
                if isempty(Loads.ulsMxyDesign)
                    ulsMoment = nan;  % Intentionally printing NaNs in summary in this case
                    segmentForceUls = nan;
                else
                    ulsMoment = Loads.ulsMxyDesign(iLoadSet);
                    segmentForceUls = SelectedModel.Segment.calc_segment_force( ...
                        ulsMoment + Loads.inclinMomentDesign(iLoadSet), -Loads.deadWeightFavorDesign);
                end

                % Extract S1 moment and compute segment force, if S1 loads are loaded
                if isempty(Loads.maxS1MomentDesign)
                    s1Moment = nan;  % Intentionally printing NaNs in summary in this case
                    segmentForceS1 = nan;
                else
                    s1Moment = Loads.maxS1MomentDesign(iLoadSet);
                    segmentForceS1 = SelectedModel.Segment.calc_segment_force( ...
                        s1Moment + Loads.inclinMomentDesign(iLoadSet), -Loads.deadWeightFavorDesign);
                end

                if isempty(Loads.Fdi)
                    fdi = [];
                else
                    fdi = Loads.Fdi(iLoadSet).fdi;
                end

                if isempty(Loads.FdiInverted)
                    fdiInverted = [];
                else
                    fdiInverted = Loads.FdiInverted(iLoadSet).fdi;
                end

                loadSetSummary = [
                    [trailing_dots(loadSetString),                     sprintf(' %9s', Loads.Inputs.Loads.tag{iLoadSet})]  % mh:ignore_style
                    [trailing_dots('    DEAD WEIGHT'),                 sprintf(' %9.1f kN', 1e-3 * Loads.deadWeightFavorDesignUls)]  % mh:ignore_style
                    [trailing_dots('    INCLINATION MOMENT (ULS, S1)'), sprintf(' %9.1f MNm', 1e-6 * Loads.inclinMomentDesign(iLoadSet))]  % mh:ignore_style
                    [trailing_dots('    INCLINATION MOMENT (FLS)'),    sprintf(' %9.1f MNm', 1e-6 * Loads.inclinMomentFlsDesign(iLoadSet))]  % mh:ignore_style
                    [trailing_dots('    ULS BENDING MOMENT'),          sprintf(' %9.1f MNm', 1e-6 * ulsMoment)]
                    [trailing_dots('    ULS SEGMENT FORCE'),           sprintf(' %9.1f kN', 1e-3 * segmentForceUls)]
                    [trailing_dots('    S1 BENDING MOMENT'),           sprintf(' %9.1f MNm', 1e-6 * s1Moment)]
                    [trailing_dots('    S1 SEGMENT FORCE'),            sprintf(' %9.1f kN', 1e-3 * segmentForceS1)]
                    [trailing_dots('    MAX. FLS BENDING MOMENT'),     sprintf(' %9.1f MNm', 1e-6 * maxFlsMoment)]  % mh:ignore_style
                    [trailing_dots('    MAX. FLS SEGMENT FORCE'),      sprintf(' %9.1f kN', 1e-3 * segmentForceMaxFls)]
                    [trailing_dots('    FDI (NORMAL SPECTRUM)'),       sprintf(' %9.4e', fdi)]
                    [trailing_dots('    FDI (INVERTED SPECTRUM)'),     sprintf(' %9.4e', fdiInverted)]
                    [trailing_dots('        COEFFICIENT A1'),          sprintf(' %9.2f', Loads.Inputs.FDI_COEFFICIENT_A1)]  % mh:ignore_style
                    [trailing_dots('        COEFFICIENT A2'),          sprintf(' %9.5f', Loads.Inputs.FDI_COEFFICIENT_A2)]  % mh:ignore_style
                    [trailing_dots('        WOHLER SLOPE M'),          sprintf(' %9.1f', Loads.Inputs.DEL_WOHLER_SLOPE)]
                    ""
                  ];
                msg = [msg; loadSetSummary];  %#ok
            end

            msg = [msg; ...
                "(values including PSF and macro-geometric SCF, excluding additional SCF)"
                "(inclination loads included in reported segment forces)"
                ""
              ];

            Obj.Logger.info('%s\n', msg{:});
        end

        function print_design_space_summary(Obj, SelectedModel)

            % Set up design variables from inputs, this will automatically contain the calculated bounds.
            Thickness = usain.space.FlangeThickness.from_inputs(SelectedModel.Inputs);
            Width = usain.space.FlangeWidth.from_inputs(SelectedModel.Inputs, ...
                [Thickness.CalculatedBounds.max_], SelectedModel.Segment.distForce);
            NumBolts = usain.space.NumberOfBolts.from_inputs(SelectedModel.Inputs, ...
                SelectedModel.diameterBoltCircle, SelectedModel.diameterBoltCircle);

            % Set up the selected design point as design_space.Bounds.
            SelectedThickness = design_space.Bounds(SelectedModel.Space.thickness, SelectedModel.Space.thickness);
            SelectedWidth = design_space.Bounds(SelectedModel.Space.width, SelectedModel.Space.width);
            SelectedNBolts = design_space.Bounds(SelectedModel.Space.nBolts, SelectedModel.Space.nBolts);

            % Perform the check if the selected point is within the calculated bounds.
            isInBoundsThickness = SelectedThickness.is_overlapping(Thickness.CalculatedBounds);
            isInBoundsWidth = SelectedWidth.is_overlapping(Width.CalculatedBounds);
            isInBoundsNBolts = SelectedNBolts.is_overlapping(NumBolts.CalculatedBounds);

            % Do something similar for the width-to-thickness ratio (without the helper methods)
            selectedWtRatio = SelectedModel.Space.width / SelectedModel.Space.thickness;
            minWtRatio = usain.space.FlangeWidth.min_width_to_thickness_ratio(SelectedModel.flangeType);
            maxWtRatio = usain.space.FlangeWidth.max_width_to_thickness_ratio(SelectedModel.flangeType);
            isInBoundsWtRatio = selectedWtRatio >= (minWtRatio - 1e-6) & selectedWtRatio <= (maxWtRatio + 1e-6);
            % NOTE: The `1e-6` is to prevent incorrect logical operations due to numerical round-off

            msg = {sprintf('\t\tD E S I G N   S P A C E   S U M M A R Y\n')};

            msg{end + 1} = sprintf( ...
                ['This check indicates if the selected design is within the internally\n', ...
                'calculated design space for this bolt option.\n']);

            printFormat = [' %-6s - ', 'range: [%.0f %.0f], value: %.0f'];
            nBoltsStatus = sprintf(printFormat, iif(isInBoundsNBolts, 'OK', 'NOT OK'), ...
                NumBolts.CalculatedBounds.min_, NumBolts.CalculatedBounds.max_, ...
                SelectedModel.Space.nBolts);
            msg{end + 1} = [trailing_dots('NUMBER OF BOLTS'), nBoltsStatus];

            thicknStatus = sprintf(printFormat, iif(isInBoundsThickness, 'OK', 'NOT OK'), ...
                1e3 * Thickness.CalculatedBounds.min_, 1e3 * Thickness.CalculatedBounds.max_, ...
                1e3 * SelectedModel.Space.thickness);
            msg{end + 1} = [trailing_dots('THICKNESS'), thicknStatus];

            widthStatus = sprintf(printFormat, iif(isInBoundsWidth, 'OK', 'NOT OK'), ...
                1e3 * Width.CalculatedBounds.min_, 1e3 * Width.CalculatedBounds.max_, ...
                1e3 * SelectedModel.Space.width);
            msg{end + 1} = [trailing_dots('WIDTH'), widthStatus];

            printFormat = [' %-6s - ', 'range: [%.1f %.1f], value: %.1f'];
            widthToThicknessStatus = sprintf(printFormat, iif(isInBoundsWtRatio, 'OK', 'NOT OK'), ...
                minWtRatio, maxWtRatio, selectedWtRatio);
            msg{end + 1} = [trailing_dots('WIDTH-TO-THICKNESS RATIO'), widthToThicknessStatus];

            msg{end + 1} = '';

            Obj.Logger.info('%s\n', msg{:});
        end

        function print_flange_model_summary(Obj, SelectedModel)

            FlangeOpening = UsainUtils.FlangeOpeningMechanics.from_flange_model(SelectedModel);
            aEff = FlangeOpening.calc_effective_a_parameter();
            innerDiameter = SelectedModel.Inputs.diamBoltCircle - 2 * SelectedModel.Segment.ReactDist.a;

            fastenerString = sprintf('%2i x %3i x %s', ...
                SelectedModel.flangeTypeFactor, SelectedModel.Space.nBolts, SelectedModel.Inputs.boltOptions{1});

            msg = { ...
                sprintf('\t\tM O D E L   S U M M A R Y\n')
                [trailing_dots('TYPE'),                        sprintf('%3s-flange', SelectedModel.flangeType)]
                [trailing_dots('WIDTH'),                       sprintf('%10g mm', 1e3 * SelectedModel.Space.width)]
                [trailing_dots('THICKNESS'),                   sprintf('%10g mm', 1e3 * SelectedModel.Space.thickness)]
                [trailing_dots('INNER WIDTH (A)'),             sprintf('%10.1f mm', 1e3 * SelectedModel.Segment.ReactDist.a)]  % mh:ignore_style
                [trailing_dots('EFFECTIVE INNER WIDTH (A'')'), sprintf('%10.1f mm', 1e3 * aEff)]
                [trailing_dots('OUTER WIDTH (B)'),             sprintf('%10.1f mm', 1e3 * SelectedModel.Segment.ReactDist.b)]  % mh:ignore_style
                [trailing_dots('OUTER DIAMETER NECK'),         sprintf('%10.1f mm', 1e3 * SelectedModel.diameterOutNeck)]  % mh:ignore_style
                [trailing_dots('BOLT CIRCLE DIAMETER'),        sprintf('%10.1f mm', 1e3 * SelectedModel.Inputs.diamBoltCircle)]  % mh:ignore_style
                [trailing_dots('INNER DIAMETER FLANGE'),       sprintf('%10.1f mm', 1e3 * innerDiameter)]
                [trailing_dots('OUTER DIAMETER FLANGE'),       sprintf('%10.1f mm', 1e3 * SelectedModel.diamOutFlange)]
                [trailing_dots('OUTER BOLT CIRCLE DIAMETER'),  sprintf('%10.1f mm', 1e3 * SelectedModel.bcdOut)]
                [trailing_dots('UPPER NECK THICKNESS'),        sprintf('%10.1f mm', 1e3 * SelectedModel.Inputs.thicknNoseUp)]  % mh:ignore_style
                [trailing_dots('LOWER NECK THICKNESS'),        sprintf('%10.1f mm', 1e3 * SelectedModel.Inputs.thicknNoseLo)]  % mh:ignore_style
                [trailing_dots('FASTENERS'),                   sprintf('%10s', fastenerString)]
                [trailing_dots('TIGHTENING METHOD'),           sprintf('%10s', char(SelectedModel.Inputs.tighteningMethod))]  % mh:ignore_style
                [trailing_dots('TEMPORARY STAGES TOOL TYPE'),  sprintf('%10s', char(SelectedModel.Inputs.TEMP_STAGES_TOOL_TYPE))]  % mh:ignore_style
                [trailing_dots('NUT'),                         sprintf('%10s', char(SelectedModel.Nut.label))]
                [trailing_dots('WASHER'),                      sprintf('%10s', char(SelectedModel.Wash.label))]
                [trailing_dots('BOLT EXTENDER LENGTH'),        sprintf('%10.1f mm', 1e3 * SelectedModel.Inputs.lengthBoltExtender)]  % mh:ignore_style
                ''
                };

            Obj.Logger.info('%s\n', msg{:});
        end

        function print_mass_summary(Obj, SelectedModel)

            totalMass = SelectedModel.massBoltAssm + SelectedModel.massFlangeUp + SelectedModel.massFlangeLo;

            % Print message
            msg = { ...
                sprintf('\t\tM A S S   S U M M A R Y\n')
                [trailing_dots('TOTAL MASS'),                  sprintf('%10.0f kg', totalMass)]
                [trailing_dots('    MASS UPPER FLANGE'),       sprintf('%10.0f kg', SelectedModel.massFlangeUp)]
                [trailing_dots('    MASS LOWER FLANGE'),       sprintf('%10.0f kg', SelectedModel.massFlangeLo)]
                [trailing_dots('    BOLT ASSEMBLY MASS'),      sprintf('%10.0f kg', SelectedModel.massBoltAssm)]
                [trailing_dots('    MASS UPPER STUB'),         sprintf('%10.0f kg', SelectedModel.massStubUp)]
                [trailing_dots('    MASS LOWER STUB'),         sprintf('%10.0f kg', SelectedModel.massStubLo)]
                ''
                };

            Obj.Logger.info('%s\n', msg{:});
        end

        function print_utilization_summary(Obj, ConditionCollection)

            msg = {sprintf('\t\tU T I L I Z A T I O N   S U M M A R Y\n')};

            for Condition = ConditionCollection.iter_conditions()
                description = char(upper(Condition.description));

                if Condition.doAssess
                    printFormat = [' %-6s - ', repmat('%6.3f ', 1, Condition.Mdl.Loads.nLoadSets)];
                    urStr = sprintf(printFormat, ...
                        iif(all(Condition.utilRatio <= Condition.targetUtilRatio), 'OK', 'NOT OK'), ...
                        Condition.utilRatio);
                else
                    urStr = sprintf(' %s', 'N.A.');
                end
                msg{end + 1} = [trailing_dots(description, 30), urStr]; %#ok<AGROW>
            end
            msg{end + 1} = '';

            Obj.Logger.info('%s\n', msg{:});
        end

    end

end
