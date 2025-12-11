classdef CostModel_Test < Unittest.TestCase & matlab.mock.TestCase

    methods (Test, TestTags = {'unit'})

        function calc_total_cost__happy(Obj)
            % GIVEN a CostModel
            Cost = usain.model.CostModel();
            Cost.costFactor = 1.1;
            Cost.totalMass = 1000;

            % WHEN, THEN
            actual = Cost.calc_cost();
            Obj.verifyEqual(actual, 1100);
        end

        function from_flange_model__happy(Obj)
            % GIVEN a FlangeModel with minimal required data
            FlangeModel = UsainUtils.SelectedModel();

            FlangeModel.flangeType = 'L';
            FlangeModel.diameterOutNeck = 6;
            FlangeModel.Space.thickness = 100e-3;
            FlangeModel.Space.width = 250e-3;
            FlangeModel.Space.nBolts = 136;
            FlangeModel.Inputs.heightNoseUp = 40e-3;
            FlangeModel.Inputs.heightNoseLo = 40e-3;
            FlangeModel.Inputs.thicknNoseUp = 50e-3;
            FlangeModel.Inputs.thicknNoseLo = 50e-3;
            FlangeModel.Inputs.ALW_UPPER_FLANGE_THICKNESS = 2e-3;
            FlangeModel.Inputs.ALW_LOWER_FLANGE_THICKNESS = 2e-3;
            FlangeModel.Inputs.RHO_FLANGE = 7850;

            FlangeModel.Inputs.diamBoltHole = 46e-3;
            FlangeModel.Bolt.label = {'HV_M42'};
            FlangeModel.Bolt.type = {'hex'};
            FlangeModel.Bolt.diam = 42e-3;
            FlangeModel.Bolt.len = 0.260;
            FlangeModel.Bolt.pitchDiameter = 0.0045;
            FlangeModel.Extr.diamOut = 0.080;
            FlangeModel.Extr.diamIn = 0.044;
            FlangeModel.Extr.len = 0;
            FlangeModel.Wash.mass = 0.2072;
            FlangeModel.Nut.mass = 0.810;

            % WHEN, THEN
            Actual = usain.model.CostModel.from_flange_model(FlangeModel);
            Obj.assertInstanceOf(Actual, 'usain.model.CostModel');
        end

        function from_flange_model_impact_of_cost_factor__happy(Obj)
            % GIVEN a FlangeModel with minimal required data
            FlangeModel = UsainUtils.SelectedModel();

            FlangeModel.flangeType = 'L';
            FlangeModel.diameterOutNeck = 4.2721;
            FlangeModel.Space.thickness = 1e-3 * [97; 88; 80];
            FlangeModel.Space.width = 1e-3 * [239; 203; 180];
            FlangeModel.Space.nBolts = [136; 118; 118];
            FlangeModel.Inputs.heightNoseUp = 34e-3;
            FlangeModel.Inputs.heightNoseLo = 340e-3;
            FlangeModel.Inputs.thicknNoseUp = 22.1e-3;
            FlangeModel.Inputs.thicknNoseLo = 22.1e-3;
            FlangeModel.Inputs.ALW_UPPER_FLANGE_THICKNESS = 2e-3;
            FlangeModel.Inputs.ALW_LOWER_FLANGE_THICKNESS = 2e-3;
            FlangeModel.Inputs.RHO_FLANGE = 7850;

            FlangeModel.Bolt.label = {'HV_M42'; 'HV_M48'; 'HV_M56'};
            FlangeModel.Bolt.diam = 1e-3 * [42; 48; 56];
            FlangeModel.Bolt.len = [0.260; 0.250; 0.270];
            FlangeModel.Bolt.type = {'hex', 'hex', 'hex'};
            FlangeModel.Bolt.pitchDiameter = [0.0045 0.0045 0.0045];
            FlangeModel.diameterBoltHole = 1e-3 * [46; 52; 61];
            FlangeModel.Extr.diamOut = [0.080; 0.095; 0.110];
            FlangeModel.Extr.diamIn = [0.044; 0.050; 0.059];
            FlangeModel.Extr.len = [0; 0; 0.024];
            FlangeModel.Wash.mass = [0.2072; 0.2971; 0.4723];
            FlangeModel.Nut.mass = [0.810; 1.180; 1.720];

            % WHEN
            CostModel = usain.model.CostModel.from_flange_model(FlangeModel);
            actualCost = CostModel.calc_cost();

            % THEN expect that the total mass of the M56 is lowest but the cost of M48 is lowest.
            Obj.verifyEqual(CostModel.totalMass(3), min(CostModel.totalMass));
            Obj.verifyEqual(actualCost(2), min(actualCost));
        end

        function fastener_size_penalty__happy(Obj)
            % GIVEN common fastener sizes
            fastenerSizes = 1e-3 .* [36; 42; 48; 56; 64; 72; 80; 90; 100];

            % WHEN
            CostModel = usain.model.CostModel();
            actual = CostModel.fastener_size_penalty(fastenerSizes);

            % THEN
            expected = [1.00000; 1.04200; 1.08400; 1.14000; 1.19600; 1.52041; 1.93282; 2.60904; 3.52184];
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-5);
        end

    end

end
