classdef ThreadRequirements < UsainUtils.ICondition
    % Condition for feasibility of bolt threads
    % The bolt thread is subject to the following requirements:
    %   1. A certain thread length must protrude the outside of the nut (i.e. visible thread). This is needed
    %      to ensure sufficient thread engagement in the nut, as well as providing sufficent grip length for a
    %      tensioner tool (if applicable).
    %   2. A certain length, generally 4P, must exist between the thread runout and the bearing face of the
    %      nut (i.e. gripped threads). Violating this requirement (i.e. < 4 threads) may significantly alter
    %      the bolt's tension resistance, making it too strong for the 10.9 class. This also leads to a
    %      decrease in thread stripping strength, possibly shifting the bolt's failure mode from bolt fracture
    %      to thread stripping. It is of paramount importance that bolt fracture is the critical failure mode,
    %      as this is directly spotted during the tightening operation. (Thread stripping is a progressive
    %      failure that may take several hours)
    %
    % This class always evaluates both sides of the fastener, and simply zeroes the utilization ratio on
    % the non-threaded side for hex-bolts.

    properties
        GrippedThreadFixedSide UsainUtils.ThreadLengthData
        VisibleThreadFixedSide UsainUtils.ThreadLengthData
        GrippedThreadFreeSide UsainUtils.ThreadLengthData
        VisibleThreadFreeSide UsainUtils.ThreadLengthData

        grippedThreadUpperFlange double
        visibleThreadUpperFlange double
        grippedThreadLowerFlange double
        visibleThreadLowerFlange double

        description string = "Bolt thread requirements"
    end
    properties (Constant)
        TOGGLE_NAME = 'DO_ASSESS_BOLT_THREAD_REQ'
    end

    methods

        function Obj = ThreadRequirements(varargin)
            % Call superclass constructor
            Obj@UsainUtils.ICondition(varargin{:});
        end

        function evaluate_condition(Obj)
            % Evaluates design condition and sets Obj.utilRatio

            % NOTE: Due to logic in overloaded do_assess(), this method is only called for single design
            % points (SelectedModel instances)

            % TODO: Try and find out if assessing this condition on the full design space can be used to
            % reduce the design space (and make subsequent calculations less memory-intensive)

            ThreadModel = UsainUtils.ThreadLengthModel.from_flange_model(Obj.Mdl);
            ThreadChecker = UsainUtils.ThreadLengthChecker.from_flange_model(Obj.Mdl);
            ThreadChecker.check_thread_lengths(ThreadModel);

            % Extract relevant results from ThreadChecker
            Obj.GrippedThreadFixedSide = ThreadChecker.GrippedThreadFixedSide;
            Obj.VisibleThreadFixedSide = ThreadChecker.VisibleThreadFixedSide;
            Obj.GrippedThreadFreeSide = ThreadChecker.GrippedThreadFreeSide;
            Obj.VisibleThreadFreeSide = ThreadChecker.VisibleThreadFreeSide;

            % Assign gripped and visbile lengths to flange side
            Obj.assign_visible_and_gripped_thread_lengths_to_flange_side();

            % Store worst-case (=max) utilization ratio of the thread requirement conditions
            Obj.utilRatio = max([ ...
                Obj.GrippedThreadFixedSide.utilization, ...
                Obj.VisibleThreadFixedSide.utilization, ...
                Obj.GrippedThreadFreeSide.utilization, ...
                Obj.VisibleThreadFreeSide.utilization]);
        end

        function fPen = calc_penalty(Obj)
            % Overloads UsainUtils.ICondition/calc_penalty
            % The thread requirements check is a GO/NO GO check
            fPen = double(~Obj.isFeasible);
        end

        function bool = do_assess(Obj)
            % Overloads UsainUtils.ICondition/do_assess
            % Assess only if input dictates so AND only on the selected model (i.e. the check run on the
            % single best flange connection found during optimization)
            bool = Obj.Mdl.Inputs.(Obj.TOGGLE_NAME) && isa(Obj.Mdl, 'UsainUtils.SelectedModel');
        end

        function assign_visible_and_gripped_thread_lengths_to_flange_side(Obj)
            % Assign gripped and visbile lengths to flange side specific properties by extracting the relevant info from
            % looping over the `UsainUtils.ThreadLengthData` properties
            props = properties(Obj)';
            for thisProp = props
                if isa(Obj.(thisProp{1}), 'UsainUtils.ThreadLengthData')
                    % Determine the flange side
                    flangeSide = Obj.(thisProp{1}).flangeSide;
                    flangeSide = upper(extractBefore(flangeSide, 2)) + extractAfter(flangeSide, 1);

                    % Determine the "new" property name to assign the data to
                    assignProp = replace(thisProp{1}, 'FixedSide', flangeSide + "Flange");
                    assignProp = replace(assignProp, 'FreeSide', flangeSide + "Flange");
                    assignProp = replace(assignProp, assignProp(1), lower(assignProp(1)));

                    % Assign the actual data
                    Obj.(assignProp) = Obj.(thisProp{1}).len;
                end
            end
        end

        function str = report_results(Obj)
            % Returns `str` which only contains the actual data to print
            % This allows for simple testing, since it allows neglecting headers, newlines etc.

            delimiter = '-----------------------------------+--------------------';

            str = { ...
                sprintf('Tightening side for installation   |  %8s', Obj.Mdl.Inputs.TIGHTENING_SIDE_INSTALLATION{1})
                sprintf('Visible thread length, upper       |  %8.1f mm', Unit.mm.from_si(Obj.visibleThreadUpperFlange))
                sprintf('Gripped thread length, upper       |  %8.1f mm', Unit.mm.from_si(Obj.grippedThreadUpperFlange))
                sprintf('Visible thread length, lower       |  %8.1f mm', Unit.mm.from_si(Obj.visibleThreadLowerFlange))
                sprintf('Gripped thread length, lower       |  %8.1f mm', Unit.mm.from_si(Obj.grippedThreadLowerFlange))
                };

            msg = [ ...
                sprintf('%s - INTERMEDIATE RESULTS\n', upper(Obj.description))
                delimiter
                str
                delimiter
                newline];

            msg = strjoin(msg, '\n');
            Obj.info(msg);
        end

    end
end
