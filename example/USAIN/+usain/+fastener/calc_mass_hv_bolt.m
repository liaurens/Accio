function mass = calc_mass_hv_bolt(diameter, len)
    % Computes mass of HV bolt
    % Can also be used for JIS bolts, even though the bolt head height (k) for JIS bolts is slightly larger
    % for bolts > M48.
    %
    % diameter: nominal diameter (e.g. 0.042 for M42)
    % len: Stud length (nominal value)

    % The bolt head height (symbol: k) is always D/1.6 for HV bolts
    headHeight = diameter / 1.6;

    % The width across flats for HV and JIS bolt/nuts (for the standard/preferred metric sizes) is 1.6D and
    % rounding it to nearest 10mm
    widthAcrossFlats = round(1.6 * 1e3 * diameter, -1) / 1e3;

    rho = 7850;
    headMass = sqrt(3) / 2 * rho * headHeight .* widthAcrossFlats.^2;
    shaftMass = pi * rho * len .* (0.98 * diameter / 2).^2;
    mass = headMass + shaftMass;
