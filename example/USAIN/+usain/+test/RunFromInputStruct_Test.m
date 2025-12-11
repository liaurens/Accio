classdef (SharedTestFixtures = {Unittest.fixtures.SilentlyLogWarningsFixture}) ...
        RunFromInputStruct_Test < Unittest.TestCase
    methods (Test, TestTags = {'integration'})

        function calc_bmin_from_inputs__happy(Obj)
            % GIVEN happy case data (stolen from testcase03.inp)
            inputData = struct();
            inputData.boltOptions = {'ISO_M72', 'ISO_M64'};
            inputData.site = 'offshore';
            inputData.tighteningMethod = {'tension'};
            inputData.zFlange = 0;
            inputData.flangeType = 'L';

            inputData.diameter = 7000;
            inputData.diameterReference = 'outneck';
            inputData.diamBoltHole = 78;
            inputData.thicknNoseUp = 60;
            inputData.thicknNoseLo = 60;

            inputData.OptionalInputs.minFlangeWidth = 500;
            inputData.OptionalInputs.maxFlangeWidth = 500;
            inputData.OptionalInputs.minFlangeThickn = 240;
            inputData.OptionalInputs.maxFlangeThickn = 260;

            BMinInputs = usain.inputs.run_dataclass.InputsBMin(inputData);

            % WHEN
            bMin = USAIN.calc_bmin_from_inputs(BMinInputs);

            % THEN check that we get a (2 x 1) vector
            Obj.assertClass(bMin, ?double);
            Obj.assertTrue(all(size(bMin) == [2, 1]));
        end

    end

end
