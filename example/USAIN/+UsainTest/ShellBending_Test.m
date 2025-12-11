classdef ShellBending_Test < Unittest.TestCase & matlab.mock.TestCase

    methods (Test, TestTags = {'unit'})

        function get_rnose__shift_mirrorred(Obj)
            % GIVEN a flange with some radius and some tolerance on the shell,
            % but not on the flange
            [Stub, ~] = Obj.createMock(?UsainUtils.ShellBending);
            Stub.diamOutNeck = 2;
            Stub.thkNose = 0;
            Stub.shiftShell = 1e-3;
            Stub.shiftFlange = 0;

            % WHEN computing the mean shell radius, taking into account
            % tolerances
            actual = Stub.rNose;

            % THEN we expect the upper (1) and lower(2) values to be mirrored
            % around the nominal value
            expect = 1 + [1e-3, -1e-3];
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-6);

            % WHEN doing the same, but with flange instead of shell tolerance
            Stub.shiftShell = 0;
            Stub.shiftFlange = 1e-3;
            actual = Stub.rNose;

            % THEN
            Obj.verifyEqual(actual, expect, 'AbsTol', 1e-6);
        end

        function process_position_x__input_matrix(Obj)
            % GIVEN a stub for ShellBending
            [Stub, ~] = Obj.createMock(?UsainUtils.ShellBending);

            % WHEN processing position x in case it is an array of size M*2
            x = ones(10, 2);
            actual = Stub.process_position_x(x);

            % THEN we expect an array of size 1*2*M to be returned
            Obj.verifySize(actual, [1, 2, 10]);

            % WHEN processing position x in case it is an array of size 1*2
            x = ones(1, 2);
            actual = Stub.process_position_x(x);

            % THEN we still expect an array of size 1*2*M to be returned
            Obj.verifySize(actual, [1, 2, 1]);
        end

        function process_position_x__input_vector(Obj)
            % GIVEN a stub for ShellBending
            [Stub, ~] = Obj.createMock(?UsainUtils.ShellBending);

            % WHEN processing position x in case it is an array of size M*1
            x = ones(10, 1);
            f = @() Stub.process_position_x(x);

            % THEN we expect an array of size 1*2*M to be returned
            Obj.verifyError(f, 'ShellBending:WrongPositionSize');
        end

    end
end
