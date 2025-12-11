classdef FlangeWidth < design_space.DesignVariable

    properties (Constant)
        EDGE_DISTANCE_RATIO = 1.2  % Minimal hole edge distance ratio, from EN 1993-1-8:2005, table 3.3
        MIN_AB_RATIO = 1.25 % Minimum required ratio between parameters "a" and "b" for L-flanges
    end

    properties
        minimumBoltCircleDiameter  % Minimum bolt circle diameter per bolt option
        maximumBoltCircleDiameter  % Maximum bolt circle diameter per bolt option
    end

    methods

        function Obj = FlangeWidth(varargin)
            Obj@design_space.DesignVariable(varargin{:});
            Obj.humanReadableName = "flange width";
        end

        function width = calc_max_flange_width(Obj, Inputs, maxThickness)
            % Returns maximum flange width

            maxRatio = Obj.max_width_to_thickness_ratio(Inputs.flangeType);
            width = maxRatio * maxThickness;
        end

        function [minimumWidth, minimumBcd, maximumBcd] = calc_min_flange_width(Obj, Inputs, maxWidth, bMin)
            % Determine the minimum possible width by setting up a range from 0 to the maximum
            % Set diameterOuterMost for a vector of the same size
            % Set diameterOutNeck for a vector of the same size
            % Set boltCircleDiameter for a vector of the same size
            % Evaluate points which satisfy the criterias (a/b ratio, hole distance to edge, secondary hole distance to
            % edge).
            % Take the minimum width

            minimumWidth = nan(size(maxWidth));
            minimumBcd = nan(size(maxWidth));
            maximumBcd = nan(size(maxWidth));

            if any(isnan(bMin))
                bMin = nan(size(maxWidth));
            end

            for iBolt = 1:numel(maxWidth)
                stepSize = 0.01 * Inputs.STEPSIZE_WIDTH;
                width = 0:stepSize:maxWidth(iBolt);
                width = width(:);

                diameterOuterMost = Obj.calc_diameter_outer_most(Inputs.diameter, Inputs.diameterReference, ...
                    width, Inputs.thicknNoseUp, Inputs.flangeType);
                diameterOutNeck = Obj.calc_diameter_out_neck(Inputs.diameter, Inputs.diameterReference, width, ...
                    Inputs.thicknNoseUp, Inputs.flangeType);
                diameterBoltCircle = Obj.calc_bolt_circle_diameter(Inputs.diamBoltCircle(iBolt), diameterOutNeck, ...
                    Inputs.thicknNoseUp, bMin(iBolt));

                % calc parameters "a" and "b"
                diameterIn = usain.model.SegmentModel.calc_inner_diameter(diameterOuterMost, width);
                a = usain.model.SegmentModel.calc_parameter_a(diameterIn, diameterBoltCircle);
                b = usain.model.SegmentModel.calc_parameter_b(Inputs.flangeType, diameterOutNeck, ...
                    diameterBoltCircle, Inputs.thicknNoseUp, Inputs.thicknNoseLo);

                % Perform checks for geometrical conditions
                isOkAbRatio = Obj.check_a_b_ratio(a, b, Inputs.flangeType);
                isOkBoltsEdgeDistance = Obj.check_bolt_edge_distance(Inputs.diamBoltHole(iBolt), a);
                isOkSecondaryHoles = Obj.check_secondary_holes_edge_distance(Inputs.SECONDARY_HOLES_DIAMETER(iBolt), ...
                    Inputs.SECONDARY_HOLES_BCD(iBolt), diameterIn);

                isOk = isOkAbRatio & isOkBoltsEdgeDistance & isOkSecondaryHoles;

                % Determine minimum width satisfying all the checks.
                minimumWidth(iBolt) = min(width(isOk));

                % Determine minimum and maximum bcd. The input bolt circle diameter is considered in this method.
                minimumBcd(iBolt) = min(diameterBoltCircle(isOk));
                maximumBcd(iBolt) = max(diameterBoltCircle(isOk));
            end

        end

        function pass = check_a_b_ratio(Obj, a, b, flangeType)
            if flangeType == 'L'
                pass = a ./ b >= Obj.MIN_AB_RATIO;
            else
                % Check not relevant for T-flanges, hence always pass.
                pass = true;
            end
        end

        function pass = check_bolt_edge_distance(Obj, boltHoleDiameter, a)
            minEdgeDistance = Obj.EDGE_DISTANCE_RATIO .* boltHoleDiameter;
            pass = a >= minEdgeDistance;
        end

        function pass = check_secondary_holes_edge_distance(Obj, secondaryHolesDiameter, ...
                secondaryHolesBoltCircleDiameter, diameterIn)
            if ~isnan(secondaryHolesDiameter)
                minEdgeDistance = Obj.EDGE_DISTANCE_RATIO .* secondaryHolesDiameter;
                pass = ((secondaryHolesBoltCircleDiameter - diameterIn) / 2) >= minEdgeDistance;
            else
                % Check not relevant if there are no secondary holes present, hence always pass.
                pass = true;
            end
        end

    end

    methods (Static)

        function Obj = from_inputs(Inputs, maxThickness, bMin)
            % Determines minimum and maximum flange width from USAIN inputs
            arguments
                Inputs struct
                maxThickness (1, :) double {mustBePositive}
                bMin (1, :) double {mustBePositive} % Minimum possible distance "b" (bolt hole to tower wall, this
                % takes a potential difference in nose thickness into consideration!)
            end

            Obj = usain.space.FlangeWidth(Inputs.STEPSIZE_WIDTH, Inputs.DO_TRIM_DESIGN_SPACE);

            calculatedMaxWidth = Obj.calc_max_flange_width(Inputs, maxThickness);
            [calculatedMinWidth, Obj.minimumBoltCircleDiameter, Obj.maximumBoltCircleDiameter] = ...
                Obj.calc_min_flange_width(Inputs, calculatedMaxWidth, bMin);
            Obj.set_calculated_bounds(calculatedMinWidth, calculatedMaxWidth);

            Obj.set_input_bounds(Inputs.minFlangeWidth, Inputs.maxFlangeWidth);
        end

        function ratio = min_width_to_thickness_ratio(flangeType)
            arguments
                flangeType (1, 1) usain.inputs.FlangeType
            end
            ratio = 1.2 + 0.8 * (flangeType == 'T');
            % NOTE: These ratios are based on engineering judgement. Update if better values are found.
        end

        function ratio = max_width_to_thickness_ratio(flangeType)
            arguments
                flangeType (1, 1) usain.inputs.FlangeType
            end
            ratio = 3 + 1 * (flangeType == 'T');
            % NOTE: These ratios are based on engineering judgement. Update if better values are found.
        end

        function diameterOuterMost = calc_diameter_outer_most(diameter, diameterReference, width, ...
                thicknNoseUp, flangeType)
            % Determine the diameterOuterMost with respect to the user defined reference point.
            arguments
                diameter double
                diameterReference string {mustBeMember(diameterReference, {'outneck', 'outermost'})}
                width double
                thicknNoseUp (1, 1) double
                flangeType string
            end

            if ~isscalar(diameter)
                assert(all(size(diameter) == size(width)), ...
                     'FlangeWidth:InconsistentInputSize', ...
                     'Inputs "diameter" and "width" must have the same dimension in case "diameter" is not a scalar');
            end

            switch diameterReference
                case 'outneck'
                    diameterOuterMost = diameter + (flangeType == 'T') * (width - thicknNoseUp);
                case 'outermost'
                    if isscalar(diameter)
                        diameterOuterMost = repmat(diameter, size(width));
                    else
                        diameterOuterMost = diameter;
                    end
            end
        end

        function diameterOutNeck = calc_diameter_out_neck(diameter, diameterReference, width, ...
                thicknNoseUp, flangeType)
            % Determine the diameterOutNeck with respect to the user defined reference point.
            arguments
                diameter double
                diameterReference string {mustBeMember(diameterReference, {'outneck', 'outermost'})}
                width double
                thicknNoseUp (1, 1) double
                flangeType string
            end

            if ~isscalar(diameter)
                assert(all(size(diameter) == size(width)), ...
                     'FlangeWidth:InconsistentInputSize', ...
                     'Inputs "diameter" and "width" must have the same dimension in case "diameter" is not a scalar');
            end

            switch diameterReference
                case 'outneck'
                    if isscalar(diameter)
                        diameterOutNeck = repmat(diameter, size(width));
                    else
                        diameterOutNeck = diameter;
                    end
                case 'outermost'
                    diameterOutNeck = diameter + (flangeType == 'T') * (thicknNoseUp - width);
            end
        end

        function boltCircleDiameter = calc_bolt_circle_diameter(boltCircleDiameter, diameterOutNeck, thicknNoseUp, bMin)
            arguments
                boltCircleDiameter double % scalar or same size as diameterOutNeck
                diameterOutNeck double
                thicknNoseUp (1, 1) double
                bMin double % scalar or same size as diameterOutNeck
            end
            % Note that bMin is considering potential difference in nose thickness between upper and lower flange of the
            % connection.

            if ~isscalar(boltCircleDiameter)
                assert(all(size(boltCircleDiameter) == size(diameterOutNeck)), ...
                     'FlangeWidth:InconsistentInputSize', ...
                     'Inputs "boltCircleDiameter" and "diameterOutNeck" must have the same dimension in case ', ...
                     '"boltCircleDiameter" is not a scalar');
            end

            if ~isscalar(bMin)
                assert(all(size(bMin) == size(diameterOutNeck)), ...
                     'FlangeWidth:InconsistentInputSize', ...
                     'Inputs "bMin" and "diameterOutNeck" must have the same dimension in case ', ...
                     '"bMin" is not a scalar');
            end

            if isnan(boltCircleDiameter)
                % Need to calculate
                boltCircleDiameter = diameterOutNeck - thicknNoseUp - 2 * bMin;
            elseif ~all(size(boltCircleDiameter) == size(diameterOutNeck))
                if isscalar(boltCircleDiameter)
                    % Need to assign with proper dimensions
                    boltCircleDiameter = repmat(boltCircleDiameter, size(diameterOutNeck));
                end
            end
        end

    end

end
