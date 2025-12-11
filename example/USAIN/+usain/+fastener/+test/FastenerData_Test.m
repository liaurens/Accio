classdef FastenerData_Test < Unittest.TestCase
    % See also: usain.fastener.test.BaseCatalogData_Test

    properties (TestParameter)
        labels = usain.fastener.CatalogLibrary.get_all_fastener_labels()
    end

    methods (Test, TestTags = {'unit'})

        function get_default__happy(Obj)
            % GIVEN
            Test = usain.fastener.FastenerData();
            Test.defaults.foo = 1;
            Test.defaults.bar = 2.3;

            % WHEN, THEN
            expectedFoo = 1;
            expectedBar = 2.3;
            Obj.assertEqual(Test.get_default('foo'), expectedFoo, 'AbsTol', 1e-6);
            Obj.assertEqual(Test.get_default('bar'), expectedBar, 'AbsTol', 1e-6);
        end

        function get_ftRc__happy(Obj)
            % GIVEN an ultimate strength and stress area
            Test = usain.fastener.FastenerData();
            Test.ultStrength = 1e9;
            Test.areaStress = 3e-3;

            % WHEN THEN
            expected = 3e6;
            Obj.assertEqual(Test.ftRc, expected, 'AbsTol', 1);
        end

        function get_minorDiameter__happy(Obj)
            % GIVEN a M72 ISO stud
            Test = usain.fastener.FastenerData();
            Test.diam = 0.072;
            Test.pitch = 0.006;

            % WHEN, THEN
            actual = Test.minorDiameter;
            expected = 0.064639;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-6);
        end

        function get_pitchDiameter__happy(Obj)
            % GIVEN a M64 ISO stud
            Test = usain.fastener.FastenerData();
            Test.diam = 0.064;
            Test.pitch = 0.006;

            % WHEN, THEN
            actual = Test.pitchDiameter;
            expected = 0.060103;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-6);
        end

        function get_length_options__input_nonnan(Obj)
            % GIVEN a bolt label and a non-nan input bolt length
            inputLength = 20e-3;
            label = 'ISO_M72';

            % WHEN, THEN
            actual = usain.fastener.FastenerData.get_length_options(inputLength, label);
            Obj.assertEqual(actual, inputLength);
        end

        function get_length_options__input_nan(Obj)
            % GIVEN a bolt label and a nan value for input bolt length
            inputLength = nan;
            label = 'ISO_M72';

            % WHEN, THEN
            actual = usain.fastener.FastenerData.get_length_options(inputLength, label);
            expected = 1e-3 * (440:10:800);
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-4);
        end

        function calc_mass__hv_bolt(Obj)
            % GIVEN, WHEN, THEN
            label = 'HV_M64';
            len = 0.400;
            actual = usain.fastener.FastenerData.calc_mass(label, len);
            expected = 12.4206;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-4);
        end

        function get_standard_thread_length__one_length_per_label(Obj, labels)
            % GIVEN, WHEN, THEN
            actual = usain.fastener.FastenerData.get_standard_thread_length(labels);
            Obj.assertNumElements(actual, 1);
        end

        function get_standard_bolt_lengths__numeric_arrays(Obj, labels)
            % GIVEN, WHEN, THEN
            actual = usain.fastener.FastenerData.get_standard_bolt_lengths(labels);
            Obj.assertClass(actual, 'double');
        end

        function calc_mass__iso_stud(Obj)
            % GIVEN, WHEN, THEN
            label = 'ISO_M64';
            len = 0.400;
            actual = usain.fastener.FastenerData.calc_mass(label, len);
            expected = 8.9086;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-4);
        end

        function calc_mass__hv_bolt_equal_jis_bolt(Obj)
            % GIVEN the mass for a HV_M42 bolt
            label = 'HV_M42';
            len = 0.123;
            massHvM42 = usain.fastener.FastenerData.calc_mass(label, len);

            % WHEN we compare that to the mass of a JIS_M42 bolt
            label = 'JIS_M42';
            len = 0.123;
            massJisM42 = usain.fastener.FastenerData.calc_mass(label, len);

            % THEN
            Obj.assertEqual(massHvM42, massJisM42, 'AbsTol', 1e-5);
        end

        function calc_expected_range_preload__happy(Obj)
            % GIVEN, WHEN, THEN
            label = 'ISO_M72';
            actual = usain.fastener.FastenerData.calc_expected_range_preload(label);
            expected = [1627610, 3255220];
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-3);
        end

    end

end
