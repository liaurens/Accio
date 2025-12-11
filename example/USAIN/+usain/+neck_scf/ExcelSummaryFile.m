classdef ExcelSummaryFile < matlab.mixin.SetGet

    properties
        Excel XlsFile
        FilePath pathlib.Path
    end

    properties (Constant, Hidden)
        TEMPLATE_PATH = pathlib.Path(which('USAIN')).parent / 'Templates' / 'flange-neck-scf-summary_TEMPLATE.xlsx'
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
            Obj.Excel.save_and_quit_excel();
        end

        function fill_sheet(Obj, Condition)

            forceGapping = Condition.BendOpen.calc_gapping_force();

            Obj.write_named_range('run_name', Condition.Mdl.Inputs.runName);
            Obj.write_named_range('run_timestamp', datestr(now()));

            Obj.write_named_range('radius_shell_1', Condition.BendStif.rNose(1), Unit.mm);
            Obj.write_named_range('radius_shell_2', Condition.BendStif.rNose(2), Unit.mm);
            Obj.write_named_range('thickness_shell_1', Condition.BendStif.thkNose(1), Unit.mm);
            Obj.write_named_range('thickness_shell_2', Condition.BendStif.thkNose(2), Unit.mm);
            Obj.write_named_range('flange_thickness', Condition.BendStif.thk, Unit.mm);
            Obj.write_named_range('a_eff_1', Condition.BendOpen.aEff(1), Unit.mm);
            Obj.write_named_range('a_eff_2', Condition.BendOpen.aEff(2), Unit.mm);
            Obj.write_named_range('b_1', Condition.BendOpen.b(1), Unit.mm);
            Obj.write_named_range('b_2', Condition.BendOpen.b(2), Unit.mm);
            Obj.write_named_range('c_1', Condition.BendOpen.c(1), Unit.mm);
            Obj.write_named_range('c_2', Condition.BendOpen.c(2), Unit.mm);
            Obj.write_named_range('e_mod', Condition.BendStif.eMod, Unit.MPa);
            Obj.write_named_range('nu', Condition.BendStif.nu);
            Obj.write_named_range('lambda_1', Condition.BendStif.geomParam(1), Unit.one_mm);
            Obj.write_named_range('lambda_2', Condition.BendStif.geomParam(2), Unit.one_mm);
            Obj.write_named_range('K_1', Condition.BendStif.flexRigdty(1), Unit.Nmm);
            Obj.write_named_range('K_2', Condition.BendStif.flexRigdty(2), Unit.Nmm);
            Obj.write_named_range('radius_rb', Condition.BendStif.rRb, Unit.mm);
            Obj.write_named_range('width_rb', Condition.BendStif.wRb, Unit.mm);
            Obj.write_named_range('height_rb', Condition.BendStif.hRb, Unit.mm);
            Obj.write_named_range('preload', Condition.BendOpen.preload, Unit.kN);
            Obj.write_named_range('stiffness_bolt', Condition.BendOpen.stiffnBolt, Unit.N_mm);
            Obj.write_named_range('load_factor', Condition.BendOpen.loadFactor);
            Obj.write_named_range('omega_1', Condition.BendOpen.omega(1), Unit.mm3);
            Obj.write_named_range('omega_2', Condition.BendOpen.omega(2), Unit.mm3);
            Obj.write_named_range('force_gapping_1', forceGapping(1), Unit.kN);
            Obj.write_named_range('force_gapping_2', forceGapping(2), Unit.kN);
            Obj.write_named_range('sn_curve_eqv_scf', Condition.SnCurve.label);
            Obj.write_named_range('eqv_scf_in_up', Condition.scfEqv(1, 1));
            Obj.write_named_range('eqv_scf_in_lo', Condition.scfEqv(2, 1));
            Obj.write_named_range('eqv_scf_out_up', Condition.scfEqv(3, 1));
            Obj.write_named_range('eqv_scf_out_lo', Condition.scfEqv(4, 1));

            x0StiffEcc = Condition.BendStif.calc_local_origin();
            x0Opening = Condition.BendOpen.calc_local_origin();
            Obj.write_named_range('x0_stiff_ecc', x0StiffEcc(1), Unit.mm);
            Obj.write_named_range('x0_rot', x0Opening(1), Unit.mm);
            Obj.write_named_range('x_weld_toe_1', Condition.BendStif.xWeldToe(1), Unit.mm);
            Obj.write_named_range('x_weld_toe_2', Condition.BendStif.xWeldToe(2), Unit.mm);

            % Store nominal stress and bending stress at weld toe, for 15 moment levels equally spaced between the -1
            % and 1 times max FLS
            moment = linspace(-1, 1, 14)' * max(Condition.Mdl.Loads.maxFlsMxy);
            [sNominal, sBending, sBendingOpen, sBendingStif] = Condition.calc_stress_transfer_funcs(moment);
            scf = 1 + sBending ./ ([sNominal, sNominal]);
            scfOpen = 1 + sBendingOpen ./ ([sNominal, sNominal]);
            scfStif = 1 + sBendingStif ./ ([sNominal, sNominal]);
            Obj.write_named_range('stress_nom_in', sNominal(:, 1), Unit.MPa);
            Obj.write_named_range('stress_nom_out', sNominal(:, 2), Unit.MPa);
            Obj.write_named_range('scf_in_1', scf(:, 1));
            Obj.write_named_range('scf_in_2', scf(:, 2));
            Obj.write_named_range('scf_out_1', scf(:, 3));
            Obj.write_named_range('scf_out_2', scf(:, 4));
            Obj.write_named_range('scf_open_in_1', scfOpen(:, 1));
            Obj.write_named_range('scf_open_in_2', scfOpen(:, 2));
            Obj.write_named_range('scf_open_out_1', scfOpen(:, 3));
            Obj.write_named_range('scf_open_out_2', scfOpen(:, 4));
            Obj.write_named_range('scf_stif_in_1', scfStif(:, 1));
            Obj.write_named_range('scf_stif_in_2', scfStif(:, 2));
            Obj.write_named_range('scf_stif_out_1', scfStif(:, 3));
            Obj.write_named_range('scf_stif_out_2', scfStif(:, 4));

            % Store data for stress path plots. Use a fine path discretization in the flange neck, and a coarser one
            % extending to 1m away from the flange mating surface.
            xGlob = unique(sort([ ...
                linspace(Condition.BendOpen.thk, 1, 10), ...
                linspace(Condition.BendOpen.thk, Condition.BendOpen.xWeldToe(1), 5)
                ]))';
            nPaths = 4;
            [sNominal, sBending] = Condition.calc_stress_path(max(Condition.Mdl.Loads.maxFlsMxy), xGlob, nPaths);
            scf = 1 + sBending ./ ([sNominal, sNominal]);
            Obj.write_named_range('x_path', xGlob, Unit.mm);
            Obj.write_named_range('stress_nom_path_1', sNominal(:, 1)', Unit.MPa);
            Obj.write_named_range('scf_path_in_1', squeeze(scf(:, 1, :))');
            Obj.write_named_range('scf_path_in_2', squeeze(scf(:, 2, :))');
            Obj.write_named_range('scf_path_out_1', squeeze(scf(:, 3, :))');
            Obj.write_named_range('scf_path_out_2', squeeze(scf(:, 4, :))');
        end

        function write_named_range(Obj, namedRange, value, Units)
            if nargin < 4
                Units = Unit.NO_DIM;
            end
            Obj.Excel.write_named_range(Units.from_si(value), namedRange);
        end

    end

end
