classdef FlangeNeckScf < UsainUtils.ICondition
    % Condition for flange neck SCF calculations (due to bending stresses)
    %   This condition is used to estimate stress concentrations on the tower
    %   wall close to the flange. Such stress concentrations arise from local
    %   bending; three contributions are considered:
    %   1. Flange acting as stiffener: The flange is locally preventing the
    %      shell to deform radially, which introduces bending. This contribution
    %      is present both under compression and under tension.
    %   2. Wall thickness change: Local bending due to the eccentricity. These
    %      two contributions are accurately determined at some distance from the
    %      flange, but deviations may occur very close to the flange (i.e. for
    %      short weld necks).
    %   3. Flange opening under tensile load: A rotation is imposed on the tower
    %      wall once the flange is opening, which is already happening at low
    %      load levels. Some approximations for this contribution are used, so
    %      it might not be very accurate - this needs to be determined based on
    %      comparison with FEA.

    properties
        SnCurve sn_curve.SnCurve % S-N curve for equivalent SCF and damage calculations
        sizeEffect double % Thickness effect for flange neck

        BendOpen UsainUtils.ShellBendingOpening
        BendStif UsainUtils.ShellBendingStiffener

        pmSumNorm double % Normalised PM-sum
        scfEqv double % Equivalent SCF (see calc_eqv_scf_iterative for definition)

        description string = "Flange neck bending stresses"
    end
    properties (Constant)
        TOGGLE_NAME = 'DO_ASSESS_FLANGE_NECK_SCF'

        % Column indices to select results pertaining to inside/outside and
        % upper/lower shell (i.e. x(:, I_UP_IN) would select result x evaluated
        % at the inside of the upper shell)
        I_IN_UP = 1
        I_IN_LO = 2
        I_OUT_UP = 3
        I_OUT_LO = 4
    end

    methods

        function Obj = FlangeNeckScf(varargin)
            Obj@UsainUtils.ICondition(varargin{:});
        end

        function bool = do_assess(Obj)
            % Overloads parent method `UsainUtils.ICondition.do_assess()`
            isLFlange = strcmp(Obj.Mdl.Inputs.flangeType, 'L');
            isSelectedModel = contains(class(Obj.Mdl), 'UsainUtils.SelectedModel');
            bool = Obj.Mdl.Inputs.(Obj.TOGGLE_NAME) && isLFlange && isSelectedModel;
        end

        function evaluate_condition(Obj)

            % Setup S-N curve and compute thickness correction
            Obj.SnCurve = Obj.setup_sn_curve(Obj.Mdl.Inputs.SN_CURVE_NECK);
            Obj.sizeEffect = Obj.calc_size_effect();

            % Setup instances for shell bending stress calculations
            Obj.BendOpen = UsainUtils.ShellBendingOpening();
            Obj.BendOpen.load_model(Obj.Mdl);
            Obj.BendStif = UsainUtils.ShellBendingStiffener();
            Obj.BendStif.load_model(Obj.Mdl);

            % Compute fatigue damage for all load sets
            nLoadSets = Obj.Mdl.Loads.nLoadSets;
            Obj.pmSumNorm = nan(4, nLoadSets);
            Obj.scfEqv = nan(4, nLoadSets);
            Obj.utilRatio = nan(1, nLoadSets);
            for iLoadSet = 1:nLoadSets

                % Compute PM-sum fatigue damage
                moment = Obj.Mdl.Loads.flsMxyDesign{iLoadSet} + Obj.Mdl.Loads.inclinMomentFlsDesign(iLoadSet);
                cycles = Obj.Mdl.Loads.flsCycles{iLoadSet};
                [pm, scf] = Obj.calc_pm_sum(moment, cycles);

                % Do the same with inverted mean values from the Markov matrix
                momentInv = Obj.Mdl.Loads.flsMxyDesignInv{iLoadSet} + Obj.Mdl.Loads.inclinMomentFlsDesign(iLoadSet);
                [pmInv, scfInv] = Obj.calc_pm_sum(momentInv, cycles);

                % Store worst-case in properties (for reporting)
                scfBothSpectra = [scf; scfInv];
                [maxPm, iMax] = max([pm; pmInv]);
                Obj.pmSumNorm(:, iLoadSet) = Obj.normalize_pm_sum(maxPm);
                Obj.scfEqv(:, iLoadSet) = arrayfun(@(i) scfBothSpectra(iMax(i), i), 1:4);
                Obj.utilRatio(1, iLoadSet) = max(Obj.pmSumNorm(:, iLoadSet));
            end

            % Print warning in case of potentially infeasible design(s)
            Obj.verify_feasibility();
        end

        function Sn = setup_sn_curve(~, label)
            % Convenience method to get an S-N curve
            FatigueParameters = fatigue_parameters.FatigueParameters();
            SnLib = FatigueParameters.SnCurveLib;
            Sn = SnLib.get_sn_curve(label);
        end

        function szEff = calc_size_effect(Obj)
            % Compute size effect (thickness correction)
            %
            % OUTPUT
            %   szEff: [double, 1*2] Thickness correction for upper and lower
            %          flange neck

            assert(~isempty(Obj.SnCurve), 'FlangeNeckScf:NoSnCurve', ...
                'Set up S-N curve first');

            szEff = [
                Obj.SnCurve.size_effect(Obj.Mdl.Inputs.thicknNoseUp), ...
                Obj.SnCurve.size_effect(Obj.Mdl.Inputs.thicknNoseLo)
                ];

        end

        function [sNomUp, sNomLo] = calc_nominal_stress(Obj, moment)
            % Computes nominal stress in shell
            %
            % INPUT
            %   moment: [double] Bending moment, usually a [N*2] range array
            %
            % OUTPUT
            %   sNom*: [double] Nominal stress in upper and lower shell

            % Compute section modulus of upper and lower shell, considering
            % thin-wall assumptions
            thk = [Obj.Mdl.Inputs.thicknNoseUp, Obj.Mdl.Inputs.thicknNoseLo];
            diamOutNeck = Obj.Mdl.diameterOutNeck;
            diamIn = diamOutNeck - 2 * thk;
            sectionMod = pi / 32 * (diamOutNeck.^4 - diamIn.^4) ./ diamOutNeck;

            % Apply macro-geometric stress effects and return nominal stress
            sNomUp = moment ./ sectionMod(1);
            sNomLo = moment ./ sectionMod(2);
        end

        function x = calc_stress_factor(Obj)
            % Computes factor to translate characteristic to design stresses
            %
            % OUTPUT:
            %   x:  [double, 1*2] Correction factor on (1) upper and (2) lower
            %       flange neck

            psf = Obj.Mdl.Inputs.PSF_CMPCLASS2_FLS * Obj.Mdl.Inputs.PSF_FLANGE_MATERIAL_FLS;
            x = Obj.sizeEffect * psf;
        end

        function [sBendIn, sBendOut] = calc_bending_stress(Obj, stress)
            % Computes bending stresses in flange neck / shell
            %
            % INPUT
            %   stress: [double, N*1] Nominal stress in upper flange
            %
            % OUTPUT
            %   sBend*: [double, N*2] Bending stress in flange neck. First
            %           column is for stresses in upper flange, second column
            %           for lower flange.

            % Compute bending stresses due to flange opening and due to the
            % stiffener effect
            [sOpenIn, sOpenOut] = Obj.BendOpen.solve(stress);
            [sStifIn, sStifOut] = Obj.BendStif.solve(stress);

            % Sum stresses to get the hotspot stress in the flange neck (i.e.
            % including SCF)
            sBendIn = sOpenIn + sStifIn;
            sBendOut = sOpenOut + sStifOut;
        end

        function [pm, scf] = calc_pm_sum(Obj, moment, cycles)
            % Computes PM-sum from applied fatigue bending moment spectra
            %
            % INPUT
            % - moment: [double, N*2] Moment ranges [min max] for N bins
            % - cycles: [double, N*1] Cycle count for N bins
            %
            % OUTPUT
            % - pm: [double, 1*4] PM-sum fatigue damage where each column
            %       represents one weld toe location, as indicated by static
            %       properties (e.g. I_IN_UP)
            % - scf: [double, 1*4] Equivalent SCF, see calc_eqv_scf_iterative

            % Compute nominal design stress
            % NOTE: Using s* as abbreviating prefix for stress variables
            [sNomUp, sNomLo] = Obj.calc_nominal_stress(moment);

            % Compute bending stresses, using only the nominal stress in the
            % upper flange neck. The shell bending calculations account for
            % assymetry already, so the nominal stress in the lower flange neck
            % is not needed here.
            [sBendInMin, sBendOutMin] = Obj.calc_bending_stress(sNomUp(:, 1));
            [sBendInMax, sBendOutMax] = Obj.calc_bending_stress(sNomUp(:, 2));

            % Reshape stress into [N*4] arrays where each column represents one
            % weld toe location, as indicated by static properties (e.g. I_IN_UP)
            sBendMin = [sBendInMin, sBendOutMin];
            sBendMax = [sBendInMax, sBendOutMax];
            sNomMin = [sNomUp(:, 1), sNomLo(:, 1), sNomUp(:, 1), sNomLo(:, 1)];
            sNomMax = [sNomUp(:, 2), sNomLo(:, 2), sNomUp(:, 2), sNomLo(:, 2)];

            % Compute hotspot stress range. Here, the nominal stress in the
            % lower neck is used to establish the hotspot stress for the lower
            % weld toes
            sHotspot = (sBendMax + sNomMax) - (sBendMin + sNomMin);
            scaling = Obj.calc_stress_factor();
            sHotspot = scaling([1 2 1 2]) .* sHotspot;

            % Compute damage sum
            pm = Obj.calc_damage_sum(Obj.SnCurve, sHotspot, cycles);

            % Compute equivalent SCF
            sNomDesign = scaling([1 2 1 2]) .* (sNomMax - sNomMin);
            scf = Obj.calc_eqv_scf_iterative(sNomDesign, cycles, pm);
        end

        function pm = normalize_pm_sum(Obj, pm)
            pm = pm ./ Obj.Mdl.Inputs.FlangeNeckScf.TARGET_PM_SUM;
        end

        function scf = calc_eqv_scf_iterative(Obj, stress, cycles, target)
            % Iteratively computes linear SCF
            % Theoretically, applying this SCF in STIFT (when using the same S-N
            % curve) would yield the same damage. However, the following details
            % lead to different damages in STIFT:
            % - USAIN computes nominal stress using thin-walled assumptions for
            %   the section modulus, while STIFT computes it exact.
            % - USAIN applies gravity loads, STIFT does not
            % - STIFT adds additional SCFs on top of this equivalent SCF, due to
            %   eccentricity and conical transitions
            %
            % Given these differences, the equivalent SCFs determined here are
            % still deemed representative for the severity of bending stresses.
            %
            % INPUT
            % stress: [N*M] Nominal stress (design value) for M details
            % cycles: [N*1] Number of cycles in bin
            % target: [1*M] Target value to find SCF for
            %
            % OUTPUT
            % scf: [1*M] SCF (linear) for which input nominal stresses yield the
            %      same damage as determined from (nonlinear) hotspot approach

            % Use Newton-Raphson solver to find f(x)=0, where x is the linear
            % SCF. The solution does not appear to be sensitive on the initial
            % guess (as long as it is positive), so take 1
            f = @(x, y) Obj.calc_damage_sum(Obj.SnCurve, x .* stress, cycles) - target;
            scf = Solvers.newton_singlevar(f, 1, []);
        end

        function pm = calc_damage_sum(~, SnCurve, stress, cycles)
            % Convenience method to calculate damage sum

            nAllow = SnCurve.calc_cycles_to_failure_mex(1e-6 * abs(stress));
            damage = cycles ./ nAllow;
            pm = sum(damage, 1);
        end

        function [stressNominal, stressBending, stressBendingOpening, stressBendingStiffener] = ...
                calc_stress_transfer_funcs(Obj, moment)
            % Returns nominal stress and bending stress at weld toe, for given applied moment.
            %
            % moment: [Nx1] Vector with applied moment(s)
            % stressNominal: [Nx2] Nominal stress at weld toe in upper (1) and lower (2) flange neck
            % stressBending: [Nx4] Bending stress at weld toe in inside upper (1), lower (2) and outside upper (3),
            %                lower (4) flange neck
            % stressBendingOpening, stressBendingStiffener: Same as `stressBending`, but considering the opening and
            %                stiffener effects separately

            % Compute nominal stresses for this range
            [sNomUp, sNomLo] = Obj.calc_nominal_stress(moment);
            stressNominal = [sNomUp, sNomLo];

            % Determine position "x" along shell, in local coordinate systems
            xGlob = Obj.BendOpen.xWeldToe; % NOTE: Same as Obj.BendStif.xWeldToe
            xOpen = xGlob - Obj.BendOpen.calc_local_origin();
            xStif = xGlob - Obj.BendStif.calc_local_origin();

            % Compute bending stress for all locations
            [sOpenIn, sOpenOut] = Obj.BendOpen.solve(stressNominal(:, 1), xOpen);
            [sStifIn, sStifOut] = Obj.BendStif.solve(stressNominal(:, 1), xStif);
            stressBending = [sOpenIn + sStifIn, sOpenOut + sStifOut];
            stressBendingOpening = [sOpenIn, sOpenOut];
            stressBendingStiffener = [sStifIn, sStifOut];
        end

        function [stressNominal, stressBending] = calc_stress_path(Obj, moment, xGlob, nPaths)
            % Returns nominal stress and bending stress at weld toe, for given applied moment.
            %
            % moment: [1x1] Max. applied moment for which stress path must be solved
            % xGlob:  [Nx1] X-coordinates (along flange neck, in global CS) at which stress must be solved
            % nPaths: [1x1] Number of paths to solve
            % stressNominal: [Nx2] Nominal stress at weld toe in upper (1) and lower (2) flange neck
            % stressBending: [Nx4] Bending stress at weld toe in inside upper (1), lower (2) and outside upper (3),
            %                lower (4) flange neck

            % Compute nominal stresses for this max. moment
            [sNomCharUp, sNomCharLo] = Obj.calc_nominal_stress(moment);
            eccRatio = sNomCharLo(1) / sNomCharUp(1);

            % Linearly distribute N=nPaths points for plotting
            stressNominal = [1, eccRatio] .* linspace(0, ceil(sNomCharUp / 10e6) * 10e6, nPaths)';

            % Add insignificant number to avoid getting NaNs if stressNominal = 0
            stressNominal(stressNominal == 0) = stressNominal(stressNominal == 0) + 1e-10;

            % Define position vector "x" along shell, in both global and local
            % coordinate systems
            xOpen = xGlob - Obj.BendOpen.calc_local_origin();
            xStif = xGlob - Obj.BendStif.calc_local_origin();

            % Compute bending stress for all locations
            [sOpenIn, sOpenOut] = Obj.BendOpen.solve(stressNominal(:, 1), xOpen);
            [sStifIn, sStifOut] = Obj.BendStif.solve(stressNominal(:, 1), xStif);
            stressBending = [sOpenIn + sStifIn, sOpenOut + sStifOut];
        end

        function Tf = plot_stress_transfer_funcs(Obj)

            % Get extrema of all bending moment ranges to determine limits for
            % which to plot transfer function. Note that the minimum bending
            % moment is not equal to the the negative of the maximum (because we
            % consider additional Fz from dead weight)
            momentMax = max(max(cat(1, Obj.Mdl.Loads.flsMxyDesign{:})));
            momentMin = min(min(cat(1, Obj.Mdl.Loads.flsMxyDesign{:})));

            % Linearly distribute N=50 points for plotting
            moment = linspace(momentMin, momentMax, 50)';

            % Compute nominal stress and bending stress at weld toe
            [sNom, sBend] = Obj.calc_stress_transfer_funcs(moment);

            % Set up StressTransferFunction object
            Tf = UsainUtils.StressTransferFunction(sNom, sBend, ...
                'thkNose', Obj.BendOpen.thkNose, 'xWeldToe', Obj.BendOpen.xWeldToe);
            Tf.plot('up');
            Tf.plot('lo');
        end

        function Tf = plot_stress_paths(Obj)

            % Get max of all bending moment ranges to upper limit for which to
            % plot stress path
            moment = max(max(abs(cat(1, Obj.Mdl.Loads.flsMxyDesign{:}))));

            % Define position vector "x" along shell, in both global and local
            % coordinate systems
            xGlob = (Obj.BendOpen.thk:0.05:1)';

            % Solve stress paths
            nPaths = 4;
            [sNom, sBend] = Obj.calc_stress_path(moment, xGlob, nPaths);

            % Set up StressTransferFunction object
            Tf = UsainUtils.BendingStressPath(xGlob, sNom, sBend, ...
                'thkNose', Obj.BendOpen.thkNose, 'xWeldToe', Obj.BendOpen.xWeldToe);
            Tf.plot('up');
            Tf.plot('lo');
        end

        function report_results(Obj)
            % Logs calculation results

            % Shortcuts
            nLoadSets = Obj.Mdl.Loads.nLoadSets;
            snStr = sprintf('(%s)', Obj.Mdl.Inputs.SN_CURVE_NECK);

            str = cell(nLoadSets + 1, 1);
            for iLoadSet = 1:nLoadSets
                pm = Obj.pmSumNorm(:, iLoadSet);
                scf = Obj.scfEqv(:, iLoadSet);

                str{iLoadSet + 1} = { ...
                    sprintf('LOAD SET #%i', iLoadSet)
                    sprintf('WELD TOE              |  PM-SUM (NORM) |       EQV. SCF')
                    sprintf('LOCATIONS             | %14s | %14s', snStr, snStr)
                    '----------------------+----------------+---------------'
                    sprintf('Inside, upper flange  | %14.4f | %14.2f', pm(Obj.I_IN_UP), scf(Obj.I_IN_UP))
                    sprintf('Inside, lower flange  | %14.4f | %14.2f', pm(Obj.I_IN_LO), scf(Obj.I_IN_LO))
                    sprintf('Outside, upper flange | %14.4f | %14.2f', pm(Obj.I_OUT_UP), scf(Obj.I_OUT_UP))
                    sprintf('Outside, lower flange | %14.4f | %14.2f', pm(Obj.I_OUT_LO), scf(Obj.I_OUT_LO))
                    ''
                    ''
                    };
            end
            str{1} = sprintf('%s - INTERMEDIATE RESULTS\n', upper(Obj.description));

            msg = [string(cat(1, str{:})); ...
                "(PM-sum computed with bending SCF only. Other SCFs, such as from plate eccentricity, are excluded)"
                ""
              ];
            Obj.Logger.info('%s\n', msg{:});
        end

        function verify_feasibility(Obj)
            % This method issues a warning if the bending stresses appear to be
            % too high.
            % The feasibility threshold is set to SCF <= 1.2 and PM-sum <= 0.5.
            % If these limits are exceeded, the topic owners should be made
            % aware. As such, the topic owners can investigate if the flange
            % design is acceptable.
            % NOTE: The limits are rather strict as this flange design condition
            % is new and we need to get a feeling for what values to accept.

            isPotentiallyInfeasible = Obj.pmSumNorm > 0.50 & Obj.scfEqv > 1.2;
            if any(isPotentiallyInfeasible(:))
                Obj.warning('USAIN:FlangeNeckScf:InfeasibleDesign', ...
                    ['Excessive SCF and damage due to bending stresses in flange neck!\n', ...
                    'Please consider increasing the amount of bolts to the maximum value, ', ...
                    'and then proceed to increase the "a''" distance until this issue is resolved.', ...
                    '\n\n\t==> Contact topic owner in case you encounter further issues']);
            end
        end

    end
end
