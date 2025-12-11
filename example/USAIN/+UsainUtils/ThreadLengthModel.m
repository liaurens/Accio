classdef ThreadLengthModel < logging.Config
    % Checks thread length requirements for bolted joints.
    %
    % In this class, reference is made to the 'fixed side' and the 'free side'. This refers to the side of the
    % fastener/flange:
    % - Fixed side (symbol: '1'): For bolts, this is the side of the bolt head.
    %   For studs, this is the side where the pre-assembled nut is (and where the tightening tool is placed during WTG
    %   installation). The pre-assembled nut is positioned at a distance from the end of the usain.fastener as defined
    %   by `MAX_VISIBLE_THREAD_LENGTH_TENSION` to ensure the tightening tool has sufficient grip length.
    % - Free side (symbol: '2'): The side opposite of the fixed side.
    %
    % Some examples
    % - For a bolt with tightening side `upper`, the bolt head will be at the 'lower' side such that the `fixed` side
    %   will be `lower` as well.
    % - For a stud with tightening side `upper`, the pre-assembled nut will be at the `upper` side and the `fixed` side
    %   will be `upper` as well.
    %
    % Assumptions made in this class:
    % - Thread length is symmetrical, i.e. same on both sides of the stud.
    % - The fastener garniture is symmetrical except for the bolt extender, meaning that the nuts and washers
    %   on either side are identical. If there is a bolt extender with non-zero length, it will be only on one
    %   side.
    % - Symmetrical tolerance on washer height.
    % - Only negative tolerance on nut height.

    properties
        fastenerType char
        fixedLength double  % Thread length above the nut on fixed side
        boltLength double
        boltLengthToleranceClass char
        diamBolt double
        pitch double
        lengthThread double

        nutHeightMin double
        nutHeightMax double
        washerHeight double
        washerHeightTolerance double
        extenderLength double = 0
        extenderLengthTolerance double = 0.5e-3

        flangeThickness double  % Design value of flange thickness
        flangeThicknessTolerancePlus double = 2.0e-3
        upperFlangeThicknessAllowance double = 2.0e-3
        lowerFlangeThicknessAllowance double = 2.0e-3
        freeSide string % upper or lower
        fixedSide string % upper or lower
    end

    methods

        function Obj = ThreadLengthModel(varargin)
            Obj = assign_varargin_2_classprop(Obj, varargin{:});
        end

        function isOk = check_thread_lengths(Obj, minVisibleThreads, minGrippedThreads)
            % Checks if thread lengths satisfy the input minima
            %
            % minVisibleThreads: Minimum number of threads protruding the nut (i.e. nut to run-in)
            % minGrippedThreads: Minimum number of threads gripped (i.e. nut to run-out)
            % isOk: Boolean flag, true if thread length is satisfied on all sides

            lenGrippedFixed = Obj.calc_gripped_length_fixed_side();
            lenGrippedFree = Obj.calc_gripped_length_free_side();
            lenVisibleFree = Obj.calc_visible_length_free_side();
            % NOTE: Visible thread length on fixed side is not calculated, because it is a fixed value (see
            % property Obj.fixedLength)

            % Check thread length. As hex bolts have no thread on the fixed side (=side of bolt head), the
            % criterion at that side will always pass, the opposite side still needs validation.
            isHexBolt = strcmpi(Obj.fastenerType, 'hex');
            isOk = (isHexBolt | lenGrippedFixed >= (minGrippedThreads * Obj.pitch)) & ...
                lenGrippedFree >= (minGrippedThreads * Obj.pitch) & ...
                lenVisibleFree >= (minVisibleThreads * Obj.pitch);
        end

        function len = calc_gripped_length_fixed_side(Obj)
            % Computes distance from bearing surface of nut to start of thread run-out, on the fixed side

            freeThread1 = Obj.fixedLength;
            lenForStud = Obj.lengthThread - Obj.nutHeightMax - freeThread1;

            % For a bolt, thread is only on one side and this will always be zero
            len = Obj.zero_for_bolt(lenForStud);

            % Round to nearest 0.001mm to avoid numerical roundoff errors in further calculations
            len = round(len, 6);
        end

        function len = calc_gripped_length_free_side(Obj)
            % Computes distance from bearing surface of nut to start of thread run-out on the free side

            boltLengthMax = Obj.boltLength + ...
                usain.fastener.calc_length_tolerance(Obj.boltLengthToleranceClass, Obj.boltLength);
            freeThread1 = Obj.fixedLength;

            % For a bolt, there is no nut nor free thread on the fixed side
            freeThread1 = Obj.zero_for_bolt(freeThread1);
            Obj.nutHeightMin = Obj.zero_for_bolt(Obj.nutHeightMin);

            flangeThicknessMin = Obj.flangeThickness;  % Min thickness == design thickness
            washerHeightMin = Obj.calc_min(Obj.washerHeight, Obj.washerHeightTolerance);
            extenderHeightMin = Obj.calc_min(Obj.extenderLength, Obj.extenderLengthTolerance);
            thicknessClampedPartsMin = 2 * flangeThicknessMin + 2 * washerHeightMin + extenderHeightMin;

            len = Obj.lengthThread - ...
                (boltLengthMax - freeThread1 - Obj.nutHeightMin - thicknessClampedPartsMin);

            % Round to nearest 0.001mm to avoid numerical roundoff errors in further calculations
            len = round(len, 6);
        end

        function len = calc_visible_length_free_side(Obj)
            % Computes distance from nut to fastener end (run-in) on the free side

            boltLengthMin = Obj.boltLength - ...
                usain.fastener.calc_length_tolerance(Obj.boltLengthToleranceClass, Obj.boltLength);
            freeThread1 = Obj.fixedLength;
            nut1HeightMax = Obj.nutHeightMax;

            % For a bolt, there is no nut nor free thread on the fixed side
            freeThread1 = Obj.zero_for_bolt(freeThread1);
            nut1HeightMax = Obj.zero_for_bolt(nut1HeightMax);

            nut2HeightMax = Obj.nutHeightMax;

            upperFlangeThicknessMax = Obj.flangeThickness + ...
                Obj.flangeThicknessTolerancePlus + ...
                Obj.upperFlangeThicknessAllowance;
            lowerFlangeThicknessMax = Obj.flangeThickness + ...
                Obj.flangeThicknessTolerancePlus + ...
                Obj.lowerFlangeThicknessAllowance;

            washerHeightMax = Obj.calc_max(Obj.washerHeight, Obj.washerHeightTolerance);
            extenderHeightMax = Obj.calc_max(Obj.extenderLength, Obj.extenderLengthTolerance);
            thicknessClampedPartsMax = upperFlangeThicknessMax + lowerFlangeThicknessMax + ...
                2 * washerHeightMax + extenderHeightMax;

            len = boltLengthMin - (freeThread1 + nut1HeightMax + nut2HeightMax + thicknessClampedPartsMax);

            % Round to nearest 0.001mm to avoid numerical roundoff errors in further calculations
            len = round(len, 6);
        end

        function value = zero_for_bolt(Obj, value)
            % Forces value to zero if the fastener type is 'hex'

            switch lower(Obj.fastenerType)
                case 'hex'
                    value = 0;
                case 'stud'
                    % Do nothing
                otherwise
                    error('ThreadLengthModel:UnknownFastenerType', ...
                        'Unknown fastener type (%s). Supported fastener types: hex, stud.', ...
                        Obj.fastenerType);
            end
        end

        function value = calc_max(~, nominal, tolerance)
            % Computes maximum value based on nominal value and tolerance.
            % If nominal value is zero, no tolerance will be accounted for.
            %
            %   nominal: Nominal value
            %   tolerance: Tolerance to be added to non-zero nominal value
            %   value: Maximum value

            value = double(abs(nominal) > 1e-6) .* (nominal + tolerance);
        end

        function value = calc_min(~, nominal, tolerance)
            % Computes minimum value based on nominal value and tolerance.
            % If nominal value is zero, no tolerance will be accounted for.
            %
            %   nominal: Nominal value
            %   tolerance: Tolerance to be substracted from non-zero nominal value
            %   value: Minimum value

            value = double(abs(nominal) > 1e-6) .* (nominal - tolerance);
        end

        function set_fixed_length(Obj, Inputs, tighteningMethod)
            % Determine visible thread length on fixed side

            if strcmp(Obj.fastenerType, 'hex')
                Obj.fixedLength = 0;  % There is no fixed length on the fixed side for hex bolts
                return
            end

            % For studs (i.e. with a fixed side)
            switch lower(tighteningMethod)
                case 'tension'
                    % For tensioning, the fixed side is to be set equal to the input maximum in order to ensure
                    % sufficient grip length.
                    % Round up values to nearest millimeter, because the fastener assembly drawings also have
                    % millimeter precision.
                    Expression = UsainUtils.LengthExpression(Inputs.MAX_VISIBLE_THREAD_LENGTH_TENSION, ...
                        @(x) round_up(x, 3));
                case 'torque'
                    % For torque, the fixed side is to be set equal to the input minimum (contrary to tension, above),
                    % in order to have a smaller bolt length
                    Expression = UsainUtils.LengthExpression(Inputs.MIN_VISIBLE_THREAD_LENGTH);
                otherwise
                    error('Could not determine fixed length for tighteningMethod=%s', tighteningMethod);
            end

            % Round to nearest 0.001mm to avoid numerical roundoff errors in further calculations
            Obj.fixedLength = round(Expression.calc_length(Obj.diamBolt, Obj.pitch), 6);
        end

        function set_fixed_and_free_side(Obj, tighteningSideInstallation)

            isStudInstallUpperSide = ~strcmp(Obj.fastenerType, 'hex') && tighteningSideInstallation == "upper";
            isBoltInstallLowerSide = strcmp(Obj.fastenerType, 'hex') && tighteningSideInstallation == "lower";

            if isStudInstallUpperSide || isBoltInstallLowerSide
                Obj.fixedSide = "upper";
                Obj.freeSide = "lower";
            else
                Obj.fixedSide = "lower";
                Obj.freeSide = "upper";
            end
        end

    end

    methods (Static)

        function Objs = from_inputs(Inputs)
            % Constructs (array of) object(s) based on USAIN inputs
            %
            % Objs: Array of N objects for N bolt options defined in USAIN inputs

            BoltOpts = usain.fastener.BoltOptionsParser(Inputs.boltOptions);
            nBoltOptions = numel(BoltOpts.label);
            Objs(nBoltOptions) = UsainUtils.ThreadLengthModel();
            for iOpt = 1:nBoltOptions
                % Get bolt catalog data from singleton CatalogLibrary (custom properties, e.g. washers, are already
                % accounted for)
                Assy = usain.fastener.CatalogLibrary.select_assemblies( ...
                    Inputs.site, BoltOpts.label{iOpt}, Inputs.tighteningMethod{iOpt}, Inputs.NUT_TYPE{iOpt});

                Obj = UsainUtils.ThreadLengthModel();
                Obj.fastenerType = Assy.Bolt.type;
                Obj.boltLengthToleranceClass = Assy.Bolt.lengthTolerance;
                Obj.diamBolt = Assy.Bolt.diam;
                Obj.pitch = Assy.Bolt.pitch;
                Obj.nutHeightMin = Assy.Nut.lenMin;
                Obj.nutHeightMax = Assy.Nut.lenMax;
                Obj.washerHeight = Assy.Washer.len;
                Obj.washerHeightTolerance = Assy.Washer.len - Assy.Washer.lenMin;
                Obj.extenderLength = max(Inputs.lengthBoltExtender(iOpt), 0);
                Obj.extenderLengthTolerance = Inputs.TOL_EXTENDER_LENGTH;
                Obj.flangeThicknessTolerancePlus = Inputs.TOL_FLANGE_THICKNESS_PLUS;
                Obj.upperFlangeThicknessAllowance = Inputs.ALW_UPPER_FLANGE_THICKNESS;
                Obj.lowerFlangeThicknessAllowance = Inputs.ALW_LOWER_FLANGE_THICKNESS;

                % Set free thread length above the nut on fixed side
                Obj.set_fixed_length(Inputs, Inputs.tighteningMethod{iOpt});

                % Set free and fixed side
                Obj.set_fixed_and_free_side(Inputs.TIGHTENING_SIDE_INSTALLATION{iOpt});

                % Set thread length based on inputs
                if isnan(BoltOpts.inputThreadLength(iOpt))
                    Obj.lengthThread = usain.fastener.FastenerData.get_standard_thread_length(BoltOpts.label{iOpt});
                else
                    Obj.lengthThread = BoltOpts.inputThreadLength(iOpt);
                end

                Objs(iOpt) = Obj;
            end
        end

        function Obj = from_flange_model(FlangeModel)
            % Constructs single object based on flange model data
            %
            % FlangeModel: FlangeModel or SelectedModel instance, with single design point
            % Obj: ThreadLengthModel instance

            assert(FlangeModel.Space.nPoints == 1, 'ThreadLengthModel:MultipleDesignPointsFound', ...
                'Construction from flange model can only be done for single design points.');

            % Shortcuts
            Inputs = FlangeModel.Inputs;

            % Build object
            Obj = UsainUtils.ThreadLengthModel();
            Obj.fastenerType = FlangeModel.Bolt.type;
            Obj.boltLengthToleranceClass = FlangeModel.Bolt.lengthTolerance;
            Obj.diamBolt = FlangeModel.Bolt.diam;
            Obj.pitch = FlangeModel.Bolt.pitch;
            Obj.nutHeightMin = FlangeModel.Nut.lenMin;
            Obj.nutHeightMax = FlangeModel.Nut.lenMax;
            Obj.washerHeight = FlangeModel.Wash.len;
            Obj.washerHeightTolerance = FlangeModel.Wash.len - FlangeModel.Wash.lenMin;
            Obj.extenderLength = FlangeModel.Extr.len;
            Obj.extenderLengthTolerance = Inputs.TOL_EXTENDER_LENGTH;
            Obj.flangeThicknessTolerancePlus = Inputs.TOL_FLANGE_THICKNESS_PLUS;
            Obj.upperFlangeThicknessAllowance = Inputs.ALW_UPPER_FLANGE_THICKNESS;
            Obj.lowerFlangeThicknessAllowance = Inputs.ALW_LOWER_FLANGE_THICKNESS;
            Obj.boltLength = FlangeModel.Bolt.len;
            Obj.lengthThread = FlangeModel.Bolt.lenThread;
            Obj.flangeThickness = FlangeModel.Space.thickness;

            Obj.set_fixed_length(FlangeModel.Inputs, FlangeModel.Tool.tighteningMethod{1});
            Obj.set_fixed_and_free_side(Inputs.TIGHTENING_SIDE_INSTALLATION{1});
        end

    end

end
