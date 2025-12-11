function do_assess_uls = get_default_do_assess_uls(countryCode)
    if strcmp(countryCode, 'ROW')
        do_assess_uls = true;
    elseif strcmp(countryCode, 'JPN')
        do_assess_uls = false;
    else
        error("Only 'ROW' or 'JPN' have defaults for DO_ASSESS_ULS defined.");
    end
end
