classdef SegmentModelFixture < matlab.unittest.fixtures.Fixture
    % SegmentModel fixture with data from HV_M42 flange that was used to compare with Frithjof Martin's implementation
    % of the polynomial model.

    properties
        data usain.model.SegmentModel
        n double = 1  % number of design points in fixture
    end

    methods

        function Obj = SegmentModelFixture(kwargs)
            arguments
                kwargs.n double = 1
            end
            Obj.n = kwargs.n;
        end

        function setup(Obj)

            Obj.data = usain.model.SegmentModel(usain.inputs.FlangeType.L);

            Obj.data.a = Obj.repeat(0.1300);
            Obj.data.aEffective = Obj.repeat(0.11801756286621);
            Obj.data.b = Obj.repeat(0.070);
            Obj.data.diameterOutNeck = Obj.repeat(4.6);
            Obj.data.diameterIn = Obj.repeat(4.170);
            Obj.data.flangeWidth = Obj.repeat(0.215);
            Obj.data.flangeThickness = Obj.repeat(0.095);
            Obj.data.neckThicknessUp = 0.030;  % always scalar
            Obj.data.neckThicknessLo = 0.030;  % always scalar
            Obj.data.diameterBoltCircle = Obj.repeat(4.430);

            Obj.data.eModulus = 210e9;  % always scalar
            Obj.data.gModulus = 210e9 / (2 * (1 + 0.3));  % always scalar

            Obj.data.nSegments = Obj.repeat(152);
            Obj.data.ftRd = Obj.repeat(839404.8);

            Obj.data.resilienceFlanges = Obj.repeat(1.5795675794773e-10);
            Obj.data.resilienceClampedParts = Obj.repeat(1.8185641974075e-10);
            Obj.data.resilienceBoltAxial = Obj.repeat(9.6162121601923e-10);
            Obj.data.resilienceBoltBending = Obj.repeat(9.34118205009327e-09);
            Obj.data.loadFactor = Obj.repeat(0.138);

        end

        function arrayValue = repeat(Obj, scalarValue)
            % Repeats scalar to match `Obj.n` design points
            arrayValue = scalarValue * ones(Obj.n, 1);
        end

    end

    methods (Access = protected)

        function bool = isCompatible(Obj, Other)
            bool = strcmp(Obj.n, Other.n);
        end

    end
end
