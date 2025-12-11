classdef Runner_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function test_typeset_job_suffix(Obj)

            % GIVEN Prepare test
            jobNo = 3;
            TestObj = usain.batch.Runner();
            Parsed.zFlange{jobNo} = -12.3;
            TestObj.Parsed = Parsed;

            % WHEN Run test
            jobSuffix = TestObj.typeset_job_suffix(jobNo);

            % THEN Verify
            expectedSuffix = 'FC3_Z-012.300m';
            Obj.verifyEqual(jobSuffix, expectedSuffix);
        end

        function test_get_baseInpFilePath(Obj)

            % GIVEN Prepare test
            expectedName = tempname;

            % WHEN Run test
            TestObj = usain.batch.Runner();
            TestObj.Parsed = struct('usainBaseInpFilePath', '');
            TestObj.Parsed.usainBaseInpFilePath = {expectedName};

            % THEN Verify
            testValue = TestObj.baseInpFilePath;
            Obj.verifyEqual(testValue, expectedName);
        end

        function test_get_iJob(Obj)

            % GIVEN Create and parse dummy input file with variable "myVar"
            testFilePath = Obj.write_dummy_inputfile('zFlange');
            InpObj = InputFile(testFilePath);

            % WHEN Run test
            TestObj = usain.batch.Runner('Inp', InpObj);
            testIJob = TestObj.iJob;

            % THEN Verify
            expectedIdx = [2; 3];
            Obj.verifyEqual(testIJob, expectedIdx);
        end

    end

    methods (Static)

        function testFilePath = write_dummy_inputfile(varName)

            if nargin < 1
                varName = 'myVar';
            end

            % Create _generated folder for storing the files temporarily. If folder is not present, create it
            % using mkdir
            generatedDir = fullfile(fileparts(mfilename('fullpath')), '_generated');
            if ~isfolder(generatedDir)
                mkdir(generatedDir);
            end

            % Write test InputFile file
            [~, tempFileName] = fileparts(tempname); % Get the temporary file name
            testFilePath = fullfile(generatedDir, [tempFileName '_TEST.inp']);

            testFileContent = { ...
                '<START>'
                [varName '(2) : 2']
                [varName '(3) : 3']
                '<END>'};

            fileId = fopen(testFilePath, 'w+');
            fprintf(fileId, '%s\n', testFileContent{:});
            fclose(fileId);
        end

        function Parsed = parse_dummy_inputfile(InpObj, varName)

            if nargin < 2
                varName = 'myVar';
            end

            % Read InputFile and parse variable
            InpObj.add_required(varName, @(x) true, ['Inps.' varName]);
            InpObj.parse();
            InpObj.assign2caller('parsed-only');
            Parsed = Inps;
        end

    end
end
