classdef NumberOfBolts < design_space.DesignVariable

    methods

        function Obj = NumberOfBolts(varargin)
            Obj@design_space.DesignVariable(varargin{:});
            Obj.humanReadableName = "number of bolts";
        end

        function distance = calc_min_bolt_distance(Obj, Inputs)
            % Computes minimum bolt distance

            BoltOpts = usain.fastener.BoltOptionsParser(Inputs.boltOptions);

            Assy = usain.fastener.CatalogLibrary.select_assemblies( ...
                Inputs.site, BoltOpts.label, Inputs.tighteningMethod, Inputs.NUT_TYPE);
            Nut = cat(1, Assy.Nut);
            Washer = cat(1, Assy.Washer);
            Bolt = cat(1, Assy.Bolt);
            diamNut = [Nut.diam];
            diamWasherOrNut = max(diamNut, [Washer.diamOut]);
            diamBolt = [Bolt.diam];

            distanceTool = Obj.calc_bolt_distance_for_tool(Inputs, diamNut);
            distanceWasher = Obj.calc_bolt_distance_for_washer(Inputs, diamWasherOrNut, diamBolt);
            distance = min( ...
                max(max(distanceTool, distanceWasher), Inputs.GLOBAL_MIN_BOLT_DISTANCE), ...
                Inputs.GLOBAL_MAX_BOLT_DISTANCE);
        end

        function distance = calc_bolt_distance_for_tool(Obj, Inputs, diamNut)
            % Check for clash between tool and adjacent nut

            BoltOpts = usain.fastener.BoltOptionsParser(Inputs.boltOptions);

            tol = Obj.get_bolt_distance_tolerance(Inputs.tighteningMethod);
            toolSizeCircDir = usain.fastener.TighteningToolData.get_tool_size_for_bolt_distance( ...
                Inputs.site, BoltOpts.label, ...
                Inputs.tighteningMethod, Inputs.NUT_TYPE, ...
                Inputs.TEMP_STAGES_TOOL_TYPE, Inputs.TOOL_DIMENSION_CIRC_DIR);
            distance = (diamNut / 2) + toolSizeCircDir + tol;
        end

        function distance = calc_bolt_distance_for_washer(~, Inputs, diamWasherOrNut, diamBolt)
            % Check for clash between neighboring washers/nuts (not expected to become critical)
            holeClearance = Inputs.diamBoltHole - diamBolt;
            distance = diamWasherOrNut + holeClearance;
        end

    end

    methods (Static)

        function Obj = from_inputs(Inputs, minimumBoltCircleDiameter, maximumBoltCircleDiameter)
            % Determines minimum and maximum number of bolts from USAIN inputs
            % In case of T-flanges with `outermost` as reference point, there will be a range for the bolt circle
            % diameter per bolt option.
            % Here we determine the absolute lower and upper limit per bolt option, neglecting the range.
            % Later on in the set up design space a filtering will be performed to ensure only design points will remain
            % with feasible number of bolts for that design point.
            % See also: `usain.space.NumberOfBolts.fix_for_number_of_bolts`
            arguments
                Inputs struct
                minimumBoltCircleDiameter (1, :) double {mustBePositive}
                maximumBoltCircleDiameter (1, :) double {mustBePositive}
            end
            Obj = usain.space.NumberOfBolts(Inputs.STEPSIZE_NBOLTS, Inputs.DO_TRIM_DESIGN_SPACE);

            % Calculate upper limit for maximum possible bolt circle diameter
            boltDistance = Obj.calc_min_bolt_distance(Inputs);
            calculatedMax = Obj.calc_max_number_of_bolts(maximumBoltCircleDiameter, boltDistance);

            % Calculate lower limit for minimum possible bolt circle diameter
            maxNumberBoltForMinBcd = Obj.calc_max_number_of_bolts(minimumBoltCircleDiameter, boltDistance);
            calculatedMin = Obj.calc_min_number_of_bolts(Inputs, minimumBoltCircleDiameter, maxNumberBoltForMinBcd);
            Obj.set_calculated_bounds(calculatedMin, calculatedMax);

            Obj.set_input_bounds(Inputs.minNBolts, Inputs.maxNBolts);
        end

        function tol = get_bolt_distance_tolerance(tighteningMethod)
            % After alignment with Marc Seidel and Simon Brauer, 2 mm was found too small for tension tools. For torque
            % tools, no issue was ever found so that is deemed safe.
            tol = nan(1, length(tighteningMethod));
            for e = enumerate(tighteningMethod)
                if strcmp(e.value, 'torque')
                    tol(e.count) = 0.002;
                elseif strcmp(e.value, 'tension')
                    tol(e.count) = 0.004;
                else
                    error('Implementation error');
                end
            end
        end

        function nBolts = calc_max_number_of_bolts(boltCircleDiameter, boltDistance)
            assert(all(size(boltCircleDiameter) == size(boltDistance)), ...
                'NumberOfBolts:InconsistentInputSize', ...
                'Inputs "boltCircleDiameter" and "boltDistance" must have the same dimensions');
            nBolts = floor(pi * boltCircleDiameter ./ boltDistance);
        end

        function nBolts = calc_min_number_of_bolts(Inputs, boltCircleDiameter, maxNumberBolts)
            assert(all(size(boltCircleDiameter) == size(maxNumberBolts)), ...
                'NumberOfBolts:InconsistentInputSize', ...
                'Inputs "boltCircleDiameter" and "maxNumberBolts" must have the same dimensions');
            % Determine number of bolts based on input max bolt distance
            nBoltsForMaxDistance = floor(pi * boltCircleDiameter ./ Inputs.GLOBAL_MAX_BOLT_DISTANCE);

            nBolts = max(nBoltsForMaxDistance, ...
                floor(Inputs.MIN_NUMBER_BOLTS_FRACTION .* maxNumberBolts));
        end

    end

end
