function youngs_modulus_bolt = get_default_bolt_youngs_modulus(countryCode)
    if strcmp(countryCode, 'ROW')
        youngs_modulus_bolt = 210;
    elseif strcmp(countryCode, 'JPN')
        youngs_modulus_bolt = 205;
    else
        error("Only 'ROW' or 'JPN' have defaults for Young's modulus defined.");
    end
end
