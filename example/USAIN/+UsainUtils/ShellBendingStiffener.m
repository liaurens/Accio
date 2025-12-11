classdef ShellBendingStiffener < UsainUtils.ShellBending
    % Models shell bending stresses due to eccentricity and stiffener effect.
    % Three effects are captured simultaneously:
    % 1. Eccentricity: Different wall thickness above and below the connection
    %    creates an eccentricity moment, which is inducing torsion in the flange
    %    (considered as a rigid ring) and bending in the shells to the this
    %    torsion/rotation of the ring.
    % 2. Stiffener effect: The flange acts as a stiffener to the shell. When the
    %    shell is loaded meridionally, a diameter change would occur for the
    %    unconstrained shell (due to transverse strain developing, depending on
    %    the Poisson's ratio). This deformation is partially prevented by the
    %    flange, which in turn introduces local bending in the shell.
    % 3. Tolerances: Similar to eccentricity, tolerances (e.g. from
    %    fabrication or enlarged bolt holes) could introduce an additional
    %    moment. This is captured by a modelling a radius shift.
    %
    % The local origin x=0 depends on the flange thickness and nose thickness,
    % see method calc_local_origin.
    %
    % Reference:
    %   Seidel, Marc. (2020). Analytical calculation of stress concentrations at
    %   welded flange necks. [Stahlbau]
    %

    properties
        % NOTE: A note on property sizes is given in parent class
        % UsainUtils.ShellBending
    end
    properties (Dependent)
        hRb double % Height of rigid body that represents the stiffener
        wRb double % Width of rigid body that represents the stiffener
        rRb double % Radius (mid) of rigid body that represents the stiffener
    end

    methods

        function Obj = ShellBendingStiffener(varargin)
            if nargin
                Obj = assign_varargin_2_classprop(Obj, varargin{:});
            end
        end

        function [q0, m0] = calc_bending_coefficients(Obj, stress)
            % See parent method:
            %   UsainUtils.ShellBending/calc_bending_coefficients

            Obj.validate_stress_input(stress);

            % Shortcuts (common literature symbols are used)
            bh = Obj.wRb * Obj.hRb;
            bh3 = Obj.wRb * Obj.hRb^3;
            k = Obj.flexRigdty;
            beta = Obj.geomParam;
            rMid = Obj.rNose;

            % Set up matrix of flexibility coefficients
            delta = zeros(4);
            delta(1, 1) = Obj.eMod / k(1) / (2 * beta(1)^3) + Obj.rRb * rMid(1) / bh;
            delta(1, 2) = Obj.eMod / k(1) / (2 * beta(1)^2);
            delta(1, 3) = Obj.rRb * rMid(2) / bh;
            delta(2, 1) = Obj.eMod / k(1) / (2 * beta(1)^2);
            delta(2, 2) = Obj.eMod / k(1) / beta(1) + 12 * Obj.rRb * rMid(1) / bh3;
            delta(2, 4) = -12 * Obj.rRb * rMid(2) / bh3;
            delta(3, 1) = Obj.rRb * rMid(1) / bh;
            delta(3, 3) = Obj.rRb * rMid(2) / bh + Obj.eMod / k(2) / (2 * beta(2)^3);
            delta(3, 4) = Obj.eMod / k(2) / (2 * beta(2)^2);
            delta(4, 2) = -12 * Obj.rRb * rMid(1) / bh3;
            delta(4, 3) = Obj.eMod / k(2) / (2 * beta(2)^2);
            delta(4, 4) = 12 * Obj.rRb * rMid(2) / bh3 + Obj.eMod / k(2) / beta(2);

            % Set up vector with deformations caused by external loading
            force = stress .* Obj.thkNose(1) .* rMid(1) ./ rMid;
            momentEccentr = force(:, 1) * rMid(1) / Obj.rRb * diff(-rMid);
            delta0 = zeros(4, length(stress));
            delta0(1, :) = -Obj.nu * rMid(1) / Obj.thkNose(1) * force(:, 1);
            delta0(2, :) = -12 * momentEccentr * Obj.rRb^2 / bh3;
            delta0(3, :) = -Obj.nu * rMid(2) / Obj.thkNose(2) * force(:, 2);
            delta0(4, :) = 12 * momentEccentr * Obj.rRb^2 / bh3;

            % Solve Ax + b = 0 (A = delta, b = delta0)
            soln = delta \ -delta0;

            % Solution `soln` has size [4*N] for N stress levels. Transpose to
            % returns [N*2] vectors q0 and m0, where the 2 represents the upper
            % and lower flange respectively
            q0 = soln([1 3], :)';
            m0 = soln([2 4], :)';
        end

        function x0 = calc_local_origin(Obj)
            % See parent method:
            %   UsainUtils.ShellBending/calc_local_origin

            x0 = max(Obj.thk - 3 * Obj.thkNose, 0);
        end

        function value = get.hRb(Obj)
            value = 2 * Obj.thk;
        end

        function value = get.wRb(Obj)
            value = Obj.wid;
        end

        function value = get.rRb(Obj)
            value = (Obj.diamOutNeck - Obj.wRb) / 2;
        end

    end
end
