classdef ICondition < matlab.mixin.Heterogeneous & logging.Config  % mh:ignore_style
    % ICONDITION Design condition (limit state) interface
    %   Inheriting from this class will give the subclass the proper 'blueprint'
    %   for being a design condition for L-flanges.
    %

    properties
        Mdl  % FlangeModel or SelectedModel

        utilRatio double  % Utilization ratio of this design constraint
        targetUtilRatio double = 1.00  % Target utilization ratio

        % TODO: Implement doSkip        % Boolean mask to indicate design points to skip
    end
    properties (Dependent)
        isFeasible                      % Boolean mask to indicate feasible design points
        nFeasible                       % Number of feasible designs

        doAssess                        % Flag to skip/execute condition evaluation
    end
    properties (Constant)
        CONDITION_CLASS_NAMES = [ ...
            "DO_ASSESS_BOLT_PLASTICITY"
            "DO_ASSESS_BOLT_THREAD_REQ"
            "DO_ASSESS_FLANGE_NECK_SCF"
            "DO_ASSESS_FLANGE_PLASTICITY"
            "DO_ASSESS_FLS"
            "DO_ASSESS_GAPPING"
            "DO_ASSESS_SCHMIDTNEUPER_APT"
            "DO_ASSESS_SLS_PRETENSION"
            "DO_ASSESS_ULS"
            "DO_ASSESS_ULS_JPN"]

    end
    properties (Abstract, Constant)
        TOGGLE_NAME
    end

    methods

        function Obj = ICondition(varargin)  % mh:ignore_style

            if nargin
                Obj = assign_varargin_2_classprop(Obj, varargin{:});
            end
        end

        function fPen = calc_penalty(Obj)
            % By default, implement quadratic penalty function. May be
            % overloaded by subclasses.
            %
            % OUTPUT
            % fPen [double] <N x 1> Penalty for N design space points

            % Take maximum utilization, normalized to 1, of all evaluated load sets
            utilRatioMaxNorm = max(Obj.utilRatio / Obj.targetUtilRatio, [], 2);
            fPen = max(0, utilRatioMaxNorm.^2 - 1);

            % No penalty for feasible conditions
            fPen(Obj.isFeasible) = 0;
        end

        function out = is_always_feasible(Obj)
            % Returns <N x 1> vector for logical TRUE values, for N design points
            % Some conditions in USAIN are merely sanity checks and should not
            % act as design drivers. For such condition, this method can be
            % called in an overloaded get_isFeasible_impl method.

            out = true(size(Obj.utilRatio, 1), 1);
        end

        function bool = do_assess(Obj)
            % Called by get.doAssess, but implemented as normal method because
            % getters cannot be overloaded
            bool = Obj.Mdl.Inputs.(Obj.TOGGLE_NAME);
        end

        function setup_condition(~)
            % Convenience method to allow for `Condition` specific additional setup.
        end

        %%%%% == SETTERS / GETTERS == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function value = get.isFeasible(Obj)
            if Obj.doAssess
                value = Obj.get_isFeasible_impl();
            else
                value = logical.empty;
            end
        end

        function value = get_isFeasible_impl(Obj)
            % GET_ISFEASIBLE_IMPL Workaround for Matlab's OOP stupidity
            % Getters (or dependent properties) cannot be overloaded in
            % Matlab subclasses.. FUCKING MATLAB %^$*(#!
            %
            % This implementation method is called in get.isFeasible and can be
            % overloaded in subclasses
            %

            % Concatenate over second dimension (= number of load sets)
            value = all(Obj.utilRatio <= Obj.targetUtilRatio, 2);
        end

        function value = get.nFeasible(Obj)
            value = nnz(Obj.isFeasible);
        end

        function value = get.doAssess(Obj)
            try
                value = Obj.do_assess();
            catch
                % For an empty object, do_assess() might fail which is reasonable. In that case, return `false` to let
                % callers know this condition was not assessed
                value = false;
            end
            % TODO: Replace by normal property isAssessed?
        end

        function report_results(~)
            % To be overloaded in subclasses
        end

    end

    methods (Abstract)
        evaluate_condition(Obj) % Evaluates design condition and sets Obj.utilRatio
    end

    methods (Static)

        function valueReshaped = squeeze_dims(value)
            % Removes singleton dimension #2, if existing, such that an array of
            % size <N x M> for N design points and M load sets can be assigned
            % to property "utilRatio"
            %
            % INPUT
            % - value [double] <NxM> or <Nx1xM>
            %
            % OUTPUT
            % - valueReshaped [double] <NxM>

            n = size(value, 1); % Number of design points
            m = size(value, ndims(value)); % Number of load sets

            % Remove singleton dimensions. In case number of design points = 1,
            % this will also removed the first dimension (yielding a row vector)
            urSqueezed = squeeze(value);

            % Reshape squeezed array to <N x M>
            valueReshaped = reshape(urSqueezed, n, m);
        end

    end
end
