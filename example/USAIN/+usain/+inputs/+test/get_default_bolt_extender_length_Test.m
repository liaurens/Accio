classdef get_default_bolt_extender_length_Test < Unittest.TestCase % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function get_default_bolt_extender_length__happy(Obj)
            % GIVEN WHEN
            actual_row = usain.inputs.get_default_bolt_extender_length('ROW');
            actual_jpn = usain.inputs.get_default_bolt_extender_length('JPN');

            % THEN
            Obj.verifyEqual(actual_row, nan);
            Obj.verifyEqual(actual_jpn, 0.0);
        end

        function get_default_bolt_extender_length__sad(Obj)
            % GIVEN WHEN THEN
            Obj.assertRaisesMessageRegex(@() usain.inputs.get_default_bolt_extender_length('invalidCountryCode'), ...
                "Only 'ROW' or 'JPN' have defaults for bolt extender defined.");
        end

    end

end
