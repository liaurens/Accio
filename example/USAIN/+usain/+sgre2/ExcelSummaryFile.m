classdef ExcelSummaryFile < matlab.mixin.SetGet

    properties
        Excel XlsFile
        FilePath pathlib.Path
    end

    properties (Constant, Hidden)
        TEMPLATE_PATH = pathlib.Path(which('USAIN')).parent / 'Templates' / 'sgre2-summary_TEMPLATE.xlsx'
    end

    methods

        function Obj = ExcelSummaryFile(filePath)
            Obj.FilePath = filePath;
        end

        function set.FilePath(Obj, value)
            assert(~pathlib.Path(value).exists(), 'File %s already exists.', value);
            Obj.FilePath = pathlib.Path(value);
        end

        function open_excel_file(Obj)
            copyfile(char(Obj.TEMPLATE_PATH), char(Obj.FilePath), 'f');
            Obj.Excel = XlsFile(char(Obj.FilePath));
        end

        function save_excel_file(Obj)
            % Set workbook to read-only and save
            Obj.Excel.save_and_quit_excel();
        end

        function create_sheets(Obj, gapAngles)

            nGapAngle = length(gapAngles);
            % First make copies of the existing (single) sheet and then rename them. This is done in separate for-loops
            % because we don't control if the `Copy()` method adds a copy before or after the reference sheet.
            for iAngle = 2:nGapAngle
                Obj.Excel.Workbook.Sheets.Item(1).Copy(Obj.Excel.Workbook.Sheets.Item(1));
            end
            for iAngle = 1:nGapAngle
                Obj.Excel.Workbook.Sheets.Item(iAngle).Name = compose("%.0f deg", rad2deg(gapAngles(iAngle)));
            end
        end

        function fill_sheet(Obj, iSheet, Condition, Inputs)
            Obj.Excel.activate_sheet(iSheet);

            Segment = Condition.BoltForceModel.Segment;

            [x, y] = Condition.BoltForceModel.calc_polynomial_coords(Inputs);

            maxFlsMoment = max(Condition.Mdl.Loads.maxFlsMxy + Condition.Mdl.Loads.inclinMomentFlsDesign);
            % TODO: Separately report maxFlsMxy and inclinMomentFlsDesign upon next Excel file update
            maxSegmentForce = Condition.Mdl.Segment.calc_segment_force( ...
                maxFlsMoment, -Condition.Mdl.Loads.deadWeightFavorDesign);
            maxBoltForce = Condition.BoltForceModel.calc_bolt_force(maxSegmentForce);

            Obj.write_named_range('creation_date', datestr(now()));
            Obj.write_named_range('analysis_name', Inputs.runName);
            Obj.write_named_range('flange_type', char(Segment.FlangeType));
            Obj.write_named_range('tower_diameter', Segment.diameterOutNeck, Unit.mm);
            Obj.write_named_range('wall_thickness_upper', Segment.neckThicknessUp, Unit.mm);
            Obj.write_named_range('wall_thickness_lower', Segment.neckThicknessLo, Unit.mm);
            Obj.write_named_range('a', Segment.a, Unit.mm);
            Obj.write_named_range('a_effective', Segment.aEffective, Unit.mm);
            Obj.write_named_range('a_star', Condition.BoltForceModel.aModified, Unit.mm);
            Obj.write_named_range('b', Segment.b, Unit.mm);
            Obj.write_named_range('t_flange', Segment.flangeThickness, Unit.mm);
            Obj.write_named_range('bolt_diameter', Condition.Mdl.Bolt.diam, Unit.mm);
            Obj.write_named_range('del', Condition.Mdl.Loads.delDesign, Unit.kNm);
            Obj.write_named_range('del_m', Inputs.DEL_WOHLER_SLOPE);
            Obj.write_named_range('del_nref', Inputs.DEL_REF_CYCLES);
            Obj.write_named_range('max_fls_moment', maxFlsMoment, Unit.MNm);
            Obj.write_named_range('max_segment_force', maxSegmentForce, Unit.kN);
            Obj.write_named_range('max_bolt_force', maxBoltForce, Unit.kN);
            Obj.write_named_range('dead_weight', Condition.Mdl.Loads.deadWeightFavorDesign, Unit.kN);
            Obj.write_named_range('dead_weight_segment', Condition.BoltForceModel.deadWeight, Unit.kN);
            Obj.write_named_range('gap_angle', Condition.BoltForceModel.GapModel.Gap.angle, Unit.deg);
            Obj.write_named_range('gap_height', Condition.BoltForceModel.GapModel.Gap.height, Unit.mm);
            Obj.write_named_range('gap_length', Condition.BoltForceModel.GapModel.Gap.len, Unit.mm);
            Obj.write_named_range('tilt_angle', Condition.BoltForceModel.GapModel.Tilt.angle, Unit.deg);
            Obj.write_named_range('preload', Condition.BoltForceModel.preload, Unit.kN);
            Obj.write_named_range('preload_gap_close', Condition.BoltForceModel.forceGapClose, Unit.kN);
            Obj.write_named_range('preload_ratio', Condition.BoltForceModel.preloadRatio);
            Obj.write_named_range('load_factor', Segment.loadFactor);
            Obj.write_named_range('stress_area', Condition.Mdl.Bolt.areaStress, Unit.mm2);
            Obj.write_named_range('bolt_string', Condition.Mdl.Bolt.label);
            Obj.write_named_range('nbolts', Segment.nSegments);
            Obj.write_named_range('gap_close_factor', Condition.BoltForceModel.GapModel.gapCloseFactor);
            Obj.write_named_range('shell_stiffness_method', Inputs.SGRE2.SHELL_STIFFNESS_METHOD);
            Obj.write_named_range('shell_stiffness', Condition.BoltForceModel.GapModel.stiffnessShell, Unit.N_mm_mm);
            Obj.write_named_range('initial_point', Inputs.SGRE2.INITIAL_POINT_OFFSET);
            Obj.write_named_range('initial_slope_reference_preload', Inputs.SGRE2.INITIAL_SLOPE_REFERENCE_PRELOAD);
            Obj.write_named_range('bending_contribution', Condition.bendingContribution);
            Obj.write_named_range('stiffness_correction_factor', Condition.BoltForceModel.stiffnessCorrectionFactor);
            Obj.write_named_range('z_1', x(1), Unit.kN);
            Obj.write_named_range('z_2', x(2), Unit.kN);
            Obj.write_named_range('z_3', x(3), Unit.kN);
            Obj.write_named_range('fs_1', y(1), Unit.kN);
            Obj.write_named_range('fs_2', y(2), Unit.kN);
            Obj.write_named_range('fs_3', y(3), Unit.kN);
            Obj.write_named_range('z_max_tot', Condition.summaryData.z_max_tot(:), Unit.kN);
            Obj.write_named_range('z_min_tot', Condition.summaryData.z_min_tot(:), Unit.kN);
            Obj.write_named_range('fs_max', Condition.summaryData.fs_max(:), Unit.kN);
            Obj.write_named_range('ms_max', Condition.summaryData.ms_max(:), Unit.Nm);
            Obj.write_named_range('smax_ax', Condition.summaryData.smax_ax(:), Unit.MPa);
            Obj.write_named_range('smax_ben', Condition.summaryData.smax_ben(:), Unit.MPa);
            Obj.write_named_range('damage', Condition.summaryData.damage(:));
            Obj.write_named_range('initial_slope_force_curve', Condition.BoltForceModel.initialSlopeForceCurve);
            Obj.write_named_range('min_bolt_force', Condition.BoltForceModel.minBoltForce, Unit.kN);
            Obj.write_named_range('initial_slope_moment_curve', Condition.BoltForceModel.initialSlopeMomentCurve, Unit.mm);  % mh:ignore_style
            Obj.write_named_range('min_bolt_moment', Condition.BoltForceModel.minBoltMoment, Unit.Nm);
            Obj.write_named_range('target_pm_sum', Condition.Mdl.Inputs.BoltFls(Condition.iBoltFls).TARGET_PM_SUM);
            Obj.write_named_range('normalized_pm_sum', Condition.utilRatio);
            Obj.write_named_range('polynomial_coeff_0', Condition.BoltForceModel.polynomialCoeffs(1) ./ 1e3);
            Obj.write_named_range('polynomial_coeff_1', Condition.BoltForceModel.polynomialCoeffs(2));
            Obj.write_named_range('polynomial_coeff_2', Condition.BoltForceModel.polynomialCoeffs(3) .* 1e3);
            % NOTE: Polynomial coefficients are converted because USAIN uses SI-units (N) and the Excel sheet shows kN
            Obj.write_named_range('bolt_yield_strength_nom', Condition.Mdl.Bolt.yieldStrengthNominal, Unit.MPa);
            Obj.write_named_range('axial_resilience_bolt', Segment.resilienceBoltAxial);
            Obj.write_named_range('axial_resilience_clamped_parts', Segment.resilienceClampedParts);
            Obj.write_named_range('bending_resilience_bolt', Segment.resilienceBoltBending ./ 1e3);
            % NOTE: Bending resilience unit is 1/Nmm, but that's not in the Unit class
            Obj.write_named_range('flatness_tolerance_1m', Inputs.SGRE2.FLATNESS_TOLERANCE, Unit.mm);
            Obj.write_named_range('area_circumferential', Segment.areaCircumferential, Unit.mm2);
            Obj.write_named_range('area_tangential', Segment.areaTangential, Unit.mm2);
            Obj.write_named_range('inertia_gap_closing', Segment.inertiaGapClosing, Unit.mm4);
            Obj.write_named_range('inertia_flange_rotation', Segment.inertiaFlangeRotation, Unit.mm4);
            Obj.write_named_range('stiffness_gap_total', Condition.BoltForceModel.GapModel.stiffnessGapTotal, Unit.N_mm_mm);  % mh:ignore_style
            Obj.write_named_range('stiffness_flange', Condition.BoltForceModel.GapModel.stiffnessFlange, Unit.N_mm_mm);
            Obj.write_named_range('stiffness_segment', Condition.BoltForceModel.GapModel.stiffnessSegment, Unit.N_mm_mm);  % mh:ignore_style
            Obj.write_named_range('force_parallel_gap_close', Condition.BoltForceModel.GapModel.forceParallelGapClose, Unit.kN);  % mh:ignore_style
            Obj.write_named_range('force_tilt_close', Condition.BoltForceModel.GapModel.forceTiltClose, Unit.kN);
            Obj.write_named_range('force_prying', Condition.BoltForceModel.GapModel.forcePrying, Unit.kN);
            Obj.write_named_range('force_gap_close_total', Condition.BoltForceModel.GapModel.forceGapClose, Unit.kN);
            Obj.write_named_range('segment_width', Segment.segmentWidth, Unit.mm);
            Obj.write_named_range('bolt_distance', Segment.boltDistance, Unit.mm);
        end

        function write_named_range(Obj, namedRange, value, Units)
            if nargin < 4
                Units = Unit.NO_DIM;
            end
            Obj.Excel.write_named_range(Units.from_si(value), namedRange);
        end

    end

end
