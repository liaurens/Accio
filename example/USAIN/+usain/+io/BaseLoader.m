classdef BaseLoader < logging.Config

    properties
        data struct  % Verified data, loaded from file
    end

    methods

        function Obj = BaseLoader(file)
            if nargin
                Obj.check_and_load_file(file);
            end
        end

        function check_and_load_file(Obj, file)
            % Loads usain.io.FilePort file and verifies loaded content
            Obj.check_filepath(file);
            fileData = Obj.load(file);
            Obj.check_data_format(fileData);
            Obj.check_version(fileData);
            Obj.set_data(fileData);
        end

        function check_filepath(Obj, file)
            File = pathlib.Path(file);
            Obj.assert(File.is_file(), 'BaseLoader:FileNotFound', 'The input USAIN file is not found.');
            Obj.assert(File.suffix == ".usn", 'BaseLoader:WrongExtension', ...
                'The input USAIN file must have extension ".usn".');
        end

        function fileData = load(~, file)
            fileData = load(pathlib.Path(file).full_path(), '-mat');
        end

        function check_data_format(Obj, fileData)
            % Verifies if loaded file has the usain.io.FilePort data structure

            Obj.assert(isfield(fileData, 'UsainPort'), 'BaseLoader:WrongFormat', ...
                'Expected field "UsainPort" in loaded file.');
        end

        function check_version(Obj, fileData)
            % Checks version of loaded usain.io.FilePort data Upon version mismatch, we report the mismatch in
            % the USAIN tool version. This is because we don't want to bother users with file versions, only
            % with tool versions.

            actualVersion = tracking.SemanticVersion(fileData.UsainPort.FILE_VERSION);
            expectedVersion = tracking.SemanticVersion(usain.io.FilePort.FILE_VERSION);
            if actualVersion ~= expectedVersion
                Obj.warning('BaseLoader:WrongVersion', ...
                    ['The version of the loaded .usn file is outdated. Functionality may be impaired. ', ...
                    'Make sure to use the latest USAIN version (%s).'], USAIN.VERSION);
            end

        end

        function set_data(Obj, fileData)
            Obj.data = fileData.UsainPort.data;
        end

    end
end
