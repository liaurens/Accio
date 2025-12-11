classdef (SharedTestFixtures = {Unittest.fixtures.SilentlyLogWarningsFixture}) ...
        BaseLoader_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function check_and_load_file__happy(Obj)
            % GIVEN a .usn file that mimics a "FilePort" .usn (it only contains the data that is checked in
            % BaseLoader
            p = pathlib.Path(mfilename('fullpath')).parent / 'data' / 'fileport-file_3_3_0.usn';

            % WHEN
            Loader = usain.io.BaseLoader();
            Loader.check_and_load_file(p);

            % THEN
            Obj.assertNotEmpty(Loader.data);
        end

        function check_filepath__file_not_found(Obj)
            % GIVEN a nonexisting file
            p = pathlib.Path([tempname, '.usn']);

            % WHEN, THEN
            Loader = usain.io.BaseLoader();
            Obj.assertError(@() Loader.check_filepath(p), 'BaseLoader:FileNotFound');
            Obj.assertError(@() Loader.check_filepath(char(p)), 'BaseLoader:FileNotFound');
        end

        function check_filepath__wrong_extension(Obj)
            % GIVEN an existing file with an extension other than .usn
            p = pathlib.Path(which(mfilename('class')));  % this file, with .m extension

            % WHEN, THEN
            Loader = usain.io.BaseLoader();
            Obj.assertError(@() Loader.check_filepath(p), 'BaseLoader:WrongExtension');
            Obj.assertError(@() Loader.check_filepath(char(p)), 'BaseLoader:WrongExtension');
        end

        function check_data_format__expect_field(Obj)
            % GIVEN 2 data structures; one with and one without a field called "UsainPort"
            goodData.UsainPort = 1;
            badData.NoUsainPort = 0;

            % WHEN, THEN
            Loader = usain.io.BaseLoader();
            Obj.verify_error_free(@() Loader.check_data_format(goodData));
            Obj.assertError(@() Loader.check_data_format(badData), 'BaseLoader:WrongFormat');
        end

        function check_version__warning_on_mismatch(Obj)
            % GIVEN 2 data structures with versions; one is the same as usain.io.FilePort.FILE_VERSION and one
            % is different
            sameVersion.UsainPort.FILE_VERSION = usain.io.FilePort.FILE_VERSION;
            olderVersion.UsainPort.FILE_VERSION = '0.0.123';

            % WHEN, THEN
            Loader = usain.io.BaseLoader();
            Obj.verify_no_warning_logged(@() Loader.check_version(sameVersion));
            Obj.verify_warning_logged(@() Loader.check_version(olderVersion), 'BaseLoader:WrongVersion');
        end

        function set_data__happy(Obj)
            % GIVEN a data structure in correct format
            fileData.UsainPort.data = struct('neverGonnaGiveYou', 'up');
            fileData.UsainPort.TYPES = struct('neverGonnaGiveYou', 'str');

            % WHEN, THEN
            Loader = usain.io.BaseLoader();
            Obj.assertEmpty(Loader.data);
            Loader.set_data(fileData);
            Obj.assertNotEmpty(Loader.data);
        end

    end
end
