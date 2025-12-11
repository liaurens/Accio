classdef DesignSpace < matlab.mixin.SetGet & logging.Config

    properties
        thickness double  % [N x 1] Flange thickness value for N design points
        width double  % [N x 1] Flange width value for N design points
        nBolts double  % [N x 1] Number of bolts for N design points
        boltId double  % [N x 1] Bolt option index for N design points

        index double  % [N x 1] Index of design points, used for selecting a subset of the design space
    end

    properties (Dependent)
        nPoints  % Number of design points
    end

    methods

        function mesh(Obj, Thickness, Width, NumBolts)
            % Meshes design space and assigns grid vectors to respective properties

            % Mesh design variables individually
            thicknessGrids = Thickness.mesh();
            widthGrids = Width.mesh();
            numberBoltsGrids = NumBolts.mesh();

            % Make all possible combinations
            nBoltOptions = numel(thicknessGrids);
            combinations = cell(1, nBoltOptions);
            for iOption = 1:nBoltOptions
                combinations{iOption} = allcomb( ...
                    widthGrids{iOption}, thicknessGrids{iOption}, numberBoltsGrids{iOption}, iOption);
            end

            % Combine to big grid that will represent to design space and distribute to properties
            fullGrid = cat(1, combinations{:});
            Obj.width = fullGrid(:, 1);
            Obj.thickness = fullGrid(:, 2);
            Obj.nBolts = fullGrid(:, 3);
            Obj.boltId = fullGrid(:, 4);
            Obj.reset_index();
        end

        function New = post_mesh(Obj, FlangeType)
            % Scrap unsound design points after meshing
            % For example, after meshing a lot of design points will have an excessive strange
            % width-to-thickness ratio. We can upfront discard such designs and improve runspeed.

            arguments
                Obj
                FlangeType usain.inputs.FlangeType
            end

            maxWtRatio = usain.space.FlangeWidth.max_width_to_thickness_ratio(FlangeType);
            minWtRatio = usain.space.FlangeWidth.min_width_to_thickness_ratio(FlangeType);
            doDiscard = ...
                Obj.width ./ Obj.thickness > maxWtRatio + 1e-6 | ...
                Obj.width ./ Obj.thickness < minWtRatio - 1e-6;
            New = Obj.deepcopy(~doDiscard, resetIndex = true);
        end

        function New = remove_infeasible_number_of_bolts(Obj, Inputs, bMin)
            % In case of T-flanges with `outermost` as reference point, there will be a range for the bolt circle
            % diameter per bolt option. The design space will be set up considering the extreme boundaries. This means
            % using the smallest possible bolt circle diameter with the least possible minimum number of bolts.
            % And similar for the upper extreme, the largest possible bolt circle diameter with the highest possible
            % maximum number of bolts.
            % The resulting design space will contain design points with mismatching combinations.
            % Some examples:
            % 1) The smallest bolt circle diameter combined with the largest maximum number of bolts.
            %    -> The number of bolts might not geometrically fit.
            % 2) The largest  bolt circle diameter combined with the least minimum number of bolts.
            %    -> The least minimum number of bolts might be smaller than the fraction of the maximum number of bolts
            %    applicable for the actual bolt circle diameter.
            %
            % This method will act on the design space and determine for each point if the number of bolts is feasible

            % Determine diameterOutNeck and  diameterBoltCircle
            diameterOutNeck = usain.space.FlangeWidth.calc_diameter_out_neck(Inputs.diameter, ...
                Inputs.diameterReference, Obj.width, Inputs.thicknNoseUp, Inputs.flangeType);

            inputDiameterBoltCircle = Inputs.diamBoltCircle(Obj.boltId);
            inputDiameterBoltCircle = inputDiameterBoltCircle(:);
            bMin = bMin(Obj.boltId);
            bMin = bMin(:);

            diameterBoltCircle = usain.space.FlangeWidth.calc_bolt_circle_diameter(inputDiameterBoltCircle, ...
                diameterOutNeck, Inputs.thicknNoseUp, bMin);

            % Determine the min and max number of bolts
            NumBolts = usain.space.NumberOfBolts();
            boltDistance = NumBolts.calc_min_bolt_distance(Inputs);
            boltDistance = boltDistance(Obj.boltId);
            boltDistance = boltDistance(:);

            maxNumberOfBolts = usain.space.NumberOfBolts.calc_max_number_of_bolts(diameterBoltCircle, boltDistance);
            minNumberOfBolts = usain.space.NumberOfBolts.calc_min_number_of_bolts(Inputs, diameterBoltCircle, ...
                maxNumberOfBolts);

            isOkNumberOfBolts = minNumberOfBolts <= Obj.nBolts & Obj.nBolts <= maxNumberOfBolts;

            New = Obj.deepcopy(isOkNumberOfBolts, resetIndex = true);
        end

        function New = deepcopy(Obj, i, kwargs)
            % Return a new object with only the design points indicated by iDesignPoints
            %
            % i: Linear or logical indices of design points to copy
            % kwargs.resetIndex: Toggle to reset `index`. Default is FALSE.
            % New: Deep copy of DesignSpace object, with only the indicated design points

            arguments
                Obj
                i = true(size(Obj.thickness))
                kwargs.resetIndex logical = false
            end

            % Verify that input is a logical or linear index array
            validateattributes(i, {'logical', 'numeric'}, {'integer', 'vector'});
            assert(all(i >= 0) & all(i <= length(Obj.thickness)), ...
                'DesignSpace:IndexOutOfBounds', 'Index out of bounds.');

            New = usain.space.DesignSpace();
            New.thickness = Obj.thickness(i, 1);
            New.width = Obj.width(i, 1);
            New.nBolts = Obj.nBolts(i, 1);
            New.boltId = Obj.boltId(i, 1);
            New.index = Obj.index(i, 1);

            if kwargs.resetIndex
                New.reset_index();
            end
        end

        function reset_index(Obj)
            % Resets index of design space
            % A reset is done if the information on the previous state of the design space is no longer needed
            Obj.index = (1:Obj.nPoints)';
        end

        function value = get.nPoints(Obj)
            value = size(Obj.thickness, 1);
        end

    end

    methods (Static)

        function Obj = from_inputs(Inputs, bMin)
            % Constructs design space from USAIN inputs and minimum "b"

            % Set up design variables
            Thickness = usain.space.FlangeThickness.from_inputs(Inputs);
            Width = usain.space.FlangeWidth.from_inputs(Inputs, [Thickness.CalculatedBounds.max_], bMin);
            NumBolts = usain.space.NumberOfBolts.from_inputs(Inputs, [Width.minimumBoltCircleDiameter], ...
                [Width.maximumBoltCircleDiameter]);

            % Set up and mesh the design space
            Obj = usain.space.DesignSpace();
            Obj.mesh(Thickness, Width, NumBolts);

            if Inputs.DO_TRIM_DESIGN_SPACE
                % Remove design points for which the number of bolts is not feasible
                Obj = Obj.remove_infeasible_number_of_bolts(Inputs, bMin);

                % Remove design points for which width-thickness ratio are unexpected
                Obj = Obj.post_mesh(Inputs.flangeType);
            end

            Obj.assert(Obj.nPoints > 0, 'USAIN:DesignSpace:NoDesignPoints', ...
                'No feasible design points possible with provided inputs.');

        end

    end
end
