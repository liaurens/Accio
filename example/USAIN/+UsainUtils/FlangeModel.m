classdef FlangeModel < matlab.mixin.SetGet & logging.Config
    % FlangeModel L- and T-flange model representation
    % An instance of this class serves as the basis for evaluating all flange
    % design constraints/conditions. Basically, this is the equivalent to
    % StructuralModel for L- and T-flanges
    %

    properties
        flangeType                                  % [char] Indicator for L- or T-flange
        doSetupLoads logical = true                 % Should we setup the Loads object

        Inputs = struct  % Parsed USAIN inputs

        Bolt = struct()  % Bolt data for input options
        Nut = struct()  % Nut data for input options
        Wash = struct()  % Washer data for input options
        Extr = struct()  % Extender data for input options
        Tool = struct()  % Tightening tool data for input options

        % Submodels
        Segment UsainUtils.SegmentModel  % Segment flange model representation

        Space usain.space.DesignSpace  % Design space
        Loads usain.loads.Loads  % Applied fatigue/extreme loads

        Condit UsainUtils.ConditContainer  % Design conditions

        minHeightNoseUp double  % Minimum nose height, upper [m]
        minHeightNoseLo double  % Minimum nose height, lower [m]

        thicknWeldBulgeUp double  % Thickness of weld bulge, upper [m]
        thicknWeldBulgeLo double  % Thickness of weld bulge, lower [m]

        bcdMin double  % Min. bolt circle diameter [m]
        bcdMax double  % Max. bolt circle diameter [m]

        diameterBoltCircle (:, 1) double  % Bolt circle diameter for each design point [m]
        bMinimum (:, 1) double  % Minimum possible distance b for each design point [m]
        diameterOutNeck (:, 1) double  % Outer diameter at the upper flange neck for each design point [m]

        diameterBoltHole (:, 1) double  % Bolt hole diameter for fastener [m]
    end

    properties (Dependent)
        massStubUp (:, 1) double  % Mass of stub part of upper flange (flange without shell part) [kg]
        massStubLo (:, 1) double  % Mass of stub part of lower flange (flange without shell part) [kg]
        massShellUp (:, 1) double  % Mass of flange shell, i.e. not the stub [kg]
        massShellLo (:, 1) double  % Mass of flange shell, i.e. not the stub [kg]
        massFlangeUp (:, 1) double  % Mass of upper flange [kg]
        massFlangeLo (:, 1) double  % Mass of lower flange [kg]
        massBoltAssm (:, 1) double  % Mass of bolt assembly [kg]
        heightTotUp (:, 1) double  % Total height of upper flange (incl. allowance) [m]
        heightTotLo (:, 1) double  % Total height of lower flange (incl. allowance) [m]
        clearWeldFilUp (:, 1) double  % Clearance weld prep to fillet radius, upper [m]
        clearWeldFilLo (:, 1) double  % Clearance weld prep to fillet radius, lower [m]
        clearToolWeld (:, 1) double  % Clearance bolt tightening tool to weld bulge [m]
        clearExtrFil (:, 1) double  % Clearance bolt extender to fillet radius [m]
        clearWashFilUp (:, 1) double  % Clearance washer to fillet radius, upper [m]
        clearWashFilLo (:, 1) double  % Clearance washer to fillet radius, lower [m]

        distBolts (:, 1) double  % Distance between fasteners [m]
        flangeTypeFactor double  % Flange type scaling factor (1 for L-flange, 2 for T-flange)
        nBoltsPrintStr char  % Number of bolts in format for DOCTOR reporting

        % Underneath properties apply to T-flange only, set empty for L-flanges
        bcdOut (:, 1) double                   % Outer bolt circle diameter
        diamOutFlange (:, 1) double            % Outer flange (stub) diameter
    end

    properties (Hidden, Constant)
        VALID_FLANGE_TYPES = {'L', 'T'} % Valid options for input flangeType
    end

    methods

        function Obj = FlangeModel(varargin)

            % Construct empty objects of user defined classes - damn fucking Matlab..
            Obj.Loads = usain.loads.Loads();
            Obj.Space = usain.space.DesignSpace();
            Obj.Segment = UsainUtils.SegmentModel();
            Obj.Condit = UsainUtils.ConditContainer();

            % Assign varargin
            if nargin
                Obj = assign_varargin_2_classprop(Obj, varargin{:});
            end
        end

        %%%%% == MODEL SETUP == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function build_model(Obj)

            % Set the flange type
            Obj.flangeType = Obj.Inputs.flangeType;

            if Obj.doSetupLoads
                Obj.Loads = usain.loads.Loads.setup(Obj.Inputs, Obj.Inputs.Milk, Obj.Inputs.StrMdl);
            end

            % Compute and set weld bulge size
            Obj.thicknWeldBulgeUp = Obj.calc_weld_bulge_size(Obj.Inputs.thicknNoseUp);
            Obj.thicknWeldBulgeLo = Obj.calc_weld_bulge_size(Obj.Inputs.thicknNoseLo);

            % Check nose heights if provided in inputs, compute and set otherwise
            Obj.calc_or_check_nose_heights();

            % Store fastener data to object properties
            Obj.assign_fastener_properties();

            % Determine bolt hole diameters for the provided input bolt options
            Obj.determine_bolt_hole_diameters();

            % Determine the minimum possible value(s) for "b" for the input boltOptions.
            % This is required to set up the design space and the bolt circle diameter.
            % Note: in case the user provided a diamBoltCircle, that will be used to set up the design space!
            bMinCalc = Obj.calc_minimum_parameter_b();
            [bMin, index] = UsainUtils.FlangeModel.determine_and_round_driving_parameter_b(bMinCalc, Obj.Inputs.B_MIN);

            if any(index == 2)
                Obj.info('Input "B_MIN" is driving criteria for "boltOption(s)": %s', ...
                    strjoin(Obj.Inputs.boltOptions(index == 2), ', '));
            end

            % Construct design space
            Obj.Space = usain.space.DesignSpace.from_inputs(Obj.Inputs, bMin);

            % Match bolt lengths to the thickness in the design space
            [boltLength, extenderLength] = usain.model.match_bolt_lengths_to_flange_thickness( ...
                Obj.Inputs, Obj.Space.thickness, Obj.Space.boltId);

            % Strip design points pertaining to thicknesses for which no bolt+extender length could be matched
            isMatched = ~isnan(boltLength);
            Obj.Space = Obj.Space.deepcopy(isMatched, resetIndex = true);
            boltLength(~isMatched) = [];
            extenderLength(~isMatched) = [];
            Obj.assert(Obj.Space.nPoints > 0, 'USAIN:FlangeModel:NoDesignPoints', ...
                'For input bolt lengths, no flange thickness could be matched.');

            % Set properties diameterOutNeck and diameterBoltCircle; this can only be performed after setting up the
            % "Width" part of the design space since it is depending on Input.diameterReference and the width of the
            % flange.
            % First need to expand bMin and Input.diamBoltCircle.
            inputDiameterBoltCircle = Obj.Inputs.diamBoltCircle(Obj.Space.boltId);
            inputDiameterBoltCircle = inputDiameterBoltCircle(:);
            bMin = bMin(Obj.Space.boltId);
            Obj.bMinimum = bMin(:);

            % TODO, move these methods from `FlangeWidth` to `FlangeModel`?
            Obj.diameterOutNeck = usain.space.FlangeWidth.calc_diameter_out_neck(Obj.Inputs.diameter, ...
                Obj.Inputs.diameterReference, Obj.Space.width, Obj.Inputs.thicknNoseUp, Obj.flangeType);

            Obj.diameterBoltCircle = usain.space.FlangeWidth.calc_bolt_circle_diameter( ...
                inputDiameterBoltCircle, Obj.diameterOutNeck, Obj.Inputs.thicknNoseUp, ...
                Obj.bMinimum);

            % Set diameter of bolt holes for each design point
            Obj.diameterBoltHole = Obj.Inputs.diamBoltHole(Obj.Space.boltId);

            % Set extreme values for the bcd and perform sanity check for robustness
            Obj.bcdMax = usain.space.FlangeWidth.calc_bolt_circle_diameter(nan, Obj.diameterOutNeck, ...
                Obj.Inputs.thicknNoseUp, Obj.bMinimum);
            Obj.bcdMin = Obj.calc_min_bolt_circle_diam();
            Obj.check_bolt_circle_diam();

            % Expand non-scalar values to yield same size as number of design space points, for convenient
            % handling and efficient matrix operations later on
            isInitialSetup = true;
            Sel = Obj.select_design_points(Obj.Space.boltId, isInitialSetup);
            for prop = fieldnames(Sel)'
                Obj.(prop{1}) = Sel.(prop{1});
            end

            % Assign bolt and extender lengths to Bolt and Extender instances (which are now spanning the size
            % of the DesignSpace)
            Obj.Bolt.len = boltLength;
            Obj.Extr.len = extenderLength;

            % Compute flange yield strength
            productThickness = min(max(Obj.heightTotLo, Obj.heightTotUp), Obj.Space.width);
            Obj.Inputs.yieldStrengthChar = ...
                usain.model.FlangeYieldStrength(Obj.Inputs.FLANGE_STEEL_TYPE).get_yield_strength(productThickness);

            % Store flange material type + grade, for reporting in DOCTOR
            Obj.Inputs.flangeMatrDesignation = Obj.typeset_material_designation();

            % Store used bolt circle diameters also in Inputs for easy output and printing in design summary.
            Obj.Inputs.diamBoltCircle = Obj.diameterBoltCircle;
        end

        function build_sub_models(Obj)

            % Build engineering submodels
            Obj.Segment = UsainUtils.SegmentModel.setup_obj(Obj);
        end

        %%%%% == DESIGN SPACE SETUP PREPARATIONS == %%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function assign_fastener_properties(Obj)

            % Reset bolt catalog, because maybe the singleton contains dirty data (e.g. custom washers, preload) from
            % the previous USAIN run
            Catalog = usain.fastener.CatalogLibrary.get_library();
            Catalog.set_clean_data();

            % Get bolt assembly objects corresponding to input boltOptions
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);

            Assy = Catalog.select_assemblies( ...
                Obj.Inputs.site, BoltOpts.label, Obj.Inputs.tighteningMethod, Obj.Inputs.NUT_TYPE);

            % Add thread length from inputs (if defined), or default thread length
            for iAssy = 1:numel(Assy)
                if isnan(BoltOpts.inputThreadLength(iAssy))
                    Assy(iAssy).Bolt.lenThread = Assy(iAssy).Bolt.get_default('lengthThread');
                else
                    Assy(iAssy).Bolt.lenThread = BoltOpts.inputThreadLength(iAssy);
                end
            end

            % If custom washers are defined in inputs, update Washer object
            for iAssy = 1:numel(Assy)
                Assy(iAssy).Washer.make_custom_washer(Obj.Inputs.CUSTOM_WASHER_DIAM_INNER(iAssy), ...
                    Obj.Inputs.CUSTOM_WASHER_DIAM_OUTER(iAssy), Obj.Inputs.CUSTOM_WASHER_THICKNESS(iAssy));
            end

            % Convert bolt assembly objects to (static) structs for speed and robustness
            Obj.Bolt = to_struct_of_arrays(cat(2, Assy.Bolt));
            Obj.Nut = to_struct_of_arrays(cat(2, Assy.Nut));
            Obj.Wash = to_struct_of_arrays(cat(2, Assy.Washer));
            Obj.Extr = to_struct_of_arrays(cat(2, Assy.Extender));
            Obj.Tool = to_struct_of_arrays(cat(2, Assy.Tool));
        end

        function thicknBulge = calc_weld_bulge_size(Obj, thicknNose)
            % CALC_WELD_BULGE_SIZE Computes weld bulge size of upper and lower flange
            % The weld bulge is used to determine the maximum allowable bolt
            % circle diameter.
            %
            % The weld bulge is calculated as 10% of the weld width.
            % Acc. to the SWP Design Rules (rev08, p13), the cutting of the
            % plates is dependent on the shell/nose thickness and may be one of
            % two types: B- or C-cut, flanges should have a c-cut. (Inconsistent
            % with appendix B - L-flange dimensioning p50 which also indicates a
            % B-cut would be possible, discussion with manufacturing engineers:
            % use C-cut).
            %
            % Acc. to the SWP Design Rules (rev06, p49/54), the maximum size of
            % the weld bulge is limited to 5mm.
            %
            % SYNTAX:
            % - thicknBulge = calc_weld_bulge_size(Obj, thicknNose)
            %
            % =============================================================
            %

            % The weld bulge is calculated as 10% of the weld width, where the
            % weld width is calculated according to the "bevel cut triangle"
            oppSideBevelTriangle = Obj.calc_bevel_triangle_sides(thicknNose);
            thicknBulge = 0.1 * 2 * oppSideBevelTriangle;

            % The maximum size of the weld bulge is limited to 5mm
            thicknBulge = min(thicknBulge, Obj.Inputs.MAX_WELD_BULGE_SIZE);
        end

        function calc_or_check_nose_heights(Obj)

            % Do this operation for both sides of a flange connection. Ugly
            % for-loop to avoid code repetition
            for side = {'Lo', 'Up'}

                % Compute minimum flange nose height
                varNoseThickn = sprintf('thicknNose%s', side{1});
                propNoseHeight = sprintf('minHeightNose%s', side{1});
                minHeightNose = Obj.calc_min_nose_height(Obj.Inputs.(varNoseThickn));
                Obj.(propNoseHeight) = minHeightNose;

                % Check input values (if defined); input values must be >= computed
                % minimum heights
                varInputHeight = sprintf('heightNose%s', side{1});
                if ~isnan(Obj.Inputs.(varInputHeight)) && minHeightNose > Obj.Inputs.(varInputHeight)
                    Obj.warning('Input "%s" is %gm while the feasible minimum is %gm.', ...
                        varInputHeight, Obj.Inputs.(varInputHeight), minHeightNose);
                end

                % Assign computed values if they were NaN (i.e. not defined in input)
                if isnan(Obj.Inputs.(varInputHeight))
                    Obj.Inputs.(varInputHeight) = minHeightNose;
                end
            end
        end

        function heightNose = calc_min_nose_height(Obj, thicknNose)
            % CALC_MIN_NOSE_HEIGHT Returns minimum nose height
            % Based on the bevel cut type, fillet radius and weld clearance, a
            % minimum nose height can be computed. This method computes this
            % minimum value and returns the maximum value of both
            %  1. Computed minimum value
            %  2. Input MIN_NOSE_HEIGHT (= min. height allowed by design rules)
            %
            % A manufacturing precision of 1mm is taken into account in the
            % calculation of the nose height. Hence, the actual flange nose
            % height will be a multiple of 1mm.
            %
            % This method considers input COUNTRYCODE, to include a DIBt/DIN
            % constraint that the nose height should be at least half of the
            % nose thickness. This is a certification requirement for German
            % projects.
            %
            % =============================================================
            %

            % Compute length of "opposite side" of bevel cut triangle; this
            % would represent the distance from nose top to weld toe
            opp = Obj.calc_bevel_triangle_sides(thicknNose);

            % Compute distance from flange surface to weld bulge/toe
            heightNose = opp + Obj.Inputs.FILLET_RADIUS + Obj.Inputs.CLEARANCE_FILLET_WELD;

            % Compute nose height by also including the minimally allowed nose
            % height (user input). Take into account manufacturing precision of
            % 1mm, i.e. round up to nearest mm
            heightNose = ceil(1e3 * max(heightNose, Obj.Inputs.MIN_NOSE_HEIGHT)) / 1e3;
        end

        function determine_bolt_hole_diameters(Obj)
            Lib = usain.fastener.CatalogLibrary.get_library();
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            for label = enumerate(BoltOpts.label)
                if isnan(Obj.Inputs.diamBoltHole(label.count))
                    defaultBoltHoleDiam = Lib.Fasteners.select('label', label.value).get_default('boltHoleDiam');
                    Obj.Inputs.diamBoltHole(label.count) = defaultBoltHoleDiam;
                end
            end
        end

        %%%%% == DESIGN SPACE SETUP == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function isFeasible = check_bolt_circle_diam(Obj)

            % Verify that min possible BCD <= max BCD
            isOutOfBounds = Obj.bcdMin > Obj.bcdMax;
            Obj.assert(~all(isOutOfBounds), 'FlangeModel:bcdMinGtbcdMax', ...
                ['No feasible bolt circle diameter ', ...
                'possible within the user defined design space: ', ...
                'minimum feasible value exceeds maximum.']);

            % Check if input bolt circle diameters are in feasible range
            isGtMax = Obj.diameterBoltCircle - Obj.bcdMax >= 1e-6;
            isLtMin = Obj.bcdMin - Obj.diameterBoltCircle > 1e-6;

            if any(isGtMax)
                Obj.warning(['One or more values for input "diamBoltCircle" are ', ...
                    'greater than the maximum feasible value.\n', ...
                    '\t==> Please double check the inputs.']);
            end
            if any(isLtMin)
                Obj.warning(['One or more values for input "diamBoltCircle" are ', ...
                    'smaller than the minimum feasible value.\n', ...
                    '\t==> Please double check the inputs.']);
            end

            isFeasible = ~isGtMax & ~isLtMin;
            Obj.assert(any(isFeasible), 'FlangeModel:noFeasibleBcd', ...
                ['No feasible bolt circle diameter in the design space.\n', ...
                    '\t==> Please double check the inputs.']);
        end

        function bcdMin = calc_min_bolt_circle_diam(Obj)
            % Computes minimum bolt circle diameter
            % According to Table 3.3 EN 1993-1-8:2005, the minimum edge distance for bolted joints is 1.2dh (dh = bolt
            % hole diameter). It is debatable whether this requirement is applicable for tower flanges, but at least it
            % provides a rule-of-thumb for spacing between the bolt holes and inner diameter of the flange.

            % Minimal hole edge distance ratio (Table 3.3 EN 1993-1-8:2005)
            edgeDistanceRatio = usain.space.FlangeWidth.EDGE_DISTANCE_RATIO;

            % Get width from design space
            width = Obj.Space.width;
            iId = Obj.Space.boltId;

            % Determine minimum bolt circle diameter by considering the edge distance ratio from either the secondary
            % holes (if defined) or the primary flange bolt holes.
            secondaryHolesBoltCircleDiameter = Obj.Inputs.SECONDARY_HOLES_BCD(iId);
            secondaryHolesBoltCircleDiameter = secondaryHolesBoltCircleDiameter(:);
            bcdMin = max( ...
                secondaryHolesBoltCircleDiameter + 2 * edgeDistanceRatio * Obj.diameterBoltHole, ...
                Obj.diameterOutNeck - 2 .* (width - edgeDistanceRatio * Obj.diameterBoltHole));

            % Round up to nearest mm
            bcdMin = ceil(round(bcdMin, 10) * 1e3) / 1e3;
        end

        function bMin = calc_minimum_parameter_b(Obj)
            % Computes the minimum possible value(s) for parameter b

            Inp = Obj.Inputs;

            % Throw warning if weld bulge of upper or lower flange is
            % greater than the flange fillet
            % TODO: assign largest of fillet and weld bulge to var and continue
            % with that value for bcdMax_*Fillet calculations

            for side = {'Lo', 'Up'}
                varName = sprintf('thicknWeldBulge%s', side{1});
                if Obj.(varName) > Inp.FILLET_RADIUS
                    Obj.warning([ ...
                        'In %s flange, weld bulge thickness (%.2fmm) > fillet radius (%.2fmm).\n', ...
                        '==> Bolt circle diameter checks might not be correct.'], ...
                        iif(strcmp(side{1}, 'Lo'), 'lower', 'upper'), 1e3 * Inp.(varName), ...
                        1e3 * Inp.FILLET_RADIUS);
                end
            end

            % Assess different criteria to determine the minimum possible "b"
            bMin_toolWeldInstall = Obj.calc_b_for_tool_weld_clearance_installation();
            bMin_toolWeldTemp = Obj.calc_b_for_tool_weld_clearance_temp_stages();
            bMin_washFillet = Obj.calc_b_for_washer_fillet_clearance();
            bMin_extrFillet = Obj.calc_b_for_extender_fillet_clearance();
            bMin_doorSegment = Obj.calc_b_for_door_segment_clearance();

            % % Return maximum (=driving) value for "b"; round up to nearest 0.5mm (will result in nearest 1mm for bcd)
            bMin = UsainUtils.FlangeModel.determine_and_round_driving_parameter_b(bMin_toolWeldInstall, ...
                bMin_toolWeldTemp, bMin_washFillet, bMin_extrFillet, bMin_doorSegment);
        end

        function b = calc_b_for_tool_weld_clearance_installation(Obj)
            % Computes minimum "b" based on clearance between installation tool and weld
            % Using geometry of side of flange where the installation tool is placed.
            % Note that "b" refers to the side with minimum nose thickness (see
            % usain.model.SegmentModel.calc_parameter_b). So it's required to account for (possible) assymmetry for
            % L-flanges. Not needed for assymmetrical T-flanges since there "b" still refers to the middle of the nose

            % Get installation tool size in radial direction
            hasOverride = ~isnan(Obj.Inputs.TOOL_DIMENSION_RADIAL_DIR);
            toolSizeRadialDir = Obj.Tool.dimRadialDir;
            toolSizeRadialDir(hasOverride) = Obj.Inputs.TOOL_DIMENSION_RADIAL_DIR(hasOverride);

            tolBcd = Obj.Inputs.TOL_BCD;
            holeClearance = (Obj.Inputs.diamBoltHole - Obj.Bolt.diam);

            % Calculate parameter "b" for both sides of the connection.
            spaceForTool = toolSizeRadialDir + ((tolBcd + holeClearance) / 2);
            deltaThicknNose = Obj.Inputs.thicknNoseLo - Obj.Inputs.thicknNoseUp;
            isL = Obj.flangeType == 'L';
            b = (Obj.Inputs.thicknNoseUp / 2) + Obj.thicknWeldBulgeUp + spaceForTool;
            bLo = (Obj.Inputs.thicknNoseLo / 2) + Obj.thicknWeldBulgeLo + spaceForTool + isL * (deltaThicknNose / 2);

            % Use applicable side where tool is placed
            hasSideLower = strcmp(Obj.Inputs.TIGHTENING_SIDE_INSTALLATION, 'lower');
            b(hasSideLower) = bLo(hasSideLower);
        end

        function b = calc_b_for_tool_weld_clearance_temp_stages(Obj)
            % Computes minimum "b" based on clearance between temporary stages tool and weld.
            % Using geometry of both flanges, as temporary stages tools may be placed on both sides.

            % In case the temporary stages tool should not be used to determine the bcd, set to nan and return
            if strcmp(Obj.Inputs.TEMP_STAGES_TOOL_TYPE, 'none')
                b = nan(size(Obj.Inputs.boltOptions));
                return
            end

            % Get temporary stages tool size in radial direction
            BoltOpts = usain.fastener.BoltOptionsParser(Obj.Inputs.boltOptions);
            nLabel = length(BoltOpts.label);
            toolSizeRadialDir = nan(1, nLabel);
            for iLabel = 1:nLabel
                if ~isnan(Obj.Inputs.TOOL_DIMENSION_RADIAL_DIR(iLabel))
                    toolSizeRadialDir(iLabel) = Obj.Inputs.TOOL_DIMENSION_RADIAL_DIR(iLabel);
                else
                    toolSizeRadialDir(iLabel) = usain.fastener.TighteningToolData.get_temp_stages_tool_obj( ...
                        Obj.Inputs.site, BoltOpts.label{iLabel}, Obj.Inputs.TEMP_STAGES_TOOL_TYPE).dimRadialDir;
                end
            end

            tolBcd = Obj.Inputs.TOL_BCD;
            holeClearance = (Obj.Inputs.diamBoltHole - Obj.Bolt.diam);

            % Calculate parameter "b" for both sides of the connection
            spaceForTool = toolSizeRadialDir + ((tolBcd + holeClearance) / 2);
            deltaThicknNose = Obj.Inputs.thicknNoseLo - Obj.Inputs.thicknNoseUp;
            isL = Obj.flangeType == 'L';
            b = (Obj.Inputs.thicknNoseUp / 2) + Obj.thicknWeldBulgeUp + spaceForTool;
            bLo = (Obj.Inputs.thicknNoseLo / 2) + Obj.thicknWeldBulgeLo + spaceForTool  + isL * (deltaThicknNose / 2);

            hasSideLower = strcmp(Obj.Inputs.TIGHTENING_SIDE_TEMP_STAGES, 'lower');
            hasSideBoth = strcmp(Obj.Inputs.TIGHTENING_SIDE_TEMP_STAGES, 'both');

            b(hasSideLower) = bLo(hasSideLower);
            b(hasSideBoth) = max(b(hasSideBoth), bLo(hasSideBoth));
        end

        function [b, bUp, bLo] = calc_b_for_washer_fillet_clearance(Obj)
            % Computes minimum "b" based on clearance between washer/nut and fillet

            diamContact = usain.fastener.calc_contact_diameter(Obj.Nut.diam, Obj.Wash.diamOut, Obj.Wash.len);

            holeClearance = (Obj.Inputs.diamBoltHole - Obj.Bolt.diam);
            distanceHoleToWall = Obj.Inputs.FILLET_RADIUS + Obj.Inputs.TOL_FILLET_RADIUS_PLUS + ...
                (diamContact / 2) + ...
                ((Obj.Inputs.TOL_BCD + holeClearance) / 2);

            deltaThicknNose = Obj.Inputs.thicknNoseLo - Obj.Inputs.thicknNoseUp;
            isL = Obj.flangeType == 'L';

            bUp = (Obj.Inputs.thicknNoseUp / 2) + distanceHoleToWall;
            bLo = (Obj.Inputs.thicknNoseLo / 2) + distanceHoleToWall + isL * (deltaThicknNose / 2);

            b = max(bUp, bLo);
        end

        function b = calc_b_for_extender_fillet_clearance(Obj)
            % Computes minimum "b" based on clearance between extender and fillet
            % Using geometry of side of flange where extender is present
            % When user Joe specifies that there should NOT be an extender (=lengthBoltExtender = 0), exclude the
            % diameter in the BCD calculation.

            if all(isnan(Obj.Inputs.lengthBoltExtender)) || all(Obj.Inputs.lengthBoltExtender < 1e-6)
                b = nan(size(Obj.Inputs.boltOptions));
                return
            end

            extenderSide = replace(Obj.Inputs.TIGHTENING_SIDE_INSTALLATION, {'upper', 'lower'}, {'Lo', 'Up'});
            hasExtenderOnLowerSide = strcmpi(extenderSide, 'Lo');

            % Use "NOT lenExt < tol" instead of "lenExt > tol" to properly account for NaN value
            includeExtender = ~(Obj.Inputs.lengthBoltExtender < 1e-6);

            holeClearance = (Obj.Inputs.diamBoltHole - Obj.Bolt.diam);
            distanceHoleToWall = Obj.Inputs.FILLET_RADIUS + Obj.Inputs.TOL_FILLET_RADIUS_PLUS + ...
                (includeExtender .* Obj.Extr.diamOut ./ 2) + ...
                ((Obj.Inputs.TOL_BCD + holeClearance) / 2);

            deltaThicknNose = Obj.Inputs.thicknNoseLo - Obj.Inputs.thicknNoseUp;
            isL = Obj.flangeType == 'L';

            b = (Obj.Inputs.thicknNoseUp / 2) + distanceHoleToWall;
            bLo = (Obj.Inputs.thicknNoseLo / 2) + distanceHoleToWall + isL * (deltaThicknNose / 2);

            b(hasExtenderOnLowerSide) = bLo(hasExtenderOnLowerSide);
        end

        function b = calc_b_for_door_segment_clearance(Obj)
            % Computes minimum "b" based on door segment thickness and installation tool or extender

            if ~Obj.Inputs.DOOR_SEGMENT.DO_INCLUDE
                b = nan(size(Obj.Inputs.boltOptions));
                return
            end

            % Get installation tool size in radial direction
            hasOverride = ~isnan(Obj.Inputs.TOOL_DIMENSION_RADIAL_DIR);
            toolSizeRadialDir = Obj.Tool.dimRadialDir;
            toolSizeRadialDir(hasOverride) = Obj.Inputs.TOOL_DIMENSION_RADIAL_DIR(hasOverride);

            % Use "NOT lenExt < tol" instead of "lenExt > tol" to properly account for NaN value
            extenderDiameter = ~(Obj.Inputs.lengthBoltExtender < 1e-6) .* Obj.Extr.diamOut;

            tDoorSegment = Obj.Inputs.DOOR_SEGMENT.THICKNESS;

            diamToolOrExtr = zeros(size(Obj.Inputs.TIGHTENING_SIDE_INSTALLATION));
            for iTool = 1:numel(Obj.Inputs.TIGHTENING_SIDE_INSTALLATION)
                if strcmp(Obj.Inputs.TIGHTENING_SIDE_INSTALLATION(iTool), 'upper')
                    diamToolOrExtr(iTool) = 2 * toolSizeRadialDir(iTool);
                else
                    diamToolOrExtr(iTool) = extenderDiameter(iTool);
                end
            end

            holeClearance = (Obj.Inputs.diamBoltHole - Obj.Bolt.diam);
            distanceHoleToDoorSegment = diamToolOrExtr / 2 + ...
                ((Obj.Inputs.TOL_BCD + holeClearance) / 2);

            b = tDoorSegment / 2 + distanceHoleToDoorSegment;
        end

        function diam = get_outer_diameter_neck_lower_flange(Obj)
            % Helper function to compute the outer diameter of the lower flange neck
            % For an L-flange, this equals to the upper flange's neck diameter as L-flanges are outside-aligned.
            % For a T-flange, the value is different in case as asymmetry, because of the center-alignment of the neck.

            if strcmp(Obj.flangeType, 'L')
                diam = Obj.diameterOutNeck;

            elseif strcmp(Obj.flangeType, 'T')
                deltaNeckThickness = Obj.Inputs.thicknNoseLo - Obj.Inputs.thicknNoseUp;
                diam = Obj.diameterOutNeck + deltaNeckThickness;

            else
                Obj.error('Unexpected error: Could not determine flange type. Please contact developer.');
            end

        end

        %%%%% == DESIGN SPACE MODIFICATIONS == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function Sel = select_design_points(Obj, iSel, isInitialSetup)
            % Select or expand design points
            %
            % iSel: Indices to expand/select design points
            % Sel: Struct with fields `Inputs`, `Bolt`, `Nut`, `Wash`, `Extr`, `Tool`, containing the selected/expanded
            % entries according to input iSel
            % isInitialSetup = true indicates that FlangeModel properties will be expanded to match the design space
            % dimensions. In this use case, iSel will have dimensions equal to the design space containing values
            % related to the bolt indices (so related to the input bolt options).

            if nargin < 3
                isInitialSetup = false;
            end

            Sel = struct();

            % Skip scalar fields in `Inputs`, and skip some fields based on their name
            skipInputs = ["Loads", "StrMdl", "Milk", "PSF_BOLT_RESISTANCE_JPN_TAG", "PSF_BOLT_RESISTANCE_JPN", ...
                "GAP_ANGLE"];
            Sel.Inputs = StructIndexSelector('excludeFields', skipInputs, ...
                'doSkipScalars', true).select(Obj.Inputs, iSel);

            % Use default selection for the other fields
            Sel.Bolt = StructIndexSelector().select(Obj.Bolt, iSel);
            Sel.Nut = StructIndexSelector().select(Obj.Nut, iSel);
            Sel.Wash = StructIndexSelector().select(Obj.Wash, iSel);
            Sel.Extr = StructIndexSelector().select(Obj.Extr, iSel);
            Sel.Tool = StructIndexSelector().select(Obj.Tool, iSel);

            if ~isInitialSetup
                % Reduce other FlangeModel properties
                Sel.bcdMin = Obj.bcdMin(iSel);
                Sel.bcdMax = Obj.bcdMax(iSel);
                Sel.diameterBoltCircle = Obj.diameterBoltCircle(iSel);
                Sel.diameterOutNeck = Obj.diameterOutNeck(iSel);
                Sel.diameterBoltHole = Obj.diameterBoltHole(iSel);
            end
        end

        %%%%% == CONDITIONS == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function reduce_design_space(Obj, isSelection)
            Obj.Space = Obj.Space.deepcopy(isSelection);

            Sel = Obj.select_design_points(find(isSelection));
            for prop = fieldnames(Sel)'
                Obj.(prop{1}) = Sel.(prop{1});
            end

            Obj.build_sub_models();
        end

        %%%%% == HELPER METHODS == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [opp, adj] = calc_bevel_triangle_sides(Obj, thicknNose)
            % Calculate the opposite and adjacent sides of the bevel angle. This calculation only support symmetrical
            % bevels on both sides of the weld (also known as double-V).
            %
            % See bevel geometry in USAIN/docs/reference/img/bevel_cut_geometry.png, where:
            % - angleBevel is denoted as "bevel angle"
            % - thicknNose is denoted as "flange nose thickness"
            % - bevelRootFace is denoted as "bevel root face"
            angleBevel = Obj.Inputs.BEVEL_ANGLE;
            bevelRootFace = Obj.Inputs.BEVEL_ROOT_FACE;
            adj = (thicknNose - bevelRootFace) ./ 2; % double sided bevel
            opp = adj .* tan(angleBevel);
        end

        function dFilletIn = calc_diameter_at_fillet(Obj, flangeSide)
            % This function calculates the diameter between the fillets
            % edges at the inside of the flange
            tNoseAtHead = cellfun(@(x) Obj.Inputs.(['thicknNose' x]), flangeSide);
            dFilletIn = Obj.diameterOutNeck - 2 * (tNoseAtHead + Obj.Inputs.FILLET_RADIUS);
        end

        function mass = calc_ring_mass(Obj, dOut, dIn, height)
            % TODO: Make it a regular function as it can be used outside the class too
            mass = pi * ((dOut ./ 2).^2 - (dIn ./ 2).^2) .* height .* Obj.Inputs.RHO_FLANGE;
        end

        function clr = calc_clearance_weldprep_fillet(Obj, thkNose)
            % Helper method to avoid code repetition, as this clearance is to be
            % computed for both sides of the flange connection
            %
            % INPUT
            %   thkNose: [double] Nose thickness
            %
            % OUTPUT
            %   clr:     [double] Clearance weldprep - fillet radius

            % Compute length of "opposite side" of bevel cut triangle; this
            % would represent the distance from nose top to weld toe
            opp = Obj.calc_bevel_triangle_sides(thkNose);

            % Compute distance from fillet to weld bulge/toe
            clr = Obj.Inputs.heightNoseLo - opp - Obj.Inputs.FILLET_RADIUS;
        end

        function str = typeset_material_designation(Obj)
            % Combine steel type and grade into material designation
            %

            steel = Obj.Inputs.FLANGE_STEEL_TYPE;
            switch upper(Obj.Inputs.countryCode)
                case 'ROW'
                    % For ROW (rest-of-world), flange material is always normalized so S355 becomes S355NL
                    grade = 'NL';
                case 'JPN'
                    % For JPN market, the flange material starts with SF. The grade is unknown at the time of
                    % implementation (contact Toni Subroto for update)
                    grade = '';
                otherwise
                    Obj.error('Implementation error. Contact developer');
            end

            % Typeset material designation (steel + grade)
            str = [steel, grade];
        end

        %%%%% == GETTERS / SETTERS == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function value = get.massStubUp(Obj)

            % Shortcuts
            % Updating the thickness with the allowances for the flange thickness
            thickn = Obj.Space.thickness + Obj.Inputs.ALW_UPPER_FLANGE_THICKNESS;
            dIn = Obj.diamOutFlange - 2 * Obj.Space.width;

            % Return mass of upper stub (i.e. flange without shell part)
            massShell = Obj.calc_ring_mass(Obj.diameterOutNeck, Obj.diameterOutNeck - 2 * ...
                Obj.Inputs.thicknNoseUp, thickn);

            massSolid = Obj.calc_ring_mass(Obj.diamOutFlange, dIn, thickn);
            massHole = Obj.calc_ring_mass(Obj.diameterBoltHole, 0, thickn);
            value = massSolid - massShell - (Obj.flangeTypeFactor .* Obj.Space.nBolts .* massHole);
        end

        function value = get.massStubLo(Obj)

            % Shortcuts
            % Updating the thickness with the allowances for the flange thickness
            thickn = Obj.Space.thickness + Obj.Inputs.ALW_LOWER_FLANGE_THICKNESS;
            dIn = Obj.diamOutFlange - 2 * Obj.Space.width;

            % Return mass of lower stub (i.e. flange without shell part)
            massShell = Obj.calc_ring_mass(Obj.diameterOutNeck, Obj.diameterOutNeck - 2 * ...
                                            Obj.Inputs.thicknNoseLo, thickn);

            massSolid = Obj.calc_ring_mass(Obj.diamOutFlange, dIn, thickn);
            massHole = Obj.calc_ring_mass(Obj.diameterBoltHole, 0, thickn);
            value = massSolid - massShell - (Obj.flangeTypeFactor .* Obj.Space.nBolts .* massHole);
        end

        function value = get.massShellUp(Obj)
            value = Obj.calc_ring_mass(Obj.diameterOutNeck, Obj.diameterOutNeck - 2 * ...
                                Obj.Inputs.thicknNoseUp, Obj.heightTotUp);
        end

        function value = get.massShellLo(Obj)
            value = Obj.calc_ring_mass(Obj.diameterOutNeck, Obj.diameterOutNeck - 2 * ...
                                    Obj.Inputs.thicknNoseLo, Obj.heightTotLo);
        end

        function value = get.massFlangeUp(Obj)
            value = Obj.massShellUp + Obj.massStubUp;
        end

        function value = get.massFlangeLo(Obj)
            value = Obj.massShellLo + Obj.massStubLo;
        end

        function value = get.massBoltAssm(Obj)

            % Shortcuts
            nBolts = Obj.Space.nBolts;

            massExtender = usain.fastener.ExtenderData.calc_mass(Obj.Extr.diamOut, Obj.Extr.diamIn, Obj.Extr.len);
            massWasher = Obj.Wash.mass;
            massNut = Obj.Nut.mass;

            massBolt = zeros(numel(Obj.Bolt.label), 1);
            isHex = contains(Obj.Bolt.type, 'hex');
            isStud = contains(Obj.Bolt.type, 'stud');
            Obj.assert(all(isHex | isStud), 'USAIN:FlangeModel:UnknownBoltType', ...
                'Unknown bolt type detected and not able to determine the bolt mass for it');

            massBolt(isHex) = usain.fastener.calc_mass_hv_bolt(Obj.Bolt.diam(isHex), Obj.Bolt.len(isHex));
            massBolt(isStud) = usain.fastener.calc_mass_iso_stud(Obj.Bolt.diam(isStud), Obj.Bolt.len(isStud));

            value = Obj.flangeTypeFactor .* nBolts .* (massExtender + massBolt + 2 * (massNut + massWasher));
        end

        function value = get.heightTotUp(Obj)

            value = Obj.Space.thickness + Obj.Inputs.heightNoseUp + Obj.Inputs.ALW_UPPER_FLANGE_THICKNESS;
        end

        function value = get.heightTotLo(Obj)

            value = Obj.Space.thickness + Obj.Inputs.heightNoseLo + Obj.Inputs.ALW_LOWER_FLANGE_THICKNESS;
        end

        function value = get.clearWeldFilUp(Obj)

            thicknNose = Obj.Inputs.thicknNoseUp;
            value = Obj.calc_clearance_weldprep_fillet(thicknNose);
        end

        function value = get.clearWeldFilLo(Obj)

            thicknNose = Obj.Inputs.thicknNoseLo;
            value = Obj.calc_clearance_weldprep_fillet(thicknNose);
        end

        function value = get.clearToolWeld(Obj)
            bcdActual = Obj.diameterBoltCircle;

            bCalcInstall = Obj.calc_b_for_tool_weld_clearance_installation();
            bCalcTemp = Obj.calc_b_for_tool_weld_clearance_temp_stages();
            bCalcDriving = max(bCalcInstall, bCalcTemp);
            bcdCalc = Obj.calc_bcd_from_parameter_b(Obj.diameterOutNeck, Obj.Inputs.thicknNoseUp, bCalcDriving);

            value = bcdCalc - bcdActual;
        end

        function value = get.clearExtrFil(Obj)
            bcdActual = Obj.diameterBoltCircle;

            bCalc = Obj.calc_b_for_extender_fillet_clearance();
            bcdCalc = Obj.calc_bcd_from_parameter_b(Obj.diameterOutNeck, Obj.Inputs.thicknNoseUp, bCalc);

            value = bcdCalc - bcdActual;
        end

        function value = get.clearWashFilUp(Obj)
            bcdActual = Obj.diameterBoltCircle;
            [~, bUp, ~] = Obj.calc_b_for_washer_fillet_clearance();
            bcdCalc = Obj.calc_bcd_from_parameter_b(Obj.diameterOutNeck, Obj.Inputs.thicknNoseUp, bUp);
            value = bcdCalc - bcdActual;
        end

        function value = get.clearWashFilLo(Obj)
            bcdActual = Obj.diameterBoltCircle;
            [~, ~, bLo] = Obj.calc_b_for_washer_fillet_clearance();
            bcdCalc = Obj.calc_bcd_from_parameter_b(Obj.diameterOutNeck, Obj.Inputs.thicknNoseUp, bLo);
            value = bcdCalc - bcdActual;
        end

        function value = get.distBolts(Obj)

            try
                value = sin(pi ./ Obj.Space.nBolts) .* Obj.diameterBoltCircle;
            catch
                value = [];
            end
        end

        function value = get.bcdOut(Obj)
            if strcmp(Obj.flangeType, 'T')
                value = 2 .* Obj.diameterOutNeck - ...
                    2 .* Obj.Inputs.thicknNoseUp - Obj.diameterBoltCircle;
            else
                value = [];
            end
        end

        function value = get.diamOutFlange(Obj)
            % Calculate outer flange (stub) diameter, specifically useful for T-flanges
            % For L-flanges, this equals `diameterOutNeck`
            hasOuterStub = (Obj.flangeTypeFactor - 1);
            value = Obj.diameterOutNeck + ...
                hasOuterStub * (Obj.Space.width - Obj.Inputs.thicknNoseUp);
        end

        function value = get.flangeTypeFactor(Obj)
            value = iif(strcmp(Obj.flangeType, 'T'), 2, 1);
        end

        function value = get.nBoltsPrintStr(Obj)
            xBolts = {'', '2x'};
            value = arrayfun(@(x) ...
                sprintf('%s%i', xBolts{Obj.flangeTypeFactor}, x), ...
                Obj.Space.nBolts, 'uni', 0);
        end

    end

    methods (Access = protected)

        function prepare_obj_for_operation(Obj)
            Obj.build_model();
            Obj.build_sub_models();
        end

    end

    methods (Static)

        function FlangeModel = setup_obj(varargin)
            % Instantiate the Flange Model Object
            FlangeModel = UsainUtils.FlangeModel(varargin{:});

            % Prepare the flange model for operation
            FlangeModel.prepare_obj_for_operation();
        end

        function bcd = calc_bcd_from_parameter_b(diameterOutNeck, thicknessNoseUp, b)
            % Convenience method to calculate the bolt circle diameter
            bcd = diameterOutNeck - thicknessNoseUp - 2 * b;
        end

        function [bMin, index] = determine_and_round_driving_parameter_b(bValues)
            arguments (Repeating)
                bValues (1, :) double
            end
            assert(all(cellfun(@(x) isequaln(size(bValues{1}), size(x)), bValues)), ...
                'FlangeModel:InconsistentInputSize', ...
                'Repeated inputs must have the same dimensions');

            % Return maximum (=driving) value for "b"; round up to nearest 0.5mm (will result in nearest 1mm for bcd)
            [bMin, index] = max(cat(1, bValues{:}), [], 1);
            bMin = ceil(round(bMin, 10) * 2e3) / 2e3;
        end

    end
end
