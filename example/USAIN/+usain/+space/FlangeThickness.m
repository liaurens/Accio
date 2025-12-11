classdef FlangeThickness < design_space.DesignVariable

    methods

        function Obj = FlangeThickness(varargin)
            Obj@design_space.DesignVariable(varargin{:});
            Obj.humanReadableName = "flange thickness";
        end

        function thickness = calc_max_flange_thickness(~, Inputs)
            % Compute maximum flange thickness

            % Get bolt length from inputs, or maximum length from catalog
            boltLabel = usain.fastener.BoltOptionsParser(Inputs.boltOptions).label;
            boltLength = usain.fastener.BoltOptionsParser(Inputs.boltOptions).inputBoltLength;
            for len = enumerate(boltLength)
                validLengths = usain.fastener.FastenerData.get_length_options(len.value, boltLabel{len.count});
                boltLength(len.count) = max(validLengths);
            end

            thickness = boltLength ./ 2;
        end

        function thickness = calc_min_flange_thickness(~, Inputs)
            % Compute minimum flange thickness, the requirement is to satisfy clampedLength / boltDiameter >= 4.

            BoltOpts = usain.fastener.BoltOptionsParser(Inputs.boltOptions);
            Assy = usain.fastener.CatalogLibrary.select_assemblies( ...
                Inputs.site, BoltOpts.label, Inputs.tighteningMethod, Inputs.NUT_TYPE);
            Washer = to_struct_of_arrays(cat(2, Assy.Washer));
            boltDiameter = BoltOpts.diameter;
            washerHeight = Washer.len;

            thickness = 2 * boltDiameter - washerHeight;
        end

    end

    methods (Static)

        function Obj = from_inputs(Inputs)
            % Determines minimum and maximum flange thickness from USAIN inputs

            Obj = usain.space.FlangeThickness(Inputs.STEPSIZE_THICKN, Inputs.DO_TRIM_DESIGN_SPACE);

            calculatedMin = Obj.calc_min_flange_thickness(Inputs);
            calculatedMax = Obj.calc_max_flange_thickness(Inputs);
            Obj.set_calculated_bounds(calculatedMin, calculatedMax);

            Obj.set_input_bounds(Inputs.minFlangeThickn, Inputs.maxFlangeThickn);
        end

    end

end
