classdef Loads < FlangeLoads
    % Loads data container

    properties
        deadWeightFavorDesignUls  % Design value for dead weight (factored with favorable PSF), for ULS

        Fdi (1, :) usain.loads.FlangeDamageIndicator  % FDI based on normal Markov matrix
        FdiInverted (1, :) usain.loads.FlangeDamageIndicator  % FDI based on inverted Markov matrix

        inclinMomentFlsChar (1, :) double  % Overturning moment from structure inclination, for FLS [Nm]
        inclinMomentFlsDesign (1, :) double  % Overturning moment from structure inclination, for FLS, factored [Nm]

        maxS1MomentDesign (1, :) double = nan  % Max. abs. bending moment from the S1 load case, in Nm. Design value.
    end

    methods

        function Obj = Loads(varargin)
            Obj@FlangeLoads(varargin{:});
        end

        function import_fls(Obj, MilkFatigueLoads, macroGeometricScf)
            % Reads FLS loads file and assigns MILK data to property Obj.Fls
            %
            % NOTE 1: The macro-geometric SCF is conveniently applied on the loads directly. As such, there's only one
            % location in the codebase where the SCF is applied, instead of applying it in every condition individually.
            % NOTE 2: The macro-geometric SCF is applied on the dead weight as well (i.e. making dead weight more
            % favorable for SCFs > 1.0). This is done to ensure, for example, that for zero external load the SGRE2.0
            % bolt force curve returns exactly the preload.
            %

            arguments
                Obj
                MilkFatigueLoads Milk.FatigueLoads
                macroGeometricScf (1, 1) double = 1.00
            end

            Obj.Fls = MilkFatigueLoads;

            % Determine contingency factor; Use linear interpolation if needed
            Obj.flsContgyFactor = Obj.interp_contingency_factor('fls');

            [Obj.flsMxyDesign, Obj.flsCycles] = deal(cell(1, Obj.nLoadSets));
            Obj.delDesign = nan(1, Obj.nLoadSets);
            Obj.Fdi(1, Obj.nLoadSets) = usain.loads.FlangeDamageIndicator();
            Obj.FdiInverted(1, Obj.nLoadSets) = usain.loads.FlangeDamageIndicator();
            for iLoadSet = 1:Obj.nLoadSets

                % If the source file is .mkv, then it's expected that the file is to be used directly and is therefore
                % exactly at the flange location. As such no interpolation is required.
                [~, ~, fileExtension] = fileparts(Obj.Fls(iLoadSet).sourceFilePath);
                if strcmp(fileExtension, '.mkv')
                    Obj.info(['The input Loads.flsFilePath for loadSet #%i is a single Markov matrix file and ', ...
                        'therefore assumed to be at the exact location of the flange z-coordinate.'], iLoadSet);
                    ranges = Obj.Fls(iLoadSet).Markov.rangeBinsDesign;
                    cycles = Obj.Fls(iLoadSet).Markov.cycleCounts;
                    means = Obj.Fls(iLoadSet).Markov.meanBins;
                else
                    % Interpolate Markov matrices to flange elevation level
                    [ranges, cycles, means, minChanDist] = Obj.Fls(iLoadSet).Markov.interpolate_z( ...
                        'M.res\_', Obj.zFlange, 'design', Obj.INTERPOLATION_METHOD, Obj.EXTRAPOLATION_METHOD_MARKOV);

                    % Info/warning based on distance between nearest channel and zFlange
                    if minChanDist > 1
                        Obj.warning(['For load set #%i ("%s"), ', ...
                            'Markov channel closest to input flange elevation level: %.3fm.\n', ...
                            'This may not be acceptable for non-preliminary designs.'], ...
                            iLoadSet, Obj.Inputs.Loads.tag{iLoadSet}, minChanDist);
                    else
                        Obj.info(['For load set #%i ("%s"), ', ...
                            'distance of Markov channel closest to input flange elevation level: %.3fm.'], ...
                            iLoadSet, Obj.Inputs.Loads.tag{iLoadSet}, minChanDist);
                    end
                end

                % Warn user if non-standard Markov matrix size is detected
                if ~Obj.Fls(iLoadSet).Markov.is_standard_size()
                    Obj.warning(['Selected Markov matrix for load set #%i has a non-standard size (%ix%i).\n', ...
                        'Any size above 51x40 is not recommended, ', ...
                        'as it might lead to memory issues during bolt fatigue assessment.'], ...
                        iLoadSet, Obj.Fls(iLoadSet).Markov.nRange, Obj.Fls(iLoadSet).Markov.nMean);
                end

                % Vectorize Markov matrix properties
                [rangeVec, cycleVec, meanVec] = ...
                    Milk.Markov.reshape_markov_matrix(ranges, cycles, means);

                % Compute FDI for normal and inverted Markov matrix
                Obj.Fdi(iLoadSet) = usain.loads.FlangeDamageIndicator( ...
                    a1 = Obj.Inputs.FDI_COEFFICIENT_A1, ...
                    a2 = Obj.Inputs.FDI_COEFFICIENT_A2, ...
                    m = Obj.Inputs.DEL_WOHLER_SLOPE).calc_fdi(rangeVec, cycleVec, meanVec);
                Obj.FdiInverted(iLoadSet) = usain.loads.FlangeDamageIndicator( ...
                    a1 = Obj.Inputs.FDI_COEFFICIENT_A1, ...
                    a2 = Obj.Inputs.FDI_COEFFICIENT_A2, ...
                    m = Obj.Inputs.DEL_WOHLER_SLOPE).calc_fdi(rangeVec, cycleVec, -meanVec);

                % Apply macro-geometric SCF on external loads (means and ranges)
                rangeVec = macroGeometricScf * rangeVec;
                meanVec = macroGeometricScf * meanVec;

                % Remove bins without cycles. Using a threshold of 0.005 as that is the minimum value to be expected in
                % a Markov matrix. Any value < 0.005 would be due to numerical round-off. This is not important for
                % fatigue calculations, but it could affect the max FLS moment in rare cases.
                hasCycles = cycleVec >= 0.005;

                % Compute min and max bending moments by subtracting/adding half
                % of the range bins to the mean value matrix
                momentMin = meanVec - (Obj.flsContgyFactor(iLoadSet) .* rangeVec) / 2;   % Nm
                momentMax = meanVec + (Obj.flsContgyFactor(iLoadSet) .* rangeVec) / 2;   % Nm
                Obj.flsMxyDesign{iLoadSet} = [momentMin(hasCycles), momentMax(hasCycles)];
                Obj.flsCycles{iLoadSet} = cycleVec(hasCycles);

                % Calc and store DEL, for reporting in DOCTOR.
                % - First create a new Markov from the (potentially) interpolated bins
                % - then convert to DEL
                % - then apply load scaling.
                % This allows for a fair comparison with e.g. DELs from STIFT
                MarkovInterpolated = Milk.Markov('cycleCounts', cycles, 'rangeBins', ranges, 'meanBins', means);
                MarkovInterpolated.psf = Obj.Fls(iLoadSet).Markov.psf;
                DelInterpolated = MarkovInterpolated.convert_to_del( ...
                    Obj.Inputs.DEL_REF_CYCLES, Obj.Inputs.DEL_WOHLER_SLOPE);
                Obj.delDesign(iLoadSet) = DelInterpolated.delDesign .* Obj.flsContgyFactor(iLoadSet);
            end

            % For the mean value check, define load ranges with inverted mean
            % values as well:
            %  - max of "normal" range bin -> min of inverted range bin
            %  - min of "normal" range bin -> max of inverted range bin
            %  - multiply by -1
            Obj.flsMxyDesignInv = cellfun(@(x) -x(:, [2 1]), Obj.flsMxyDesign, 'uni', 0);

            % Store maximum load values, used for some SLS checks
            Obj.maxFlsMxy = cellfun(@(x) max(abs(x(:))), Obj.flsMxyDesign);
        end

        function import_s1(Obj, S1Loads, macroGeometricScf)
            % Imports maximum S1 load (moment Mxy) at flange elevation level.
            % Stores to property `maxS1MomentDesign`.

            arguments
                Obj
                S1Loads (1, :) Milk.ServiceAbilityLoads
                macroGeometricScf (1, 1) double = 1.00
            end

            % Determine contingency factor on S1 loads; Use linear interpolation if needed
            loadScalingFactor = Obj.interp_contingency_factor('S1');

            Obj.maxS1MomentDesign = nan(1, Obj.nLoadSets);
            for iLoadSet = 1:Obj.nLoadSets

                if S1Loads(iLoadSet).isEmpty
                    Obj.maxS1MomentDesign(iLoadSet) = nan;
                else
                    % Interpolate S1 loads to flange elevation level
                    zLoads = cell2mat(S1Loads(iLoadSet).Channels.zLevels);
                    xLoads = S1Loads(iLoadSet).loads;
                    interpolatedS1Moment = Milk.ServiceAbilityLoads.interp1(zLoads, xLoads, Obj.zFlange, ...
                                            Obj.INTERPOLATION_METHOD, Obj.EXTRAPOLATION_METHOD);

                    % Apply macro-geometric SCF and load scaling
                    Obj.maxS1MomentDesign(iLoadSet) = ...
                        interpolatedS1Moment * macroGeometricScf * loadScalingFactor(iLoadSet);
                end

            end
        end

        function moment = get_max_sls_moment(Obj)
            % Returns bending moment to be used for SLS conditions.
            %
            % The returned moment is a design value, including scaling and a macro-geometric SCF (if present).
            % Inclination loads are not included.
            %
            % The moment is determined as follows:
            % 1. If S1 loads are available, use those
            % 2. If S1 loads are not available, use the maximum FLS bending moment

            moment = Obj.maxS1MomentDesign;
            moment(isnan(moment)) = Obj.maxFlsMxy(isnan(moment));
        end

    end

    methods (Static)

        function Obj = setup(Inputs, MilkData, StructuralModel)
            arguments
                Inputs
                MilkData
                StructuralModel
            end
            Obj = usain.loads.Loads('Inputs', Inputs, 'zFlange', Inputs.zFlange);

            % Compute dead weight
            % NOTE: The macro-geometric SCF is applied on the dead weight as well (i.e. making dead weight more
            % favorable for SCFs > 1.0). This is done to ensure, for example, that for zero external load the SGRE2.0
            % bolt force curve returns exactly the preload.
            if ~isnan(Inputs.DEAD_WEIGHT)
                Obj.deadWeightChar = Inputs.DEAD_WEIGHT;
            else
                Obj.deadWeightChar = Obj.calc_dead_weight(StructuralModel);
            end
            Obj.deadWeightFavorDesign = ...
                Inputs.MACRO_GEOMETRIC_SCF * Obj.Inputs.PSF_FAVORABLE_LOADS * Obj.deadWeightChar;
            Obj.deadWeightFavorDesignUls = Obj.Inputs.PSF_FAVORABLE_LOADS * Obj.deadWeightChar;

            % Compute overturning moment from structure inclination
            if ~isnan(Inputs.INCLINATION_MOMENT)
                Obj.inclinMomentChar = Inputs.INCLINATION_MOMENT * ones(1, Obj.nLoadSets);
            else
                Obj.inclinMomentChar = Obj.calc_inclination_moment(StructuralModel, Obj.Inputs.Loads.inclinationValue);
            end
            Obj.inclinMomentDesign = Milk.ExtremeLoads.PSF_GRAVITY * Obj.inclinMomentChar;

            if isnan(Inputs.INCLINATION_MOMENT_FLS)
                Obj.inclinMomentFlsChar = Obj.calc_inclination_moment(StructuralModel, ...
                    Obj.Inputs.Loads.inclinationValueFls);
            else
                Obj.inclinMomentFlsChar = Inputs.INCLINATION_MOMENT_FLS * ones(1, Obj.nLoadSets);
            end
            Obj.inclinMomentFlsDesign = ...
                Milk.ExtremeLoads.PSF_GRAVITY * Inputs.MACRO_GEOMETRIC_SCF * Obj.inclinMomentFlsChar;

            % Import load from inputs loads files or manual override
            if ~isnan(Inputs.ULS_BENDING_MOMENT)
                Obj.ulsMxyDesign = Inputs.ULS_BENDING_MOMENT * ones(1, Obj.nLoadSets);
            elseif Obj.check_is_required_uls(Inputs)
                Obj.import_uls(MilkData.Uls);
            end

            if Obj.check_is_required_fls(Inputs)
                Obj.import_fls(MilkData.Fls, Inputs.MACRO_GEOMETRIC_SCF);
            end

            if Obj.check_is_required_s1(Inputs)
                if isnan(Inputs.S1_BENDING_MOMENT)
                    Obj.import_s1(MilkData.S1, Inputs.MACRO_GEOMETRIC_SCF);
                else
                    Obj.maxS1MomentDesign = Inputs.S1_BENDING_MOMENT * ones(1, Obj.nLoadSets);
                end
            end
        end

        function isRequired = check_is_required_fls(Inputs)
            isRequired = any([ ...
                Inputs.DO_ASSESS_FLS, ...
                Inputs.DO_ASSESS_GAPPING, ...
                Inputs.DO_ASSESS_SLS_PRETENSION, ...
                Inputs.DO_ASSESS_FLANGE_NECK_SCF]);
        end

        function isRequired = check_is_required_uls(Inputs)
            isRequired = any([ ...
                Inputs.DO_ASSESS_ULS, ...
                Inputs.DO_ASSESS_ULS_JPN]);
        end

        function isRequired = check_is_required_s1(Inputs)
            isRequired = any([ ...
                Inputs.DO_ASSESS_BOLT_PLASTICITY, ...
                Inputs.DO_ASSESS_FLANGE_PLASTICITY]);
        end

    end
end
