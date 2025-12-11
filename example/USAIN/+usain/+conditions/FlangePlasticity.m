classdef FlangePlasticity < UsainUtils.ICondition

    properties
        description string = "Preload loss from flange plasticity"
    end
    properties (Constant)
        TOGGLE_NAME = 'DO_ASSESS_FLANGE_PLASTICITY'
    end

    methods

        function Obj = FlangePlasticity(varargin)
            Obj@UsainUtils.ICondition(varargin{:});
        end

        function bool = do_assess(Obj)
            % Overloads parent method `UsainUtils.ICondition.do_assess()`
            isLFlange = Obj.Mdl.Inputs.flangeType == usain.inputs.FlangeType.L;
            bool = Obj.Mdl.Inputs.(Obj.TOGGLE_NAME) && isLFlange;
        end

        function evaluate_condition(Obj)

            % Get flange segment force at SLS (S1) load level
            moment = Obj.Mdl.Loads.get_max_sls_moment() + Obj.Mdl.Loads.inclinMomentDesign;
            segmentForceMaxFls = Obj.Mdl.Segment.calc_segment_force(moment, -Obj.Mdl.Loads.deadWeightFavorDesign);
            segmentForceMaxFls = Obj.squeeze_dims(segmentForceMaxFls);

            % Compute failure mode D, at which plastic strain develops in flange body
            failureModeD = Obj.calc_failure_mode_d();

            % Compute utilization ratio from F_U,D >= Z/x (`x` is max FM D utilization)
            Obj.utilRatio = segmentForceMaxFls ./ Obj.Mdl.Inputs.MAX_FAILURE_MODE_D_FLS_UTILIZATION ./ failureModeD;

            % Print warning in case of potentially infeasible design(s)
            Obj.verify_feasibility();
        end

        function failureMode = calc_failure_mode_d(Obj)
            % Uses UsainUtils.UltimateLimitState to compute FM D
            UlsCondition = UsainUtils.UltimateLimitState('Mdl', Obj.Mdl);
            UlsCondition.yieldStrengthDes = UlsCondition.calc_design_yield_strength();
            UlsCondition.boltStrengthDes = UlsCondition.calc_design_tension_resistance_bolt();
            UlsCondition.plasticLimit = UlsCondition.calc_plastic_limit_neck();
            failureMode = UlsCondition.calc_failure_mode_d();
        end

        function verify_feasibility(Obj)
            % Although the isFeasible property is forced `true` (see `get_isFeasible_impl()`), this method checks for
            % overutilized design points.

            if any(Obj.utilRatio(:) > Obj.targetUtilRatio)
                Obj.warning('USAIN:FlangePlasticity:InfeasibleDesign', ...
                    "Loss of preload due to plastic strain in the flange detected. " + ...
                    "FEA check may be required.");
            end
        end

        function value = get_isFeasible_impl(Obj)
            % Overloading parent method to mimic overloading get.isFeasible

            % Always return true (this condition is merely a check, not a design driver)
            value = Obj.is_always_feasible();
        end

    end
end
