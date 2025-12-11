classdef FlangeYieldStrength

    properties
        steelType string  % Flange steel type specification (e.g. S355)
    end

    methods

        function Obj = FlangeYieldStrength(steelType)
            Obj.steelType = steelType;
        end

        function yieldStrength = get_yield_strength(Obj, productThickness)
            % Returns yield strength for given product thickness value(s)
            %
            % productThickness: N-element array with product thickness values
            % yieldStrength: N-element array with characteristic yield strength values

            if Obj.steelType == "S355"
                % Set up interpolant for S355 flange steel, according to Design Brief
                thicknessSamples =     [63  80  100 150 200 350] * 1e-3;
                yieldStrengthSamples = [325 315 295 285 275 275] * 1e6;
                yieldStrengthFunc = griddedInterpolant(thicknessSamples, yieldStrengthSamples, 'previous', 'none');
                % NOTE: The yield strength differs from the S355 definition in class `YieldStrengthTable`, because the
                % implementation here is specifically for flanges (different manufacturing process than plates)
            else
                % Get interpolant from StructuralModel's library
                yieldStrengthFunc = YieldStrengthTable.get_library().get_yield_strength(Obj.steelType);
            end

            yieldStrength = yieldStrengthFunc(productThickness);
        end

        function bool = is_flange_steel_type(Obj)
            % True if `steelType` will return yield strength values for flanges (not for rolled plates)
            % The yield strength of a rolled plate is different than, for example, for a ring rolled flange. Flange
            % specific yield strength values are only defined for S355 (EN) and SF520 (JIS).

            bool = contains(Obj.steelType, ["S355", "SF520"]);
        end

        function [message, level] = check_steel_type(Obj)
            % Prepares log message and level in case of unexpected class properties

            if Obj.is_flange_steel_type()
                % Log nothing; this is the expected path
                message = '';
                level = logging.Level.NOTSET;
            else
                % Log warning message that yield strength values are not specifically for flange steel
                message = sprintf(['Flange-specific yield strength values for "%s" steel are not defined; ', ...
                    'using values for rolled plates instead.'], Obj.steelType);
                level = logging.Level.WARNING;
            end
        end

    end

end
