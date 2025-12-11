classdef EquivalentScfOutputStep_Test < Unittest.TestCase

    methods (Test, TestTags = {'integration'})

        function run__expected(Obj)
            % GIVEN a runner with a EquivalentScfOutputStep
            Step = usain.neck_scf.EquivalentScfOutputStep();
            Runner = runner.SequentialRunner().add(Step);

            % ... inputs required to run the step
            Inputs.zFlange = -37.1800;
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % ... StructuralModel data required to run the step
            StrMdl.Inp.Plate.Parsed.elemLabel = {'TW37', 'FL08', 'FL09', 'TW38'}';
            StrMdl.Inp.Plate.Parsed.zCoordTop = [-77.3600, -37.4980, -37.1800, -36.8620]';
            StrMdl.Inp.Plate.zCoordBot = [-37.4980, -37.1800, -36.8620, -29.9820]';
            StrMdl.Levels.zRange = [-77.3600, -29.9820];
            Runner.set(usain.DataKeys.StructuralModel, StrMdl);

            % ... a FlangeNeckScf condition with SCFs for 2 load sets
            Condition = UsainUtils.FlangeNeckScf();
            Condition.scfEqv = [ ...
                1.1, 1.2
                1.4, 1.3
                1.5, 1.6
                1.8, 1.7];
            Collection = usain.conditions.ConditionCollection();
            Collection.ConditionArray = {Condition};
            Runner.set(usain.DataKeys.SelectedConditionCollection, Collection);

            % WHEN
            Step.run();

            % THEN
            Actual = Runner.get(usain.DataKeys.FlangeNeckScfOutputData);
            Obj.verifyEqual(Actual.labels, ["FL08", "FL09"]);
            Obj.verifyEqual(Actual.bendingScfInside, [1.2, 1.4]);
            Obj.verifyEqual(Actual.bendingScfOutside, [1.6, 1.8]);
        end

    end

    methods (Test, TestTags = {'unit'})

        function is_active__active(Obj)
            % GIVEN a runner with a EquivalentScfOutputStep
            Step = usain.neck_scf.EquivalentScfOutputStep();
            Runner = runner.SequentialRunner().add(Step);

            % WHEN
            Inputs.structureInpFilePath = 'c:/foo';
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = true;
            Inputs.flangeType = 'L';
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % THEN
            Obj.verifyTrue(Step.is_active());
        end

        function is_active__inactive(Obj)
            % GIVEN a runner with a EquivalentScfOutputStep
            Step = usain.neck_scf.EquivalentScfOutputStep();
            Runner = runner.SequentialRunner().add(Step);

            % WHEN toggle is false and StructuralModel is provided
            Inputs.structureInpFilePath = 'c:/foo';
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = false;
            Inputs.flangeType = 'L';
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % THEN
            Obj.verifyFalse(Step.is_active());

            % WHEN toggle is true and StructuralModel is not provided
            Inputs.structureInpFilePath = '';
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = true;
            Inputs.flangeType = 'L';
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % THEN
            Obj.verifyFalse(Step.is_active());

            % WHEN toggle is true and StructuralModel is provided, but a T-flange is assessed
            Inputs.structureInpFilePath = 'c:/foo';
            Inputs.DO_ASSESS_FLANGE_NECK_SCF = true;
            Inputs.flangeType = 'T';
            Runner.set(usain.DataKeys.Inputs, Inputs);

            % THEN
            Obj.verifyFalse(Step.is_active());
        end

    end
end
