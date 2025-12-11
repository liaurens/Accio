function diff_usn(pathA, pathB)
    % Utility to compare .usn or .usn_full files

    assert(isequal(pathlib.Path(pathA).suffix, pathlib.Path(pathB).suffix), 'File extensions must be the same.');

    if pathlib.Path(pathA).suffix == ".usn_full"
        % This is a .usn_full file. Load only the SelectedModel and compare those.
        UsnA = load(pathA, '-mat').UsainData.Mdl;
        UsnB = load(pathB, '-mat').UsainData.Mdl;

        % Some fields are known to differ intentionally. For example, "boltLength" is never set if input "boltOptions"
        % already contains the bolt length
        ignoreFields = ["boltLength", "inputFilePath"];
    else
        % Use the FilePort loader to load the .usn file
        UsnA = usain.io.FilePort().load_file(pathA);
        UsnB = usain.io.FilePort().load_file(pathB);

        % Expect that `structuralModelOutputPath` differs between the two, because every USAIN run writes a
        % StructuralModel to a unique path
        ignoreFields = "structuralModelOutputPath";
    end

    % Compare structs A and B recursively. We'll (ab)use the built-in testing framework to compare structs recursively.
    TestCase = matlab.unittest.TestCase.forInteractiveUse();
    TestCase.assertThat(UsnA, matlab.unittest.constraints.IsEqualTo(UsnB, "IgnoringFields", ignoreFields));

    fprintf('Files are equal!\n');
end
