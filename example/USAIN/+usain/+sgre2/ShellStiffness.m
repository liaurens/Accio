classdef ShellStiffness

    properties (Constant)
        VALID_SHELL_STIFFNESS_METHODS = ["interpolated", "simplified"]
    end

    methods (Abstract)

        % Returns shell stiffness
        %
        % diameterOut: Outer diameter of shell [m]
        % thicknessShell: Thickness of shell [m]
        % angleGap: Angle of gap [rad]
        % eModulus: Modulus of elasticity [Pa]
        value = calc_stiffness(Obj, diameterOut, thicknessShell, lengthGap, eModulus)

    end

    methods (Static)

        function Obj = create(methodName)
            % Factory method for returning a concrete ShellStiffness instance

            switch methodName
                case "simplified"
                    Obj = usain.sgre2.SimplifiedShellStiffness();
                case "interpolated"
                    Obj = usain.sgre2.InterpolatedShellStiffness();
                otherwise
                    error('ShellStiffness:UnsupportedMethod', ...
                        'Method %s is not supported.', methodName);
            end
        end

    end
end
