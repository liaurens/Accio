classdef GapCloseModelFixture < matlab.unittest.fixtures.Fixture
    % GapCloseModel fixture with data from "IEC_Example_Rev2" flange that was used to compare results in the IEC
    % 61400-6/AMD1 working group.

    properties
        data usain.sgre2.GapCloseModel
        n double = 1  % number of design points in fixture
    end

    methods

        function Obj = GapCloseModelFixture(kwargs)
            arguments
                kwargs.n double = 1
            end
            Obj.n = kwargs.n;
        end

        function setup(Obj)
            Obj.data = usain.sgre2.GapCloseModel();

            Obj.data.Gap = usain.sgre2.GapData();
            Obj.data.Gap.angle = deg2rad(30);
            Obj.data.Gap.len = 1.204;
            Obj.data.Gap.height = 0.778e-3;

            Obj.data.forceGapClose = Obj.repeat(276900);
            Obj.data.gapCloseStiffnessRatio = 0.5;
            Obj.data.stiffnessShell = Obj.repeat(2874e6);
            Obj.data.stiffnessGapTotal = Obj.repeat(7540e6);
            Obj.data.stiffnessSegment = Obj.repeat(17585e6);
            Obj.data.stiffnessCorrectionFactor = Obj.repeat(1.43);
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
