classdef UltimateLimitState < UsainUtils.UlsCondition
    % ULTIMATELIMITSTATE Condition for ULS resistance of L-flanges
    %   Calculation of stress in the flange is done according to Petersen and
    %   Seidel:
    %   - Petersen: Stahlbau - Grundlagen der Berechnung und baulichen
    %     Ausbildung von Stahlbauten, 3. Auflage, 1997 (chapter 9.6.4.:
    %     plasto-statische Theorie des L-modelles.)
    %   - Schaumann/Seidel: Zur Bestimmung der Grenztragfaehigkeit von
    %     Verbindungenmit planmaessig auf Zug beanspruchten Schrauben,
    %     Bauingenieur 75 (2000).
    %
    %   Assumptions:
    %   1) The elastic-plastic theory is used.
    %   2) The flange is regarded as a beam with the width of one bolt.
    %   3) The limit states are calculated based on the theory of yield hinges.
    %
    %   The original approach according to Petersen contains three possible
    %   failure modes (A, B, C). Seidel enhanced the calculation by replacing
    %   failure more C by two failure modes D and E. Usually, using failure mode
    %   D and E results in higher allowable tension in the bolted connection
    %   compared to failure mode C and therefore only modes A, B, D and E will
    %   be considered:
    %   - Failure Mode A: Failure of the bolt due to tension.
    %   - Failure Mode B: Failure of the bolt due to tension and yield hinge
    %     in tower shell.
    %   - Failure Mode D: Yield hinge in tower shell and in flange material,
    %     additional bending stiffness of bolts is included.
    %   - Failure Mode E: Assumed yield hinge in flange in middle of the
    %     washer.

    properties
        % N = Number of design points
        % M = Number of load sets
        failModeA % [N x M] Segment force at which failure mode A occurs
        failModeB % [N x M] Segment force at which failure mode B occurs
        failModeD % [N x M] Segment force at which failure mode D occurs
        failModeE % [N x M] Segment force at which failure mode E occurs

        boltStrengthDes  % [N x M] Tensile resistance of a bolt
        plasticLimit     % [N x M] Plastic capacity of flange neck (axial for L-flanges, shear for T-flanges)

        description string = "Ultimate limit state"
    end
    properties (Dependent)
        failModeCrit     % [N x 1] Critical (design driving) failure mode level
        failModeCritStr string  % [N x 1] Critical (design driving) failure mode string
    end
    properties (Constant)
        MAX_ITER = 100  % Max. number of iterations to converged to failure mode (for B, D and E)
        VALID_REACTION_DIST_METHODS = {'seidel' 'tobinaga'}
        TOGGLE_NAME = 'DO_ASSESS_ULS'
    end

    methods

        function Obj = UltimateLimitState(varargin)
            % Call superclass constructor
            Obj@UsainUtils.UlsCondition(varargin{:});
        end

        function setup_condition(Obj)
            Obj.yieldStrengthDes = Obj.calc_design_yield_strength();
            Obj.boltStrengthDes = Obj.calc_design_tension_resistance_bolt();
            Obj.plasticLimit = Obj.calc_plastic_limit_neck();

            % Evaluate failure modes
            Obj.failModeA = Obj.calc_failure_mode_a();
            Obj.failModeB = Obj.calc_failure_mode_b();
            Obj.failModeD = Obj.calc_failure_mode_d();
            Obj.failModeE = Obj.calc_failure_mode_e();
        end

        function evaluate_condition(Obj)
            Obj.mxy = Obj.Mdl.Loads.ulsMxyDesign + Obj.Mdl.Loads.inclinMomentDesign;
            Obj.fz = -Obj.Mdl.Loads.deadWeightFavorDesignUls;
            Obj.fDesign = Obj.calc_design_segment_force();

            Obj.utilRatio = Obj.fDesign ./ Obj.failModeCrit;
        end

        function value = get_isFeasible_impl(Obj)

            % Regardless of flange type, require that the utilization <= the target
            isFeasibleUtilization = Obj.utilRatio <= Obj.targetUtilRatio;

            % Depending on flange type, either FM B or FM A should be governing
            if strcmp(Obj.Mdl.flangeType, 'L')
                expectedCriticalFailureMode = "B";
            elseif strcmp(Obj.Mdl.flangeType, 'T')
                expectedCriticalFailureMode = "A";
            else
                error('Implementation error.');
            end
            hasFeasibleMechanics = Obj.failModeCritStr == expectedCriticalFailureMode;

            % Concatenate over second dimension (= number of load sets)
            value = all(isFeasibleUtilization & hasFeasibleMechanics, 2);
        end

        function failMode = calc_failure_mode_a(Obj)
            % Compute ULS failure mode A
            % See class helpdoc for more info
            %

            % Define failure mode A, which is static and equal to the bolt
            % plastic limit
            failMode = Obj.Mdl.flangeTypeFactor .* Obj.boltStrengthDes;
        end

        function failMode = calc_failure_mode_b(Obj)
            % Compute ULS failure mode B

            ftRd = Obj.boltStrengthDes;
            bB = Obj.calc_outer_width('B');
            cStar = Obj.Mdl.Segment.distBoltAtShell;
            fyD = Obj.yieldStrengthDes;

            % Calculate the effective rim distance a'
            aPrime = Obj.calc_effective_rim_distance();

            % Define shorthand notation, to be used in the remainder of this method
            c = cStar;
            f = fyD;

            % Use notation from `docs\explanation\closed-form-failure-modes.md`
            Mi = ftRd .* aPrime;
            Li = aPrime + bB;

            [coefficientA, coefficientB, coefficientC] = Obj.get_quadratic_equation_coefficients(f, c, Li, Mi);
            failMode = Obj.solve_quadratic_equation(coefficientA, coefficientB, coefficientC);

            % Check if flange neck yields before failure mode (N > Npl or N > 2*Vpl). If so, this failure mode will not
            % occur. Compute the failure mode without M/N or M/V interaction to have a value to demonstrate that this
            % failure mode is not driving
            isFailureModeExceedsPlasticLimit = failMode > (Obj.Mdl.flangeTypeFactor * Obj.plasticLimit);
            failModeWithoutMpl3 = Obj.Mdl.flangeTypeFactor .* (ftRd .* aPrime) ./ (aPrime + bB);
            failMode(isFailureModeExceedsPlasticLimit) = failModeWithoutMpl3(isFailureModeExceedsPlasticLimit);
        end

        function failMode = calc_failure_mode_d(Obj)
            % Compute ULS failure mode D

            thickn = Obj.Mdl.Space.thickness;
            fyD = Obj.yieldStrengthDes;
            bD = Obj.calc_outer_width('D');
            cPrime = Obj.Mdl.Segment.distBolt - Obj.Mdl.Inputs.diamBoltHole;
            cStar = Obj.Mdl.Segment.distBoltAtShell;

            % Compute plastic moment at bolt hole side
            mPl2Prime = (fyD .* cPrime .* thickn.^2) ./ 4;

            % Additional bending moment to account for influence of bolt bending
            diamContact = usain.fastener.calc_contact_diameter(Obj.Mdl.Nut.diam, Obj.Mdl.Wash.diamOut, ...
                Obj.Mdl.Wash.len);
            ftRd = Obj.boltStrengthDes;
            deltaMpl2 = (ftRd / 2) .* ((diamContact + Obj.Mdl.Inputs.diamBoltHole) ./ 4);

            % Define shorthand notation, to be used in the remainder of this method
            c = cStar;
            f = fyD;

            % Use notation from `docs\explanation\closed-form-failure-modes.md`
            Mi = mPl2Prime + deltaMpl2;
            Li = bD;

            [coefficientA, coefficientB, coefficientC] = Obj.get_quadratic_equation_coefficients(f, c, Li, Mi);
            failMode = Obj.solve_quadratic_equation(coefficientA, coefficientB, coefficientC);

            % Check if flange neck yields before failure mode (N > Npl or N > 2*Vpl). If so, this failure mode will not
            % occur. Compute the failure mode without M/N or M/V interaction to have a value to demonstrate that this
            % failure mode is not driving
            isFailureModeExceedsPlasticLimit = failMode > (Obj.Mdl.flangeTypeFactor * Obj.plasticLimit);
            failModeWithoutMpl3 = Obj.Mdl.flangeTypeFactor .* (mPl2Prime + deltaMpl2) ./ bD;
            failMode(isFailureModeExceedsPlasticLimit) = failModeWithoutMpl3(isFailureModeExceedsPlasticLimit);
        end

        function failMode = calc_failure_mode_e(Obj)
            % Compute ULS failure mode E

            thickn = Obj.Mdl.Space.thickness;
            fyD = Obj.yieldStrengthDes;
            bE = Obj.calc_outer_width('E');
            c = Obj.Mdl.Segment.distBolt;
            cStar = Obj.Mdl.Segment.distBoltAtShell;

            % Compute plastic moment at bolt hole center
            mPl2 = (fyD .* c .* thickn.^2) ./ 4;

            % Define shorthand notation, to be used in the remainder of this method
            f = fyD;
            c = cStar;

            % Use notation from `docs\explanation\closed-form-failure-modes.md`
            Mi = mPl2;
            Li = bE;

            [coefficientA, coefficientB, coefficientC] = Obj.get_quadratic_equation_coefficients(f, c, Li, Mi);
            failMode = Obj.solve_quadratic_equation(coefficientA, coefficientB, coefficientC);

            % Check if flange neck yields before failure mode (N > Npl or N > 2*Vpl). If so, this failure mode will not
            % occur. Compute the failure mode without M/N or M/V interaction to have a value to demonstrate that this
            % failure mode is not driving
            isFailureModeExceedsPlasticLimit = failMode > (Obj.Mdl.flangeTypeFactor * Obj.plasticLimit);
            failModeWithoutMpl3 = Obj.Mdl.flangeTypeFactor .* mPl2 ./ bE;
            failMode(isFailureModeExceedsPlasticLimit) = failModeWithoutMpl3(isFailureModeExceedsPlasticLimit);
        end

        function failMode = calc_failure_mode_b_iterative(Obj)

            bB = Obj.calc_outer_width('B');
            aEff = Obj.calc_effective_rim_distance();
            ftRd = Obj.boltStrengthDes;

            % Solve
            failureModeFunction = @(mPl3) Obj.Mdl.flangeTypeFactor .* (ftRd .* aEff + mPl3) ./ (aEff + bB);
            [failMode, isConverged] = Obj.solve_failure_mode(failureModeFunction);

            % Check convergence of M/N or M/V interaction. Compute non-converged failure modes with Mpl3=0.
            Obj.verify_convergence(isConverged, 'B');
            if any(~isConverged)
                failureModeWithoutInteraction = failureModeFunction(0);
                failMode(~isConverged) = failureModeWithoutInteraction(~isConverged);
            end
        end

        function failMode = calc_failure_mode_d_iterative(Obj)

            thickn = Obj.Mdl.Space.thickness;
            fyD = Obj.yieldStrengthDes;
            bD = Obj.calc_outer_width('D');
            cPrime = Obj.Mdl.Segment.distBolt - Obj.Mdl.Inputs.diamBoltHole;
            mPl2Prime = (fyD .* cPrime .* thickn.^2) ./ 4;
            diamContact = usain.fastener.calc_contact_diameter(Obj.Mdl.Nut.diam, Obj.Mdl.Wash.diamOut, ...
                Obj.Mdl.Wash.len);
            deltaMpl2 = (Obj.boltStrengthDes / 2) .* ((diamContact + Obj.Mdl.Inputs.diamBoltHole) ./ 4);

            % Solve
            failureModeFunction = @(mPl3) Obj.Mdl.flangeTypeFactor .* (mPl2Prime + deltaMpl2 + mPl3) ./ bD;
            [failMode, isConverged] = Obj.solve_failure_mode(failureModeFunction);

            % Check convergence of M/N or M/V interaction. Compute non-converged failure modes with Mpl3=0.
            Obj.verify_convergence(isConverged, 'D');
            if any(~isConverged)
                failureModeWithoutInteraction = failureModeFunction(0);
                failMode(~isConverged) = failureModeWithoutInteraction(~isConverged);
            end
        end

        function failMode = calc_failure_mode_e_iterative(Obj)

            thickn = Obj.Mdl.Space.thickness;
            fyD = Obj.yieldStrengthDes;
            bE = Obj.calc_outer_width('E');
            mPl2 = (fyD .* Obj.Mdl.Segment.distBolt .* thickn.^2) ./ 4;

            % Solve
            failureModeFunction = @(mPl3) Obj.Mdl.flangeTypeFactor .* (mPl2 + mPl3) ./ bE;
            [failMode, isConverged] = Obj.solve_failure_mode(failureModeFunction);

            % Check convergence of M/N or M/V interaction. Compute non-converged failure modes with Mpl3=0.
            Obj.verify_convergence(isConverged, 'E');
            if any(~isConverged)
                failureModeWithoutInteraction = failureModeFunction(0);
                failMode(~isConverged) = failureModeWithoutInteraction(~isConverged);
            end
        end

        function [failMode, isConverged] = solve_failure_mode(Obj, func)
            % Iteratively solves failure mode
            %
            % func: function_handle to compute failure mode, which takes 1 input argument: Mpl3

            % Initialize while-loop
            failMode = 0;
            iIter = 1;
            isConverged = false;

            while ~all(isConverged(:)) && iIter < Obj.MAX_ITER

                % Compute plastic moment at location 3 (which depends on the failure mode itself due to M/N or M/V
                % interaction)
                plasticMoment3 = Obj.calc_plastic_moment(failMode, Obj.plasticLimit);

                % Update failure mode
                prevMode = failMode;
                failMode = func(plasticMoment3);

                % Check convergence
                absDelta = abs(failMode - prevMode);
                isConverged = absDelta <= 1;
                iIter = iIter + 1;

                if all(failMode(:) > (Obj.Mdl.flangeTypeFactor * Obj.plasticLimit(:)))
                    % The failure mode for all design points exceed the plastic limit. Terminate iterations and return
                    % failure mode when Mpl3 = 0.
                    isConverged = true(size(failMode));
                    failMode = func(0);
                    break
                end
            end
        end

        function plasticMoment = calc_plastic_moment(Obj, fMode, plasticLimit)
            % Calculates plastic moment at 'location 3'
            % In literature referred to as "plastic moment 3", symbol Mpl3

            % Shortcuts
            cStar = Obj.Mdl.Segment.distBoltAtShell;
            fyD = Obj.yieldStrengthDes;
            minTNose = min(Obj.Mdl.Inputs.thicknNoseUp, Obj.Mdl.Inputs.thicknNoseLo);
            thickn = Obj.Mdl.Space.thickness;

            % Compute plastic moment at 'location 3' (flange neck for L-flanges, flange for T-flanges)
            switch Obj.Mdl.flangeType
                case 'L'
                    plasticMoment = (1 - (fMode ./ plasticLimit).^2) .* (fyD .* cStar .* minTNose.^2) ./ 4;
                    plasticMoment(fMode > plasticLimit) = 0;
                case 'T'
                    plasticMoment = sqrt(1 - ((fMode ./ 2) ./ plasticLimit).^2) .* ((fyD .* cStar .* thickn.^2) ./ 4);
                    plasticMoment(fMode > 2 * plasticLimit) = 0;
                    % NOTE: We check `N/(2*Vpl)`, and use `Fu/2` in the calculation of Mpl3_M/V, because connection is
                    % symmetrical while the model considers only the L-flange part
                otherwise
                    error('Implementation error');
            end
        end

        function plastMom = calc_init_plastic_moment(Obj)
            % Initial guess for plastic moment at 'location 3' (plastic deformation at weld neck), to be used to
            % determine the effective inner width, a', when using 'seidel' as REACTION_DISTANCE_METHOD.

            % Shortcuts
            cStar = Obj.Mdl.Segment.distBoltAtShell;
            minTNose = min(Obj.Mdl.Inputs.thicknNoseUp, Obj.Mdl.Inputs.thicknNoseLo);
            thickn = Obj.Mdl.Space.thickness;

            % Compute plastic moment
            switch Obj.Mdl.flangeType
                case 'L'
                    plastMom = (Obj.Mdl.Inputs.yieldStrengthChar .* cStar .* minTNose.^2) ./ 4;
                case 'T'
                    plastMom = (Obj.Mdl.Inputs.yieldStrengthChar .* cStar .* thickn.^2) ./ 4;
                otherwise
                    error('Implementation error');
            end
        end

        function plasticLimit = calc_plastic_limit_neck(Obj)
            % Computes N_pl (L-flanges) or V_pl (T-flanges), i.e. the force at which the flange neck yields

            segmentWidth = Obj.Mdl.Segment.distBoltAtShell;

            switch Obj.Mdl.flangeType
                case 'L'
                    % Compute `N_pl`,i.e. the force at which the flange neck fails under pure tension
                    thickness = min(Obj.Mdl.Inputs.thicknNoseUp, Obj.Mdl.Inputs.thicknNoseLo);
                    plasticLimit = segmentWidth .* thickness .* Obj.yieldStrengthDes;

                case 'T'
                    % Computes `V_pl`, i.e. the force at which the flange neck fails under pure shear
                    thickness = Obj.Mdl.Space.thickness;
                    plasticLimit = ((1 / sqrt(3)) .* segmentWidth .* thickness .* Obj.yieldStrengthDes);

                otherwise
                    error('Implementation error');
            end
        end

        function [coefficientA, coefficientB, coefficientC] = get_quadratic_equation_coefficients(Obj, f, c, Li, Mi)
            % Helper method to determine the coefficients to solve `ax^2 + bx + c = 0`
            %
            % see also `docs\explanation\closed-form-failure-modes.md`

            switch Obj.Mdl.flangeType
                case 'L'
                    t = min(Obj.Mdl.Inputs.thicknNoseUp, Obj.Mdl.Inputs.thicknNoseLo);

                    coefficientA = 1 ./ (4 .* f .* c .* Li);
                    coefficientB = 1;
                    coefficientC = -(Mi ./ Li) - (f .* t.^2 .* c) ./ (4 .* Li);
                case 'T'
                    t = Obj.Mdl.Space.thickness;

                    coefficientA = ((3 .* t.^2) ./ (16 * Li.^2)) + 1;
                    coefficientB = (-4 .* Mi) ./ Li;
                    coefficientC = ((4 .* Mi.^2) ./ Li.^2) - ((c.^2 .* f.^2 .* t.^4) ./ (4 .* Li.^2));
            end
        end

        function solution = solve_quadratic_equation(Obj, a, b, c)
            % Helper method to solve `ax^2 + bx + c = 0` and returning the physical solution
            %
            % a, b, c: coefficients for quadratic equation, see also `docs\explanation\closed-form-failure-modes.md`

            solution1 = (-b + sqrt(b.^2 - 4 .* a .* c)) ./ (2 .* a);
            solution2 = (-b - sqrt(b.^2 - 4 .* a .* c)) ./ (2 .* a);

            solution = Obj.get_physical_solution(solution1, solution2);
        end

        function soln = get_physical_solution(~, soln1, soln2)
            % Returns the physical failure mode value from different analytical solutions
            %
            % The iterative failure mode calculations are rewritten into an analytical form, yielding multiple
            % solutions (similar to the fact that x^2 = 4 has two solutions x = 2 and x = -2).
            % This helper method returns the physically correct failure mode, given two solutions.

            % First, discard any complex number; this is non-physical and indicates infeasibility
            soln1(abs(imag(soln1)) > 0) = nan;
            soln2(abs(imag(soln2)) > 0) = nan;

            % Take maximum failure mode of both solutions (one is expected to be negative, which is the
            % solution we want to ignore)
            soln = max(real(soln1), real(soln2));
        end

        function verify_convergence(Obj, isConverged, failureModeStr)
            % Checks if iteratively solved failure modes have converged
            % Modes B, D and E require iterations to solve for the M/N or M/V interaction. If the failure mode is not
            % governing (e.g. when neck yielding develops for smaller forces than the failure mode), the iterative
            % stepping does not converge.
            % This method logs a warning in case non-convergence is detected.

            % TODO: Do not log anything if this failure mode is not governing

            if ~all(isConverged)
                Obj.warning('USAIN:UltimateLimitState:NotConverged', ...
                    ['M/N or M/V interaction for failure mode %s did not converge. ', ...
                    'If this failure mode is not governing, non-convergence is OK.\n', ...
                    'If this failure mode is governing, this flange design is not feasible.'], ...
                    failureModeStr);
            end
        end

        function tLim = calc_limit_thickness(Obj, effRimDist, plastMoment)

            % Define shortcuts, using names Seidel's naming convention (mostly)
            aEff = effRimDist;
            b = Obj.Mdl.Segment.distForce;
            cPrime = Obj.Mdl.Segment.distBolt - Obj.Mdl.Inputs.diamBoltHole;
            fyChar = Obj.Mdl.Inputs.yieldStrengthChar;
            ftRc = Obj.Mdl.Bolt.ftRc;

            % Following [Seidel eq 164]
            diamContact = usain.fastener.calc_contact_diameter(Obj.Mdl.Nut.diam, Obj.Mdl.Wash.diamOut, ...
                Obj.Mdl.Wash.len);
            tLim = sqrt( ...
                ((ftRc .* aEff + plastMoment) ./ (aEff + b) .* (8 * b) - ...
                ftRc .* (diamContact + Obj.Mdl.Inputs.diamBoltHole) - ...
                8 .* plastMoment) ./ ...
                (2 .* cPrime .* fyChar));
        end

        function bX = calc_outer_width(Obj, failMode)
            % Determines the outer width (in literature referred to as distance b) to consider in the failure mode
            % calculation. It is dependend on both failure mode and flange type.

            bX = Obj.Mdl.Segment.distForce;

            if strcmpi(failMode, 'E')
                diamContact = usain.fastener.calc_contact_diameter(Obj.Mdl.Nut.diam, Obj.Mdl.Wash.diamOut, ...
                    Obj.Mdl.Wash.len);
                bX = bX - ((diamContact + Obj.Mdl.Inputs.diamBoltHole) ./ 4);
            end

            if strcmpi(Obj.Mdl.flangeType, 'T')
                r = Obj.Mdl.Inputs.FILLET_RADIUS;
                thkNose = min([Obj.Mdl.Inputs.thicknNoseUp, Obj.Mdl.Inputs.thicknNoseLo]);
                bX = bX - 0.5 .* thkNose - 0.8 .* r;
            end
        end

        function effRimDist = calc_effective_rim_distance(Obj)
            switch lower(Obj.Mdl.Inputs.REACTION_DISTANCE_METHOD)
                case 'seidel'
                    % Limit thickness values are not known at this point; provide actual thickness values to compute
                    % first guess for the effective rim distance
                    thickn = Obj.Mdl.Space.thickness;
                    effRimDist = Obj.Mdl.Segment.ReactDist.calc_aeff_seidel_uls(thickn);
                    plastMomShell = Obj.calc_init_plastic_moment();

                    % Calculate distance bolt center to reaction force
                    iIter = 1;
                    isConverged = false;
                    while ~all(isConverged(:)) && iIter < Obj.MAX_ITER

                        tLim = Obj.calc_limit_thickness(effRimDist, plastMomShell);
                        prevRimDist = effRimDist;
                        effRimDist = Obj.Mdl.Segment.ReactDist.calc_aeff_seidel_uls(tLim);

                        isConverged = abs(prevRimDist - effRimDist) <= 1e-5;  % converged if delta < 0.01mm
                        iIter = iIter + 1;
                    end

                case 'tobinaga'
                    % Following Tobinaga (2017); no need to update iteratively
                    effRimDist = Obj.Mdl.Segment.ReactDist.calc_aeff_tobinaga();

                otherwise
                    Obj.validatestring(Obj.Mdl.Inputs.REACTION_DISTANCE_METHOD, ...
                        Obj.VALID_REACTION_DIST_METHODS, mfilename, 'input "REACTION_DISTANCE_METHOD"');
            end
        end

        function report_results(Obj)

            % TODO: Extend reporting with N/Npl results and convergence check

            % Shortcuts
            nLoadSets = Obj.Mdl.Loads.nLoadSets;
            critModeStr = Obj.failModeCritStr;
            critMode = Obj.failModeCrit;

            str = cell(nLoadSets + 1, 1);
            for iLoadSet = 1:nLoadSets

                if any([Obj.Mdl.Loads.Uls.isEmpty])
                    thisTag = 'Expert input: ULS_BENDING_MOMENT';
                else
                    thisTag = Obj.Mdl.Loads.Uls(iLoadSet).tag;
                end

                if strcmp(Obj.Mdl.flangeType, 'L')
                    modeB = Obj.failModeB;
                    str{iLoadSet + 1} = { ...
                        sprintf('LOAD SET #%i (%s)', iLoadSet, thisTag)
                        '-----------------------------+--------------------------'
                        sprintf('Critical failure mode        | %14s', critModeStr(iLoadSet))
                        sprintf('Critical failure mode level  | %14.0f kN', 1e-3 * critMode(iLoadSet))
                        sprintf('Failure mode B level         | %14.0f kN ', 1e-3 * modeB(iLoadSet))
                        sprintf('FM D / FM B                  | %14.2f', Obj.failModeD(iLoadSet) / modeB(iLoadSet))
                        '-----------------------------+--------------------------'
                        ''
                        };

                elseif strcmp(Obj.Mdl.flangeType, 'T')
                    str{iLoadSet + 1} = { ...
                        sprintf('LOAD SET #%i (%s)', iLoadSet, thisTag)
                        '-----------------------------+--------------------------'
                        sprintf('Critical failure mode        | %14s', critModeStr(iLoadSet))
                        sprintf('Critical failure mode level  | %14.0f kN', 1e-3 * critMode(iLoadSet))
                        sprintf('Failure mode A level         | %14.0f kN ', 1e-3 * Obj.failModeA(iLoadSet))
                        '-----------------------------+--------------------------'
                        ''
                        };

                else
                    error('Implementation error');
                end

            end
            str{1} = sprintf('%s - INTERMEDIATE RESULTS\n', upper(Obj.description));
            Obj.info(strjoin(cat(1, str{:}), '\n'));
            fprintf('\n');  % separator before next log message

            if strcmp(Obj.Mdl.flangeType, 'L')
                if ~all(strcmpi(critModeStr, 'B'))
                    Obj.warning('USAIN:UltimateLimitState:FailureModeBNotDriving', ...
                        ['Failure mode B is not governing the L-flange connection''s ULS capacity.\n', ...
                        'This indicates an unsound design.\n', ...
                        'Make sure the rules-of-thumb are satisfied, adjust the design where needed and ', ...
                        'contact topic owner if unsure.']);
                end
            end

            if strcmp(Obj.Mdl.flangeType, 'T') && ~all(strcmpi(critModeStr, 'A'))
                Obj.warning('USAIN:UltimateLimitState:FailureModeANotDriving', ...
                    ['Failure mode A is not governing the T-flange connection''s ULS capacity.\n', ...
                    'This indicates an unsound design.\n', ...
                    'Make sure the rules-of-thumb are satisfied, adjust the design where needed and ', ...
                    'contact topic owner if unsure.']);
            end
        end

        function value = get.failModeCrit(Obj)
            % Return minimum value of all failure modes
            critMode = Obj.failModeA;
            for str = ["A", "B", "D", "E"]
                thisMode = Obj.('failMode' + str);
                critMode = min(critMode, thisMode);
            end
            value = critMode;
        end

        function value = get.failModeCritStr(Obj)
            critMode = Obj.failModeCrit;
            value = repmat("", size(critMode));
            for str = ["A", "B", "D", "E"]
                thisMode = Obj.('failMode' + str);
                isCrit = abs(critMode - thisMode) < 1e-6;
                value(isCrit) = str;
            end
        end

    end

    methods (Static)

        function modeStr = calc_critical_failure_mode(FlangeModel)
            % Convenience method to get the critical failure mode.
            %
            % This method can be used to compute the critical failure mode for the design space in input `FlangeModel`,
            % as required by bolt force models such as Petersen's.
            % This is convenient because it does not require difficult indexing operations to find the critical failure
            % mode in the design space that was used when the `UltimateLimitStateStep` was run.
            %
            % NOTE: The critical failure mode could differ per load set if robustness checks are among the load sets
            % (where the PSFs are forced to 1.00).
            %
            % modeStr: M-by-N string array with critical failure modes, for M design points and N loads sets

            arguments
                FlangeModel (1, 1) UsainUtils.FlangeModel
            end

            UlsCondition = UsainUtils.UltimateLimitState();
            UlsCondition.Mdl = FlangeModel;
            UlsCondition.setup_condition();

            % For N load sets and M design ponts, get M-by-N string array with critical failure modes
            modeStr = UlsCondition.failModeCritStr;
        end

    end
end
