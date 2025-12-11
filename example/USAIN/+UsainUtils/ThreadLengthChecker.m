classdef ThreadLengthChecker < logging.Config

    properties
        GrippedThreadFixedSide UsainUtils.ThreadLengthData
        VisibleThreadFixedSide UsainUtils.ThreadLengthData
        GrippedThreadFreeSide UsainUtils.ThreadLengthData
        VisibleThreadFreeSide UsainUtils.ThreadLengthData

        Inputs  % USAIN inputs
        tighteningMethod char
        diameter double
        pitch double
        fastenerType char
    end

    methods

        function Obj = ThreadLengthChecker()
        end

        function bool = check_thread_lengths(Obj, ThreadModel)
            % Evaluate visible/gripped thread lengths fixed/free sides
            %
            % ThreadModel: UsainUtils.ThreadLengthModel
            % bool: Boolean mask indicating feasiblity of all thread lengths

            grippedLengthFixedSide = ThreadModel.calc_gripped_length_fixed_side();
            Obj.check_gripped_thread_fixed_side(ThreadModel.fixedSide, grippedLengthFixedSide);

            visibleLengthFixedSide = ThreadModel.fixedLength;
            Obj.check_visible_thread_fixed_side(ThreadModel.fixedSide, visibleLengthFixedSide);

            grippedLengthFreeSide = ThreadModel.calc_gripped_length_free_side();
            Obj.check_gripped_thread_free_side(ThreadModel.freeSide, grippedLengthFreeSide);

            visibleLengthFreeSide = ThreadModel.calc_visible_length_free_side();
            Obj.check_visible_thread_free_side(ThreadModel.freeSide, visibleLengthFreeSide);

            bool = Obj.is_valid_lengths();
        end

        function bool = is_valid_lengths(Obj)
            % Checks feasibility of all evaluated thread lengths

            bool = max( ...
                max(Obj.GrippedThreadFixedSide.utilization, Obj.VisibleThreadFixedSide.utilization), ...
                max(Obj.GrippedThreadFreeSide.utilization, Obj.VisibleThreadFreeSide.utilization)) <= 1.00;
        end

        function len = calc_thread_length_limit(Obj, minOrMax, visibleOrGripped, tighteningMethod)
            % Returns numeric thread length limit
            % This function looks up the length expression expert inputs and processes this to return a
            % numeric value.
            %
            % minOrMax: Limit identification string: 'min', 'max' (case-insensitive)
            % visibleOrGripped: Thread identification string: 'visible', 'gripped' (case-insensitive)
            % tighteningMethod: Optional. Tightening method: 'torque', 'tension' (case-insensitive)

            if nargin < 4
                tighteningMethod = Obj.tighteningMethod;
            end

            inputVarName = UsainUtils.LengthExpression.format_input_variable_name( ...
                minOrMax, visibleOrGripped, tighteningMethod);

            if isfield(Obj.Inputs, inputVarName)
                Expression = UsainUtils.LengthExpression(Obj.Inputs.(inputVarName));
                len = Expression.calc_length(Obj.diameter, Obj.pitch);
            else
                Obj.error('ThreadLengthChecker:InputNotFound', 'Input not found: %s.', inputVarName);
            end
        end

        function check_gripped_thread_fixed_side(Obj, flangeSide, length)
            % Evaluate gripped threads on fixed side. This is only relevant for studs; force a utilization of
            % 0.0 for hex-bolts
            %
            % flangeSide : Side (upper or lower) of flange connection where thread length is evaluated
            % length: Length of gripped thread on fixed side of fastener

            Obj.GrippedThreadFixedSide = UsainUtils.ThreadLengthData(flangeSide, length);
            minimumLength = Obj.calc_thread_length_limit('min', 'gripped');
            maximumLength = Inf;
            Obj.GrippedThreadFixedSide.calc_utilization(minimumLength, maximumLength);

            % Set utilization ratio to 0.0 for hex-bolts because there is no thread on the fixed side
            Obj.GrippedThreadFixedSide.zero_utilization_for_hex_bolt(Obj.fastenerType);
        end

        function check_visible_thread_fixed_side(Obj, flangeSide, length)
            % Evaluate visible threads on fixed side. This is only relevant for studs; force a utilization of
            % 0.0 for hex-bolts
            %
            % flangeSide : Side (upper or lower) of flange connection where thread length is evaluated
            % length: Length of visible thread on fixed side of fastener

            Obj.VisibleThreadFixedSide = UsainUtils.ThreadLengthData(flangeSide, length);
            minimumLength = Obj.calc_thread_length_limit('min', 'visible');
            maximumLength = Obj.calc_thread_length_limit('max', 'visible');
            if strcmp(Obj.tighteningMethod, 'tension')
                % Because MAX_VISIBLE_THREAD_LENGTH_TENSION is rounded up to the nearest millimeter in
                % UsainUtils.ThreadLengthModel, do the same here.
                maximumLength = round_up(maximumLength, 3);
            end
            Obj.VisibleThreadFixedSide.calc_utilization(minimumLength, maximumLength);

            % Set utilization ratio to 0.0 for hex-bolts because there is no thread on the fixed side
            Obj.VisibleThreadFixedSide.zero_utilization_for_hex_bolt(Obj.fastenerType);
        end

        function check_gripped_thread_free_side(Obj, flangeSide, length)
            % Evaluate gripped threads on free side
            %
            % flangeSide : Side (upper or lower) of flange connection where thread length is evaluated
            % length: Length of gripped thread on free side of fastener

            Obj.GrippedThreadFreeSide = UsainUtils.ThreadLengthData(flangeSide, length);
            minimumLength = Obj.calc_thread_length_limit('min', 'gripped');
            maximumLength = Inf;
            Obj.GrippedThreadFreeSide.calc_utilization(minimumLength, maximumLength);
        end

        function check_visible_thread_free_side(Obj, flangeSide, length)
            % Evaluate visible threads on free side
            %
            % flangeSide : Side (upper or lower) of flange connection where thread length is evaluated
            % length: Length of visible thread on free side of fastener

            Obj.VisibleThreadFreeSide = UsainUtils.ThreadLengthData(flangeSide, length);

            minimumLength = Obj.calc_thread_length_limit('min', 'visible', Obj.tighteningMethod);

            % For hex-bolts, the socket must fit over the nut on the free side
            if strcmpi(Obj.fastenerType, 'hex')
                maximumLength = Obj.calc_thread_length_limit('max', 'visible');
            else
                % For stud bolts, there is no (known) maximum
                maximumLength = Inf;
            end
            Obj.VisibleThreadFreeSide.calc_utilization(minimumLength, maximumLength);
        end

    end

    methods (Static)

        function Objs = from_inputs(Inputs)
            % Constructs (array of) object(s) based on USAIN inputs
            %
            % Objs: Array of N objects for N bolt options defined in USAIN inputs

            BoltOpts = usain.fastener.BoltOptionsParser(Inputs.boltOptions);
            nBoltOptions = numel(BoltOpts.label);
            Objs(nBoltOptions) = UsainUtils.ThreadLengthChecker();
            for iOpt = 1:nBoltOptions

                Assy = usain.fastener.CatalogLibrary.select_assemblies( ...
                    Inputs.site, BoltOpts.label{iOpt}, Inputs.tighteningMethod{iOpt}, Inputs.NUT_TYPE{iOpt});

                Obj = UsainUtils.ThreadLengthChecker();
                Obj.Inputs = Inputs;
                Obj.tighteningMethod = Assy.Tool.tighteningMethod;
                Obj.diameter = Assy.Bolt.diam;
                Obj.pitch = Assy.Bolt.pitch;
                Obj.fastenerType = Assy.Bolt.type;

                Objs(iOpt) = Obj;
            end
        end

        function Obj = from_flange_model(FlangeModel, iBoltOption)
            % Constructs single object based on flange model data
            %
            % FlangeModel: FlangeModel or SelectedModel instance, with single design point
            % iBoltOption: Optional. Selection index in case multiple bolt options exist in flange model
            % Obj: ThreadLengthChecker instance

            if nargin < 2
                iBoltOption = 1;
            end

            Obj = UsainUtils.ThreadLengthChecker();
            Obj.Inputs = FlangeModel.Inputs;
            Obj.tighteningMethod = FlangeModel.Tool.tighteningMethod{iBoltOption};
            Obj.diameter = FlangeModel.Bolt.diam(iBoltOption);
            Obj.pitch = FlangeModel.Bolt.pitch(iBoltOption);
            Obj.fastenerType = FlangeModel.Bolt.type{iBoltOption};
        end

    end

end
