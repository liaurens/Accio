function mass = calc_mass_iso_stud(pitchDiameter, len)
    % Computes mass of an ISO stud
    %
    % pitchDiameter: pitch diameter of external thread (e.g. see ISO 724)
    % len: Stud length (nominal value)

    rho = 7850;
    mass = pi * rho * len .* (pitchDiameter / 2).^2;
