classdef ResilienceModel_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function calc_resilience_hv_bolt__expected(Obj)
            % GIVEN, WHEN, THEN
            Fixture = Obj.applyFixture(usain.model.test.fixtures.ResilienceModelFixture('HV_single')).data;
            actual = Fixture.calc_resilience_hv_bolt();
            Obj.verifyEqual(actual, 5.2240e-7, 'RelTol', 1e-4);

            % WHEN we ignore the bolt extender
            Obj.assertFalse(Fixture.doIgnoreExtender);
            Obj.assertGreaterThan(Fixture.Extender.len, 0);
            Fixture.doIgnoreExtender = true;

            % THEN
            actualWithoutExtender = Fixture.calc_resilience_hv_bolt();
            Obj.verifyGreaterThan(actual, actualWithoutExtender);
            Obj.verifyEqual(actualWithoutExtender, 5.0760e-7, 'RelTol', 1e-4);
        end

        function calc_resilience_iso_stud__expected(Obj)
            % GIVEN, WHEN, THEN
            Fixture = Obj.applyFixture(usain.model.test.fixtures.ResilienceModelFixture('ISO_multi')).data;
            actual = Fixture.calc_resilience_iso_stud();
            Obj.verifyEqual(actual(1), 6.4568e-7, 'RelTol', 1e-4);
            Obj.verifyEqual(actual(2), 7.1069e-7, 'RelTol', 1e-4);

            % WHEN we ignore the bolt extender
            Obj.assertFalse(Fixture.doIgnoreExtender);
            Obj.assertGreaterThan(Fixture.Extender.len(1), 0);  % design point #2 has no extender, intentionally
            Fixture.doIgnoreExtender = true;

            % THEN we expect the resilience to change of design point #1, but not for #2 because it has no extender
            actualWithoutExtender = Fixture.calc_resilience_iso_stud();
            Obj.verifyGreaterThan(actual(1), actualWithoutExtender(1));
            Obj.verifyEqual(actualWithoutExtender(1), 6.1953e-7, 'RelTol', 1e-4);
            Obj.verifyEqual(actual(2), actualWithoutExtender(2));
        end

        function calc_resilience_washers__expected(Obj)
            % GIVEN, WHEN, THEN
            Fixture = Obj.applyFixture(usain.model.test.fixtures.ResilienceModelFixture('HV_single')).data;
            actual = Fixture.calc_resilience_washers();
            Obj.verifyEqual(actual, 1.3672e-08, 'RelTol', 1e-4);
        end

        function calc_resilience_washers__no_washer(Obj)
            % GIVEN, WHEN, THEN
            Fixture = Obj.applyFixture(usain.model.test.fixtures.ResilienceModelFixture('ISO_multi')).data;
            Fixture.Washer.len(2) = 0;
            actual = Fixture.calc_resilience_washers();
            Obj.verifyEqual(actual(2), 0);
        end

        function calc_resilience_extender__expected(Obj)
            % GIVEN, WHEN, THEN
            Fixture = Obj.applyFixture(usain.model.test.fixtures.ResilienceModelFixture('HV_single')).data;
            actual = Fixture.calc_resilience_extender();
            Obj.verifyEqual(actual, 6.1175e-09, 'RelTol', 1e-4);

            % WHEN we ignore the bolt extender
            Obj.assertFalse(Fixture.doIgnoreExtender);
            Obj.assertGreaterThan(Fixture.Extender.len, 0);
            Fixture.doIgnoreExtender = true;

            % THEN
            actualWithoutExtender = Fixture.calc_resilience_extender();
            Obj.verifyEqual(actualWithoutExtender, 0);
        end

        function calc_resilience_extender__no_extender(Obj)
            % GIVEN, WHEN, THEN
            Fixture = Obj.applyFixture(usain.model.test.fixtures.ResilienceModelFixture('ISO_multi')).data;
            Fixture.Extender.len(2) = 0;
            actual = Fixture.calc_resilience_extender();
            Obj.verifyEqual(actual(2), 0);
        end

        function calc_resilience_flanges__expected(Obj)
            % GIVEN, WHEN, THEN
            Fixture = Obj.applyFixture(usain.model.test.fixtures.ResilienceModelFixture('HV_single')).data;
            actual = Fixture.calc_resilience_flanges();
            Obj.verifyEqual(actual, 1.0090e-07, 'RelTol', 1e-4);
        end

        function calc_bending_resilience_fastener__expected(Obj)
            % GIVEN fixture data for 3 design points: 1 hex bolt and 2 studs, respectively
            Fixture = Obj.applyFixture(usain.model.test.fixtures.ResilienceModelFixture('mixed')).data;

            % WHEN
            actual = Fixture.calc_bending_resilience_fastener();
            actualBolt = Fixture.calc_bending_resilience_hv_bolt();
            actualStud = Fixture.calc_bending_resilience_iso_stud();

            % THEN
            Obj.verifyEqual(actual(1), actualBolt(1));
            Obj.verifyEqual(actual(2), actualStud(2));
            Obj.verifyEqual(actual(3), actualStud(3));
        end

        function calc_bending_resilience_hv_bolt__expected(Obj)
            % GIVEN, WHEN, THEN
            Fixture = Obj.applyFixture(usain.model.test.fixtures.ResilienceModelFixture('HV_single')).data;
            actual = Fixture.calc_bending_resilience_hv_bolt();
            Obj.verifyEqual(actual, 0.0019928, 'RelTol', 1e-4);

            % WHEN we ignore the bolt extender
            Obj.assertFalse(Fixture.doIgnoreExtender);
            Obj.assertGreaterThan(Fixture.Extender.len, 0);
            Fixture.doIgnoreExtender = true;

            % THEN
            actualWithoutExtender = Fixture.calc_bending_resilience_hv_bolt();
            Obj.verifyGreaterThan(actual, actualWithoutExtender);
            Obj.verifyEqual(actualWithoutExtender, 0.0019349, 'RelTol', 1e-4);
        end

        function calc_bending_resilience_iso_stud__expected(Obj)
            % GIVEN, WHEN, THEN
            Fixture = Obj.applyFixture(usain.model.test.fixtures.ResilienceModelFixture('ISO_multi')).data;
            actual = Fixture.calc_bending_resilience_iso_stud();
            Obj.verifyEqual(actual(1), 0.0023023, 'RelTol', 1e-4);
            Obj.verifyEqual(actual(2), 0.0025156, 'RelTol', 1e-4);

            % WHEN we ignore the bolt extender
            Obj.assertFalse(Fixture.doIgnoreExtender);
            Obj.assertGreaterThan(Fixture.Extender.len(1), 0);  % design point #2 has no extender, intentionally
            Fixture.doIgnoreExtender = true;

            % THEN we expect the resilience to change of design point #1, but not for #2 because it has no extender
            actualWithoutExtender = Fixture.calc_bending_resilience_iso_stud();
            Obj.verifyGreaterThan(actual(1), actualWithoutExtender(1));
            Obj.verifyEqual(actualWithoutExtender(1), 0.0022121, 'RelTol', 1e-4);
            Obj.verifyEqual(actual(2), actualWithoutExtender(2));
        end

    end

    methods (Test, TestTags = {'intergation'})

        function from_flange_model__happy(Obj)
            % GIVEN a FlangeModel with all data set required for setting up a ReslienceModel
            % TODO: Replace the code below by a proper fixture
            site = usain.inputs.Site.OFFSHORE;
            Assy = usain.fastener.CatalogLibrary.select_assemblies(site, 'ISO_M72', 'tension', 'ISR');
            Assy.Bolt.len = 0.650;
            Assy.Bolt.lenThread = Assy.Bolt.defaults.lengthThread;
            Assy.Extender.len = 0;
            FlangeModel = UsainUtils.FlangeModel();
            FlangeModel.Bolt = Assy.Bolt.to_struct_of_arrays();
            FlangeModel.Nut = Assy.Nut.to_struct_of_arrays();
            FlangeModel.Wash = Assy.Washer.to_struct_of_arrays();
            FlangeModel.Extr = Assy.Extender.to_struct_of_arrays();
            FlangeModel.Inputs.E_BOLT = 210e6;
            FlangeModel.Inputs.E_FLANGE = 210e6;
            FlangeModel.Inputs.IGNORE_BOLT_EXTENDER = true;
            FlangeModel.Inputs.diamBoltHole = Assy.Bolt.defaults.boltHoleDiam;
            FlangeModel.Space.thickness = 0.150;

            % WHEN
            Model = usain.model.ResilienceModel.from_flange_model(FlangeModel);

            % THEN expect inputs to be set
            Obj.verifyNotEmpty(Model.Bolt);
            Obj.verifyNotEmpty(Model.Extender);
            Obj.verifyNotEmpty(Model.Nut);
            Obj.verifyNotEmpty(Model.Washer);
            Obj.verifyNotEmpty(Model.eModulusBolt);
            Obj.verifyNotEmpty(Model.eModulusFlange);
            Obj.verifyNotEmpty(Model.doIgnoreExtender);
            Obj.verifyNotEmpty(Model.diameterBoltHole);
            Obj.verifyNotEmpty(Model.flangeThickness);

            % and outputs to be set (calculated)
            Obj.verifyGreaterThan(Model.resilienceBolt, 0);
            Obj.verifyGreaterThan(Model.resilienceClampedParts, 0);
            Obj.verifyGreaterThan(Model.resilienceFlanges, 0);
            Obj.verifyGreaterThan(Model.bendingResilienceBolt, 0);
            Obj.verifyGreaterThan(Model.loadFactor, 0);
        end

    end
end
