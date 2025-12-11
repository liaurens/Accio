classdef get_default_bolt_resistance_jpn_Test < Unittest.TestCase % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function get_default_bolt_resistance_jpn__happy(Obj)
            % GIVEN WHEN
            actual_row = usain.inputs.get_default_bolt_resistance_jpn('ROW');
            actual_jpn = usain.inputs.get_default_bolt_resistance_jpn('JPN');

            % THEN
            Obj.verifyEqual(actual_row, nan);
            Obj.verifyEqual(actual_jpn, [1.25 1.875 1.0]);
        end

        function get_default_bolt_resistance_jpn__sad(Obj)
            % GIVEN WHEN THEN
            Obj.assertRaisesMessageRegex(@() usain.inputs.get_default_bolt_resistance_jpn('invalidCountryCode'), ...
                "Only 'ROW' or 'JPN' have defaults for PSF_BOLT_RESISTANCE_JPN defined.");
        end

    end

end
