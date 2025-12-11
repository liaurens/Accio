classdef ReactionDistance < logging.Config
    % Effective reaction distance, in literature commonly refered to as a'
    % Both Seidel's and Tobinaga's methods for determining a' are supported. For
    % the former, distinction between FLS and ULS conditions are made.

    properties
        a double % Distance bolt axis to inside flange (a)
        b double % Distance bolt axis to mid shell (b)
        t double % Flange thickness
    end

    methods

        function Obj = ReactionDistance(a, b, t)
            if nargin
                Obj.a = a;
                Obj.b = b;
                Obj.t = t;
            end
        end

        function aEff = calc_aeff_seidel_fls(Obj)
            % In Seidel's thesis, this effective width is denoted with "a*"
            % This effective width is to be used for FLS conditions only

            % Compute reduced rim distance "a*"
            aEff = min(0.9 * Obj.t, Obj.a);

            % Additional criterion in case a > b
            aIfAGreaterThanB = min(aEff, ...
                Obj.b + (Obj.a - Obj.b) ./ (3 .* Obj.b) .* Obj.t);
            aEff(Obj.a > Obj.b) = aIfAGreaterThanB(Obj.a > Obj.b);
        end

        function aEff = calc_aeff_seidel_uls(Obj, tLim)
            % In Seidel's thesis, this effective width is denoted with "a'"
            % This effective width is to be used for ULS conditions only

            % Following [Seidel eqs. 167 & 168]
            aEff = min(Obj.a, ...
                max( ...
                    1.25 .* Obj.b, ...
                    min( ...
                        1.25 .* (Obj.t ./ tLim).^2 .* Obj.b, ...
                        3 .* Obj.b)));
        end

        function aEff = calc_aeff_tobinaga(Obj)

            % Following [Tobinaga 2017]
            lambda = Obj.calc_tobinaga_correction();
            aEff = lambda .* Obj.a;
        end

        function lambda = calc_tobinaga_correction(Obj)
            % Returns correction factor lambda on the point of reaction force
            % application, according to Tobinaga (2017).

            % Determine a/b ratio and stick to limits
            abRatio = Obj.a ./ Obj.b;

            % Determine aspect ratio "alpha" and cap its value to the limits
            % originally proposed by Tobinaga (also in IEC 61400-6 G.16)
            aspectRatio = Obj.t ./ (Obj.a + Obj.b);
            alpha = min(1, max(-0.12 * abRatio + 0.55, aspectRatio));

            % Compute correction factor lambda (also in IEC 61400-6 G.16)
            beta = (abRatio - 1.25).^0.32 + 0.45;
            lambda = min(1, 1 - (1 - alpha.^beta).^5);
            lambda(abRatio <= 1.25) = 1;
        end

        function pass = check_tobinaga_limits(Obj)
            abRatio = Obj.a ./ Obj.b;
            pass = abRatio <= 2.25;
        end

        function report_tobinaga_violation(Obj)
            pass = Obj.check_tobinaga_limits();
            if ~all(pass)
                Obj.warning('USAIN:ReactionDistance:TobinagaLimitExceeded', ...
                    ['Ratio a/b for flange is %.2f. ', ...
                    'Tobinaga''s method is applicable for a/b up to and including 2.25 only.\n', ...
                    'If the flange is highly utilized for ULS, extra precaution needs to be taken.', ...
                    '\n\n\t==> Please check the SGRE Design Rules and/or contact topic owner.'], ...
                    Obj.a ./ Obj.b);
            end
        end

    end
end
