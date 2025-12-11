classdef get_default_flange_youngs_modulus_Test < Unittest.TestCase % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function get_default_flange_youngs_modulus__happy(Obj)
            % GIVEN WHEN
            actual_row = usain.inputs.get_default_flange_youngs_modulus('ROW');
            actual_jpn = usain.inputs.get_default_flange_youngs_modulus('JPN');

            % THEN
            Obj.verifyEqual(actual_row, 210);
            Obj.verifyEqual(actual_jpn, 205);
        end

        function get_default_flange_youngs_modulus__sad(Obj)
            % GIVEN WHEN THEN
            Obj.assertRaisesMessageRegex(@() usain.inputs.get_default_flange_youngs_modulus('invalidCountryCode'), ...
                "Only 'ROW' or 'JPN' have defaults for Young's modulus defined.");
        end

    end

end
