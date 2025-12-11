function OutputPath = save_full_usain_file(UsainData, UsnFilePath)
    % Saves .usn_full (dump) file
    %
    % UsainData: see usain.io.WriteFileStep to understand what should be in there
    % UsnFilePath: a pathlib.Path object for the corresponding .usn file
    % OutputPath: a pathlib.Path object for the written .usn_full file

    UsainData.versionAtSave = USAIN.VERSION;

    % Skip `table` types ('\.Tab$') because `Convert.to_basic_type()` does not support this.
    % Skip linked parents ('\.Parent$') to avoid recursive calles in `Convert.to_basic_type()`.
    % Skip StructuralModel objects because they are too complex for `Convert.to_basic_type()`.
    skipNames = {'\.Tab$', '\.Parent$', '\.StrMdl$'};
    UsainData = Convert.to_basic_type(UsainData, skipNames);

    OutputPath = UsnFilePath.with_suffix('.usn_full');
    save(OutputPath.full_path, 'UsainData', '-v7');
end
