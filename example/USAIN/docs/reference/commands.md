# User commands

All of the commands below apply to Matlab.

!!! tip
    Click the links in the table above to quickly navigate to the detailed description of a command.

| Command                                                 | Description                                                     |
| ------------------------------------------------------- | --------------------------------------------------------------- |
| [`USAIN.copy_inputfiles`](#copy_inputfiles)             | Copies all default USAIN input files to a specified directory   |
| [`USAIN.do_input_checks`](#do_input_checks)             | Performs pre-run input checks without running the tool          |
| [`USAIN.do_input_checks_batch`](#do_input_checks_batch) | Batch check USAIN overrides input file without running the tool |
| [`USAIN.run`](#run)                                     | Runs USAIN from a given input file                              |
| [`USAIN.run_batch`](#run_batch)                         | Runs USAIN in batch mode from a given overrides input file      |

## `copy_inputfiles`

Copies all default USAIN input files to a specified directory

The syntax from this command is:

=== "Syntax"

    ```matlab
    targetFilePaths = USAIN.copy_inputfiles(targetDir)
    ```

=== "Example"

    ```matlab
    USAIN.copy_inputfiles('c:\my\awesome\project\')
    ```

Where the parameters are defined as:

#### `targetDir`: full file path, optional

:   Target directory where the input file will be stored.

    If not specified, the user will be prompted to specify one.

    If the directory does not exist it will be created.

    !!! note
        Existing files will never be overwritten. For example, if `targetDir` is set to `c:\my\project\` and there is an input file `c:\my\project\USAIN.inp`, the command will copy a new input file to `c:\my\project\USAIN_rev01.inp`.

#### `targetFilePaths`: full file paths, optional

:   Cell array of strings containing the full file paths of the created input file(s).

    See [input file](./inputfile.md) for more information about it.

## `do_input_checks`

Performs pre-run input checks without running the tool.

The syntax from this command is:

=== "Syntax"

    ```matlab
    USAIN.do_input_checks(inputFilePath, doSkipVoid)
    ```

=== "Example"

    ```matlab
    USAIN.do_input_checks('c:\my\awesome\project\InputFile_USAIN.inp')
    ```

Where the parameters are defined as:

#### `inputFilePath`: full file path

:   Full path to filled out USAIN [input file](./inputfile.md).

#### `doSkipVoid`: boolean, optional

:   Flag to skip variables that have a value `<VOID>`.

    This flag is used by `TEXACO`, to skip variables for which no data is present yet.

    For manual runs, it is advised to not use this feature.

## `do_input_checks_batch`

Batch check USAIN overrides input file without running the tool.

The syntax from this command is:

=== "Syntax"

    ```matlab
    USAIN.do_input_checks_batch(inputFilePath, doSkipVoid)
    ```

=== "Example"

    ```matlab
    USAIN.do_input_checks_batch('c:\my\awesome\project\USAIN_BatchRunner.inp')
    ```

Where the parameters are the same as defined for [`do_input_checks`](#do_input_checks).

In this case, the `inputFilePath` must point to a USAIN overrides input file.

## `run`

Runs USAIN from a given input file.

The syntax from this command is:

=== "Syntax"

    ```matlab
    USAIN.run(inputFilePath)
    ```

=== "Example"

    ```matlab
    USAIN.run('c:\my\awesome\project\InputFile_USAIN.inp')
    ```

Where the parameters are defined as:

#### `inputFilePath`: full file path

:   Full file path to USAIN [input file](./inputfile.md).

#### `OutData`: dataclass, optional

:   Container with outputs that could be passed on to the caller function, if any.

    Typically, this is output argument is not needed (it is mainly used by TEXACO).

#### `Obj`: USAIN object, optional

:   USAIN object with content based on run.

    Typically, this is output argument is not needed.

## `run_batch`

Runs USAIN in batch mode from a given overrides input file.

The syntax from this command is:

=== "Syntax"

    ```matlab
    USAIN.run_batch(inputFilePath)
    ```

=== "Example"

    ```matlab
    USAIN.run_batch('c:\my\awesome\project\USAIN_BatchRunner.inp')
    ```

Where the parameters are defined as:

#### `inputFilePath`: full file path

:   Full file path to USAIN [overrides input file](#404).

<!--TODO WPSSD-6762 Provide link to batch run tutorial-->
