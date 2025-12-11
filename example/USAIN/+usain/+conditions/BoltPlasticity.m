classdef BoltPlasticity < UsainUtils.ICondition

    properties
        iBoltFls double  % Index to select `BoltFls.*` input block
        iAngle double  % Index to select from gap angle from `Inputs.SGRE2.GAP_ANGLE`
    end
    properties (Dependent)
        description string
    end
    properties (Constant)
        TOGGLE_NAME = 'DO_ASSESS_BOLT_PLASTICITY'
        YIELD_LIMIT_FACTOR = 0.85
    end

    methods

        function Obj = BoltPlasticity(iBoltFls, iAngle, varargin)
            % Call superclass constructor
            Obj@UsainUtils.ICondition(varargin{:});
            Obj.iBoltFls = iBoltFls;
            Obj.iAngle = iAngle;
        end

        function evaluate_condition(Obj)

            % Get flange segment force at SLS (S1) load level
            moment = Obj.Mdl.Loads.get_max_sls_moment() + Obj.Mdl.Loads.inclinMomentDesign;
            segmentForce = Obj.Mdl.Segment.calc_segment_force(moment, -Obj.Mdl.Loads.deadWeightFavorDesign);
            segmentForce = Obj.squeeze_dims(segmentForce);

            % Compute bolt force at max FLS
            boltForceMaxFls = Obj.calc_max_fls_bolt_force(segmentForce);

            % Compute the utilization based on a resistance of 85% of nominal yield
            resistance = Obj.Mdl.Bolt.areaStress * Obj.YIELD_LIMIT_FACTOR .* Obj.Mdl.Bolt.yieldStrengthNominal;
            Obj.utilRatio = boltForceMaxFls ./ resistance;

            % Print warning in case of potentially infeasible design(s)
            Obj.verify_feasibility();
        end

        function boltForce = calc_max_fls_bolt_force(Obj, segmentForce)
            % Construct bolt force models for each input (and, in case of `sgre2`, each gap size) and compute the bolt
            % force at max FLS load. Return the maximum bolt force from all models.
            %
            % segmentForce: NxM array for N design points and M load sets
            % boltForce: NxM array for N design points and M load sets

            Inputs = Obj.Mdl.Inputs;
            assert(strcmpi(Inputs.BoltFls(Obj.iBoltFls).BOLT_FORCE_MODEL, "sgre2"), ...
                "Only the 'sgre2' model is supported for evaluating plastic strain in bolts.");

            % Determine design preload
            preloadFls = usain.fastener.get_preload( ...
                        Obj.Mdl.Tool.defaultPreload, ...
                        Inputs.BoltFls(Obj.iBoltFls).CUSTOM_PRELOAD, ...
                        Inputs.BoltFls(Obj.iBoltFls).PRELOAD_LOSS_FACTOR_FLS);

            % Construct a FatigueLimitStateWithSgre2_0 instance for each gap angle that is set in inputs
            BoltForceModel = ...
                UsainUtils.BoltForceModelFactory().get_model( ...
                    Obj.Mdl, ...
                    Inputs.BoltFls(Obj.iBoltFls).BOLT_FORCE_MODEL, ...
                    preloadFls, ...
                    Inputs.SGRE2.GAP_ANGLE(Obj.iAngle));

            % Compute bolt force
            boltForce = BoltForceModel.calc_bolt_force(segmentForce);
        end

        function verify_feasibility(Obj)
            % Although the isFeasible property is forced `true` (see `get_isFeasible_impl()`), this method checks for
            % overutilized design points.

            if any(Obj.utilRatio(:) > Obj.targetUtilRatio)
                Obj.warning('USAIN:BoltPlasticity:InfeasibleDesign', ...
                    "Loss of preload due to plastic strain in the bolt detected (%i%% yield limit exceeded). " + ...
                    "Either artificially reduce the design preload, or use FEA.", 100 * Obj.YIELD_LIMIT_FACTOR);
            end
        end

        function value = get_isFeasible_impl(Obj)
            % Overloading parent method to mimic overloading get.isFeasible

            % Always return true (this condition is merely a check, not a design driver)
            value = Obj.is_always_feasible();
        end

        function value = get.description(Obj)
            % Add BoltFls block and gap angle indices to description, if the condition has been run.
            if ~isempty(Obj.Mdl)
                gapAngleDeg = rad2deg(Obj.Mdl.Inputs.SGRE2.GAP_ANGLE(Obj.iAngle));
                value = compose("Preload loss from bolt plasticity (set #%i, %g deg)", Obj.iBoltFls, gapAngleDeg);
            else
                value = "Preload loss from bolt plasticity";
            end
        end

    end

end
