classdef FlangeGapping < UsainUtils.ICondition
    % FLANGEGAPPING Condition for flange gapping up to bolt axis
    %   In this condition, the tension load at which flange gapping up to the
    %   centerline of the bolt is determined. Excessive opening of flange
    %   connections subjected to FLS loads is not desired. This condition can be
    %   used to verify the max. FLS load is not exceeding load at which this
    %   gapping occurs.
    %
    %   The calculation method followed here is based on section 5.2.1 of
    %   - M. Seidel. Zur Bemessung geschraubter Ringflanschverbindungen von
    %     Windenergieanlagen. Schriftenreihe des Instituts fuer Stahlbau der
    %     Universitaet Hannover. Shaker, 2001.
    %
    %   NOTE: This condition is merely a check, not a design driver
    %

    properties
        forceGapAtBcd double % [Nx1] Segment force for which flange will open up to bolt axis
        preload double % [Nx1] Preload in bolt

        description string = "Flange gapping under FLS loading"
    end
    properties (Constant)
        TOGGLE_NAME = 'DO_ASSESS_GAPPING'
    end

    methods

        function Obj = FlangeGapping(varargin)
            % Call superclass constructor
            Obj@UsainUtils.ICondition(varargin{:});
        end

        function bool = do_assess(Obj)
            % Overloads parent method `UsainUtils.ICondition.do_assess()`
            isLFlange = strcmp(Obj.Mdl.Inputs.flangeType, 'L');
            bool = Obj.Mdl.Inputs.(Obj.TOGGLE_NAME) && isLFlange;
        end

        function evaluate_condition(Obj)

            Obj.preload = usain.fastener.get_preload(Obj.Mdl.Tool.defaultPreload, ...
                Obj.Mdl.Inputs.FlangeGapping.CUSTOM_PRELOAD, 1);

            % Compute tension force on flange segment for which flange opens up to bolt axis
            Obj.forceGapAtBcd = Obj.calc_opening_force();

            % Get max. FLS load at flange segment and apply macro-geometric stress effects (already in maxFlsMxy)
            moment = Obj.Mdl.Loads.maxFlsMxy + Obj.Mdl.Loads.inclinMomentFlsDesign;
            fSegment = Obj.Mdl.Segment.calc_segment_force(moment, -Obj.Mdl.Loads.deadWeightFavorDesign);
            fSegment = Obj.squeeze_dims(fSegment);

            % Determine utilization
            Obj.utilRatio = fSegment ./ Obj.forceGapAtBcd;

            % Print (suppressable) warning in case of infeasible design(s)
            % NOTE: The warning is to be suppressed during optimisation
            Obj.verify_feasibility();
        end

        function force = calc_opening_force(Obj)
            % Computes segment tension force for which flange opens up to bolt axis

            % Shortcuts
            thickn = Obj.Mdl.Space.thickness;
            b = Obj.Mdl.Segment.distForce;
            c = Obj.Mdl.Segment.distBolt;

            % Derive properties required to computed opening force
            stiffnBolt = 1 ./ Obj.Mdl.Segment.resilBolt;
            aElas = Obj.Mdl.Segment.ReactDist.calc_aeff_seidel_fls();
            omega = 3 * b .* ...
                (aElas .* c - stiffnBolt .* thickn ./ Obj.Mdl.Inputs.E_BOLT) + ...
                2 .* aElas.^2 .* c .* (1 - Obj.Mdl.Segment.loadFactor);
            % NOTE: omega is compute according to eq. 107 in Seidel's thesis

            % Compute tension force on flange segment for which flange opens up
            % to bolt axis
            force = 2 * Obj.preload .* aElas.^2 .* c ./ omega;
        end

        function verify_feasibility(Obj)
            % Although the isFeasible property is forced to be always true, this
            % method can be called to check for over-utilised design points.

            if any(Obj.utilRatio(:) > Obj.targetUtilRatio)
                Obj.warning('USAIN:FlangeGapping:InfeasibleDesign', ...
                    ['Chances of flange opening due to FLS loading!\n', ...
                    'This indicates severe fatigue damage in the fasteners and/or the flange neck. ', ...
                    'If the bolt fatigue PM-sum and flange neck SCFs are acceptable, ', ...
                    'this warning can be ignored. Otherwise, further verification may be required.', ...
                    '\n\n\t==> Please check the SGRE Design Rules and/or contact topic owner.']);
            end
        end

        function value = get_isFeasible_impl(Obj)
            % Overloading parent method to mimic overloading get.isFeasible

            % Always return true (this condition is merely a check, not a design
            % driver)
            value = Obj.is_always_feasible();
        end

    end
end
