classdef FlangeThickness_Test < Unittest.TestCase

    properties (TestParameter)
        nDesignPoints = {1, 4}  % For testing scalar and array operations
    end

    methods (Test, TestTags = {'unit'})

        function calc_max_flange_thickness__happy(Obj)
            % GIVEN
            Test = usain.space.FlangeThickness();
            InputsSimple.boltOptions = {'ISO_M72'};
            InputsMulti.boltOptions = {'ISO_M64', 'ISO_M72'};
            InputsWithLength.boltOptions = {'ISO_M72x500'};

            % WHEN, THEN
            Obj.assertNumElements(Test.calc_max_flange_thickness(InputsSimple), 1);
            Obj.assertNumElements(Test.calc_max_flange_thickness(InputsMulti), 2);
            Obj.assertEqual(Test.calc_max_flange_thickness(InputsWithLength), 0.250, 'AbsTol', 1e-8);
        end

        function calc_min_flange_thickness__happy(Obj)
            % GIVEN
            Test = usain.space.FlangeThickness();
            InputsSimple.site = usain.inputs.Site.OFFSHORE;
            InputsSimple.tighteningMethod = {'tension'};
            InputsSimple.NUT_TYPE = {'ISR'};
            InputsSimple.boltOptions = {'ISO_M72'};

            % WHEN, THEN
            Obj.verifyEqual(Test.calc_min_flange_thickness(InputsSimple), 0.144, 'AbsTol', 1e-8);

            % NEXT GIVEN more detailed inputs for the bolt option
            InputsWithLength.site = usain.inputs.Site.OFFSHORE;
            InputsWithLength.tighteningMethod = {'tension'};
            InputsWithLength.NUT_TYPE = {'ISR'};
            InputsWithLength.boltOptions = {'ISO_M72x500'};

            Obj.assertEqual(Test.calc_min_flange_thickness(InputsWithLength), 0.144, 'AbsTol', 1e-8);

            % NEXT GIVEN multiple options and differnt configuration, i.e. different washers
            InputsMulti.site = usain.inputs.Site.OFFSHORE;
            InputsMulti.tighteningMethod = {'tension', 'torque'};
            InputsMulti.NUT_TYPE = {'ISR', 'ISO'};
            InputsMulti.boltOptions = {'ISO_M64', 'ISO_M64'};

            % WHEN, THEN expect the ISR to get larger thickness compared to the ISO counterpart, since that does not
            % have a washer (it is integrated with the nut).
            Obj.assertEqual(Test.calc_min_flange_thickness(InputsMulti), [0.128, 0.118], 'AbsTol', 1e-8);
        end

        function from_inputs__happy(Obj, nDesignPoints)
            % GIVEN
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = nDesignPoints)).data;

            % WHEN
            actual = usain.space.FlangeThickness.from_inputs(Inputs);

            % THEN
            Obj.assertInstanceOf(actual, 'design_space.DesignVariable');
            Obj.assertClass(actual, 'usain.space.FlangeThickness');
            Obj.assertNotEmpty(actual.InputBounds);
            Obj.assertNotEmpty(actual.CalculatedBounds);
            Obj.assertNotEmpty(actual.stepSize);
        end

    end

end
