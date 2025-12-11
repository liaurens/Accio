classdef get_preload_Test < Unittest.TestCase  % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function get_preload__happy(Obj)
            % GIVEN data to get the preload
            defaultPreload = [1000 1000 2000 2000];
            customPreload = [3000 3000 NaN NaN];
            loadFactor = 1;

            % WHEN getting preload
            actualPreload = usain.fastener.get_preload(defaultPreload, customPreload, loadFactor);

            % THEN
            expected = [3000 3000 2000 2000];
            Obj.assertEqual(expected, actualPreload);

            % WHEN getting preload with other loadFactor
            loadFactor = 0.9;
            actualPreload = usain.fastener.get_preload(defaultPreload, customPreload, loadFactor);

            % THEN
            expected = [2700 2700 1800 1800];
            Obj.assertEqual(expected, actualPreload);
        end

        function get_preload__custompreload_all_nan(Obj)
            % GIVEN data to get the preload, customPreload values are NaN
            defaultPreload = [1000 1000 2000 2000];
            customPreload = [NaN NaN NaN NaN];
            loadFactor = 1;

            % WHEN getting preload
            actualPreload = usain.fastener.get_preload(defaultPreload, customPreload, loadFactor);

            % THEN
            expected = [1000 1000 2000 2000];
            Obj.assertEqual(expected, actualPreload);

            % WHEN getting preload with other loadFactor
            loadFactor = 0.9;
            actualPreload = usain.fastener.get_preload(defaultPreload, customPreload, loadFactor);

            % THEN
            expected = [900 900 1800 1800];
            Obj.assertEqual(expected, actualPreload);
        end

        function get_preload__custompreload_all_have_values(Obj)
            % GIVEN data to get the preload, customPreload values are not NaN
            defaultPreload = [1000 1000 2000 2000];
            customPreload = [2000 2000 2500 2500];
            loadFactor = 1;

            % WHEN getting preload
            actualPreload = usain.fastener.get_preload(defaultPreload, customPreload, loadFactor);

            % THEN
            expected = [2000 2000 2500 2500];
            Obj.assertEqual(expected, actualPreload);

            % WHEN getting preload with other loadFactor
            loadFactor = 0.9;
            actualPreload = usain.fastener.get_preload(defaultPreload, customPreload, loadFactor);

            % THEN
            expected = [1800 1800 2250 2250];
            Obj.assertEqual(expected, actualPreload);
        end

        function get_preload__custompreload_has_single_value(Obj)
            % GIVEN data to get the preload, customPreload is a single value
            defaultPreload = 1000;
            customPreload = 2000;
            loadFactor = 1;

            % WHEN getting preload
            actualPreload = usain.fastener.get_preload(defaultPreload, customPreload, loadFactor);

            % THEN
            expected = 2000;
            Obj.assertEqual(expected, actualPreload);

            % WHEN getting preload with other loadFactor
            loadFactor = 0.9;
            actualPreload = usain.fastener.get_preload(defaultPreload, customPreload, loadFactor);

            % THEN
            expected = 1800;
            Obj.assertEqual(expected, actualPreload);

            % WHEN defaultPreload is a vector, and customPreload still scalar
            Obj.assertEqual(usain.fastener.get_preload([1 2], 3, 1), [3 3]);
        end

        function get_preload__custompreload_has_single_nan_value(Obj)
            % GIVEN data to get the preload, customPreload is a NaN
            defaultPreload = 1000;
            customPreload = NaN;
            loadFactor = 1;

            % WHEN getting preload
            actualPreload = usain.fastener.get_preload(defaultPreload, customPreload, loadFactor);

            % THEN
            expected = 1000;
            Obj.assertEqual(expected, actualPreload);

            % WHEN getting preload with other loadFactor
            loadFactor = 0.9;
            actualPreload = usain.fastener.get_preload(defaultPreload, customPreload, loadFactor);

            % THEN
            expected = 900;
            Obj.assertEqual(expected, actualPreload);

            % WHEN defaultPreload is a vector, and customPreload still scalar
            Obj.assertEqual(usain.fastener.get_preload([1 2], nan, 1), [1 2]);
        end

        function get_preload__size_mismatch(Obj)
            % GIVEN data to get the preload, vector size is not same
            defaultPreload = [1000 1000 2000];
            customPreload = [3000 3000 NaN NaN];
            loadFactor = 1;

            % WHEN getting preload
            f = @() usain.fastener.get_preload(defaultPreload, customPreload, loadFactor);

            % THEN
            Obj.assertRaisesMessageRegex(f, ...
                'Expected size of arg "customPreload" to be scalar or equal to "defaultPreload".');

            % WHEN getting preload
            defaultPreload = [1000 1000 2000];
            customPreload = [3000 3000];
            loadFactor = 1;
            f = @() usain.fastener.get_preload(defaultPreload, customPreload, loadFactor);

            % THEN
            Obj.assertRaisesMessageRegex(f, ...
                'Expected size of arg "customPreload" to be scalar or equal to "defaultPreload".');
        end

        function get_preload__loadfactor_behavior(Obj)
            % GIVEN, WHEN, THEN
            Obj.assertEqual(usain.fastener.get_preload(1000, 2000, 1), 2000);
            Obj.assertEqual(usain.fastener.get_preload(1000, nan, 1), 1000);
            Obj.assertEqual(usain.fastener.get_preload(1000, 2000, 0.9), 1800);
            Obj.assertEqual(usain.fastener.get_preload(1000, nan, 0.9), 900);
        end

    end

end
