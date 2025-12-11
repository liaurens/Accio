classdef BaseCatalogData_Test < Unittest.TestCase
    % Generic tests for usain.fastener.BaseCatalogData child classes

    properties
        Dummy % Implementation of usain.fastener.BaseCatalogData with abstract properties set
    end
    properties (TestParameter)
        childClasses = {'usain.fastener.ExtenderData', 'usain.fastener.FastenerData', ...
            'usain.fastener.GarnitureData', 'usain.fastener.NutData', 'usain.fastener.TighteningToolData', ...
            'usain.fastener.WasherData'}
        catalogName = {'Garnitures', 'Fasteners', 'Nuts', 'Washers', 'Extenders', 'Tools'}
    end

    methods (TestClassSetup)

        function create_dummy_object(Obj)
            % Assign a value to abstract properties
            dummyCatalogPath = fullfile(fileparts(mfilename('fullpath')), '_data', 'dummy_catalog_happy.yml');
            RawCatalogData = usain.fastener.CatalogReader('sourcePath', dummyCatalogPath);
            Obj.Dummy = usain.fastener.test.DummyCatalogData.from_struct(RawCatalogData.parsed);
        end

    end

    methods (Test, TestTags = {'unit'})

        function import_struct__input_struct_missing_fields(Obj)
            % GIVEN a struct with some required input fields missing
            S = struct();
            S.some = 1;
            S.wrongField = 2;
            S.anotherWrongField = 3;

            % WHEN THEN
            Test = usain.fastener.test.DummyCatalogData();
            f = @() Test.import_struct(S);
            Obj.assertError(f, 'BaseCatalogData:import_struct:MissingField');
        end

        function import_struct__happy_case(Obj)
            % GIVEN a struct with some required input fields missing
            S = struct();
            S.some = 'str';
            S.thing = 123;
            S.test = 'onetwo';

            % WHEN THEN
            Test = usain.fastener.test.DummyCatalogData();
            Test.import_struct(S);
            Obj.assertEqual(Test.some, 'str');
            Obj.assertEqual(Test.thing, 123);
            Obj.assertEqual(Test.test, 'onetwo');
        end

        function select__single_name_value_pair(Obj)
            % GIVEN
            % WHEN we select based on a single name-value pair
            actual = Obj.Dummy.select('some', 'one');

            % THEN
            Obj.assertEqual(actual.some, 'one');
        end

        function select__multiple_name_value_pairs(Obj)
            % GIVEN
            % WHEN we select based on multiple name-value pairs
            actual = Obj.Dummy.select('some', 'one', 'test', 'test');

            % THEN
            Obj.assertEqual(actual.some, 'one');
            Obj.assertEqual(actual.thing, 1);
        end

        function select__incorrect_signature(Obj)
            % GIVEN
            % WHEN calling select() without a name-value pair
            % THEN
            expect = 'BaseCatalogData:select:WrongSignature';
            Obj.assertError(@() Obj.Dummy.select(), expect);
            Obj.assertError(@() Obj.Dummy.select('some'), expect);
            Obj.assertError(@() Obj.Dummy.select('some', 'one', 'else'), expect);
        end

        function select__name_not_a_required_field(Obj)
            % GIVEN
            % WHEN calling select() with a name-value pair reflecting a non-existing field
            % THEN
            Obj.assertError(@() Obj.Dummy.select('doesntexist', 'test'), ...
                'BaseCatalogData:select:NameArgNotFound');
        end

        function select__no_unique_match(Obj)
            % GIVEN
            % WHEN calling select() with name-value pair(s) that don't result in a unique match
            % THEN
            Obj.assertError(@() Obj.Dummy.select('test', 'test'), 'BaseCatalogData:select:NoUniqueMatch');
        end

        function required_fields__is_prop(Obj, childClasses)
            % GIVEN the required fields of a usain.fastener.BaseCatalogData child class
            TempFunc = str2func(['@()', childClasses, '.REQUIRED_FIELDS']);
            requiredFields = TempFunc();

            % WHEN THEN
            isRequiredAndProperty = ismember(requiredFields, properties(childClasses));
            Obj.assertTrue(all(isRequiredAndProperty));
        end

        function validate_input__not_string_like(Obj)
            % GIVEN inputs that are not a string-like type (char, cellstr, string)
            % WHEN THEN
            errorId = 'BaseCatalogData:validate_input:WrongType';
            Obj.assertError(@() usain.fastener.BaseCatalogData.validate_input({'test', 1}, 1, 'foo', 'bar'), errorId);
            Obj.assertError(@() usain.fastener.BaseCatalogData.validate_input(123, 1, 'foo', 'bar'), errorId);
            Obj.assertError(@() usain.fastener.BaseCatalogData.validate_input([true, false], 1, 'foo', 'bar'), errorId);
        end

        function validate_input__incorrect_length(Obj)
            % GIVEN valid inputs but wrong length
            inpVals = {'torque', 'tension'};
            expectedLength = length(inpVals) + 1;
            expectedValues = {'torque', 'tension'};

            % WHEN THEN
            f = @() usain.fastener.BaseCatalogData.validate_input(inpVals, expectedLength, expectedValues, 'foo');
            Obj.assertError(f, 'BaseCatalogData:validate_input:ValidationError');
        end

        function validate_input__invalid_options(Obj)
            % GIVEN inputs of correct length but with invalid strings
            expectedLength = 1;
            expectedValues = {'torque', 'tension'};

            % WHEN THEN
            errorId = 'BaseCatalogData:validate_input:ValidationError';
            Obj.assertError(@() usain.fastener.BaseCatalogData.validate_input('foo', expectedLength, expectedValues, 'bar'), errorId);  % mh:ignore_style
            Obj.assertError(@() usain.fastener.BaseCatalogData.validate_input('torkue', expectedLength, expectedValues, 'bar'), errorId);  % mh:ignore_style
            Obj.assertError(@() usain.fastener.BaseCatalogData.validate_input('TENSION', expectedLength, expectedValues, 'bar'), errorId);  % mh:ignore_style
        end

    end

    methods (Test, TestTags = {'integration'})

        function to_struct_of_arrays__happy(Obj, catalogName)
            % GIVEN
            Lib = usain.fastener.CatalogLibrary.get_library();
            CatalogData = Lib.(catalogName);

            % WHEN we convert the catalog data (objects) to static structs
            % THEN
            actual = CatalogData.to_struct_of_arrays();
            Obj.assertInstanceOf(actual, 'struct');
        end

        function validate__passes_for_standard_catalog_file(Obj, catalogName)
            % GIVEN
            Lib = usain.fastener.CatalogLibrary.get_library();
            CatalogData = Lib.(catalogName);

            % WHEN THEN
            f = @() CatalogData.validate();
            Obj.verify_error_free(f);
        end

    end
end
