classdef get_default_nut_type_Test < Unittest.TestCase % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function get_default_nut_type__happy(Obj)
            % GIVEN valid boltLabel and tighteningMethod (both are checked to be valid)
            boltLabel = {'HV_M48', 'ISO_M64', 'ISO_M72', 'JIS_M56'};
            tighteningMethod = {'torque', 'torque', 'tension', 'torque'};

            % WHEN
            actual = usain.inputs.get_default_nut_type(boltLabel, tighteningMethod);

            % THEN
            expected = {'HV', 'ISO', 'ISR', 'JIS'};
            Obj.verifyEqual(actual, expected);
        end

        function get_default_nut_type__sad(Obj)
            % GIVEN inputs with different size
            boltLabel = {'HV_M48', 'ISO_M64', 'ISO_M72', 'JIS_M56'};
            tighteningMethod = {'torque', 'torque' };

            % WHEN, THEN
            Obj.assertRaisesMessageRegex(@() usain.inputs.get_default_nut_type(boltLabel, tighteningMethod), ...
                'Inputs boltLabel and tighteningMethod must have the same size.');
        end

    end

end
