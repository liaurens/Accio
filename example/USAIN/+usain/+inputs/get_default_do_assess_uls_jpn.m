function do_assess_uls_jpn = get_default_do_assess_uls_jpn(countryCode)
    if strcmp(countryCode, 'ROW')
        do_assess_uls_jpn = false;
    elseif strcmp(countryCode, 'JPN')
        do_assess_uls_jpn = true;
    else
        error("Only 'ROW' or 'JPN' have defaults for DO_ASSESS_ULS_JPN defined.");
    end
end
