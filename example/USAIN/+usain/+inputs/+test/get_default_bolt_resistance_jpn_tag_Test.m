classdef get_default_bolt_resistance_jpn_tag_Test < Unittest.TestCase % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function get_default_bolt_resistance_jpn_tag__happy(Obj)
            % GIVEN WHEN
            actual_row = usain.inputs.get_default_bolt_resistance_jpn_tag('ROW');
            actual_jpn = usain.inputs.get_default_bolt_resistance_jpn_tag('JPN');

            % THEN
            Obj.verifyEqual(actual_row, '');
            Obj.verifyEqual(actual_jpn, {'shortTerm' 'longTerm' 'seismic'});
        end

        function get_default_bolt_resistance_jpn_tag__sad(Obj)
            % GIVEN WHEN THEN
            Obj.assertRaisesMessageRegex(@() usain.inputs.get_default_bolt_resistance_jpn_tag('invalidCountryCode'), ...
                "Only 'ROW' or 'JPN' have defaults for PSF_BOLT_RESISTANCE_JPN_TAG defined.");
        end

    end

end
