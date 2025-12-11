classdef TighteningToolData_Test < Unittest.TestCase
    % See also: usain.fastener.test.BaseCatalogData_Test

    methods (Test, TestTags = {'unit'})

        function verify_temp_stages_tools__happy(Obj)
            % GIVEN
            site = usain.inputs.Site.OFFSHORE;

            % WHEN calling the test method with valid inputs, with and without output arguments
            usain.fastener.TighteningToolData.verify_temp_stages_tools(site, {'HV_M72', 'ISO_M42'}, 'normal');
            usain.fastener.TighteningToolData.verify_temp_stages_tools(site, {'ISO_M42'}, 'thin');
            withArgout = usain.fastener.TighteningToolData.verify_temp_stages_tools(site, {'JIS_M42'}, 'normal');

            % THEN we expect no errors and in case an output argument is provided, a function handle is returned
            Obj.assertInstanceOf(withArgout, 'function_handle');
        end

        function verify_temp_stages_tools__invalid_combination(Obj)
            % GIVEN
            site = usain.inputs.Site.OFFSHORE;

            % WHEN calling the test method with invalid inputs
            % THEN
            Obj.assertError( ...
                @() usain.fastener.TighteningToolData.verify_temp_stages_tools(site, {'HV_M72', 'ISO_M42'}, 'thin'), ...
                'TighteningToolData:verify_temp_stages_tools:InvalidCombination');
            Obj.assertError( ...
                @() usain.fastener.TighteningToolData.verify_temp_stages_tools(site, {'JIS_M72'}, 'thin'), ...
                'TighteningToolData:verify_temp_stages_tools:InvalidCombination');
        end

        function get_temp_stages_tool_obj__happy(Obj)
            % GIVEN
            site = usain.inputs.Site.OFFSHORE;

            % WHEN THEN
            Obj.assertEqual( ...
                usain.fastener.TighteningToolData.get_temp_stages_tool_obj(site, 'ISO_M42', 'normal').label, ...
                'ISO_M42_torque_offshore');
            Obj.assertEqual( ...
                usain.fastener.TighteningToolData.get_temp_stages_tool_obj(site, 'ISO_M48', 'thin').label, ...
                'ISO_M48_torqueThin_offshore');
            Obj.assertEqual( ...
                usain.fastener.TighteningToolData.get_temp_stages_tool_obj(site, 'JIS_M56', 'normal').label, ...
                'JIS_M56_torque_offshore');
        end

        function get_tool_size_for_bolt_distance__happy(Obj)
            % GIVEN
            site = usain.inputs.Site.OFFSHORE;

            % WHEN THEN
            actual = usain.fastener.TighteningToolData.get_tool_size_for_bolt_distance( ...
                site, 'ISO_M64', 'tension', 'ISR', 'normal', nan);
            Obj.assertEqual(actual, 0.074);

            actual = usain.fastener.TighteningToolData.get_tool_size_for_bolt_distance( ...
                site, 'ISO_M64', 'tension', 'ISR', 'thin', nan);
            Obj.assertEqual(actual, 0.0635);

            actual = usain.fastener.TighteningToolData.get_tool_size_for_bolt_distance( ...
                site, 'JIS_M64', 'torque', 'JIS', 'normal', nan);
            Obj.assertEqual(actual, 0.0765);

            actual = usain.fastener.TighteningToolData.get_tool_size_for_bolt_distance( ...
                site, 'ISO_M64', 'tension', 'ISR', 'normal', 0.123);
            Obj.assertEqual(actual, 0.123);

            actual = usain.fastener.TighteningToolData.get_tool_size_for_bolt_distance( ...
                site, 'ISO_M64', 'tension', 'ISR', 'normal', 0.001);
            Obj.assertEqual(actual, 0.001);
        end

        function get_tool_size_for_bolt_distance__array_inputs(Obj)
            % GIVEN array inputs
            site = usain.inputs.Site.OFFSHORE;
            label = {'ISO_M42', 'ISO_M42'};
            method = {'tension', 'torque'};
            nutType = {'ISR', 'ISO'};
            override = [nan, nan];

            % WHEN, THEN
            actual = usain.fastener.TighteningToolData.get_tool_size_for_bolt_distance( ...
                site, label, method, nutType, 'normal', override);
            Obj.assertSize(actual, [1 2]);

            % WHEN having inconsistent array sizes
            label = label(1);
            actual = @() usain.fastener.TighteningToolData.get_tool_size_for_bolt_distance( ...
                site, label, method, nutType, 'normal', override);
            Obj.assertError(actual, 'TighteningToolData:get_tool_size:WrongSizeArgsIn');
        end

    end

end
