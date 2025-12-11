classdef FlangeDamageIndicator
    % Flange Damage Indicator (FDI)
    %
    % Typical syntax:
    %     >> Markov = Milk.Markov.setup_from_markov_file( ... );
    %     >> [ranges, cycles, means] = Markov.reshape_markov_matrix( ... );
    %     >> fdi = usain.loads.FlangeDamageIndicator(a1=0.1, a2=0.0003, m=4).calc_fdi(ranges, cycles, means);

    properties
        a1 (1, 1) double  % Coefficient a1, typically 0.1
        a2 (1, 1) double  % Coefficient a2, typically 0.0003
        m (1, 1) double  % Woehler slope

        fdi (1, 1) double  % Computed FDI value
    end

    methods

        function Obj = FlangeDamageIndicator(kwargs)
            % a1, a2: Coefficients for FDI, typically 0.1 and 0.0003 respectively
            % m: Woehler slope, typically 4

            arguments
                kwargs.a1 (1, 1) double = nan
                kwargs.a2 (1, 1) double = nan
                kwargs.m (1, 1) double = nan
            end

            Obj.a1 = kwargs.a1;
            Obj.a2 = kwargs.a2;
            Obj.m = kwargs.m;
        end

        function Obj = calc_fdi(Obj, ranges, cycles, means)
            % ranges, cycles, means: N-by-1 arrays with vectorized Markov columns, in SI units

            assert(length(cycles) == length(means) && length(cycles) == length(ranges), ...
                'Input vectors must be of equal length.');

            % The FDI assumes moments in MNm
            means_MNm = Unit.MNm.from_si(means);
            ranges_MNm = Unit.MNm.from_si(ranges);

            fdiEntries = cycles .* ((Obj.a1 + 2 * Obj.a2 * means_MNm) .* ranges_MNm).^Obj.m;
            isTensile = (means + 0.5 * ranges) > 0;
            Obj.fdi = sum(fdiEntries(isTensile));
        end

    end
end
