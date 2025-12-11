classdef CatalogReader_Test < Unittest.TestCase

    methods (TestClassSetup)

        function setup_dir(Obj)
            Obj.testDir = fileparts(mfilename('fullpath'));
        end

    end

    methods (Test, TestTags = {'integration'})

        function construction__happy_case(Obj)
            % GIVEN a file path to a correct, uniform catalog file
            yamlPath = Obj.get_file_path(['_data\' 'dummy_catalog_happy.yml']);

            % WHEN THEN
            usain.fastener.CatalogReader('sourcePath', yamlPath, 'uniformFields', true);
        end

        function construction__non_uniform_error(Obj)
            % GIVEN a file path to a correct, uniform catalog file
            yamlPath = Obj.get_file_path(['_data\' 'dummy_catalog_nonuniform.yml']);

            % WHEN calling with uniformFields = false
            % THEN expect no error
            usain.fastener.CatalogReader('sourcePath', yamlPath, 'uniformFields', false);

            % WHEN calling with uniformFields = true
            % THEN expect error
            f = @() usain.fastener.CatalogReader('sourcePath', yamlPath, 'uniformFields', true);
            Obj.assertError(f, 'CatalogReader:NonUniformData');
        end

    end

    methods (Test, TestTags = {'unit'})

        function check_required_fields__missing_fields_error(Obj)
            % GIVEN a mimicked parsed catalog file
            Test = usain.fastener.CatalogReader();
            Test.parsed = struct();
            Test.parsed.data.hello = 'world';
            Test.parsed.data.test = 12;

            % WHEN
            requiredFields = {'hello', 'test', 'notpresent'};
            f = @() Test.check_required_fields(requiredFields);

            % THEN
            expect = 'CatalogReader:MissingRequiredFields';
            Obj.assertError(f, expect);

            % Test case sensitivity
            Obj.assertError(@() Test.check_required_fields({'hello', 'TEST'}), expect);
        end

    end
end
