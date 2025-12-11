classdef FatigueLimitState < UsainUtils.ICondition
    % Condition for FLS resistance of bolts in L- and T-flanges

    properties
        SnCurve sn_curve.SnCurve

        sizeEffect               % Thickness effect
        pmSumNorm                % Normalised PM-sum
        pmSumNormInv             % Normalised PM-sum (using inverse load spectrum)
        pmSum                    % Non-normalized PM-sum
        pmSumInv                 % Non-normalized PM-sum (using inverse load spectrum)
        iBoltFls                 % BoltFls block index
        BoltForceModel           % Bolt force curve, must be a concrete implementation of UsainUtils.BoltForceModel
    end
    properties (Dependent)
        description string
    end
    properties (Dependent)
        utilRatioGeomConstraint  % Util. ratio for Schmidt-Neuper constraint: (a+b/thickn) <= 3
    end
    properties (Constant)
        TOGGLE_NAME = 'DO_ASSESS_FLS'
    end

    methods

        function Obj = FatigueLimitState(iBoltFls, varargin)
            % Call superclass constructor
            Obj@UsainUtils.ICondition(varargin{:});
            Obj.iBoltFls = iBoltFls;
        end

        function setup_condition(Obj)
            Obj.setup_bolt_force_model();
        end

        function setup_bolt_force_model(Obj)
            % Set up bolt force model (Schmidt-Neuper or Petersen)
            Inputs = Obj.Mdl.Inputs;
            preloadFls = usain.fastener.get_preload( ...
                Obj.Mdl.Tool.defaultPreload, ...
                Inputs.BoltFls(Obj.iBoltFls).CUSTOM_PRELOAD, ...
                Inputs.BoltFls(Obj.iBoltFls).PRELOAD_LOSS_FACTOR_FLS);
            Obj.BoltForceModel = UsainUtils.BoltForceModelFactory().get_model(Obj.Mdl, ...
                Inputs.BoltFls(Obj.iBoltFls).BOLT_FORCE_MODEL, preloadFls);
        end

        function evaluate_condition(Obj)
            % EVALUATE_CONDITION Evaluates PM-sum fatigue damages

            % Setup S-N curve if not done already
            if isempty(Obj.SnCurve)
                Obj.SnCurve = Obj.setup_sn_curve();
            end
            Obj.sizeEffect = Obj.calc_size_effect();

            % Compute normalized PM-sums for both normal and inverse fatigue
            % load spectra, for each load set individually
            nLoadSets = Obj.Mdl.Loads.nLoadSets;
            [Obj.pmSumNorm, Obj.pmSumNormInv, Obj.pmSum, Obj.pmSumInv] = deal(cell(1, nLoadSets));
            Obj.utilRatio = nan(Obj.Mdl.Space.nPoints, nLoadSets);
            for iLoadSet = 1:nLoadSets

                cycles = Obj.Mdl.Loads.flsCycles{iLoadSet};
                moment = Obj.Mdl.Loads.flsMxyDesign{iLoadSet} + Obj.Mdl.Loads.inclinMomentFlsDesign(iLoadSet);

                pm = Obj.calc_pm_sum(moment, cycles);
                Obj.pmSum{iLoadSet} = pm;
                Obj.pmSumNorm{iLoadSet} = pm ./ Obj.Mdl.Inputs.BoltFls(Obj.iBoltFls).TARGET_PM_SUM;

                momentInv = Obj.Mdl.Loads.flsMxyDesignInv{iLoadSet} + Obj.Mdl.Loads.inclinMomentFlsDesign(iLoadSet);
                pm  = Obj.calc_pm_sum(momentInv, cycles);
                Obj.pmSumInv{iLoadSet} = pm;
                Obj.pmSumNormInv{iLoadSet} = pm ./ Obj.Mdl.Inputs.BoltFls(Obj.iBoltFls).TARGET_PM_SUM;

                % Assign most damaging results to Obj.utilRatio
                Obj.utilRatio(:, iLoadSet) = ...
                    max([Obj.pmSumNorm{iLoadSet}, Obj.pmSumNormInv{iLoadSet}], [], 2);
            end
        end

        function Sn = setup_sn_curve(Obj)
            % Returns S-N curve for bolts
            FatigueParameters = fatigue_parameters.FatigueParameters();
            SnLib = FatigueParameters.SnCurveLib;
            Sn = SnLib.get_sn_curve(Obj.Mdl.Inputs.BoltFls(Obj.iBoltFls).SN_CURVE_BOLT);

            % Set reference thickness equal to 30mm, as is applicable for bolts
            Sn.tRef = 30e-3;

            % Set thickness exponent based on expert input
            Sn.tExp =  Obj.Mdl.Inputs.BoltFls(Obj.iBoltFls).THICKNESS_EXPONENT_BOLT;
        end

        function szEff = calc_size_effect(Obj)
            assert(~isempty(Obj.SnCurve), 'Set up S-N curve first');
            szEff = Obj.SnCurve.size_effect(Obj.Mdl.Bolt.diam);
        end

        function stressFactor = calc_stress_factor(Obj)
            % Computes factor to translate characteristic -> design stresses

            stressFactor = Obj.sizeEffect * ...
                           Obj.Mdl.Inputs.PSF_CMPCLASS2_FLS * ...
                           Obj.Mdl.Inputs.BoltFls(Obj.iBoltFls).PSF_BOLT_MATERIAL_FLS * ...
                           Obj.Mdl.Inputs.ADDITIONAL_SCF_FLS;
        end

        function pm = calc_pm_sum_full(Obj, moment, cycles)
            % Computes PM-sum from applied fatigue bending moment spectra
            %
            % INPUT
            % - moment [double] <M x N> See method calc_bolt_force
            % - cycles [double] <M x 1> Cycles for M bins
            %
            % OUTPUT
            % - pm [double] <K x 1> PM-sum fatigue damage for K design points

            % Translate moment on flange to force in bolt
            fBolt = Obj.calc_bolt_force(moment);

            % Compute bolt stress (design values)
            stressChar = bsxfun(@rdivide, fBolt, Obj.Mdl.Bolt.areaStress);
            stressFactor = Obj.calc_stress_factor();
            stressDesign = bsxfun(@times, stressFactor, stressChar);

            % Compute linear damage sum (PM sum)
            % NOTE: SnCurve objects work in [MPa], so convert inputs
            nEndurance = Obj.SnCurve.calc_cycles_to_failure_mex(1e-6 * stressDesign);
            damage = bsxfun(@rdivide, cycles(:)', nEndurance);

            % Compute normalized damage sum
            pm = sum(damage, 2);
        end

        function pm = calc_pm_sum(Obj, moment, cycles)
            % Computes PM-sum from applied fatigue bending moment spectra
            % Calculation speed is improved for large design spaces:
            % - If the flange segment force does not exceed the first knee point
            %   in the Schmidt-Neuper model, the results are independent of
            %   flange width. With that knowledge the design space is reduced.
            %
            % INPUT
            % - moment [double, M*N] See method calc_bolt_force
            % - cycles [double, M*1] Cycles for M bins
            %
            % OUTPUT
            % - pm [double, K*1] PM-sum fatigue damage for K design points

            % Make selection mask based on the max segment forces, this can reduce the design space because of
            % independency on flange width
            maxMoment = max(max(moment));
            fSegmentMax = Obj.Mdl.Segment.calc_segment_force(maxMoment, -Obj.Mdl.Loads.deadWeightFavorDesign);
            isWidthDependent = Obj.BoltForceModel.is_width_dependent(fSegmentMax);

            % Abuse the design space array as follows: Set all widths for which isWidthDependent = false to a
            % number that is not already in the width column of the design space array (e.g. -1). Then take
            % the unique rows to determine which design point to evaluate (iCalc) and how to expand this
            % subset to the full design space (iAssign)
            designCombs = [Obj.Mdl.Space.width, Obj.Mdl.Space.thickness, Obj.Mdl.Space.nBolts, Obj.Mdl.Space.boltId];
            designCombs(~isWidthDependent, 1) = -1;
            [~, iCalc, iAssign] = unique(designCombs, 'rows', 'stable');

            % Perform PM-sum calculations only on design points that are
            % depending on the flange width
            pmSubset = Obj.calc_pm_sum_for_subset(moment, cycles, iCalc);

            % Expand evaluated subset to all design points
            pm = pmSubset(iAssign);
        end

        function pm = calc_pm_sum_for_subset(Obj, moment, cycles, iCalc)
            % Computes PM-sum on subset of design points.
            %
            % INPUT
            % - moment [double, M*N] See method calc_bolt_force
            % - cycles [double, M*1] Cycles for M bins
            % - iCalc  [double, K*1] Index mask with to be included design points
            %
            % OUTPUT
            % - fBolt [double, K*M] Bolt forces for K design points and M bins
            %         in fatigue load spectrum

            % Compute stress factor fully (=fast). Select subset later
            stressFactor = Obj.calc_stress_factor();

            % Compute bolt force range for subset only
            % The subset is furter divided per bolt size to avoid potential out-of-memory issues.
            boltIdsforICalc = Obj.Mdl.Space.boltId(iCalc);

            uniqueIds = unique(boltIdsforICalc);
            pm = nan(size(iCalc));
            for thisBoltId = uniqueIds(:)'
                isThisBoltId = boltIdsforICalc == thisBoltId;
                iCalcId = iCalc(isThisBoltId);
                fThisBolt = Obj.calc_bolt_force(moment, iCalcId);

                % Perfrom PM-sum caclulation on subset only
                stressChar = bsxfun(@rdivide, fThisBolt, Obj.Mdl.Bolt.areaStress(iCalcId));
                stressDes = bsxfun(@times, stressFactor(iCalcId), stressChar);
                nAllow = Obj.SnCurve.calc_cycles_to_failure_mex(1e-6 * stressDes);
                damage = bsxfun(@rdivide, cycles(:)', nAllow);
                pm(isThisBoltId) = sum(damage, 2);
            end
        end

        function fBolt = calc_bolt_force(Obj, moment, iCalc)
            % Retuns bolt/stud force, computed from moment acting on flange
            %
            % INPUT
            % - moment [double] <M x N> Fatigue bending moment ranges (N=2)
            %          acting on flange, M bins
            % - iCalc  [double, K*1] Index mask with to be included design
            %   points. Optional: all design points considered if not input
            %
            % OUTPUT
            % - fBolt [double] <K x M> Bolt forces for K design points and M
            %         bins in fatigue load spectrum

            if nargin < 3
                iCalc = 1:Obj.Mdl.Space.nPoints;
            end

            % Compute flange segment fatigue loads (ranges) and apply macro-geometric stress effects
            fSegment = Obj.Mdl.Segment.calc_segment_force(moment, -Obj.Mdl.Loads.deadWeightFavorDesign, iCalc);
            fSegmentCalcMin = fSegment(:, :, 1) ./ Obj.Mdl.flangeTypeFactor;
            fSegmentCalcMax = fSegment(:, :, 2) ./ Obj.Mdl.flangeTypeFactor;

            % Use Schmidt-Neuper model to derive bolt force (still ranges)
            fBoltMin = Obj.BoltForceModel.get_bolt_force(fSegmentCalcMin, iCalc);
            fBoltMax = Obj.BoltForceModel.get_bolt_force(fSegmentCalcMax, iCalc);

            % Convert ranges to absolute forces, acting on the bolt
            fBolt = fBoltMax - fBoltMin;
        end

        function update_description(Obj)
            Obj.description = "Fatigue limit state" + sprintf(' (set #%i)', Obj.iBoltFls);
        end

        function report_results(Obj)

            nLoadSets = Obj.Mdl.Loads.nLoadSets;
            delimiter = '-----------------------------+--------------------------';

            str = { ...
                sprintf('%s - INTERMEDIATE RESULTS\n', upper(Obj.description))
                delimiter
                sprintf('S-N curve                    | %14s', Obj.SnCurve.label)
                sprintf('Thickness exponent           | %14.2f', Obj.Mdl.Inputs.BoltFls(Obj.iBoltFls).THICKNESS_EXPONENT_BOLT)  % mh:ignore_style
                sprintf('Target PM-sum                | %14.3f', Obj.Mdl.Inputs.BoltFls(Obj.iBoltFls).TARGET_PM_SUM)
              };
            for iLoadSet = 1:nLoadSets
                maxPmSum = max([Obj.pmSum{iLoadSet}, Obj.pmSumInv{iLoadSet}], [], 2);
                str{end + 1} = sprintf('PM-sum, load set #%i          | %14.3f', ...
                    iLoadSet, maxPmSum); %#ok
                str{end + 1} = sprintf('Norm. PM-sum, load set #%i    | %14.3f', ...
                    iLoadSet, Obj.utilRatio(1, iLoadSet)); %#ok
            end
            str = [ ...
                str
                delimiter
                Obj.BoltForceModel.get_intermediate_results()
                delimiter
                newline];

            msg = strjoin(str, '\n');
            Obj.info(msg);
        end

        %%%%% == GETTERS / SETTERS == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function value = get.utilRatioGeomConstraint(Obj)

            if ~Obj.doAssess
                % Always return a value to prevent an error when FilePort calls this method while the condition is not
                % assessed
                value = [];
                return
            end

            % Compute utilization ratio
            thickn = Obj.Mdl.Space.thickness;
            a = Obj.Mdl.Segment.distRim;
            b = Obj.Mdl.Segment.distForce;
            value = ((a + b) ./ thickn) ./ 3;
        end

        function value = get.description(Obj)
            value = Obj.get_description();
        end

    end

    methods (Access = protected)

        function str = get_description(Obj)
            str = compose("Fatigue limit state (set #%i)", Obj.iBoltFls);
        end

    end

end
