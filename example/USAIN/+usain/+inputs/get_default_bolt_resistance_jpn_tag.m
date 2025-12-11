function psf_bolt_resistance_jpn_tag = get_default_bolt_resistance_jpn_tag(countryCode)
    if strcmp(countryCode, 'ROW')
        psf_bolt_resistance_jpn_tag = '';
    elseif strcmp(countryCode, 'JPN')
        psf_bolt_resistance_jpn_tag = {'shortTerm' 'longTerm' 'seismic'};
    else
        error("Only 'ROW' or 'JPN' have defaults for PSF_BOLT_RESISTANCE_JPN_TAG defined.");
    end
end
