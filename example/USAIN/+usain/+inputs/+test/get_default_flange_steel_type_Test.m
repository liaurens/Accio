classdef get_default_flange_steel_type_Test < Unittest.TestCase % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function get_default_flange_steel_type__happy(Obj)
            % GIVEN WHEN
            actual_row = usain.inputs.get_default_flange_steel_type('ROW');
            actual_jpn = usain.inputs.get_default_flange_steel_type('JPN');

            % THEN
            Obj.verifyEqual(actual_row, 'S355');
            Obj.verifyEqual(actual_jpn, 'SF520');
        end

        function get_default_flange_steel_type__sad(Obj)
            % GIVEN WHEN THEN
            Obj.assertRaisesMessageRegex(@() usain.inputs.get_default_flange_steel_type('invalidCountryCode'), ...
                "Only 'ROW' or 'JPN' have defaults for flange steel type defined.");
        end

    end

end
