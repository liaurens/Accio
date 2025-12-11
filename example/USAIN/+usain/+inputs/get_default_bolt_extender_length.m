function extender_length = get_default_bolt_extender_length(countryCode)
    if strcmp(countryCode, 'ROW')
        extender_length = nan;
    elseif strcmp(countryCode, 'JPN')
        extender_length = 0.0;
    else
        error("Only 'ROW' or 'JPN' have defaults for bolt extender defined.");
    end
end
