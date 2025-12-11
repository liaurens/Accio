classdef PostLoadManipulations_Test < UsainTest.UsainTestCase

    methods (Test, TestTags = {'unit'})

        function set_flange_element_index__happy(Obj)
            % GIVEN a StructuralModel and z-level for intermediate flange connection
            Inputs.StrMdl = Obj.setup_test_structural_model();
            Inputs.zFlange = -37.18;

            % WHEN
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.set_flange_element_index();

            % THEN
            expected = [6; 7];
            Obj.verifyEqual(Manipulator.iElem, expected);

            % NEXT GIVEN z-level for interface flange connection
            Inputs.zFlange = -17.3;

            % WHEN
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.set_flange_element_index();

            % THEN
            expected = 11;
            Obj.verifyEqual(Manipulator.iElem, expected);
        end

        function set_diameter__happy(Obj)
            % GIVEN user provided input and no StructuralModel
            Inputs.diameter = 1234;

            % WHEN
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.set_diameter();

            % THEN
            Obj.verifyEqual(Manipulator.Inputs.diameter, Inputs.diameter);

            % NEXT GIVEN user input and a StructuralModel
            Inputs.StrMdl = Obj.setup_test_structural_model();

            % WHEN
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.iElem = [6; 7];
            Manipulator.set_diameter();

            % THEN expect user input to be goverining
            Obj.verifyEqual(Manipulator.Inputs.diameter, Inputs.diameter);

            % NEXT GIVEN no user input with a StructuralModel
            Inputs.diameter = nan;

            % WHEN
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.iElem = [6; 7];
            Manipulator.set_diameter();

            % THEN
            expected = 7;
            Obj.verifyEqual(Manipulator.Inputs.diameter, expected);
        end

        function set_flange_type__happy(Obj)
            % GIVEN user input and no StructuralModel
            Inputs.flangeType = 'T';

            % WHEN
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.set_flange_type();

            % THEN
            Obj.verifyEqual(Manipulator.Inputs.flangeType, 'T');

            % NEXT GIVEN user input and a StructuralModel
            Inputs.StrMdl = Obj.setup_test_structural_model();

            % WHEN
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.iElem = [6; 7];
            Manipulator.set_flange_type();

            % THEN
            Obj.verifyEqual(Manipulator.Inputs.flangeType, 'T');

            % NEXT GIVEN no user input and a StructuralModel
            Inputs.flangeType = '';
            Inputs.StrMdl = Obj.setup_test_structural_model();

            % WHEN
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.iElem = [6; 7];
            Manipulator.set_flange_type();

            % THEN
            Obj.verifyEqual(Manipulator.Inputs.flangeType, 'L');
        end

        function set_nose_thickness__happy(Obj)
            % GIVEN user input for the thickness of the nose on both sides of the connection
            Inputs.thicknNoseUp = 12;
            Inputs.thicknNoseLo = 34;

            % WHEN
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.iElem = [6; 7];
            Manipulator.set_nose_thickness();

            % THEN
            Obj.verifyEqual(Manipulator.Inputs.thicknNoseUp, Inputs.thicknNoseUp);
            Obj.verifyEqual(Manipulator.Inputs.thicknNoseLo, Inputs.thicknNoseLo);

            % NEXT GIVEN only one side (thisSide) gets a user input value and a StructuralModel
            Inputs.StrMdl = Obj.setup_test_structural_model();
            rng("shuffle"); % To ensure `randi` will actually be random
            thisSide = iif(randi([0 1]) == 1, 'Up', 'Lo');
            otherSide = iif(thisSide == "Up", 'Lo', 'Up');
            thisSideName = sprintf('thicknNose%s', thisSide);
            otherSideName = sprintf('thicknNose%s', otherSide);
            Inputs.(otherSideName) = nan;

            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.iElem = [6; 7];
            Manipulator.set_nose_thickness();

            % THEN
            expectedOtherSideThickness = 0.060; % equal thickness for both sides in StructuralModel
            Obj.verifyEqual(Manipulator.Inputs.(thisSideName), Inputs.(thisSideName));
            Obj.verifyEqual(Manipulator.Inputs.(otherSideName), expectedOtherSideThickness);

            % NEXT GIVEN no user input, a StructuralModel and ensure it's the interface flange connection
            Inputs.thicknNoseUp = nan;
            Inputs.thicknNoseLo = nan;

            % WHEN
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.iElem = 11; % Interface flange has only 1 element.
            Manipulator.set_nose_thickness();

            % THEN
            expected = 0.070;
            Obj.verifyEqual(Manipulator.Inputs.thicknNoseUp, expected);
            Obj.verifyEqual(Manipulator.Inputs.thicknNoseLo, expected);
        end

    end

    methods

        function StrMdl = setup_test_structural_model(~)
            StructuralModelPath = pathlib.Path(fileparts(mfilename('fullpath'))) / '..' / '..' / '+io' / '+test' / ...
                'data' / 'simple_structural_model.mat';
            Inputs.structureInpFilePath = char(StructuralModelPath.resolve());
            StrMdl = StructuralModel(char(Inputs.structureInpFilePath));
        end

    end

    methods (Test, TestTags = {'integration'})

        function set_inputs_from_structural_model__no_structural_model__happy(Obj)
            % GIVEN empty inputs struct and not providing a StructuralModel
            Inputs = struct();
            Inputs.structureInpFilePath = '';

            % WHEN
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.set_inputs_from_structural_model();

            % THEN
            Obj.verifyEqual(Manipulator.Inputs, Inputs);
        end

        function set_inputs_from_structural_model__happy(Obj)
            % GIVEN inputs struct where all data should be taken from StructuralModel and providing a StructuralModel
            Inputs.structureInpFilePath = 'somePath';
            Inputs.StrMdl = Obj.setup_test_structural_model();
            Inputs.zFlange = -37.18;
            Inputs.diameter = nan;
            Inputs.flangeType = '';
            Inputs.thicknNoseUp = nan;
            Inputs.thicknNoseLo = nan;

            % WHEN
            Manipulator = usain.inputs.PostLoadManipulations(Inputs = Inputs);
            Manipulator.set_inputs_from_structural_model();

            % THEN
            Obj.verifyEqual(Manipulator.iElem, [6; 7]);
            Obj.verifyEqual(Manipulator.Inputs.diameter, 7);
            Obj.verifyEqual(Manipulator.Inputs.flangeType, 'L');
            Obj.verifyEqual(Manipulator.Inputs.thicknNoseUp, 0.06);
            Obj.verifyEqual(Manipulator.Inputs.thicknNoseLo, 0.06);
        end

    end

end
