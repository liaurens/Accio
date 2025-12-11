classdef ToolToWallClashCheck < logging.Config
    % This class is used to identify interference between the tightening tool and the structure wall
    % Specifically, this interference check could drive the BCD in case of tension cylinders (relatively high)
    % and conical plates.

    % TODO: This must be extended to also check the outer diameter in case of T-flanges.

    properties
        Mdl UsainUtils.SelectedModel
    end

    methods

        function Obj = ToolToWallClashCheck(varargin)
            Obj = assign_varargin_2_classprop(Obj, varargin{:});
        end

        function bcd = calc_max_allowable_bcd(Obj)
            % Computes max allowable bolt circle diameter to avoid clashing of tool and structure wall
            %
            % bcd: Maximum allowable bolt circle diameter

            fDiam = Obj.setup_inner_diameter_interpolant();

            % Compute the z-coordinate of the top of the tightening tool
            zToolTop = Obj.Mdl.Space.thickness + Obj.Mdl.Tool.dimHeight;
            switch lower(char(Obj.Mdl.Inputs.TIGHTENING_SIDE_INSTALLATION))
                case "upper"
                    zCalc = Obj.Mdl.Inputs.zFlange - zToolTop;
                case "lower"
                    zCalc = Obj.Mdl.Inputs.zFlange + zToolTop;
            end

            tolBcd = Obj.Mdl.Inputs.TOL_BCD_TOOL_WALL;
            boltHoleClearance = (Obj.Mdl.Inputs.diamBoltHole - Obj.Mdl.Bolt.diam);
            bcd = fDiam(zCalc) - 2 * Obj.Mdl.Tool.dimRadialDir - boltHoleClearance - tolBcd;
            bcd = min(bcd);
            bcd = floor(bcd * 1e3) / 1e3;  % round down to nearest mm
        end

        function report_results(Obj)
            % Reports results of clash check
            % A warning is logged if a clash is detected or if the check could not be carried out

            bcd = Obj.calc_max_allowable_bcd();
            if Obj.Mdl.Inputs.diamBoltCircle > bcd
                Obj.warning('USAIN:ToolToWallClashCheck:ClashDetected', ...
                    ['Clash between tool and structure wall detected. ', ...
                    'The maximum allowable bolt circle diameter to avoid this is %.0fmm.'], ...
                    1e3 * bcd);
            end

            if isnan(bcd) && Obj.Mdl.Tool.dimHeight > 1e-4
                msg = UsainUtils.ToolToWallClashCheck.message_clash_not_checked( ...
                    Obj.Mdl.Inputs.TIGHTENING_SIDE_INSTALLATION);
                Obj.warning('USAIN:ToolToWallClashCheck:ClashNotChecked', msg);
            end
        end

    end

    methods (Access = protected)

        function fDiam = setup_inner_diameter_interpolant(Obj)
            % Construct interpolant for inner diameter as function of z-coordinate
            % The interpolant returns NaN in case of extrapolation. Extrapolation is not allowed because the
            % structure's inner diameter profile cannot be 'guessed'.
            %
            % fDiam: griddedInterpolant for inner diameter as function of z-coordinate

            StrMdl = Obj.Mdl.Inputs.StrMdl;
            z = [StrMdl.Inp.Plate.Parsed.zCoordTop(1); StrMdl.Inp.Plate.zCoordBot];
            diamInTop = StrMdl.Inp.Plate.Parsed.diamTop - 2 * StrMdl.Inp.Plate.Parsed.wallThickn;
            diamInBot = StrMdl.Inp.Plate.Parsed.diamBot - 2 * StrMdl.Inp.Plate.Parsed.wallThickn;
            diamIn = [diamInTop(1); diamInBot];
            fDiam = griddedInterpolant(z, diamIn, 'linear', 'none');
        end

    end

    methods (Static)

        function Obj = from_flange_model(FlangeModel)

            % This check only works with a single design point
            assert(isa(FlangeModel, 'UsainUtils.SelectedModel'), ...
                'USAIN:ToolToWallClashCheck:NotASelectedModel', ...
                'Input must be a UsainUtils.SelectedModel.');

            Obj = UsainUtils.ToolToWallClashCheck('Mdl', FlangeModel);
        end

        function msg = post_parse_checks(site, boltOptions, tighteningMethod, nutType, structureInpFilePath)
            % Performs "post-parse" checks, to be executed in USAIN.do_post_parse_checks

            % Get tool data
            label = usain.fastener.BoltOptionsParser(boltOptions).label;
            Assemblies = usain.fastener.CatalogLibrary.select_assemblies(site, label, tighteningMethod, nutType);
            Tools = [Assemblies.Tool];
            toolHeight = [Tools.dimHeight];

            % For tools with a nonzero height (tension cylinders), a StructuralModel must be present
            if any(toolHeight > 1e-4 & isempty(structureInpFilePath))
                msg = 'StructuralModel is required for clash check of tension tools and structure wall.';
            else
                msg = '';
            end
        end

        function msg = post_load_checks(site, boltOptions, tighteningMethod, tighteningSide, nutType, zFlange, structuralModelZRange) % mh:ignore_style
            % Performs "post-load" checks, to be executed in USAIN.do_post_load_checks
            %
            % warnMsg: Cell of warning messages, if any

            msg = '';

            % Get tool data
            label = usain.fastener.BoltOptionsParser(boltOptions).label;
            Assemblies = usain.fastener.CatalogLibrary.select_assemblies(site, label, tighteningMethod, nutType);
            Tools = [Assemblies.Tool];

            for Tool = Tools(:)'
                if Tool.dimHeight < 1e-4
                    continue  % skip check if tool height is zero
                end

                % Verify that structuralModelZRange covers the (approximated) top of the tightening tool
                if strcmpi(tighteningSide, 'upper')
                    zCheck = min(structuralModelZRange);  % top elevation level
                else
                    zCheck = max(structuralModelZRange);  % bottom elevation level; applicable for 'lower'
                end
                if abs(zFlange - zCheck) < 1e-6
                    msg = UsainUtils.ToolToWallClashCheck.message_clash_not_checked(tighteningSide);
                    break  % one message suffices
                end
            end
        end

    end

    methods (Static, Hidden)

        function msg = message_clash_not_checked(applicationSide)
            % Composes text for (warning) message that clash could not be checked
            %
            % applicationSide: Tool application side, either 'Up' or 'Lo'
            % msg: warning message

            switch lower(char(applicationSide))
                case 'upper'
                    words = ["above", "top"];
                case 'lower'
                    words = ["below", "bottom"];
                otherwise
                    error('Invalid applicationSide.');
            end
            msg = sprintf(['Cannot check for clash of tension tools and structure wall: ', ...
                'StructuralModel does not provide data %s the flange connection ', ...
                'and the tightening tool is applied on the %s of the connection.'], words);
        end

    end
end
