classdef GapData <  logging.Config

    properties
        angle double  % Gap angle in radians
        len double  % Gap length, measured at outer diameter of flange neck
        height double  % Design gap height
    end

    methods

        function Obj = GapData(angle, diameterOutNeck, tolerancePerMeter)

            if nargin
                if nargin < 3
                    tolerancePerMeter = 1.4e-3;
                end

                Obj.angle = angle;
                Obj.len = Obj.calc_gap_length(diameterOutNeck);
                Obj.height = Obj.calc_design_gap_height(diameterOutNeck, tolerancePerMeter);
            end
        end

        function len = calc_gap_length(Obj, diameterOutNeck)
            len = diameterOutNeck / 2 * Obj.angle;
        end

        function height = calc_design_gap_height(Obj, diameterOutNeck, tolerancePerMeter)
            % Assumptions on gap height distribution (from AFToR project findings, according to IEC 61400-6/AMD1)
            heightMean = (6.5 ./ diameterOutNeck) .* (tolerancePerMeter / 1.4e-3) .* ...
                (0.025 * Obj.len.^2 + 0.12 .* Obj.len);
            heightCov = 0.35 + 200 * rad2deg(Obj.angle)^-1.6;
            heightStd = heightMean * heightCov;

            % Compute log-normal statistical parameters
            logStd = sqrt(log(1 + heightStd.^2  ./ heightMean.^2));
            logMean = log(heightMean) - logStd.^2 ./ 2;

            % The following lines are copied from Matlab's `logninv` function, which itself is not used to stay
            % independent of toolboxes (and corresponding licenses)
            PERCENTILE = 0.95;
            logx0 = -sqrt(2) .* erfcinv(2 * PERCENTILE);
            height = 1e-3 * exp(logStd .* logx0 + logMean);
        end

        function check_diameter_limitation(Obj, diameterOutNeck)
            % The formulas for computing design gap heights, in this class, are
            % applicable to flange diameters at the outside of the neck up to and including 10.0m.

            if diameterOutNeck > 10.0
                Obj.warning('USAIN:GapData:diameterLimitExceeded', ...
                    ['The diameter at the outside of the flange neck is %.3fm.\n', ...
                    'The design gap height calculations are applicable to diameters <= 10.0m.\n'], ...
                    diameterOutNeck);
            end
        end

    end

    methods (Static)

        function tolerance = calc_local_tolerance(diameter, tolerancePerMeter)
            % Returns local flatness tolerance (units m/30deg)
            length30Degrees = pi * diameter / 12;
            tolerance = tolerancePerMeter * length30Degrees^0.5;
        end

        function tolerance = calc_global_tolerance(diameter, tolerancePerMeter)
            % Returns global flatness tolerance (units m/360deg)
            % The factor 1.5 between local and global flatness is determined in the AFToR project, ref IEC 61400-6/AMD1
            tolerance = 1.5 * usain.sgre2.GapData.calc_local_tolerance(diameter, tolerancePerMeter);
        end

    end

end
