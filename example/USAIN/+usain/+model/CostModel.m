classdef CostModel

    properties
        fastenerMass (:, 1) double {mustBePositive}
        flangeMass (:, 1) double {mustBePositive}
        totalMass (:, 1) double {mustBePositive}
        costFactor (:, 1) double {mustBePositive}
    end

    properties (Constant)
        SLOPE = 7
        EXPONENT = 30
        REFERENCE_POINT_1 = 0.036
        REFERENCE_POINT_2 = 0.064
    end

    methods

        function value = calc_cost(Obj)

            value = Obj.costFactor .* Obj.totalMass;
        end

        function value = fastener_size_penalty(Obj, boltSize)
            % Penalty function to favor smaller fastener diameters.
            linearPart = 1 + Obj.SLOPE .* (boltSize - Obj.REFERENCE_POINT_1);
            exponentialPart = (1 + Obj.SLOPE .* (Obj.REFERENCE_POINT_2 - Obj.REFERENCE_POINT_1)) .* ...
                exp(Obj.EXPONENT .* (boltSize - Obj.REFERENCE_POINT_2));
            value = max(linearPart, exponentialPart);
        end

    end

    methods (Static)

        function Obj = from_flange_model(FlangeModel)

            arguments
                FlangeModel UsainUtils.FlangeModel
            end

            Obj = usain.model.CostModel();

            Obj.flangeMass = FlangeModel.massFlangeUp + FlangeModel.massFlangeLo;
            Obj.fastenerMass = FlangeModel.massBoltAssm;
            Obj.totalMass = Obj.flangeMass + Obj.fastenerMass;
            Obj.costFactor = Obj.fastener_size_penalty(FlangeModel.Bolt.diam);
        end

    end
end
