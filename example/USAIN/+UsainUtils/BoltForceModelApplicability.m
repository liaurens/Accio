classdef BoltForceModelApplicability < UsainUtils.ICondition
    % BOLTFORCEMODELAPPLICABILITY Condition for applicability of Schmidt-Neuper bolt force model
    %   The criterion of applicability for the Schmidt-Neuper bolt force model
    %   is defined as
    %       (a+b/thickn) <= 3
    %   where
    %       a       - Flange rim distance
    %       b       - Force application distance
    %       thickn  - Flange thickness
    %
    %   The constraint is according to eq. (6) in:
    %       Schmidt, H.; Neuper, M. - Zum elastostatischen Tragverhalten
    %       exzentrisch gezogener L-Stoesse mit vorgespannten Schrauben
    %

    properties
        description string = "Schmidt-Neuper applicability"
    end

    properties (Constant)
        TOGGLE_NAME = 'DO_ASSESS_SCHMIDTNEUPER_APT'
    end

    methods

        function Obj = BoltForceModelApplicability(varargin)
            % Call superclass constructor
            Obj@UsainUtils.ICondition(varargin{:});
        end

        function bool = do_assess(Obj)
            % Overloads parent method `UsainUtils.ICondition.do_assess()`
            bool = any([Obj.Mdl.Inputs.BoltFls.BOLT_FORCE_MODEL] == "schmidtneuper");
        end

        function evaluate_condition(Obj)

            % Calculations dependent on thickness and width of flange
            thickn = Obj.Mdl.Space.thickness;

            % Compute utilization ratio
            a = Obj.Mdl.Segment.distRim;
            b = Obj.Mdl.Segment.distForce;
            Obj.utilRatio = ((a + b) ./ thickn) ./ 3;
        end

        function fPen = calc_penalty(Obj)
            fPen = double(~Obj.isFeasible);
        end

    end
end
