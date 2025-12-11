function nut_type = get_default_nut_type(boltLabel, tighteningMethod)
    % Return default(s) for input NUT_TYPE

    assert(length(boltLabel) == length(tighteningMethod), ...
        'Inputs boltLabel and tighteningMethod must have the same size.');

    boltSeries = extractBefore(boltLabel, '_');
    nut_type = boltSeries;
    nut_type(strcmp(tighteningMethod, 'tension')) = {'ISR'};
end
