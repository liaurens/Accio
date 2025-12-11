classdef validate_custom_preload_combinations_Test < Unittest.TestCase  % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function validate_custom_preload_combinations__all_nan(Obj)
            % GIVEN data to validate custom preload combination where all the values are nan
            % WHEN having one BoltFls block and one boltOption
            BoltFls.CUSTOM_PRELOAD = NaN;
            flangeGappingPreload = NaN;
            slsPretensionPreload = NaN;
            flangeNeckScfPreload = NaN;

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertTrue(pass);
            Obj.assertEmpty(msg);

            % WHEN having multiple BoltFls blocks and one boltOption
            BoltFls(1).CUSTOM_PRELOAD = NaN;
            BoltFls(2).CUSTOM_PRELOAD = NaN;

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertTrue(pass);
            Obj.assertEmpty(msg);

            % WHEN having multiple BoltFls blocks and multiple boltOptions
            BoltFls(1).CUSTOM_PRELOAD = [NaN NaN];
            BoltFls(2).CUSTOM_PRELOAD = [NaN NaN];
            BoltFls(3).CUSTOM_PRELOAD = [NaN NaN];
            flangeGappingPreload = [NaN NaN];
            slsPretensionPreload = [NaN NaN];
            flangeNeckScfPreload = [NaN NaN];

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertTrue(pass);
            Obj.assertEmpty(msg);

            % WHEN having one BoltFls blocks and multiple boltOptions
            BoltFls = struct();
            BoltFls.CUSTOM_PRELOAD = [NaN NaN];

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertTrue(pass);
            Obj.assertEmpty(msg);
        end

        function validate_custom_preload_combinations__others_matching(Obj)
            % GIVEN data to validate custom preload combinations where the other three are identical and matches
            % with (one of) the BoltFls.CUSTOM_PRELOAD values
            % WHEN having one BoltFls block and one boltOption
            BoltFls.CUSTOM_PRELOAD = 100;
            flangeGappingPreload = 100;
            slsPretensionPreload = 100;
            flangeNeckScfPreload = 100;

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertTrue(pass);
            Obj.assertEmpty(msg);

            % WHEN having multiple BoltFls blocks and one boltOption
            BoltFls(1).CUSTOM_PRELOAD = 100;
            BoltFls(2).CUSTOM_PRELOAD = NaN;

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertTrue(pass);
            Obj.assertEmpty(msg);

            % GIVEN having multiple BoltFls blocks and multiple boltOptions
            BoltFls(1).CUSTOM_PRELOAD = [100 200];
            BoltFls(2).CUSTOM_PRELOAD = [NaN NaN];
            BoltFls(3).CUSTOM_PRELOAD = [300 400];
            flangeGappingPreload = [300 400];
            slsPretensionPreload = [300 400];
            flangeNeckScfPreload = [300 400];

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertTrue(pass);
            Obj.assertEmpty(msg);

            % WHEN having one BoltFls blocks and multiple boltOptions
            BoltFls = struct();
            BoltFls.CUSTOM_PRELOAD = [300 400];

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertTrue(pass);
            Obj.assertEmpty(msg);
        end

        function validate_custom_preload_combinations__others_not_equal(Obj)
            % GIVEN data to validate custom preload combinations where the other three are not all the same
            % WHEN having pne BoltFls block and one boltOption
            BoltFls.CUSTOM_PRELOAD = 100;
            flangeGappingPreload = 100;
            slsPretensionPreload = 200;
            flangeNeckScfPreload = 100;
            expectedMsg = ['Expected all values for ', ...
                'FlangeGapping.CUSTOM_PRELOAD, SlsPretension.CUSTOM_PRELOAD, FlangeNeckScf.CUSTOM_PRELOAD ', ...
                'to be the same and to be identical to one of the BoltFls.CUSTOM_PRELOAD values.'];

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertFalse(pass);
            Obj.assertEqual(expectedMsg, msg);

            % WHEN having multiple BoltFls blocks and one boltOption
            BoltFls(1).CUSTOM_PRELOAD = 100;
            BoltFls(2).CUSTOM_PRELOAD = NaN;
            flangeGappingPreload = 100;
            slsPretensionPreload = NaN;
            flangeNeckScfPreload = 200;

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertFalse(pass);
            Obj.assertEqual(expectedMsg, msg);

            % WHEN having multiple BoltFls blocks and two boltOptions
            BoltFls(1).CUSTOM_PRELOAD = [100 200];
            BoltFls(2).CUSTOM_PRELOAD = [NaN NaN];
            BoltFls(3).CUSTOM_PRELOAD = [300 400];
            flangeGappingPreload = [100 200];
            slsPretensionPreload = [NaN NaN];
            flangeNeckScfPreload = [300 400];

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertFalse(pass);
            Obj.assertEqual(expectedMsg, msg);

            % WHEN having one BoltFls blocks and multiple boltOptions
            BoltFls = struct();
            BoltFls.CUSTOM_PRELOAD = [100 200];
            flangeGappingPreload = [100 200];
            slsPretensionPreload = [NaN NaN];
            flangeNeckScfPreload = [100 200];

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertFalse(pass);
            Obj.assertEqual(expectedMsg, msg);
        end

        function validate_custom_preload_combinations__others_not_matching(Obj)
            % GIVEN data to validate custom preload combinations where the other three are all the same, but do not
            % match with any of the BoltFls.CUSTOM_PRELOAD values
            % WHEN having pne BoltFls block and one boltOption
            BoltFls.CUSTOM_PRELOAD = 200;
            flangeGappingPreload = 100;
            slsPretensionPreload = 100;
            flangeNeckScfPreload = 100;
            expectedMsg = ['Expected all values for ', ...
                'FlangeGapping.CUSTOM_PRELOAD, SlsPretension.CUSTOM_PRELOAD, FlangeNeckScf.CUSTOM_PRELOAD ', ...
                'to be the same and to be identical to one of the BoltFls.CUSTOM_PRELOAD values.'];

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertFalse(pass);
            Obj.assertEqual(expectedMsg, msg);

            % WHEN having multiple BoltFls blocks and one boltOption
            BoltFls(1).CUSTOM_PRELOAD = 200;
            BoltFls(2).CUSTOM_PRELOAD = 100;
            flangeGappingPreload = NaN;
            slsPretensionPreload = NaN;
            flangeNeckScfPreload = NaN;

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertFalse(pass);
            Obj.assertEqual(expectedMsg, msg);

            % WHEN having multiple BoltFls blocks and multiple boltOptions
            BoltFls(1).CUSTOM_PRELOAD = [100 200];
            BoltFls(2).CUSTOM_PRELOAD = [100 200];
            BoltFls(3).CUSTOM_PRELOAD = [100 200];
            flangeGappingPreload = [NaN NaN];
            slsPretensionPreload = [NaN NaN];
            flangeNeckScfPreload = [NaN NaN];

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            Obj.assertFalse(pass);
            Obj.assertEqual(expectedMsg, msg);

            % WHEN having multiple BoltFls blocks and multiple boltOptions
            BoltFls(1).CUSTOM_PRELOAD = [NaN NaN];
            BoltFls(2).CUSTOM_PRELOAD = [NaN NaN];
            BoltFls(3).CUSTOM_PRELOAD = [NaN NaN];
            flangeGappingPreload = [100 200];
            slsPretensionPreload = [100 200];
            flangeNeckScfPreload = [100 100];

            % THEN
            [pass, msg] = usain.inputs.validate_custom_preload_combinations(BoltFls, flangeGappingPreload, ...
                slsPretensionPreload, flangeNeckScfPreload);
            expectedMsg = ['No CUSTOM_PRELOAD defined in BoltFls block(s), ', ...
                'therefore also expected that none of the ', ...
                'FlangeGapping.CUSTOM_PRELOAD, SlsPretension.CUSTOM_PRELOAD, FlangeNeckScf.CUSTOM_PRELOAD ', ...
                'inputs are defined.'];
            Obj.assertFalse(pass);
            Obj.assertEqual(expectedMsg, msg);
        end

    end
end
