classdef (SharedTestFixtures = {Unittest.fixtures.SilentlyLogWarningsFixture}) ...
        ICondition_Test < UsainTest.UsainTestCase & matlab.mock.TestCase % mh:ignore_style

    properties (TestParameter)
        nPts = {1, 2, 100}
        nLoadSets = {1, 3}
    end

    methods

        function [Mock, MockBehavior] = init_mock(Obj)
            % Constructs mocked UsainUtils.ICondition object

            % Assign a value to abstract properties
            props.TOGGLE_NAME = 'Test';
            [Mock, MockBehavior] = Obj.createMock(?UsainUtils.ICondition, 'DefaultPropertyValues', props);
        end

    end

    methods (Test, TestTags = {'unit'})

        function squeeze_dims__size_return_arg_with_input_3d(Obj, nPts, nLoadSets)
            % Is the expected array size returned by squeeze_dims?
            % Are the returned values as expected as well?

            % Setup
            inputArray = rand(nPts, 1, nLoadSets);
            expect = [nPts, nLoadSets];

            % Test
            Mock = Obj.init_mock();
            actual = Mock.squeeze_dims(inputArray);

            % Verify
            Obj.verifySize(actual, expect);
            for iLoadSet = 1:nLoadSets
                Obj.verifyEqual(actual(:, iLoadSet), inputArray(:, 1, iLoadSet));
            end
        end

        function squeeze_dims__size_return_arg_with_input_2d(Obj, nPts, nLoadSets)
            % Is the expected array size returned by squeeze_dims?
            % Are the returned values as expected as well?

            % Setup
            inputArray = rand(nPts, nLoadSets);
            expect = [nPts, nLoadSets];

            % Test
            Mock = Obj.init_mock();
            actual = Mock.squeeze_dims(inputArray);

            % Verify
            Obj.verifySize(actual, expect);
            Obj.verifyEqual(actual, inputArray);
        end

    end

end
