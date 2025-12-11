classdef InterpolatedShellStiffness < usain.sgre2.ShellStiffness

    properties
        Interpolant % 3D `scatteredInterpolant` such that stiffness = F(outer diam, thickness, gap angle)
    end

    properties (Constant)
        % CSV_DATA_FILE - .csv file with headers "radius", "thickness", "gap_angle", "shell_stiffness", describing FEA
        % shell stiffness data
        CSV_DATA_FILE = pathlib.Path('../shell_stiffness.csv').resolve_to(mfilename('fullpath'))
    end

    methods

        function Obj = InterpolatedShellStiffness()

            Csv = Obj.load_csv();
            Obj.Interpolant = Obj.setup_interpolant(Csv.data);
        end

        function Csv = load_csv(Obj)
            Csv = io.CsvFile('sourcePath', Obj.CSV_DATA_FILE);
            Csv.read('%f%f%f%f');
        end

        function Interpolant = setup_interpolant(~, CsvData)
            % CsvData: `data` from read `io.CsvFile` object
            %
            % This method assumes the following fields are present:
            %   - radius (shell radius, in mm)
            %   - thickness (shell thickness, in mm)
            %   - gap_angle (gap angle, in deg)
            %   - shell_stiffness (in N/mm/mm)
            % NOTE: This assumption is verified in unit tests

            % Set up interpolant based on FE data
            diameter = 2 * CsvData.radius * 1e-3;
            gapAngle = deg2rad(CsvData.gap_angle);
            Interpolant = scatteredInterpolant( ...
                diameter, ...
                CsvData.thickness * 1e-3, ...
                gapAngle, ...
                CsvData.shell_stiffness * 1e6); % N/m/m

            % Disallow extrapolation because it is unknown how reliable extrapolated results are
            Interpolant.ExtrapolationMethod = 'none';
        end

        function value = calc_stiffness(Obj, diameterOut, thicknessShell, angleGap, eModulus)
            % See `usain.sgre2.ShellStiffness.calc_stiffness` for argument list

            assert(any(abs(eModulus - 210e9) < 1e6), ...
                'Modulus of elasticity must be 210 MPa for interpolating shell stiffness.');

            value = Obj.Interpolant(diameterOut, ones(size(diameterOut)) * thicknessShell, ...
                ones(size(diameterOut)) * angleGap);

            assert(~any(isnan(value)), ...
                'InterpolatedShellStiffness:calc_stiffness:ExtrapolationNeeded', ...
                ['Extrapolation needed for shell stiffness calculations. This is not supported. ', ...
                'Use the `simplified` shell stiffness method instead (input SGRE2.SHELL_STIFFNESS_METHOD).']);
        end

    end
end
