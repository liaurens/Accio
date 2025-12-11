classdef BendingStressPath < UsainUtils.StressTransferFunction

    properties
        xGlobal double % Path along wall, x=0 at flange mating surface. Size [M, 2]
    end
    properties (Dependent)
        scf
    end

    methods

        function Obj = BendingStressPath(xGlobal, varargin)
            Obj@UsainUtils.StressTransferFunction(varargin{:});
            Obj.xGlobal = xGlobal;
        end

        function plot(Obj, upOrLo)
            % Overloads UsainUtils.StressTransferFunction.plot

            % Set up hidden InteractiveAxes
            IAx = UtilsGUIs.InteractiveAxes.quick_setup({'Visible', 'off'});

            % Plot some lines. Stresses are in SI-units ([Pa]) and humans
            % understand [MPa], so apply conversion factor of 1e-6
            scfIn = squeeze(Obj.scf(:, Obj.get_col_id(upOrLo, 'in'), :));
            scfOut = squeeze(Obj.scf(:, Obj.get_col_id(upOrLo, 'out'), :));
            IAx.hAx.ColorOrderIndex = 1;
            hLn = plot(IAx.hAx, 1e3 * Obj.xGlobal, scfIn, '-');
            IAx.hAx.ColorOrderIndex = 1;
            plot(IAx.hAx, 1e3 * Obj.xGlobal, scfOut, '--');

            % Plot weld toe position
            xToe = 1e3 * Obj.xWeldToe(Obj.get_col_id(upOrLo));
            plot(IAx.hAx, ones(1, 2) * xToe, [-5, 5], 'k:', 'YLimInclude', 'off');

            % Make pretty before showing on screen
            sNomMpa = 1e-6 * Obj.sNom(:, 1);
            Obj.markup_axis(IAx.hAx, upOrLo);
            IAx.legend(hLn, arrayfun(@(x) sprintf('%.0f MPa', x), sNomMpa, 'uni', 0), ...
                'Location', 'SouthEast', 'NumColumns', 2);
            IAx.hLeg.Title.String = 'Upper wall load level';
            IAx.hAx.Parent.Visible = 'on';
        end

        function markup_axis(Obj, hAx, upOrLo)
            % Overloads UsainUtils.StressTransferFunction.markup_axis

            % Make additional legend to distinguish inside/outside
            h(1) = plot(hAx, nan, nan, 'k-');
            h(2) = plot(hAx, nan, nan, 'k--');
            h(3) = plot(hAx, nan, nan, 'k:');
            hAxCopy = axes('Position', hAx.Position, 'Visible', 'off');
            legend(hAxCopy, h, {'Inside', 'Outside', 'Weld toe'}, ...
                'Location', 'NorthEast');

            % Add labels, titles and legends
            locStr = validatestring(upOrLo, {'upper', 'lower'});
            hAx.XLabel.String = 'Distance along wall (from mating surface) [mm]';
            hAx.YLabel.String = 'SCF [-]';
            hAx.Title.String = { ...
                sprintf('SCF along %s wall', locStr), ...
                sprintf('s1=%.1fmm; s2=%.1fmm', ...
                    1e3 * Obj.thkNose(1), 1e3 * Obj.thkNose(2))};

            % Axis markup
            hAx.XLim(1) = 0;
            grid(hAx, 'on');
        end

        function value = get.scf(Obj)
            value = Obj.sHotspot ./ [Obj.sNom, Obj.sNom];
        end

    end
end
