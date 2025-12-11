classdef TFlangeSegmentModelFixture < matlab.unittest.fixtures.Fixture  % mh:ignore_style
    % SegmentModel fixture with data from a lookalike Moray West T-flange

    properties
        data usain.model.SegmentModel
        n double = 1  % number of design points in fixture
    end

    methods

        function Obj = TFlangeSegmentModelFixture(kwargs)  % mh:ignore_style
            arguments
                kwargs.n double = 1
            end
            Obj.n = kwargs.n;
        end

        function setup(Obj)

            Obj.data = usain.model.SegmentModel(usain.inputs.FlangeType.T);

            Obj.data.a = Obj.repeat(0.1405);
            Obj.data.b = Obj.repeat(0.1425);
            Obj.data.diameterOutNeck = Obj.repeat(7.5);
            Obj.data.diameterIn = Obj.repeat(6.842);
            Obj.data.flangeWidth = Obj.repeat(0.566);
            Obj.data.flangeThickness = Obj.repeat(0.130);
            Obj.data.neckThicknessUp = 0.092;  % always scalar
            Obj.data.neckThicknessLo = 0.105;  % always scalar
            Obj.data.diameterBoltCircle = Obj.repeat(7.123);

            Obj.data.eModulus = 210e9;  % always scalar
            Obj.data.gModulus = 210e9 / (2 * (1 + 0.3));  % always scalar

            Obj.data.nSegments = Obj.repeat(220);
            Obj.data.ftRd = Obj.repeat(1102982.4);

            Obj.data.resilienceFlanges = Obj.repeat(1.4049837943771400e-10);
            Obj.data.resilienceClampedParts = Obj.repeat(1.4049837943771400e-10);
            Obj.data.resilienceBoltAxial = Obj.repeat(1.1016952577960500e-9);
            Obj.data.resilienceBoltBending = Obj.repeat(9.31864119912e-6);
            Obj.data.loadFactor = Obj.repeat(0.11310505482);
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
