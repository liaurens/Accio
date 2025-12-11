function [pass, msg] = validate_custom_preload_combinations(boltFlsPreload, flangeGappingPreload, ...
    slsPretensionPreload, flangeNeckScfPreload)
    % Validates the boltfls custom preload in combination with other three assessments. There are four different
    % scenarios to validate as described in the online documentation how-to guide: Perform multiple bolt fatigue
    % assessments in a single USAIN run.
    % Inputs
    % boltFlsPreload       : array of struct containing CUSTOM_PRELOAD which is [1xN, double]
    % flangeGappingPreload : [1xN, double]
    % slsPretensionPreload : [1xN, double]
    % flangeNeckScfPreload : [1xN, double], Where N is number of boltoptions.
    %

    preloadOtherName = {'FlangeGapping'; 'SlsPretension'; 'FlangeNeckScf'};
    preloadOthers = {flangeGappingPreload slsPretensionPreload flangeNeckScfPreload};
    preloadBoltFls = {boltFlsPreload.CUSTOM_PRELOAD};

    othersAllNan = all(cellfun(@(x) all(isnan(x)), preloadOthers));
    boltFlsAllNan = all(cellfun(@(x) all(isnan(x)), preloadBoltFls));
    othersAllEqual = isequaln(preloadOthers{:});

    if othersAllEqual
        % Other three are identical, so comparing one of them with preloadBoltFls is sufficient to indicate a match
        bothHaveMatchingValue = any(cellfun(@(x) isequaln(x, preloadOthers{1}), preloadBoltFls));
    else
        bothHaveMatchingValue = false;
    end

    msg = '';
    if boltFlsAllNan
        if othersAllNan
            % When all boltFls and others are NaN, the defaultPreload data will be extracted from the catalog,
            % hence a valid input combination.
        else
            % Error
            msg = sprintf(['No CUSTOM_PRELOAD defined in BoltFls block(s), therefore also ', ...
                'expected that none of the %s inputs are defined.'], ...
                join(string(preloadOtherName) + ".CUSTOM_PRELOAD", ", "));
        end
    else
        if bothHaveMatchingValue && othersAllEqual
            % Other three are identical to each other and to one of the boltFls blocks.
            % hence a valid input combination.
        else
            % Error
            msg = sprintf(['Expected all values for %s to be the same and to be ' ...
                'identical to one of the BoltFls.CUSTOM_PRELOAD values.'], ...
                join(string(preloadOtherName) + ".CUSTOM_PRELOAD", ", "));
        end
    end

    pass = isempty(msg);

end
