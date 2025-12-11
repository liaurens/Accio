function psf_bolt_resistance_jpn = get_default_bolt_resistance_jpn(countryCode)
    if strcmp(countryCode, 'ROW')
        psf_bolt_resistance_jpn = nan;
    elseif strcmp(countryCode, 'JPN')
        psf_bolt_resistance_jpn = [1.25 1.875 1.0];
    else
        error("Only 'ROW' or 'JPN' have defaults for PSF_BOLT_RESISTANCE_JPN defined.");
    end
end
