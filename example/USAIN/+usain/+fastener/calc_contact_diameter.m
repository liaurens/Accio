function diam = calc_contact_diameter(diamNut, diamWasher, lenWasher)
    % Returns diameter of fastener component in contact with flange (either round nut or washer)
    %
    %   diam: diameter of fastener component (nut/washer)

    inputsSameLength = all(numel(diamNut) == [numel(diamWasher) numel(lenWasher)]);
    assert(inputsSameLength, 'calc_contact_diameter:InputNotSameLength', ...
        'Inputs must all have the same length');

    diam = diamWasher;
    diam(lenWasher < 1e-6) = diamNut(lenWasher < 1e-6);
