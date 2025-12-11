classdef get_default_do_assess_uls_Test < Unittest.TestCase % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function get_default_do_assess_uls__happy(Obj)
            % GIVEN WHEN
            actual_row = usain.inputs.get_default_do_assess_uls('ROW');
            actual_jpn = usain.inputs.get_default_do_assess_uls('JPN');

            % THEN
            Obj.verifyTrue(actual_row);
            Obj.verifyFalse(actual_jpn);
        end

        function get_default_do_assess_uls__sad(Obj)
            % GIVEN WHEN THEN
            Obj.assertRaisesMessageRegex(@() usain.inputs.get_default_do_assess_uls('invalidCountryCode'), ...
                "Only 'ROW' or 'JPN' have defaults for DO_ASSESS_ULS defined.");
        end

    end

end
