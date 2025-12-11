classdef FlangeWidth_Test < Unittest.TestCase

    properties (TestParameter)
        nDesignPoints = {1, 4}  % For testing scalar and array operations
    end

    methods (Test, TestTags = {'unit'})

        function calc_max_flange_width__happy(Obj)
            % GIVEN, WHEN, THEN
            Inputs.flangeType = 'L';
            Width = usain.space.FlangeWidth();
            Obj.verifyNumElements(Width.calc_max_flange_width(Inputs, 0.100), 1);
            Obj.verifyNumElements(Width.calc_max_flange_width(Inputs, [0.100, 0.200]), 2);
            Obj.verifyEqual(Width.calc_max_flange_width(Inputs, 0.123), 0.369, 'AbsTol', 1e-4);

            % WHEN we have a T-flange
            % THEN
            Inputs.flangeType = 'T';
            Obj.verifyEqual(Width.calc_max_flange_width(Inputs, 0.123), 0.492, 'AbsTol', 1e-4);
        end

        function calc_min_flange_width__happy(Obj)
            % GIVEN
            InputsSingle = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            InputsMulti = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            maxWidth = 0.500;
            bMin = nan;

            % WHEN, THEN
            Width = usain.space.FlangeWidth();
            Obj.verifyNumElements(Width.calc_min_flange_width(InputsSingle, maxWidth, bMin), 1);
            Obj.verifyNumElements(Width.calc_min_flange_width(InputsMulti, [maxWidth, maxWidth], [bMin, bMin]), 2);
            Obj.verifyEqual(Width.calc_min_flange_width(InputsSingle, maxWidth, bMin), 0.3387, 'AbsTol', 1e-4);
            Obj.verifyEqual(Width.calc_min_flange_width(InputsMulti, [maxWidth, maxWidth], [bMin, bMin]), ...
                [0.3387, 0.3387], 'AbsTol', 1e-4);
        end

        function calc_min_flange_width__tflange(Obj)
            % GIVEN inputs for an L-flange, and correspondingly the minimum L-flange width
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            maxWidth = 1;
            bMin = nan;
            minLFlangeWidth = usain.space.FlangeWidth().calc_min_flange_width(Inputs, maxWidth, bMin);

            % WHEN changing the inputs to describe a T-flange
            Inputs.flangeType = 'T';

            % THEN expect a different minimum flange width
            minTFlangeWidth = usain.space.FlangeWidth().calc_min_flange_width(Inputs, maxWidth, bMin);
            Obj.verifyNotEqual(minLFlangeWidth, minTFlangeWidth);
            Obj.verifyLessThan(minLFlangeWidth, minTFlangeWidth);
        end

        function min_width_to_thickness_ratio__happy(Obj)
            % GIVEN, WHEN, THEN
            L = usain.inputs.FlangeType.L;
            T = usain.inputs.FlangeType.T;
            Obj.verifyEqual(usain.space.FlangeWidth.min_width_to_thickness_ratio(L), 1.2);
            Obj.verifyEqual(usain.space.FlangeWidth.min_width_to_thickness_ratio(T), 2.0);

            % WHEN inputting a string
            % THEN expect the method to work as well
            usain.space.FlangeWidth.min_width_to_thickness_ratio('L');
            usain.space.FlangeWidth.min_width_to_thickness_ratio('T');
        end

        function max_width_to_thickness_ratio__happy(Obj)
            % GIVEN, WHEN, THEN
            L = usain.inputs.FlangeType.L;
            T = usain.inputs.FlangeType.T;
            Obj.verifyEqual(usain.space.FlangeWidth.max_width_to_thickness_ratio(L), 3.0);
            Obj.verifyEqual(usain.space.FlangeWidth.max_width_to_thickness_ratio(T), 4.0);

            % WHEN inputting a string
            % THEN expect the method to work as well
            usain.space.FlangeWidth.max_width_to_thickness_ratio('L');
            usain.space.FlangeWidth.max_width_to_thickness_ratio('T');
        end

        function calc_diameter_outer_most__scalar_and_row_vector__happy(Obj)
            % GIVEN Scalar diameter and a row vector width
            diameter = 7;
            diameterReference = 'outneck';
            width = 0:10e-3:200e-3;
            thicknNoseUp = 50e-3;
            L = usain.inputs.FlangeType.L;
            T = usain.inputs.FlangeType.T;

            % WHEN
            actualL = usain.space.FlangeWidth.calc_diameter_outer_most(diameter, diameterReference, width, ...
                thicknNoseUp, L);
            actualT = usain.space.FlangeWidth.calc_diameter_outer_most(diameter, diameterReference, width, ...
                thicknNoseUp, T);

            % THEN
            Obj.verifySize(actualL, size(width));
            Obj.verifySize(actualT, size(width));
            Obj.verifyTrue(all(actualL == diameter));
            Obj.verifyEqual(min(actualT), 6.95); % This is the diameter at the middle of the upper flange nose
            Obj.verifyEqual(min(actualT), actualT(1));
            Obj.verifyEqual(max(actualT), 7.15);
            Obj.verifyEqual(max(actualT), actualT(end));
        end

        function calc_diameter_outer_most__vector_inputs__happy(Obj)
            % GIVEN vectors for diameter and width
            diameter = 7 * ones(1, 21); % same size as width
            diameterReference = 'outneck';
            width = 0:10e-3:200e-3;
            thicknNoseUp = 50e-3;
            L = usain.inputs.FlangeType.L;
            T = usain.inputs.FlangeType.T;

            % WHEN
            actualL = usain.space.FlangeWidth.calc_diameter_outer_most(diameter, diameterReference, width, ...
                thicknNoseUp, L);
            actualT = usain.space.FlangeWidth.calc_diameter_outer_most(diameter, diameterReference, width, ...
                thicknNoseUp, T);

            % THEN
            Obj.verifySize(actualL, size(width));
            Obj.verifySize(actualT, size(width));
            Obj.verifyTrue(all(actualL == diameter));
            Obj.verifyEqual(min(actualT), 6.95); % This is the diameter at the middle of the upper flange nose
            Obj.verifyEqual(min(actualT), actualT(1));
            Obj.verifyEqual(max(actualT), 7.15);
            Obj.verifyEqual(max(actualT), actualT(end));
        end

        function calc_diameter_outer_most__vector_inputs__sad(Obj)
            % GIVEN column vector for diameter and row vector for width
            diameter = 7 * ones(21, 1);
            diameterReference = 'outneck';
            width = 0:10e-3:200e-3;
            thicknNoseUp = 50e-3;
            L = usain.inputs.FlangeType.L;

            % WHEN, THEN
            f = @() usain.space.FlangeWidth.calc_diameter_outer_most(diameter, diameterReference, width, ...
                thicknNoseUp, L);
            Obj.assertError(f, 'FlangeWidth:InconsistentInputSize');
        end

        function calc_diameter_outer_most__reference_outer_most__happy(Obj)
            % GIVEN inputs and diameter reference "outermost"
            % Note: test for reference outneck is already covered in the test:
            % `calc_diameter_outer_most__scalar_and_row_vector__happy`
            diameter = 7;
            diameterReference = 'outermost';
            width = [0:10e-3:200e-3]';
            thicknNoseUp = 50e-3;
            L = usain.inputs.FlangeType.L;
            T = usain.inputs.FlangeType.T;

            % WHEN
            actualL = usain.space.FlangeWidth.calc_diameter_outer_most(diameter, diameterReference, width, ...
                thicknNoseUp, L);
            actualT = usain.space.FlangeWidth.calc_diameter_outer_most(diameter, diameterReference, width, ...
                thicknNoseUp, T);

            % THEN
            Obj.verifyEqual(actualL, actualT);
            Obj.verifySize(actualL, size(width));
            Obj.verifyTrue(all(actualT == diameter));

            % NEXT GIVEN vector input
            diameter = 7 * ones(21, 1);

            % WHEN
            actualL = usain.space.FlangeWidth.calc_diameter_outer_most(diameter, diameterReference, width, ...
                thicknNoseUp, L);
            actualT = usain.space.FlangeWidth.calc_diameter_outer_most(diameter, diameterReference, width, ...
                thicknNoseUp, T);

            % THEN
            Obj.verifyEqual(actualL, actualT);
            Obj.verifySize(actualL, size(width));
            Obj.verifyTrue(all(actualT == diameter));
        end

        function calc_diameter_out_neck__scalar_and_row_vector__happy(Obj)
            % GIVEN
            diameter = 7;
            diameterReference = 'outneck';
            width = [0:10e-3:200e-3]';
            thicknNoseUp = 50e-3;
            L = usain.inputs.FlangeType.L;
            T = usain.inputs.FlangeType.T;

            % WHEN
            actualL = usain.space.FlangeWidth.calc_diameter_out_neck(diameter, diameterReference, width, ...
                thicknNoseUp, L);
            actualT = usain.space.FlangeWidth.calc_diameter_out_neck(diameter, diameterReference, width, ...
                thicknNoseUp, T);

            % THEN
            Obj.verifyEqual(actualL, actualT);
            Obj.verifySize(actualL, size(width));
            Obj.verifyTrue(all(actualT == diameter));
        end

        function calc_diameter_out_neck__vector_inputs__happy(Obj)
            % GIVEN
            diameter = 7 * ones(21, 1);
            diameterReference = 'outneck';
            width = [0:10e-3:200e-3]';
            thicknNoseUp = 50e-3;
            L = usain.inputs.FlangeType.L;
            T = usain.inputs.FlangeType.T;

            % WHEN
            actualL = usain.space.FlangeWidth.calc_diameter_out_neck(diameter, diameterReference, width, ...
                thicknNoseUp, L);
            actualT = usain.space.FlangeWidth.calc_diameter_out_neck(diameter, diameterReference, width, ...
                thicknNoseUp, T);

            % THEN
            Obj.verifyEqual(actualL, actualT);
            Obj.verifySize(actualL, size(width));
            Obj.verifyTrue(all(actualT == diameter));
        end

        function calc_diameter_out_neck__vector_inputs__sad(Obj)
            % GIVEN
            diameter = 7 * ones(21, 1);
            diameterReference = 'outneck';
            width = 0:10e-3:200e-3;
            thicknNoseUp = 50e-3;
            L = usain.inputs.FlangeType.L;

            % WHEN
            f = @() usain.space.FlangeWidth.calc_diameter_out_neck(diameter, diameterReference, width, ...
                thicknNoseUp, L);
            Obj.assertError(f, 'FlangeWidth:InconsistentInputSize');
        end

        function calc_diameter_out_neck__reference_outer_most__happy(Obj)
            % GIVEN
            diameter = 7;
            diameterReference = 'outermost';

            width = [0:10e-3:200e-3]';
            thicknNoseUp = 50e-3;
            L = usain.inputs.FlangeType.L;
            T = usain.inputs.FlangeType.T;

            % WHEN
            actualL = usain.space.FlangeWidth.calc_diameter_out_neck(diameter, diameterReference, width, ...
                thicknNoseUp, L);
            actualT = usain.space.FlangeWidth.calc_diameter_out_neck(diameter, diameterReference, width, ...
                thicknNoseUp, T);

            % THEN
            Obj.verifySize(actualL, size(width));
            Obj.verifySize(actualT, size(width));
            Obj.verifyTrue(all(actualL == diameter));
            Obj.verifyEqual(min(actualT), 6.85);
            Obj.verifyEqual(min(actualT), actualT(end));
            Obj.verifyEqual(max(actualT), 7.05); % Note physically not possible, since width = 0. Will be filtered later
            Obj.verifyEqual(max(actualT), actualT(1));
        end

        function calc_diameter_out_neck__reference_out_neck__happy(Obj)
            % GIVEN
            diameter = 7;
            diameterReference = 'outneck';
            width = [0:10e-3:200e-3]';
            thicknNoseUp = 50e-3;
            L = usain.inputs.FlangeType.L;
            T = usain.inputs.FlangeType.T;

            % WHEN
            actualL = usain.space.FlangeWidth.calc_diameter_out_neck(diameter, diameterReference, width, ...
                thicknNoseUp, L);
            actualT = usain.space.FlangeWidth.calc_diameter_out_neck(diameter, diameterReference, width, ...
                thicknNoseUp, T);

            % THEN
            Obj.verifyEqual(actualL, actualT);
            Obj.verifySize(actualL, size(width));
            Obj.verifyTrue(all(actualT == diameter));
        end

        function calc_bolt_circle_diameter__happy(Obj)
            % GIVEN some geometry description and no user defined input for the bolt circle diameter
            inputBoltCircleDiameter = nan;
            diameterOutNeck = 7 * ones(100, 1);
            thicknNoseUp = 50e-3;
            bMin = 100e-3;

            % WHEN THEN
            actual = usain.space.FlangeWidth.calc_bolt_circle_diameter(inputBoltCircleDiameter, diameterOutNeck, ...
                thicknNoseUp, bMin);
            Obj.verifySize(actual, size(diameterOutNeck));
            Obj.verifyTrue(all(actual == 6.75));

            % NEXT GIVEN a user defined input for the bolt circle diameter
            inputBoltCircleDiameter = 6.5;

            % WHEN THEN
            actual = usain.space.FlangeWidth.calc_bolt_circle_diameter(inputBoltCircleDiameter, diameterOutNeck, ...
                thicknNoseUp, bMin);
            Obj.verifySize(actual, size(diameterOutNeck));
            Obj.verifyTrue(all(actual == 6.5));

            % NEXT GIVEN a user defined vector input for the bolt circle diameter
            inputBoltCircleDiameter = 6.5 * ones(100, 1);

            % WHEN THEN
            actual = usain.space.FlangeWidth.calc_bolt_circle_diameter(inputBoltCircleDiameter, diameterOutNeck, ...
                thicknNoseUp, bMin);
            Obj.verifySize(actual, size(diameterOutNeck));
            Obj.verifyTrue(all(actual == 6.5));
        end

        function calc_bolt_circle_diameter__sad(Obj)
            % GIVEN inputs and inconsistent input size for boltCircleDiameter
            inputBoltCircleDiameter = 6 * ones(1, 100);
            diameterOutNeck = 7 * ones(100, 1);
            thicknNoseUp = 50e-3;
            bMin = 100e-3;

            % WHEN THEN
            f = @() usain.space.FlangeWidth.calc_bolt_circle_diameter(inputBoltCircleDiameter, diameterOutNeck, ...
                thicknNoseUp, bMin);
            Obj.assertError(f, 'FlangeWidth:InconsistentInputSize');

            % NEXT GIVEN inputs and inconsistent input size for bMin
            inputBoltCircleDiameter = 6;
            diameterOutNeck = 7 * ones(100, 1);
            thicknNoseUp = 50e-3;
            bMin = 100e-3 * ones(2, 1);

            % WHEN THEN
            f = @() usain.space.FlangeWidth.calc_bolt_circle_diameter(inputBoltCircleDiameter, diameterOutNeck, ...
                thicknNoseUp, bMin);
            Obj.assertError(f, 'FlangeWidth:InconsistentInputSize');
        end

        function check_a_b_ratio__happy(Obj)
            % GIVEN
            b = ones(10, 1);
            a = 10 * b;
            L = usain.inputs.FlangeType.L;
            T = usain.inputs.FlangeType.T;

            % WHEN
            Width = usain.space.FlangeWidth();
            actualL = Width.check_a_b_ratio(a, b, L);
            actualT = Width.check_a_b_ratio(a, b, T);

            % THEN
            Obj.verifyTrue(all(actualL));
            Obj.verifySize(actualL, size(a));
            Obj.verifyTrue(actualT);
            Obj.verifySize(actualT, [1, 1]);

            % NEXT GIVEN same inputs but changing 1 value in a
            a(1) = 1;

            % WHEN
            Width = usain.space.FlangeWidth();
            actualL = Width.check_a_b_ratio(a, b, L);
            actualT = Width.check_a_b_ratio(a, b, T);

            % THEN
            Obj.verifyFalse(actualL(1));
            Obj.verifyTrue(all(actualL(2:end)));
            Obj.verifySize(actualL, size(a));
            Obj.verifyTrue(actualT);
        end

        function check_bolt_edge_distance__happy(Obj)
            % GIVEN
            boltHoleDiameter = 61;
            a = 100:200; % clear sufficient distance to the edge.

            % WHEN THEN
            Width = usain.space.FlangeWidth();
            actual = Width.check_bolt_edge_distance(boltHoleDiameter, a);
            Obj.verifySize(actual, size(a));
            Obj.verifyTrue(all(actual));

            % NEXT GIVEN
            a = 1:62; % clearly not sufficient distance to edge
            Width = usain.space.FlangeWidth();
            actual = Width.check_bolt_edge_distance(boltHoleDiameter, a);
            Obj.verifyFalse(any(actual));
        end

        function check_secondary_holes_edge_distance__happy(Obj)
            % GIVEN not using secondary holes, hence inputs are nan
            secondaryHoleDiameter = nan;
            secondaryHolesBoltCircleDiameter = nan;
            diameterIn = 7 * ones(100, 1);

            % WHEN THEN
            Width = usain.space.FlangeWidth();
            actual = Width.check_secondary_holes_edge_distance(secondaryHoleDiameter, ...
                secondaryHolesBoltCircleDiameter, diameterIn);
            Obj.verifyTrue(actual);

            % NEXT GIVEN secondary holes to be used; with large distance to inner diameter of the flange
            secondaryHoleDiameter = 20e-3;
            secondaryHolesBoltCircleDiameter = 7.5;

            % WHEN THEN
            Width = usain.space.FlangeWidth();
            actual = Width.check_secondary_holes_edge_distance(secondaryHoleDiameter, ...
                secondaryHolesBoltCircleDiameter, diameterIn);
            Obj.verifyTrue(all(actual));

            % NEXT GIVEN 3 different inner diameters; 2 are obviously not suitable to allow the secondary holes
            diameterIn = [7, 7.5, 8];

            % WHEN THEN
            Width = usain.space.FlangeWidth();
            actual = Width.check_secondary_holes_edge_distance(secondaryHoleDiameter, ...
                secondaryHolesBoltCircleDiameter, diameterIn);
            Obj.verifyTrue(actual(1));
            Obj.verifyFalse(any(actual(2:end)));
        end

    end

    methods (Test, TestTags = {'integration'})

        function from_inputs__happy(Obj, nDesignPoints)
            % GIVEN
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = nDesignPoints)).data;
            maxThickness = 0.123 * ones(1, length(Inputs.boltOptions));
            bMin = 0.123 * ones(1, length(Inputs.boltOptions));

            % WHEN
            actual = usain.space.FlangeWidth.from_inputs(Inputs, maxThickness, bMin);

            % THEN
            Obj.verifyInstanceOf(actual, 'design_space.DesignVariable');
            Obj.verifyClass(actual, 'usain.space.FlangeWidth');
            Obj.verifyNotEmpty(actual.InputBounds);
            Obj.verifyNotEmpty(actual.CalculatedBounds);
            Obj.verifyNotEmpty(actual.stepSize);
        end

    end

end
