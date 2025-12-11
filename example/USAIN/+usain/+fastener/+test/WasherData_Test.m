classdef WasherData_Test < Unittest.TestCase
    % See also: usain.fastener.test.BaseCatalogData_Test

    methods (TestMethodTeardown)

        function set_clean_catalog_data(~)
            % In case the catalog data (singleton) is modified, future tests might be impaired. Therefore,
            % make sure a test is closed by resetting the catalog data.
            Lib = usain.fastener.CatalogLibrary.get_library();
            Lib.set_clean_data();
        end

    end

    methods (Test, TestTags = {'unit'})

        function make_custom_washer__input_nan(Obj)
            % GIVEN
            Wash = usain.fastener.test.WasherData_Test.get_simple_test_object();
            origDIn = Wash.diamIn;
            origDOut = Wash.diamOut;
            origLen = Wash.len;

            % WHEN
            Wash.make_custom_washer(nan, nan, nan);

            % THEN not replaced
            Obj.verifyEqual(Wash.diamIn, origDIn);
            Obj.verifyEqual(Wash.diamOut, origDOut);
            Obj.verifyEqual(Wash.len, origLen);
        end

        function make_custom_washer__real_values(Obj)
            % GIVEN
            Wash = usain.fastener.test.WasherData_Test.get_simple_test_object();
            origDIn = Wash.diamIn;
            origDOut = Wash.diamOut;
            origLen = Wash.len;

            % WHEN
            Wash.make_custom_washer(Wash.diamIn * 1.1, Wash.diamOut * 1.1, Wash.len * 1.1);

            % THEN replaced by larger numbers
            Obj.verifyEqual(Wash.diamIn, 1.1 * origDIn, 'AbsTol', 1e-4);
            Obj.verifyEqual(Wash.diamOut, 1.1 * origDOut, 'AbsTol', 1e-4);
            Obj.verifyEqual(Wash.len, 1.1 * origLen, 'AbsTol', 1e-4);
        end

        function get_mass__happy(Obj)
            % GIVEN an ISO M56 washer
            Lib = usain.fastener.CatalogLibrary.get_library();
            Washer = Lib.Washers.select('label', 'ISO_M56');

            % WHEN, THEN
            actual = Washer.mass;
            expected = 0.44274;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-5);
        end

    end

    methods (Static)

        function Wash = get_simple_test_object()
            Lib = usain.fastener.CatalogLibrary.get_library();
            Wash = Lib.Washers(1);
        end

    end
end
