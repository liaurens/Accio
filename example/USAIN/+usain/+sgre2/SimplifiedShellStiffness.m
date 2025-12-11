classdef SimplifiedShellStiffness < usain.sgre2.ShellStiffness

    methods

        function value = calc_stiffness(~, diameterOut, thicknessShell, angleGap, eModulus)
            % Compute shell stiffness using empirical estimate (validated against FEA)
            % NOTE: `shellStiffnessFactor` differs from documentation, as the formula here is adapted to SI units
            %
            % See `usain.sgre2.ShellStiffness.calc_stiffness` for argument list

            lengthGap = diameterOut / 2 * angleGap;
            shellStiffnessFactor = max(1.8, 1.3 + (0.8 - 0.16 * diameterOut / 2) .* lengthGap);
            value = eModulus * thicknessShell ./ shellStiffnessFactor ./ lengthGap;
        end

    end
end
