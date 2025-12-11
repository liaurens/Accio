function [boltLength, extenderLength] = match_bolt_lengths_to_flange_thickness(Inputs, thickness, boltIds)
    % Match bolt (and extender) lengths to flange thickness
    %
    % boltLength: bolt lengths matched to N flange thickness values
    % extenderLength: extender lengths matched to N flange thickness values
    %
    % NaN values mean that match was found for a given flange thickness

    % TODO: This function is temporarily moved from the phased out UsainUtils.DesignSpace class. Proper refactoring to
    % make the logic in the function readable and testable needs to be done.

    boltLength = nan(size(thickness));
    extenderLength = nan(size(thickness));

    ThreadModels = UsainUtils.ThreadLengthModel.from_inputs(Inputs);
    ThreadCheckers = UsainUtils.ThreadLengthChecker.from_inputs(Inputs);

    BoltOpts = usain.fastener.BoltOptionsParser(Inputs.boltOptions);

    for iOpt = unique(boltIds(:)')

        [uniqueThickness, ~, iUnq] = unique(thickness(boltIds == iOpt));
        matchedBoltLength = nan(size(uniqueThickness));
        matchedExtenderLength = nan(size(uniqueThickness));
        % The calculations in this loop will be split depending on bolt option, a different procedure is required for
        % HV bolts compared to all other options.
        if contains(BoltOpts.label{iOpt}, 'HV')
            % The bolt length for HV is basically obtained by looking it up from DASt table3a using the nominal
            % clamped length. For check runs it's required to see if the provided bolt length option results in a match
            % with that from the lookup table for the clamped length in the design space.
            % The clamped length is determined using nominal thicknesses:
            % flange thickness: design thickness + allowance
            % washers: nominal (=max) thickness as per DASt
            % extenders: nominal, neglecting tolerances. Note that extenders are actually not expected to be used,
            % but considered to allow for more extensive "checking" of old designs.

            Assy = usain.fastener.CatalogLibrary.select_assemblies( ...
                Inputs.site, BoltOpts.label{iOpt}, Inputs.tighteningMethod{iOpt}, Inputs.NUT_TYPE{iOpt});

            boltSize = usain.fastener.BoltOptionsParser(Assy.Bolt.label).boltSizeString;
            washerHeight = Assy.Washer.len;

            % Either take the extender length from USAIN inputs (if set), or take all allowed lengths.
            % Sort lengths such that first match will always be the shortest length.
            extenderLengths = sort(usain.fastener.ExtenderData.get_length_options( ...
                Inputs.lengthBoltExtender(iOpt), BoltOpts.label{iOpt}, Inputs.STEPSIZE_BOLT_EXT_LEN));

            % Calculated clamped lengths also considering all possible extender lengths
            clampedLengths = 2 .* uniqueThickness + Inputs.ALW_UPPER_FLANGE_THICKNESS + ...
                Inputs.ALW_LOWER_FLANGE_THICKNESS + 2 .* washerHeight + extenderLengths;

            % The bolt extenders could lead to many identical clamped lengths, reshape and use unique to reduce
            % computation cost.
            clampedLengthsVector = reshape(clampedLengths, numel(clampedLengths), 1);
            [unqClampedLengths, ~, iUnqClampedLengths] = unique(clampedLengthsVector);

            % Query bolt lengths for the unique clamped lengths and in turn expand to original dimensions
            boltLengthForUnqClampedLengths = usain.fastener.DastHvLengthData.query_bolt_length(boltSize, ...
                unqClampedLengths);
            boltLengthForClampedLengthVector = boltLengthForUnqClampedLengths(iUnqClampedLengths);
            boltLengthForClampedLength = reshape(boltLengthForClampedLengthVector, size(clampedLengths));

            % Match the queried bolt lengths corresponding to the clampedLengths (design space dependent) with the
            % possible bolt lengths. For the possible bolt lengths, either take the bolt length from USAIN inputs
            % (if set), or take all allowed lengths.
            % Sort lengths such that first match will always be the shortest length.

            possibleBoltLengths = sort( ...
                usain.fastener.FastenerData.get_length_options(BoltOpts.inputBoltLength(iOpt), BoltOpts.label{iOpt}));

            [isMatchedBoltLength, idSmallestMatchedBoltLength] = ismembertol(boltLengthForClampedLength, ...
                possibleBoltLengths, 1e-6);

            % The values of idSmallestMatchedBoltLength indicates the index of the matched possibleBoltLength.
            % The columns relate to the extenderLengths.
            % If there is no match, the value will be 0, exclude these to find the actual id corresponding to the
            % minimum possible bolt length and the id for minimum extender length.
            hasMatch = any(isMatchedBoltLength, 2);
            idSmallestMatchedBoltLength(idSmallestMatchedBoltLength <= 0) = nan;
            [idBoltLength, idExtenderLength] = min(idSmallestMatchedBoltLength, [], 2);
            % Ensure that idExtenderLength also reflects nan where idBoltLength is nan
            idExtenderLength(isnan(idBoltLength)) = nan;

            for iThickn = 1:length(uniqueThickness)
                if ~hasMatch(iThickn)
                    continue
                end
                matchedBoltLength(iThickn) = possibleBoltLengths(idBoltLength(iThickn));
                matchedExtenderLength(iThickn) = extenderLengths(idExtenderLength(iThickn));
            end

        else

            % The calculations in this for-loop are vectorized using 3D arrays:
            % Dimension #1: flange thickness
            % Dimension #2: bolt length
            % Dimension #3: bolt extender length

            % Prepare UsainUtils.ThreadLengthModel instance for bolt length matching
            ThreadModel = ThreadModels(iOpt);
            ThreadModel.flangeThickness = uniqueThickness;

            % Either take the bolt length from USAIN inputs (if set), or take all allowed lengths.
            % Sort lengths such that first match will always be the shortest length
            ThreadModel.boltLength = sort( ...
                usain.fastener.FastenerData.get_length_options(BoltOpts.inputBoltLength(iOpt), BoltOpts.label{iOpt}));

            % Either take the extender length from USAIN inputs (if set), or take all allowed lengths.
            % Sort lengths such that first match will always be the shortest length
            extenderLengths = sort(usain.fastener.ExtenderData.get_length_options( ...
                    Inputs.lengthBoltExtender(iOpt), BoltOpts.label{iOpt}, Inputs.STEPSIZE_BOLT_EXT_LEN));
            ThreadModel.extenderLength = reshape(extenderLengths, 1, 1, []);  % Shift to dimension #3

            % Evaluate gripped and visibile thread lengths
            ThreadCheck = ThreadCheckers(iOpt);
            isOkThread = ThreadCheck.check_thread_lengths(ThreadModel);

            % For each thickness value, find minimum bolt length for which thread lengths are still OK
            for iThickn = 1:length(uniqueThickness)
                isMatch = reshape(isOkThread(iThickn, :, :), [size(isOkThread, 2), size(isOkThread, 3)]);
                iMinBoltLength = find(isMatch, 1, 'first');

                if isempty(iMinBoltLength)
                    % This does not hint at an implementation error; it's perfectly valid that a given thickness
                    % can not be matched with a bolt+extender length
                    continue
                end

                [iBoltLength, iExtenderLength] = ind2sub(size(isMatch), iMinBoltLength);
                matchedBoltLength(iThickn) = ThreadModel.boltLength(iBoltLength);
                matchedExtenderLength(iThickn) = ThreadModel.extenderLength(iExtenderLength);
            end

        end

        % Expand to all design points for this bolt ID
        boltLength(boltIds == iOpt) = matchedBoltLength(iUnq);
        extenderLength(boltIds == iOpt) = matchedExtenderLength(iUnq);
    end

end
