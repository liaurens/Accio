classdef FatigueLimitStateWithSgre2_0 < UsainUtils.FatigueLimitState  % mh:ignore_style
    % Temporary class to do an FLS assessment using the SGRE2.0 bolt load model.

    properties
        iAngle double
        summaryData struct  % Selected data with intermediate results, for WriteSummaryFileStep
        bendingContribution double  % Contribution of bending stresses to fatigue damage
    end

    methods

        function Obj = FatigueLimitStateWithSgre2_0(iBoltFls, iAngle, varargin)  % mh:ignore_style
            Obj@UsainUtils.FatigueLimitState(iBoltFls, varargin{:});
            Obj.iAngle = iAngle;
        end

        function setup_condition(Obj)
            Obj.setup_bolt_force_model();
        end

        function setup_bolt_force_model(Obj)
            % Set up SGRE2.0 bolt force model
            Inputs = Obj.Mdl.Inputs;
            preloadFls = usain.fastener.get_preload( ...
                Obj.Mdl.Tool.defaultPreload, ...
                Inputs.BoltFls(Obj.iBoltFls).CUSTOM_PRELOAD, ...
                Inputs.BoltFls(Obj.iBoltFls).PRELOAD_LOSS_FACTOR_FLS);
            Obj.BoltForceModel = UsainUtils.BoltForceModelFactory().get_model(Obj.Mdl, ...
                Inputs.BoltFls(Obj.iBoltFls).BOLT_FORCE_MODEL, preloadFls, Inputs.SGRE2.GAP_ANGLE(Obj.iAngle));
        end

        function Sn = setup_sn_curve(Obj)
            % Returns S-N curve for bolts
            sDetail = round(str2double(extractAfter(Obj.Mdl.Inputs.BoltFls(Obj.iBoltFls).SN_CURVE_BOLT, "EC3_DC")));
            assert(~isnan(sDetail), 'Bolt S-N curve not recognized as a valid EC3 S-N curve.');

            % Set up Eurocode 3 S-N curve with bolt-specific knee point and thickness effect parameters
            Sn = sn_curve.SnCurve.setup_curve_eurocode( ...
                'label', sprintf('EC3_DC%.0f', sDetail), ...
                'sDetail', sDetail, ...
                'doApplyCutoff', false, ...
                'nKnee', 2e6, ...
                'tRef', 30e-3, ...
                'tExp', Obj.Mdl.Inputs.BoltFls(Obj.iBoltFls).THICKNESS_EXPONENT_BOLT);

        end

        function kBending = calc_bending_contribution(Obj)
            % Computes fatigue damage contribution ratio of bending stresses, compared to normal stresses

            if ~isnan(Obj.Mdl.Inputs.SGRE2.BENDING_CONTRIBUTION)
                kBending = Obj.Mdl.Inputs.SGRE2.BENDING_CONTRIBUTION;
            else
                diameterBolt = Obj.Mdl.Bolt.diam;
                kBending = max(0.5, 0.5 + 0.5 .* (log(diameterBolt) - log(36e-3)) ./ (log(150e-3) - log(36e-3)));
            end
        end

        function szEff = calc_size_effect(Obj)
            % Computes size effect with >M72 penalty (preferred), or takes thickness exponent from inputs
            % NOTE: Overloads superclass method

            assert(~isempty(Obj.SnCurve), 'Set up S-N curve first');

            if ~isnan(Obj.SnCurve.tExp)
                szEff = Obj.SnCurve.size_effect(Obj.Mdl.Bolt.diam);
            else
                szEff = (Obj.Mdl.Bolt.diam ./ Obj.SnCurve.tRef).^0.1 .* max(1, (Obj.Mdl.Bolt.diam ./ 72e-3).^0.25);
            end
        end

        function pm = calc_pm_sum_for_subset(Obj, moment, cycles, iCalc)
            % Overloads UsainUtils.FatigueLimitState.calc_pm_sum_for_subset()
            %
            % In contrast to Schmidt-Neuper and Petersen, SGRE2.0 considers both bolt forces and moments.
            % Overloading of this method is done to accommodate this difference.

            stressFactor = Obj.calc_stress_factor();
            Obj.bendingContribution = Obj.calc_bending_contribution();
            stressDiameter = sqrt(4 * Obj.Mdl.Bolt.areaStress ./ pi);
            sectionModulus = pi * stressDiameter.^3 / 32;

            % Compute flange segment fatigue loads (ranges) and apply macro-geometric stress effects
            segmentForce = Obj.Mdl.Segment.calc_segment_force(moment, -Obj.Mdl.Loads.deadWeightFavorDesign);
            segmentForceMin = segmentForce(:, :, 1);
            segmentForceMax = segmentForce(:, :, 2);

            % The "subset" is furter divided per bolt size to avoid potential out-of-memory issues.
            boltIdsforICalc = Obj.Mdl.Space.boltId;
            uniqueIds = unique(boltIdsforICalc);

            boltForceMin = nan(size(segmentForceMin));
            boltForceMax = boltForceMin;
            damage = nan(size(segmentForceMin));
            pm = nan(size(boltIdsforICalc));

            for thisBoltId = uniqueIds(:)'
                isThisBoltId = boltIdsforICalc == thisBoltId;
                iCalcId = iCalc(isThisBoltId);

                % Compute bolt forces and moments
                boltForceMin(iCalcId, :) = Obj.BoltForceModel.calc_bolt_force(segmentForceMin, iCalcId);
                boltForceMax(iCalcId, :) = Obj.BoltForceModel.calc_bolt_force(segmentForceMax, iCalcId);
                boltForceRange = boltForceMax(iCalcId, :) - boltForceMin(iCalcId, :);

                % Note: to get the bolt moment, the input bolt force must have the same dimensions as the segment force
                boltMomentMin = Obj.BoltForceModel.calc_bolt_moment(segmentForceMin, boltForceMin, iCalcId);
                boltMomentMax = Obj.BoltForceModel.calc_bolt_moment(segmentForceMax, boltForceMax, iCalcId);
                boltMomentRange = boltMomentMax - boltMomentMin;

                % Compute stresses
                axialStressRange = (boltForceRange ./ Obj.Mdl.Bolt.areaStress(iCalcId)) .* stressFactor(iCalcId);
                bendingStressRange = (boltMomentRange ./ sectionModulus(iCalcId)) .* stressFactor(iCalcId);
                totalStressRange = axialStressRange + Obj.bendingContribution(iCalcId) .* bendingStressRange;

                % Perform PM-sum calculation
                nAllowableCycles = Obj.SnCurve.calc_cycles_to_failure_mex(1e-6 * totalStressRange);
                damage(isThisBoltId, :) = bsxfun(@rdivide, cycles(:)', nAllowableCycles);
                pm(isThisBoltId) = sum(damage(isThisBoltId, :), 2);
            end

            % Fill `summaryData` struct for exporting intermediate results to Excel overview (see WriteSummaryFileStep)
            if isscalar(pm) && (~isfield(Obj.summaryData, 'damage') || sum(Obj.summaryData.damage, 2) <= pm)
                Obj.summaryData = struct();
                Obj.summaryData.z_max_tot = segmentForceMax;
                Obj.summaryData.z_min_tot = segmentForceMin;
                Obj.summaryData.fs_max = boltForceMax;
                Obj.summaryData.ms_max = boltMomentMax;
                Obj.summaryData.smax_ax = (boltForceMax ./ Obj.Mdl.Bolt.areaStress);
                Obj.summaryData.smax_ben = (boltMomentMax ./ sectionModulus);
                Obj.summaryData.damage = damage;
            end
        end

        function report_results(Obj)

            nLoadSets = Obj.Mdl.Loads.nLoadSets;
            delimiter = '---------------------------------+--------------------------';

            str = { ...
                sprintf('%s - INTERMEDIATE RESULTS', upper(Obj.description))
                delimiter
                sprintf('%32s | %14s', 'S-N curve', Obj.SnCurve.label)
                sprintf('%32s | %14.2f', 'Size effect', Obj.sizeEffect)
                sprintf('%32s | %14.1f %%%%', 'Bending contribution', 100 * Obj.bendingContribution)
                sprintf('%32s | %14.3f', 'Target PM-sum', Obj.Mdl.Inputs.BoltFls(Obj.iBoltFls).TARGET_PM_SUM)
              };
            for iLoadSet = 1:nLoadSets
                maxPmSum = max([Obj.pmSum{iLoadSet}, Obj.pmSumInv{iLoadSet}], [], 2);
                loadSetStr = sprintf('PM-sum, load set #%i', iLoadSet);
                str{end + 1} = sprintf('%32s | %14.3f', loadSetStr, maxPmSum); %#ok
                loadSetStr = sprintf('Norm. PM-sum, load set #%i', iLoadSet);
                str{end + 1} = sprintf('%32s | %14.3f', loadSetStr, Obj.utilRatio(1, iLoadSet)); %#ok
            end
            str = [str; delimiter];
            for iLoadSet = 1:nLoadSets

                maxMoment = Obj.Mdl.Loads.maxFlsMxy(iLoadSet);
                inclinationMoment = Obj.Mdl.Loads.inclinMomentFlsDesign(iLoadSet);
                maxSegmentForce = Obj.Mdl.Segment.calc_segment_force( ...
                    maxMoment + inclinationMoment, -Obj.Mdl.Loads.deadWeightFavorDesign);
                maxBoltForce = Obj.BoltForceModel.calc_bolt_force(maxSegmentForce);

                loadSetStr = sprintf(', load set #%i', iLoadSet);

                loadSetResults = { ...
                    sprintf('%32s | %14.1f MNm', ['Max. FLS moment', loadSetStr], maxMoment * 1e-6)
                    sprintf('%32s | %14.1f MNm', ['Inclination moment', loadSetStr], inclinationMoment * 1e-6)
                    sprintf('%32s | %14.1f kN', ['Max. segment force', loadSetStr], maxSegmentForce * 1e-3)
                    sprintf('%32s | %14.1f kN', ['Max. bolt force', loadSetStr], maxBoltForce * 1e-3)
                    };
                str = [str; loadSetResults];  %#ok
            end
            str = [str
                delimiter
                sprintf('%32s | %14s', 'Applied bolt force model', 'SGRE2.0')
                sprintf('%32s | %14g deg', 'Gap angle', rad2deg(Obj.BoltForceModel.GapModel.Gap.angle))
                sprintf('%32s | %14.1f mm', 'Gap length', Obj.BoltForceModel.GapModel.Gap.len * 1e3)
                sprintf('%32s | %14.3f mm', 'Gap height', Obj.BoltForceModel.GapModel.Gap.height * 1e3)
                sprintf('%32s | %14.3g deg', 'Flange tilt (angular)', rad2deg(Obj.BoltForceModel.GapModel.Tilt.angle))
                sprintf('%32s | %14.1f kN', 'Dead weight on segment', Obj.BoltForceModel.deadWeight * -1e-3)
                sprintf('%32s | %14.1f kN', 'Preload', Obj.BoltForceModel.preload * 1e-3)
                sprintf('%32s | %14.1f kN', 'Gap closing force', Obj.BoltForceModel.forceGapClose * 1e-3)
                sprintf('%32s | %14.1f %%%%', 'Ratio', 100 * Obj.BoltForceModel.preloadRatio)
                sprintf('%32s | %14.3f', 'Stiffness correction factor', Obj.BoltForceModel.stiffnessCorrectionFactor)
                sprintf('%32s | %14.4f', 'Initial slope of force curve', Obj.BoltForceModel.initialSlopeForceCurve)
                sprintf('%32s | %14.2f kN', 'Min. bolt force (F_s,min)', Obj.BoltForceModel.minBoltForce * 1e-3)
                sprintf('%32s | %14.1f mm', 'Parameter a*', Obj.BoltForceModel.aModified * 1e3)
                sprintf('%32s | %14.2f Nm', 'Residual moment (M_0)', Obj.BoltForceModel.residualMoment)
                sprintf('%32s | %14.4f', 'Initial slope moment curve', Obj.BoltForceModel.initialSlopeMomentCurve * 1e3)
                sprintf('%32s | %14.2f Nm', 'Min. bolt moment (M_s,min)', Obj.BoltForceModel.minBoltMoment)
                delimiter
                newline
                ];
            % TODO: Use `Unit` class for conversion instead

            msg = strjoin(str, '\n');
            Obj.info(msg);

        end

    end

    methods (Access = protected)

        function str = get_description(Obj)
            gapAngleDeg = rad2deg(Obj.Mdl.Inputs.SGRE2.GAP_ANGLE(Obj.iAngle));
            str = compose("Fatigue limit state (set #%i, %g deg)", Obj.iBoltFls, gapAngleDeg);
        end

    end

end
