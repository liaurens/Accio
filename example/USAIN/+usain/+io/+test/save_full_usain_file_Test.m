classdef save_full_usain_file_Test < UsainTest.UsainTestCase % mh:ignore_style

    methods (TestClassSetup)

        function setup_dir(Obj)
            Obj.testDir = fileparts(mfilename('fullpath'));
        end

    end

    methods (Test, TestTags = {'unit'})

        function save_full_usain_file__happy(Obj)
            % GIVEN
            UsainData = struct();
            FilePortPath = pathlib.Path(Obj.testDir) / '_generated' / 'save_full_usain_file__happy.usn';

            % WHEN
            Actual = usain.io.save_full_usain_file(UsainData, FilePortPath);

            % THEN
            Obj.assertClass(Actual, 'pathlib.Path');
            Obj.verifyTrue(Actual.is_file());
            Obj.verifyTrue(Actual.exists());
            Obj.verifyEqual(Actual.suffix, ".usn_full");
        end

        function save_full_usain_file__input_file_extension(Obj)
            % GIVEN two input file paths with no extension or extension other than the expected .usn
            UsainData = struct();
            NoExtension = pathlib.Path(Obj.testDir) / '_generated' / 'foo';
            UnexpectedExtension = pathlib.Path(Obj.testDir) / '_generated' / 'bar.baz';

            % WHEN
            ActualNoExtension = usain.io.save_full_usain_file(UsainData, NoExtension);
            ActualUnexpectedExtension = usain.io.save_full_usain_file(UsainData, UnexpectedExtension);

            % THEN
            Obj.verifyEqual(ActualNoExtension.suffix, ".usn_full");
            Obj.verifyEqual(ActualUnexpectedExtension.suffix, ".usn_full");
        end

        function save_full_usain_file__struct_name(Obj)
            % GIVEN dummy data to save a .usn_full file
            DummyData = struct('Mdl', 'foo');

            % WHEN saving the full file and loading it
            destinationPath = pathlib.Path(Obj.testDir) / '_generated' / 'save_full_usain_file__struct_name.usn';
            Actual = usain.io.save_full_usain_file(DummyData, destinationPath);
            loadedData = load(char(Actual), '-mat');

            % THEN expect field `UsainData` to be loaded
            Obj.verifyTrue(isfield(loadedData, 'UsainData'));
        end

    end
end
