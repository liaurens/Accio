classdef UpdateStructuralModelStep_Test < UsainTest.UsainTestCase

    methods (TestClassSetup)

        function setup_dir(Obj)
            Obj.testDir = fileparts(mfilename('fullpath'));
        end

    end

    methods (Test, TestTags = {'integration'})

        function run__with_structural_model(Obj)
            % GIVEN a sequential runner with just the step for this test class and set inputs such that a
            % StructuralModel file can be updated
            Runner = runner.SequentialRunner().add( ...
                usain.io.UpdateStructuralModelStep() ...
                );

            TargetDir = pathlib.Path(Obj.testDir) / '_generated';
            StructuralModelPath = pathlib.Path(Obj.testDir) / 'data' / 'simple_structural_model.mat';

            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;
            Inputs.structureInpFilePath = char(StructuralModelPath);
            Inputs.zFlange = -17.3;  % corresponds to flange level in simple_structural_model.mat
            Inputs.targetDir = char(TargetDir);

            StructuralModelObj = StructuralModel(Inputs.structureInpFilePath);
            StructuralModelObj.Logger.level = logging.Level.WARNING;  % suppress StructuralModel INFO logs in tests

            SelectedModel.flangeType = 'L';
            SelectedModel.Space.thickness = 0.123;
            SelectedModel.massStubUp = 1234;
            SelectedModel.massStubLo = 1235;
            SelectedModel.massBoltAssm = 890;
            SelectedModel.Inputs.heightNoseUp = 0.04;
            SelectedModel.Inputs.heightNoseLo = 0.04;

            Runner.set(usain.DataKeys.Inputs, Inputs);
            Runner.set(usain.DataKeys.StructuralModel, StructuralModelObj);
            Runner.set(usain.DataKeys.SelectedModel, SelectedModel);

            % WHEN, THEN
            Obj.verify_error_free(@() Runner.run());
            Obj.verifyEmpty(Runner.SkippedSteps);
            Obj.verifyTrue(Runner.is_gettable(usain.DataKeys.StructuralModelOutputPath));
            Obj.verifyTrue(Runner.get(usain.DataKeys.StructuralModelOutputPath).is_file());
        end

        function run__no_structural_model(Obj)
            % GIVEN a sequential runner with just the step for this test class and set inputs such that no
            % StructuralModel file will be updated
            Runner = runner.SequentialRunner().add( ...
                usain.io.UpdateStructuralModelStep() ...
                );

            Runner.set(potato.DataKeys.Inputs, struct());
            Runner.set(potato.DataKeys.SelectedModel, struct());
            Runner.set(potato.DataKeys.StructuralModel, []);

            % WHEN, THEN expect the step to be skipped because there is no StructuralModel input
            Obj.verify_error_free(@() Runner.run());
            Obj.verifyNotEmpty(Runner.SkippedSteps);
            Obj.verifyFalse(Runner.is_gettable(potato.DataKeys.StructuralModelOutputPath));
        end

    end

    methods (Test, TestTags = {'unit'})

        function update_structural_model__happy(Obj)
            % GIVEN data to update StructuralModel
            structuralModelPath = char(pathlib.Path(Obj.testDir) / 'data' / 'simple_structural_model.mat');
            StructuralModelObj = StructuralModel(structuralModelPath);
            StructuralModelObj.Logger.level = logging.Level.WARNING;  % suppress StructuralModel INFO logs in tests

            SelectedModel.Space.thickness = 0.123;
            SelectedModel.massStubUp = 1234;
            SelectedModel.massStubLo = 1235;
            SelectedModel.massBoltAssm = 890;
            SelectedModel.Inputs.heightNoseUp = 0.056;
            SelectedModel.Inputs.heightNoseLo = 0.078;
            SelectedModel.flangeType = 'L';  % Note: in the provided StrMdl, the flange at -17.3 is a T-flange

            Inputs.diameterReference = 'outneck';
            Inputs.zFlange = -17.3;
            Inputs.ALW_UPPER_FLANGE_THICKNESS = 0.002;
            Inputs.ALW_LOWER_FLANGE_THICKNESS = 0.002;

            % WHEN
            Actual = usain.io.UpdateStructuralModelStep().update_structural_model( ...
                StructuralModelObj, SelectedModel, Inputs);
            Original = StructuralModel(structuralModelPath);
            % NOTE: Rebuild original StructuralModel because Actual and StructuralModelObj point to the same object

            % THEN expect that the Actual StructuralModel differs from the Original one
            Obj.verifyNotEqual(Actual.Inp.Plate.Parsed.elemLength, Original.Inp.Plate.Parsed.elemLength);
            Obj.verifyNotEqual(Actual.Inp.Plate.Parsed.zCoordTop, Original.Inp.Plate.Parsed.zCoordTop);
            % Field `mass` in `Inp.Elem.Parsed` is a cell arrays, hence the incomprehensible comparison below
            Obj.verifyNotEqual( ...
                cell2mat(Actual.Inp.Elem.Parsed.mass(Actual.Inp.Elem.isFlangeMass)), ...
                cell2mat(Original.Inp.Elem.Parsed.mass(Actual.Inp.Elem.isFlangeMass)));
            Obj.verifyNotEqual(Actual.Inp.Plate.Parsed.elemType, Original.Inp.Plate.Parsed.elemType);
        end

        function get_target_path_info__happy(Obj)
            % GIVEN
            TargetDir = pathlib.Path(Obj.testDir) / '_generated';

            Inputs.runName = 'foo';
            Inputs.targetDir = char(TargetDir);

            % WHEN
            [TargetFileDir, targetFileName] = usain.io.UpdateStructuralModelStep().get_target_path_info(Inputs);

            % THEN
            ExpectedTargetDir = pathlib.Path(TargetDir / 'StrucMod');
            expectedTargetFileName = 'InputTable_StrMdl_foo';

            Obj.verifyEqual(TargetFileDir, ExpectedTargetDir);
            Obj.verifyEqual(targetFileName, expectedTargetFileName);
        end

    end
end
