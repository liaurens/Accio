function flange_steel_type = get_default_flange_steel_type(countryCode)
    if strcmp(countryCode, 'ROW')
        flange_steel_type = 'S355';
    elseif strcmp(countryCode, 'JPN')
        flange_steel_type = 'SF520';
    else
        error("Only 'ROW' or 'JPN' have defaults for flange steel type defined.");
    end
end
