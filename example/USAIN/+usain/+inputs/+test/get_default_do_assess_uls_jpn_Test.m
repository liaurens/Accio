classdef get_default_do_assess_uls_jpn_Test < Unittest.TestCase % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function get_default_do_assess_uls_jpn__happy(Obj)
            % GIVEN WHEN
            actual_row = usain.inputs.get_default_do_assess_uls_jpn('ROW');
            actual_jpn = usain.inputs.get_default_do_assess_uls_jpn('JPN');

            % THEN
            Obj.verifyFalse(actual_row);
            Obj.verifyTrue(actual_jpn);
        end

        function get_default_do_assess_uls_jpn__sad(Obj)
            % GIVEN WHEN THEN
            Obj.assertRaisesMessageRegex(@() usain.inputs.get_default_do_assess_uls_jpn('invalidCountryCode'), ...
                "Only 'ROW' or 'JPN' have defaults for DO_ASSESS_ULS_JPN defined.");
        end

    end

end
