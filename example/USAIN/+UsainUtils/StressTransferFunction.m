classdef StressTransferFunction < matlab.mixin.SetGet

    properties
        % NOTE: Using s* as abbreviating prefix for stress variables
        sNom double % Nominal stress. Size [N, 2] for resp. upper and lower wall
        sBend double % Bending stress. Size [N, 4] according to static properties in UsainUtils.FlangeNeckScf
        %            % (e.g. I_IN_UP)

        % Metadata for figure (titles, axis labels, legends)
        thkNose double % Wall thickness [upper, lower]
        xWeldToe double % Distance weld toe from flange mating surface [upper, lower]
    end
    properties
        sHotspot double % Hotspot stress. Size [N, 4], see property sBend
    end

    methods

        function Obj = StressTransferFunction(sNom, sBend, varargin)
            if nargin
                Obj.sNom = sNom;
                Obj.sBend = sBend;
                Obj = assign_varargin_2_classprop(Obj, varargin{:});
            end
        end

        function iCol = get_col_id(~, upOrLo, inOrOut)
            % Convenience method to get column from N-by-4 array
            if nargin < 3
                % Or N-by-2 array
                inOrOut = 'in';
            end
            indexProp = sprintf('I_%s_%s', upper(inOrOut), upper(upOrLo));
            iCol = UsainUtils.FlangeNeckScf.(indexProp);
        end

        function plot(Obj, upOrLo)

            % Set up hidden InteractiveAxes
            IAx = UtilsGUIs.InteractiveAxes.quick_setup({'Visible', 'off'});

            % Plot some lines. Stresses are in SI-units ([Pa]) and humans
            % understand [MPa], so apply conversion factor of 1e-6
            hotspotIn = Obj.sHotspot(:, Obj.get_col_id(upOrLo, 'in'));
            hotspotOut = Obj.sHotspot(:, Obj.get_col_id(upOrLo, 'out'));
            x = Obj.sNom(:, Obj.get_col_id(upOrLo));
            y = [hotspotIn, hotspotOut];
            plot(IAx.hAx, 1e-6 * x, 1e-6 * y, '-');
            plot(IAx.hAx, 1e-6 * x, 1e-6 * x, '--');

            % Make pretty before showing on screen
            IAx.legend({'Inside', 'Outside', 'Linear (SCF = 1)'}, 'Location', 'NorthWest');
            Obj.markup_axis(IAx.hAx, upOrLo);
            IAx.hAx.Parent.Visible = 'on';
        end

        function markup_axis(Obj, hAx, upOrLo)
            % Adds some swag to the figure

            % Add labels, titles and legends
            locStr = validatestring(upOrLo, {'upper', 'lower'});
            hAx.XLabel.String = 'Nominal stress [MPa]';
            hAx.YLabel.String = 'Hotspot stress [MPa]';
            hAx.Title.String = { ...
                sprintf('Stress depending on load level, %s wall', locStr), ...
                sprintf('s1=%.1fmm; s2=%.1fmm; x=%.0fmm', ...
                    1e3 * Obj.thkNose(1), 1e3 * Obj.thkNose(2), ...
                    1e3 * Obj.xWeldToe(Obj.get_col_id(upOrLo)))};

            % Axis markup
            grid(hAx, 'on');
            hAx.XAxisLocation = 'origin';
            hAx.YAxisLocation = 'origin';
            axis(hAx, 'tight');
        end

        function value = get.sHotspot(Obj)
            value = Obj.sBend + [Obj.sNom, Obj.sNom];
        end

    end
end
