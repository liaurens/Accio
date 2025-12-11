classdef UltimateLimitStateJpn < UsainUtils.UlsCondition
    % ULTIMATELIMITSTATEJPN Condition for ULS resistance of L-flanges for Japan
    %
    %   Calculation of stress in the flange is done according:
    %   - Guidelines for Design of Wind Turbine Support Structures and Foundation (2010 edition, chapter 07)
    %
    %    The calculations are fairly similar to those described by Petersen but can't be related directly to
    %    each other. More information on Petersen's calculations can be found here:
    %    <a href="matlab:; help UsainUtils.UltimateLimitState">USAINUTILS.ULTIMATELIMITSTATE</a>
    %
    %   The ULS verification involves three different failure modes (A, B, C), which are similar to the modes
    %   described by Petersen and Seidel. The Japanese design guidelines either simplified a failure mode
    %   calculation, or describe a combination of the Petersen and Seidel modes.
    %   - Failure Mode A: Failure of the bolt due to tension, including prying action.
    %     (Condition a <= 1.25b must be met)
    %   - Failure Mode B: Failure of the bolt due to tension and yield hinge in tower shell.
    %     (The calculations are a simplified version of the Petersen and Seidel failure mode B)
    %   - Failure Mode C: Yield hinge in tower shell and in flange material at the bolt hole center plane.
    %
    %   Note that in the calculations of the Japanese failure modes the prying reaction force arm must be
    %   calculated according to the Tobinaga and Ishihara method, see the design brief for details.
    %

    properties
        % N = Number of design points
        % M = Number of load sets

        failModeA % [N x M] Failure of the bolt due to tension, including prying action
        failModeB % [N x M] Failure of the bolt due to tension and yield hinge in tower shell
        failModeC % [N x M] Yield hinge in tower shell and in flange material at bolt center plane

        psfYield  % [1 x M] PSF on bolt yield strength, dependent on the load event (e.g. shortTerm, etc.)

        description string = "Ultimate limit state Japan"
    end
    properties (Dependent)
        failModeCrit     % [N x 1] Critical (design driving) failure mode level
        failModeCritStr  % [N x 1] Critical (design driving) failure mode string
    end
    properties (Constant)

        FAIL_MODE_STR = {'A' 'B' 'C'} % List with to be evaluated failure mode identifiers

        VALID_REACTION_DIST_METHODS = {'tobinaga'}
        VALID_EVENT_TAGS = {'shortTerm', 'longTerm', 'seismic'}

        TOGGLE_NAME = 'DO_ASSESS_ULS_JPN'
    end

    methods

        function Obj = UltimateLimitStateJpn(varargin)
            Obj@UsainUtils.UlsCondition(varargin{:});
        end

        function evaluate_condition(Obj)

            Obj.psfYield = Obj.calc_bolt_yield_psf();
            Obj.yieldStrengthDes = Obj.calc_design_yield_strength();

            % Evaluate failure modes
            for mode = Obj.FAIL_MODE_STR
                Obj.(['failMode' mode{1}]) = Obj.(['calc_failure_mode_' lower(mode{1})])();
            end

            Obj.mxy = Obj.Mdl.Loads.ulsMxyDesign + Obj.Mdl.Loads.inclinMomentDesign;
            Obj.fz = -Obj.Mdl.Loads.deadWeightFavorDesignUls;
            Obj.fDesign = Obj.calc_design_segment_force();

            Obj.utilRatio = Obj.determine_utilization();
        end

        function ftrd = calc_design_tension_resistance_bolt(Obj)
            % Overloads UsainUtils.UlsCondition/calc_design_tension_resistance_bolt
            % Returns design value of tension resistance of bolt, accounting for different load events
            % (short-term, long-term, seismic)

            ftrd = 0.9 * Obj.Mdl.Bolt.ftRc ./ Obj.psfYield;
        end

        function failMode = calc_failure_mode_a(Obj)
            % CALC_FAILURE_MODE_A Compute ULS failure mode A
            % See class helpdoc for more info
            %
            % SEE ALSO
            % UsainUtils.UltimateLimitStateJpn
            %

            % Define failure mode A, flange type dependent
            % L-flange: failure of the bolt due to tension and prying action (according Tobinaga method)
            % T-flange: failure of the bolt due to tension

            ftRd = Obj.calc_design_tension_resistance_bolt();
            bA = Obj.calc_outer_width();

            switch Obj.Mdl.flangeType
                case 'L'
                    effRimDist = Obj.calc_effective_rim_distance();
                    failMode = ftRd ./ (1 + bA ./ effRimDist);
                case 'T'
                    failMode = Obj.Mdl.flangeTypeFactor .* ftRd;
            end
        end

        function failMode = calc_failure_mode_b(Obj)
            % CALC_FAILURE_MODE_B Compute ULS failure mode B
            % See class helpdoc for more info
            %
            % SEE ALSO
            % UsainUtils.UltimateLimitStateJpn
            %

            effRimDist = Obj.calc_effective_rim_distance();
            plastMomShell = Obj.calc_plastic_moment();
            bB = Obj.calc_outer_width();
            ftRd = Obj.calc_design_tension_resistance_bolt();

            failMode = Obj.Mdl.flangeTypeFactor .* (plastMomShell + effRimDist .* ftRd) ./ (effRimDist + bB);
        end

        function failMode = calc_failure_mode_c(Obj)
            % CALC_FAILURE_MODE_C Compute ULS failure mode C
            % See class helpdoc for more info
            %
            % SEE ALSO
            % UsainUtils.UltimateLimitStateJpn
            %

            thickn = Obj.Mdl.Space.thickness;
            fyD = Obj.yieldStrengthDes;
            bC = Obj.calc_outer_width();
            cPrime = Obj.Mdl.Segment.distBolt - Obj.Mdl.Inputs.diamBoltHole;
            plastMomShell = Obj.calc_plastic_moment();

            % Compute plastic moment at bolt hole side
            mPl2Prime = (fyD .* cPrime .* thickn.^2) ./ 4;

            failMode = Obj.Mdl.flangeTypeFactor .* (plastMomShell + mPl2Prime) ./ bC;
        end

        function plastMomShell = calc_plastic_moment(Obj)

            % Plastic moment develops differently depending on flange type, for L-flange in the nose while
            % for T-flanges in the flange.
            switch Obj.Mdl.flangeType
                case 'L'
                    t = min(Obj.Mdl.Inputs.thicknNoseUp, Obj.Mdl.Inputs.thicknNoseLo);
                case 'T'
                    t = Obj.Mdl.Space.thickness;
            end
            cStar = Obj.Mdl.Segment.distBoltAtShell;
            fyD = Obj.yieldStrengthDes;

            plastMomShell = (fyD .* cStar .* t.^2) ./ 4;
        end

        function effRimDist = calc_effective_rim_distance(Obj)
            switch lower(Obj.Mdl.Inputs.REACTION_DISTANCE_METHOD)

                case 'tobinaga'
                    % Following Tobinaga (2017); no need to update iteratively
                    % In Japan only this Tobinaga Ishihari approach should
                    % be applied!
                    effRimDist = Obj.Mdl.Segment.ReactDist.calc_aeff_tobinaga();

                otherwise
                    Obj.validatestring(Obj.Mdl.Inputs.REACTION_DISTANCE_METHOD, ...
                        Obj.VALID_REACTION_DIST_METHODS, mfilename, 'input "REACTION_DISTANCE_METHOD"');
            end
        end

        function value = determine_utilization(Obj)
            % DETERMINE_UTILIZATION Determine the maximum ULS utilization for each
            % design point.
            % Due to the loadcase specific PSF to use for bolt
            % yield, the failure modes A and B are of dimension [N x M] rather
            % than [N x 1] as  for the calculations in UltimateLimitState.
            % The applied design load is different for each loadset, which
            % causes the utilization for failure mode C to be in the same
            % dimensions as utiliazations of failure modes A and B, i.e. [N x M].
            % The maximum  utilization is then determined by searching for the
            % maximum per designpoint and loadcase. This is done by putting the
            % three failure modes in a third dimension and search the maxima as
            % well in third dimension, resulting in the utilization ratios with
            % dimension [N x M].

            allFailModes = cellfun(@(x) Obj.(['failMode' x]), Obj.FAIL_MODE_STR, 'uni', 0);
            utilRatiosPerMode = cellfun(@(x) Obj.fDesign ./ x, allFailModes, 'uni', 0);

            [value, ~] = max(cat(3, utilRatiosPerMode{:}), [], 3);
        end

        function psf = calc_bolt_yield_psf(Obj)
            % Returns the partial safety factor to apply on the bolt tension resistance is loadcase specific,
            % a distinction is made between shortTerm, longTerm and seismic
            %
            % psf: [double, M*1] PSF on bolt tension resistnace for M load sets

            tags = {Obj.Mdl.Loads.Uls.tag};
            psf = nan(1, numel(tags));
            for iTag = 1:numel(tags)
                % Strip down loads tag string to essential part only
                strippedTag = Obj.VALID_EVENT_TAGS( ...
                    cellfun(@(x) contains(tags{iTag}, x), Obj.VALID_EVENT_TAGS));

                % Find matching index with input PSF_BOLT_RESISTANCE_JPN_TAG, and use corresponding PSF
                iMatch = contains(Obj.Mdl.Inputs.PSF_BOLT_RESISTANCE_JPN_TAG, strippedTag);
                Obj.assert(nnz(iMatch) == 1, 'Implementation error. Contact developer.');
                psf(iTag) = Obj.Mdl.Inputs.PSF_BOLT_RESISTANCE_JPN(iMatch);
            end
        end

        function bX = calc_outer_width(Obj)
            % Note: this method is basically a copy of UsainUtils.UltimateLimitState.calc_outer_width()
            %
            % Determines the outer width (in literature referred to as distance b) to consider in the failure
            % mode calculation. There are some differences compared to the ROW situation:
            % - Not dependent on the failure mode. Investigations are ongoing to identify if this can be
            % introduced, along with replacement of failmode C by modes D and E
            % - For T-flanges the fillet contribution is only considered as a factor 0.5r (instead of 0.8r)

            bX = Obj.Mdl.Segment.distForce;

            if strcmpi(Obj.Mdl.flangeType, 'T')
                r = Obj.Mdl.Inputs.FILLET_RADIUS;
                thkNose = min([Obj.Mdl.Inputs.thicknNoseUp, Obj.Mdl.Inputs.thicknNoseLo]);
                bX = bX - 0.5 .* thkNose - 0.5 .* r;
            end
        end

        function report_results(Obj)

            % Shortcuts
            nLoadSets = Obj.Mdl.Loads.nLoadSets;
            critModeStr = Obj.failModeCritStr;
            critMode = Obj.failModeCrit;

            str = cell(nLoadSets + 1, 1);
            for iLoadSet = 1:nLoadSets

                str{iLoadSet + 1} = { ...
                    sprintf('LOAD SET #%i (%s)', iLoadSet, Obj.Mdl.Loads.Uls(iLoadSet).tag)
                    '-----------------------------+--------------------------'
                    sprintf('Critical failure mode        | %14s', critModeStr{iLoadSet})
                    sprintf('Critical failure mode level  | %14.0f kN', 1e-3 * critMode(iLoadSet))
                    '-----------------------------+--------------------------'
                    ''
                    };
            end
            str{1} = sprintf('%s - INTERMEDIATE RESULTS\n', upper(Obj.description));
            Obj.info(strjoin(cat(1, str{:}), '\n'));
            fprintf('\n');  % separator before next log message
        end

        function value = get.failModeCrit(Obj)
            % Return minimum value of all failure modes
            critMode = Obj.failModeA;
            for str = Obj.FAIL_MODE_STR
                thisMode = Obj.(['failMode' str{1}]);
                critMode = min(critMode, thisMode);
            end
            value = critMode;
        end

        function value = get.failModeCritStr(Obj)
            critMode = Obj.failModeCrit;
            value = repmat({''}, size(critMode));
            for str = Obj.FAIL_MODE_STR
                thisMode = Obj.(['failMode' str{1}]);
                isCrit = abs(critMode - thisMode) < 1e-6;
                value(isCrit) = str;
            end
        end

    end

end
