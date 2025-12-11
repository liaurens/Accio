classdef FlangeTiltMechanicsFixture < matlab.unittest.fixtures.Fixture
    % FlangeTiltMechanics fixture with data from a lookalike Moray West T-flange

    properties
        data usain.sgre2.FlangeTiltMechanics
        n double = 1  % number of design points in fixture
    end

    methods

        function Obj = FlangeTiltMechanicsFixture(kwargs)
            arguments
                kwargs.n double = 1
            end
            Obj.n = kwargs.n;
        end

        function setup(Obj)
            Obj.data = usain.sgre2.FlangeTiltMechanics(usain.inputs.FlangeType.T);

            Obj.data.eModulus = 210e9;  % always scalar
            Obj.data.flangeThickness = Obj.repeat(0.130);
            Obj.data.neckThickness = 0.0985;
            Obj.data.parameterB = Obj.repeat(0.13925);
            Obj.data.flangeWidth = Obj.repeat(0.566);
            Obj.data.radiusMidNeck = Obj.repeat(3.70075);
            Obj.data.segmentWidth = Obj.repeat(0.105693173);
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
