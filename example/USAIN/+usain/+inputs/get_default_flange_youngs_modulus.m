function youngs_modulus_flange = get_default_flange_youngs_modulus(countryCode)
    if strcmp(countryCode, 'ROW')
        youngs_modulus_flange = 210;
    elseif strcmp(countryCode, 'JPN')
        youngs_modulus_flange = 205;
    else
        error("Only 'ROW' or 'JPN' have defaults for Young's modulus defined.");
    end
end
