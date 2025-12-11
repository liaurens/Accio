classdef (SharedTestFixtures = {Unittest.fixtures.SilentlyLogWarningsFixture}) ...
        DesignSpace_Test < Unittest.TestCase & matlab.mock.TestCase

    methods

        function Test = setup_dummy_object(~, nDesignPoints)
            Test = usain.space.DesignSpace();
            Test.thickness = (1:nDesignPoints)';
            Test.width = 0.1 + (1:nDesignPoints)';
            Test.nBolts = 0.2 + (1:nDesignPoints)';
            Test.boltId = 0.3 + (1:nDesignPoints)';
            Test.index = (1:nDesignPoints)';
        end

        function assertDesignSpaceSize(Obj, Actual, expectedSize)
            % Convenience method to assert the size of a DesignSpace object
            Obj.assertClass(Actual, 'usain.space.DesignSpace');
            Obj.assertSize(Actual.thickness, [expectedSize, 1]);
            Obj.assertSize(Actual.width, [expectedSize, 1]);
            Obj.assertSize(Actual.nBolts, [expectedSize, 1]);
            Obj.assertSize(Actual.boltId, [expectedSize, 1]);
        end

    end

    methods (Test, TestTags = {'unit'})

        function mesh__happy(Obj)
            % GIVEN mocked design variables
            [ThicknessStub, ThicknessBehavior] = Obj.createMock(?usain.space.FlangeThickness);
            [WidthStub, WidthBehavior] = Obj.createMock(?usain.space.FlangeWidth);
            [NumBoltsStub, NumBoltsBehavior] = Obj.createMock(?usain.space.NumberOfBolts);
            Obj.assignOutputsWhen(withAnyInputs(ThicknessBehavior.mesh()), {[1, 2], [10, 11]});
            Obj.assignOutputsWhen(withAnyInputs(WidthBehavior.mesh()), {[3, 4], [12, 13]});
            Obj.assignOutputsWhen(withAnyInputs(NumBoltsBehavior.mesh()), {[5, 6], [14, 15]});

            % WHEN
            Test = usain.space.DesignSpace();
            Test.mesh(ThicknessStub, WidthStub, NumBoltsStub);

            % THEN we expect 16 design points (2 bolt options, 2*2*2 combinations per bolt option)
            Obj.assertDesignSpaceSize(Test, 16);
            Obj.assertEqual(unique(Test.thickness), [1; 2; 10; 11]);
            Obj.assertEqual(unique(Test.width), [3; 4; 12; 13]);
            Obj.assertEqual(unique(Test.nBolts), [5; 6; 14; 15]);
            Obj.assertEqual(unique(Test.boltId), [1; 2]);
        end

        function post_mesh__strip_large_width_to_thickness_ratios(Obj)
            % GIVEN a design space with 4 points; 2 of which have a w/t > 3
            Space = usain.space.DesignSpace();
            nDesignPoints = 4;
            Space.thickness = 0.100 * ones(nDesignPoints, 1);
            Space.width = [2 3 4 5]' .* Space.thickness;
            Space.nBolts = 123 * ones(nDesignPoints, 1);
            Space.boltId = ones(nDesignPoints, 1);
            Space.index = (1:nDesignPoints)';
            FlangeType = usain.inputs.FlangeType.L;

            % WHEN
            Space = Space.post_mesh(FlangeType);

            % THEN we expect points with w/t > 3 to be discarded
            Obj.verifyEqual(Space.nPoints, 2);
            Obj.verifyEqual(Space.width, [0.200 0.300]', 'AbsTol', 1e-6);
        end

        function post_mesh__strip_small_width_to_thickness_ratios(Obj)
            % GIVEN a design space with 4 points; 2 of which have a w/t < 1.2
            Space = usain.space.DesignSpace();
            nDesignPoints = 4;
            Space.thickness = 0.100 * ones(nDesignPoints, 1);
            Space.width = [0.9 1.15 1.2 2]' .* Space.thickness;
            Space.nBolts = 123 * ones(nDesignPoints, 1);
            Space.boltId = ones(nDesignPoints, 1);
            Space.index = (1:nDesignPoints)';
            FlangeType = usain.inputs.FlangeType.L;

            % WHEN
            Space = Space.post_mesh(FlangeType);

            % THEN we expect points with w/t > 3 to be discarded
            Obj.verifyEqual(Space.nPoints, 2);
            Obj.verifyEqual(Space.width, [0.120 0.200]', 'AbsTol', 1e-6);
        end

        function deepcopy__linear_indices(Obj)
            % GIVEN a dummy design space with 10 design points
            Original = Obj.setup_dummy_object(10);

            % WHEN deep-copying 4 points of the design space
            New = Original.deepcopy([1, 2, 3, 10]);

            % THEN we expect a newly created design space object with 4 design points, and the original design space is
            % not changed
            Obj.assertDesignSpaceSize(New, 4);
            Obj.assertDesignSpaceSize(Original, 10);
            Obj.assertEqual(New.thickness, [1; 2; 3; 10]);
            Obj.assertEqual(New.width, [1.1; 2.1; 3.1; 10.1]);
            Obj.assertEqual(New.nBolts, [1.2; 2.2; 3.2; 10.2]);
            Obj.assertEqual(New.boltId, [1.3; 2.3; 3.3; 10.3]);

            % WHEN deep-copying 2 points of the previously copied object, with indices not ordered
            Newer = New.deepcopy([4, 2]);
            Obj.assertDesignSpaceSize(Newer, 2);
            Obj.assertEqual(Newer.thickness, [10; 2]);
            Obj.assertEqual(Newer.width, [10.1; 2.1]);
            Obj.assertEqual(Newer.nBolts, [10.2; 2.2]);
            Obj.assertEqual(Newer.boltId, [10.3; 2.3]);
        end

        function deepcopy__boolean_indices(Obj)
            % GIVEN a dummy design space with 10 design points
            Original = Obj.setup_dummy_object(10);

            % WHEN deep-copying the first and last points
            New = Original.deepcopy([true; false; false; false; false; false; false; false; false; true]);

            % THEN we expect a newly created design space object with 4 design points, and the original design space is
            % not changed
            Obj.assertDesignSpaceSize(New, 2);
            Obj.assertDesignSpaceSize(Original, 10);
            Obj.assertEqual(New.thickness, [1; 10]);
            Obj.assertEqual(New.width, [1.1; 10.1]);
            Obj.assertEqual(New.nBolts, [1.2; 10.2]);
            Obj.assertEqual(New.boltId, [1.3; 10.3]);
        end

        function deepcopy__no_arg(Obj)
            % GIVEN a dummy design space with 10 design points
            Original = Obj.setup_dummy_object(3);

            % WHEN deep-copying without args
            New = Original.deepcopy();

            % THEN we expect a newly created design space object with the same data
            Obj.assertDesignSpaceSize(New, 3);
            Obj.assertDesignSpaceSize(Original, 3);
            Obj.assertEqual(New.thickness, [1; 2; 3]);
            Obj.assertEqual(New.width, [1.1; 2.1; 3.1]);
            Obj.assertEqual(New.nBolts, [1.2; 2.2; 3.2]);
            Obj.assertEqual(New.boltId, [1.3; 2.3; 3.3]);
        end

        function deepcopy__reset_index(Obj)
            % GIVEN a dummy design space with 10 design points
            Original = Obj.setup_dummy_object(3);
            Original.index = [10; 20; 30];

            % WHEN deep-copying without the resetIndex keyword arg
            % THEN
            New = Original.deepcopy();
            Obj.verifyEqual(New.index, Original.index);

            % WHEN deep-copying with the resetIndex keyword arg set to TRUE
            % THEN
            New = Original.deepcopy(resetIndex = true);
            Obj.verifyEqual(New.index, [1; 2; 3]);

            % WHEN deep-copying with the resetIndex keyword arg set to FALSE
            % THEN
            New = Original.deepcopy(resetIndex = false);
            Obj.verifyEqual(New.index, Original.index);
        end

        function deepcopy__bad_indices(Obj)
            % GIVEN a dummy design space with 10 design points
            Original = Obj.setup_dummy_object(10);

            % WHEN deep-copying some points of the design space, with "bad" indices
            % THEN
            Obj.assertError(@() Original.deepcopy([1, 2, 3.4]), 'MATLAB:expectedInteger');
            Obj.assertError(@() Original.deepcopy([]), 'MATLAB:expectedVector');
            Obj.assertError(@() Original.deepcopy([1, -1]), 'DesignSpace:IndexOutOfBounds');
            Obj.assertError(@() Original.deepcopy([1, 20, 30]), 'DesignSpace:IndexOutOfBounds');
            Obj.assertError(@() Original.deepcopy(11), 'DesignSpace:IndexOutOfBounds');
        end

        function reset_index__happy(Obj)
            % GIVEN
            Space = usain.space.DesignSpace();
            Space.index = [1; 11; 12; 13];
            Space.thickness = [1; 2; 3; 4];  % for getter nPoints

            % WHEN, THEN
            Space.reset_index();
            Obj.verifyEqual(Space.index, [1; 2; 3; 4]);
        end

    end

    methods (Test, TestTags = {'integration'})

        function from_inputs__happy(Obj)
            % GIVEN
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            bMin = [0.1350, 0.1350];

            % WHEN
            actual = usain.space.DesignSpace.from_inputs(Inputs, bMin);

            % THEN
            Obj.assertClass(actual, 'usain.space.DesignSpace');
            Obj.assertNotEmpty(actual.thickness);
            Obj.assertNotEmpty(actual.width);
            Obj.assertNotEmpty(actual.nBolts);
            Obj.assertNotEmpty(actual.boltId);
            Obj.assertNotEmpty(actual.index);
            Obj.assertEqual(size(actual.thickness), size(actual.width));
            Obj.assertEqual(size(actual.thickness), size(actual.nBolts));
            Obj.assertEqual(size(actual.thickness), size(actual.boltId));
            Obj.assertEqual(size(actual.thickness), size(actual.index));
        end

        function from_inputs__post_mesh_large_width_to_thickness_ratio(Obj)
            % GIVEN inputs and ensuring that post_mesh will be run and impact the design space
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.DO_TRIM_DESIGN_SPACE = true;
            maxWidthThicknessRatio = usain.space.FlangeWidth.max_width_to_thickness_ratio(Inputs.flangeType);
            Inputs.maxFlangeThickn = Inputs.maxFlangeWidth ./ (1.1 * maxWidthThicknessRatio);
            bMin = [0.1350, 0.1350];

            % WHEN
            actual = usain.space.DesignSpace.from_inputs(Inputs, bMin);

            % THEN expect that for all points: width / thickness <= maxWidthThicknessRatio
            Obj.assertLessThanOrEqual(actual.width ./ actual.thickness, ...
                maxWidthThicknessRatio + 1e-6);

            % WHEN setting DO_TRIM_DESIGN_SPACE to false such that post_mesh is not called
            Inputs.DO_TRIM_DESIGN_SPACE = false;
            actual = usain.space.DesignSpace.from_inputs(Inputs, bMin);

            % THEN expect that some points have width / thickness > maxWidthThicknessRatio
            Obj.assertTrue(any(actual.width ./ actual.thickness > maxWidthThicknessRatio));
        end

        function from_inputs__post_mesh_small_width_to_thickness_ratio(Obj)
            % GIVEN inputs and ensuring that post_mesh will be run and impact the design space
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.DO_TRIM_DESIGN_SPACE = true;
            minWidthThicknessRatio = usain.space.FlangeWidth.min_width_to_thickness_ratio(Inputs.flangeType);
            Inputs.maxFlangeThickn = Inputs.maxFlangeWidth ./ (0.9 * minWidthThicknessRatio);
            bMin = [0.1350, 0.1350];

            % WHEN
            actual = usain.space.DesignSpace.from_inputs(Inputs, bMin);

            % THEN expect that for all points: width / thickness >= minWidthThicknessRatio
            Obj.assertGreaterThanOrEqual(actual.width ./ actual.thickness, ...
                minWidthThicknessRatio - 1e-6);

            % WHEN setting DO_TRIM_DESIGN_SPACE to false such that post_mesh is not called
            Inputs.DO_TRIM_DESIGN_SPACE = false;
            actual = usain.space.DesignSpace.from_inputs(Inputs, bMin);

            % THEN expect that some points have width / thickness < minWidthThicknessRatio
            Obj.assertTrue(any(actual.width ./ actual.thickness < minWidthThicknessRatio));
        end

        function remove_infeasible_number_of_bolts__happy(Obj)
            % GIVEN fixture inputs and explicitely set a few inputs necessary for this test
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 4)).data;
            Inputs.flangeType = usain.inputs.FlangeType.T;
            Inputs.diameterReference = 'outermost';
            Inputs.diamBoltCircle = nan;

            % ALSO GIVEN a simple ficticious DesignSpace
            Space = usain.space.DesignSpace();
            nDesignPoints = 4;
            Space.thickness = 0.100 * ones(nDesignPoints, 1);
            Space.width = [1; 1; 5; 5] .* Space.thickness;
            Space.nBolts = 240 * ones(nDesignPoints, 1);
            Space.boltId = ones(nDesignPoints, 1);
            Space.index = (1:nDesignPoints)';

            bMin = 0.135;

            % WHEN all design points have a feasible number of bolts, THEN
            NewSpace = Space.remove_infeasible_number_of_bolts(Inputs, bMin);
            Obj.assertEqual(Space, NewSpace);

            % NEXT WHEN enforcing an infeasible number of bolts for two design points
            Space.nBolts(1) = 10;
            Space.nBolts(4) = 100000;
            NewSpace = Space.remove_infeasible_number_of_bolts(Inputs, bMin);
            Obj.assertEqual(NewSpace.nPoints, 2);
        end

    end

end
