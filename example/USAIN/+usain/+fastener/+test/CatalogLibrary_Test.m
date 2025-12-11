classdef CatalogLibrary_Test < Unittest.TestCase

    methods (TestMethodTeardown)

        function set_clean_catalog_data(~)
            % In case the catalog data (singleton) is modified, future tests might be impaired. Therefore,
            % make sure a test is closed by resetting the catalog data.
            Lib = usain.fastener.CatalogLibrary.get_library();
            Lib.set_clean_data();
        end

    end

    methods (Test, TestTags = {'unit'})

        function standard_catalog_path__file_found(Obj)
            % GIVEN the path to the standard catalog file
            catalogFilePath = usain.fastener.CatalogLibrary.CATALOG_PATH;

            % WHEN, THEN
            Obj.assertTrue(isfile(catalogFilePath));
        end

        function get_library__happy_case(Obj)
            % GIVEN a clean slate, having cleared a specific persistent variable
            % from memory
            clear +usain\+fastener\CatalogLibrary;

            % WHEN THEN
            Lib = usain.fastener.CatalogLibrary.get_library();
            Obj.assertInstanceOf(Lib, 'usain.fastener.CatalogLibrary');
        end

        function get_library__returns_clean_data(Obj)
            % GIVEN the library with some dirty data
            Lib = usain.fastener.CatalogLibrary.get_library();
            Lib.Fasteners(1).len = 1.23;
            Lib.Washers(2).diamOut = 123;

            % WHEN we query the library again
            Lib = usain.fastener.CatalogLibrary.get_library();

            % THEN we expect dirty data to be returned
            Obj.assertEqual(Lib.Fasteners(1).len, 1.23);
            Obj.assertEqual(Lib.Washers(2).diamOut, 123);

            % WHEN we explicitly reset the data
            Lib = usain.fastener.CatalogLibrary.get_library();
            Lib.set_clean_data();

            % THEN we expect clean data to be returned
            Obj.assertNotEqual(Lib.Fasteners(1).len, 1.23);
            Obj.assertNotEqual(Lib.Washers(2).diamOut, 123);
        end

        function select_assemblies__select_single_assembly(Obj)
            % GIVEN
            Lib = usain.fastener.CatalogLibrary.get_library();

            % WHEN we select a single assembly
            Assy = Lib.select_assemblies(usain.inputs.Site.OFFSHORE, 'ISO_M64', 'torque', 'ISO');

            % THEN
            Obj.assertLength(Assy, 1);
            Obj.assertEqual(Assy.Bolt.label, 'ISO_M64');
            Obj.assertEqual(Assy.Bolt.label, Assy.Washer.label);
            Obj.assertEqual(Assy.Bolt.label, Assy.Nut.label);
            Obj.assertEqual(Assy.Bolt.label, Assy.Extender.label);
            Obj.assertEqual(Assy.Tool.label, 'ISO_M64_torque_offshore');
        end

        function select_assemblies__select_multiple_assemblies(Obj)
            % GIVEN
            Lib = usain.fastener.CatalogLibrary.get_library();

            % WHEN we select a single assembly
            Assy = Lib.select_assemblies(usain.inputs.Site.OFFSHORE, ...
                {'ISO_M64', 'HV_M48'}, {'tension', 'torque'}, {'ISR', 'HV'});

            % THEN
            Obj.assertLength(Assy, 2);
            Obj.assertEqual(Assy(1).Bolt.label, 'ISO_M64');
            Obj.assertEqual(Assy(1).Nut.label, 'ISR_M64');
            Obj.assertEqual(Assy(2).Bolt.label, 'HV_M48');
        end

    end
end
