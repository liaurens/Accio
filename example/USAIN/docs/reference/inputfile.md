# Input file description

This section describes the USAIN input file, with a focus on the *main inputs*. Besides these, there are [expert inputs](../reference/expert-inputs.md) which should be used with caution.

The input file has the following field groups:

- [Flange geometry](#flange-geometry)
- [Design space](#design-space)
- [Bolt related](#bolt-related)
- [Loads](#loads)
- [Miscellaneous](#miscellaneous)
- [Outputs settings](#outputs-settings)

## Flange geometry

The flange geometry inputs can either be derived from a StructuralModel file or manually specified.
For commercial project work it is often preferred to provide a StructuralModel rather than manual specification of the flange geometry, because this ensures that the flange design is compliant with the rest of the structure. For studies, the manual inputs could prove useful.

The following inputs are part of this section.

=== "Input parameters"

    ```yaml
    structureInpFilePath              :
    flangeType                        :
    zFlange                           :
    diameter                          :
    diameterReference                 :
    thicknNoseUp                      :
    thicknNoseLo                      :
    heightNoseUp                      :
    heightNoseLo                      :
    ```

=== "Typical inputs with StructuralModel"

    ```yaml
    structureInpFilePath              : c:\my-project\strmdl.xlsm
    flangeType                        :
    zFlange                           : -12.34
    diameter                          :
    diameterReference                 :
    thicknNoseUp                      :
    thicknNoseLo                      :
    heightNoseUp                      :
    heightNoseLo                      :
    ```

    *When setting input `structureInpFilePath`, most of the info can be derived from the StructuralModel data.
    In case of a mismatch between a value derived from StructuralModel and a USAIN input, the latter is used.*

=== "Typical inputs without StructuralModel"

    ```yaml
    structureInpFilePath              :
    flangeType                        : L
    zFlange                           : -12.34
    diameter                          : 7500
    diameterReference                 :
    thicknNoseUp                      : 55
    thicknNoseLo                      : 60
    heightNoseUp                      :
    heightNoseLo                      :
    ```

    *When leaving input `structureInpFilePath` empty, the flange geometry must be specified manually.*


#### `structureInpFilePath`: full file path

:   StructuralModel file (file extension: .xlsm or .mat).

    Valid values: full file path.

    Example of `structureInpFilePath`:

    ```yaml
    structureInpFilePath: c:\my-project\strmdl.xlsm
    ```

    - `StructuralModel.help`
    - <a href="https://siemensgamesa.sharepoint.com/teams/IP000BC/Shared%20Documents/Forms/AllItems.aspx?csf=1&web=1&e=gWJqbk&cid=ed3abf07%2D1676%2D4b45%2Da887%2D2caa0456baa8&RootFolder=%2Fteams%2FIP000BC%2FShared%20Documents%2F%5FToolDocumentation%2FTool%5Ftraining%2FLegacyFO%5FPostSummerSchool&FolderCTID=0x0120009C4737F294E81B41885BE1266F292C28">Post summer school tutorials (sharepoint)</a>

#### `site`: string

:   Type of site for which the flange is to be designed/checked.

    Valid values: `onshore`, `offshore`

#### `flangeType`: string, optional

:   Type of flange to be designed/checked. If not set, value from StructuralModel is taken.
    USAIN supports both L-flanges and T-flanges.

    Valid values: `L`, `T`

    ??? info "Automatic switch from L- to T-flange?"

        See the [automatic switch from L- to T-flange](../explanation/t-flanges.md#automatic-switch-from-l-flange-to-t-flange) section to see how this inputs will be manipulated if such a switch is perfomed.

#### `zFlange`: number

:   Flange elevation level in StructuralModel's coordinate system (0m @ LAT, positive z downward)

    Units: [m].

#### `diameter`: number, optional

:   Diameter of flange used as starting point for the design. See [`diameterReference`](#diameterreference-string-optional) for more information.
    If not set, the outer diameter of the upper connecting plate from StructuralModel is taken.

    Units: [mm].

#### `diameterReference`: string, optional

:    Diameter reference point.

     Valid values: `outneck`, `outermost`

     USAIN can design flanges considering a different fixed reference point, either the outer diameter at the flange neck, or the outermost diameter of the flange.
     Only relevant in case of T-flanges.

#### `thicknNoseUp`: number, optional

:   Thickness of upper flange neck. If not set, value from StructuralModel is taken.

    Units: [mm].

#### `thicknNoseLo`: number, optional

:   Thickness of lower flange neck. If not set, value from StructuralModel is taken.

    Units: [mm].

#### `heightNoseUp`: number, optional

:   Height of upper flange neck. Computed internally if not set.

    Units: [mm]

#### `heightNoseLo`: number, optional

:   Height of lower flange neck. Computed internally if not set.

    Units: [mm]

## Design space

!!! info inline end "More info"
    For more information on how USAIN sets up and handles the design space please revert to the [design space explanation](../explanation/design-space.md) page.

USAIN finds an optimal design by first setting up a *design space* with all possible combinations of:

* Flange width
* Flange thickness
* Number of bolts
* Bolt option

This section gives an overview of the inputs that can be used to control the design space.

The following inputs are part of this section.

=== "Input parameters"

    ```yaml
    boltOptions                       :
    minNBolts                         :
    maxNBolts                         :
    minFlangeWidth                    :
    maxFlangeWidth                    :
    minFlangeThickn                   :
    maxFlangeThickn                   :
    ```

=== "Typical inputs for design run"

    ```yaml
    boltOptions                       : ISO_M64 ISO_M72
    minNBolts                         : 112
    maxNBolts                         : 140
    minFlangeWidth                    : 250
    maxFlangeWidth                    :
    minFlangeThickn                   : 130
    maxFlangeThickn                   :
    ```

    *To design a new flange connection, use engineering judgement to set the design space limits.
    A smaller design space will mean that USAIN runs faster.*

=== "Typical inputs for check run"

    ```yaml
    boltOptions                       : ISO_M64x480
    minNBolts                         : 156
    maxNBolts                         : 156
    minFlangeWidth                    : 325
    maxFlangeWidth                    : 325
    minFlangeThickn                   : 151
    maxFlangeThickn                   : 151
    ```

    *For a check run, provide a single bolt option (with length) and set the upper and lower bounds of the other design variables to the same value:*

#### `boltOptions`: (list of) string(s)

:   Bolt option(s) to be included in analysis.

    A bolt option is a combination of series, nominal diameter and optionally bolt length and thread length.

    Examples of `boltOptions`:

    === "Only series and diameter"

        ```yaml
        boltOptions: ISO_M64
        ```

        *To take all standard bolt lengths for given diameter.*

    === "With length"

        ```yaml
        boltOptions: ISO_M64x480
        ```

        *To specify a single diameter & bolt length combination (standard thread length will be taken).*

    === "With thread length"

        ```yaml
        boltOptions: ISO_M64x480x123
        ```

        *To specify a single diameter & bolt length combination and a (non-standard) thread length.*

    === "Multiple options"

        ```yaml
        boltOptions: ISO_M64x480 ISO_M72
        ```

        *Separate options by one or more spaces.*

#### `minNBolts`: number, optional

:   Minimum number of bolts. Computed/determined internally if not set, otherwise specify either single value or one for each bolt option.

#### `maxNBolts`: number, optional

:   Maximum number of bolts. Computed/determined internally if not set, otherwise specify either single value or one for each bolt option.

#### `minFlangeWidth`: number, optional

:   Minimum flange width. Computed/determined internally if not set, otherwise specify either single value or one for each bolt option.

    Specify the design value, i.e. excluding allowance.

    Units: [mm].

    ??? info "Automatic switch from L- to T-flange?"

        See the [automatic switch from L- to T-flange](../explanation/t-flanges.md#automatic-switch-from-l-flange-to-t-flange) section to see how this inputs will be manipulated if such a switch is perfomed.

#### `maxFlangeWidth`: number, optional

:   Maximum flange width. Computed/determined internally if not set, otherwise specify either single value or one for each bolt option.

    Specify the design value, i.e. excluding allowance.

    Units: [mm].

    ??? info "Automatic switch from L- to T-flange?"

        See the [automatic switch from L- to T-flange](../explanation/t-flanges.md#automatic-switch-from-l-flange-to-t-flange) section to see how this inputs will be manipulated if such a switch is perfomed.

#### `minFlangeThickn`: number, optional

:   Minimum flange thickness. Computed/determined internally if not set, otherwise specify either single value or one for each bolt option.

    Specify the design value, i.e. excluding allowance.

    Units: [mm].

#### `maxFlangeThickn`: number, optional

:   Maximum flange thickness. Computed/determined internally if not set, otherwise specify either single value or one for each bolt option.

    Specify the design value, i.e. excluding allowance.

    Units: [mm].

## Bolt related

The following inputs are part of this section.

=== "Input parameters"

    ```yaml
    tighteningMethod                  :
    diamBoltHole                      :
    diamBoltCircle                    :
    lengthBoltExtender                :
    ```

=== "Typical inputs for design run"

    ```yaml
    tighteningMethod                  : tension
    diamBoltHole                      :
    diamBoltCircle                    :
    lengthBoltExtender                : 0
    ```

    *Empty inputs will internally be replaced by defaults from a catalog.*

=== "Typical inputs for check run"

    ```yaml
    tighteningMethod                  : torque
    diamBoltHole                      : 78
    diamBoltCircle                    : 7432
    lengthBoltExtender                : 12
    ```

    *For a check run, provide inputs for a single [bolt option](#boltoptions-list-of-strings).
    It's good practice to explicitly specify all inputs, to prevent USAIN from using unintended default values.*

#### `tighteningMethod`: string, required

:   Tightening method.

    Valid values: `torque`, `tension`

    Specify either single value or one for each bolt option.

#### `diamBoltHole`: number, optional

:   Diameter of bolt hole.

    Units: [mm]

    This input parameter can be used to specify enlarged bolt holes.
    If not set, the default for each bolt option will be used.
    Otherwise, specify either single value or one for each bolt option.

#### `diamBoltCircle`: number, optional

:   Diameter of bolt circle diameter.

    Units: [mm]

    Computed/determined internally if not set, otherwise specify either single value or one for each bolt option.

#### `lengthBoltExtender`: number, optional

:   Bolt extender length.

    Units: [mm]

    Computed/determined internally if not set, otherwise specify either a single value or one value for each bolt option.
    The default is to leave the field empty, this allows bolt extenders to be included. However, it's expected not to use bolt extenders.
    Therefore it's expected to provide a value 0 as input, since this will ensure the bolt extender not to be considered in the design.

## Loads

The following inputs are part of this section.
To define multiple load sets, you can copy-and-paste the entire block.
At least the fields documented on this page must be present for each block in the input file.

!!! info "Optional or required"

    (Most of) the inputs in this section are defined as **optional**.
    This means that the inputs need not be given a value: If no value is set in the input file, a default value will be used.

    Still, all optional inputs must be present in a `Loads` block.
    If this is not the case, USAIN will exit with an error message that states which subfields are missing.

=== "Single load set"

    ```yaml
    Loads.tag                         : DeepSoft
    Loads.flsFilePath                 : c:\my-project\bhwac_fatigue_loads_forTLD.scm
    Loads.flsScalingFactor            : 1.05 1.05
    Loads.flsScalingLevel             : -200  200
    Loads.S1FilePath                  : .\relative\paths\allowed.mat
    Loads.S1ScalingFactor             : 1.02 1.03
    Loads.S1ScalingLevel              : -200  200
    Loads.ulsFilePath                 : c:\my-project\any-ultimate-loads.mat
    Loads.ulsScalingFactor            : 1.12 1.34
    Loads.ulsScalingLevel             : -200  200
    Loads.inclinationValue            : 0.75
    Loads.inclinationValueFls         : 0.125
    Loads.inclinationUnit             : deg
    Loads.dlcFilter                   :
    ```

=== "Multiple load sets"

    ```yaml
    Loads.tag                         : DeepSoft
    Loads.flsFilePath                 : c:\my-project\bhwac_fatigue_loads_forTLD.scm
    Loads.flsScalingFactor            : 1.05 1.05
    Loads.flsScalingLevel             : -200  200
    Loads.S1FilePath                  : .\relative\paths\allowed.mat
    Loads.S1ScalingFactor             : 1.02 1.03
    Loads.S1ScalingLevel              : -200  200
    Loads.ulsFilePath                 : c:\my-project\any-ultimate-loads.mat
    Loads.ulsScalingFactor            : 1.12 1.34
    Loads.ulsScalingLevel             : -200  200
    Loads.inclinationValue            : 0.75
    Loads.inclinationValueFls         : 0.125
    Loads.inclinationUnit             : deg
    Loads.dlcFilter                   :

    Loads.tag                         : hurricane
    Loads.flsFilePath                 : 'c:\my-project\bhwac fatigue loads_forTLD.scm'
    Loads.flsScalingFactor            : 1.00 1.00
    Loads.flsScalingLevel             : -200  200
    Loads.S1FilePath                  : 'c:\my-project\some-s1-loads.mat'
    Loads.S1ScalingFactor             : 1.00 1.00
    Loads.S1ScalingLevel              : -200  200
    Loads.ulsFilePath                 : c:\my-project\hurricane-ultimate-loads.meat
    Loads.ulsScalingFactor            : 1.12 1.34
    Loads.ulsScalingLevel             : -200  200
    Loads.inclinationValue            : 0.75
    Loads.inclinationValueFls         : 0.125
    Loads.inclinationUnit             : deg
    Loads.dlcFilter                   : DLCI
    ```

    *Optionally, one can append the `Loads.` blocks with indices between brackets.
    That is, `Loads(1).` for the first block, etc.*

#### `Loads.tag`: string, optional

:   Event tag to indicate different ULS subsets.

    Any string can me input, but some strings trigger additional functionality:

    * `seismic` → Robustness check for APAC region [IEC 61400-1 (seismic, section 11.6)]
    * `hurricane` → Robustness check for US region [IEC 61400-3 ed. 4 (hurricane, Annex I)]
    * `shortTerm`, `longTerm`, `seismic` in combination with [`countryCode`](#countrycode-string-optional) set to `JPN` → See the [Japan specific reference page](../reference/Japan-design.md)

    When a robustness check is triggered, some partial safety factors will be set to 1.0. For more information, see the [robustness check reference page](#404)

<!-- TODO: Link to robustness check reference page -->

#### `Loads.flsFilePath`: full file path, optional

:   File path to FLS loads file.

    The input can be left empty if no calculations using fatigue loads are required.

    Only BHawC loads are supported (`*.scm` or `*.mkv` files), because Markov matrices are required (due to the nonlinear transfer function of applied loads to bolt loads).

    ??? question "Which file type should I use for my run?"

        The `*.scm` file is the preferred input, this contains info regarding all relevant Markov matrices for the structure and their corresponding z-levels.
        This also allows for interpolation between Markov matrices, which is relevant for initial design using scaled loads.

        It is possible to provide a single Markov matrix file (being a `*.mkv` file), however this assumes that the flange z-level matches exactly with that of the Markov matrix.

#### `Loads.flsScalingFactor`: vector of numbers, optional

:   Contingency factor applied on fatigue loads.

    This input is to be used in combination with [`Loads.flsScalingLevel`](#loadsflsscalinglevel-vector-of-numbers-optional).
    The length of both input vectors must be the same.
    Scaling factors are linearly interpolated between sample points. Extrapolation is not allowed.

#### `Loads.flsScalingLevel`: vector of numbers, reference levels, optional

:   Levels for contingency factor applied on fatigue loads.

    This input is to be used in combination with [`Loads.flsScalingFactor`](#loadsflsscalinglevel-vector-of-numbers-optional).
    The length of both input vectors must be the same.

    Scaling factors are linearly interpolated between sample points. Extrapolation is applied if needed.
    Reference levels inputs like 'towerTop' or 'interface' are also allowed if a Structural Model is provided.

#### `Loads.S1FilePath`: full file path, optional

:   File path to S1 loads file.

    The input can be left empty if no calculations using S1 loads are required.

    If expert input [`S1_BENDING_MOMENT`](./expert-inputs.md#s1_bending_moment-number) is set, the S1 file(s) input here are ignored.

    If neither this input nor [`S1_BENDING_MOMENT`](./expert-inputs.md#s1_bending_moment-number) is set, the SLS conditions will be assessed using the maximum FLS moment.
    This may be acceptable for studies, but not for official designs.

    Only BHawC loads are supported (`*.mat` files).

#### `Loads.S1ScalingFactor`: vector of numbers, optional

:   Contingency factor applied on fatigue loads.

    If set in input file, scaling factors must be ≥ 0.1 and ≤ 3.0.

    This input is to be used in combination with [`Loads.S1ScalingLevel`](#loadss1scalinglevel-vector-of-numbers-optional).
    The length of both input vectors must be the same.
    Scaling factors are linearly interpolated between sample points. Extrapolation is not allowed.

    If expert input [`S1_BENDING_MOMENT`](./expert-inputs.md#s1_bending_moment-number) is set, the S1 scaling factors are ignored.

#### `Loads.S1ScalingLevel`: vector of numbers, reference levels, optional

:   Levels for contingency factor applied on fatigue loads.

    This input is to be used in combination with [`Loads.S1ScalingFactor`](#loadss1scalinglevel-vector-of-numbers-optional).
    The length of both input vectors must be the same.

    Scaling factors are linearly interpolated between sample points. Extrapolation is applied if needed.
    Reference levels inputs like 'towerTop' or 'interface' are also allowed if a Structural Model is provided.

#### `Loads.ulsFilePath`: full file path, optional

:   File path to ULS loads file.

    The input can be left empty if no calculations using ULS loads are required.

    Loads from various sources are supported:
    * MEATLOAF: .meat files
    * BHawC: circle and threshold or contemporaneous load files

#### `Loads.ulsScalingFactor`: vector of numbers, optional

:   Contingency factor applied on ULS loads.

    This input is to be used in combination with [`Loads.ulsScalingLevel`](#loadsulsscalinglevel-vector-of-numbers-optional).
    The length of both input vectors must be the same.

    Scaling factors are linearly interpolated between sample points. Extrapolation is applied if needed.

#### `Loads.ulsScalingLevel`: vector of numbers, reference levels, optional

:   Levels for contingency factor applied on ULS loads.

    This input is to be used in combination with [`Loads.ulsScalingFactor`](#loadsulsscalinglevel-vector-of-numbers-optional).
    The length of both input vectors must be the same.
    Scaling factors are linearly interpolated between sample points. Extrapolation is not allowed.
    Reference levels inputs like 'towerTop' or 'interface' are also allowed if a Structural Model is provided.

#### `Loads.inclinationValue`: number, optional

:   Inclination value, for which to compute inclination loads.

    The unit of the inclination value is given by the value of [Loads.inclinationUnit](#loadsinclinationunit-string-optional).

    The internally computed inclination loads are superimposed on applied ULS overturning moments.
    Hence if the applied loads already include inclination effects, set this input to 0, or leave empty.

    This input can only be used if a StructuralModel is provided in input [`structureInpFilePath`](#structureinpfilepath-full-file-path).

#### `Loads.inclinationValueFls`: number, optional

:   Inclination value, for which to compute inclination loads to be used for FLS assessments.

    See [`Loads.inclinationValue`](#loadsinclinationvalue-number-optional).
    The only difference is that this input is used for FLS assessments.

    For onshore flange design, this value should typically be set to 0 (according to IEC 61400-6/AMD1).

    For offshore flange design, this value should typically be set to 0.125°.
    This reflects 50% of the inclination due to maximum expected settlement from operation accumulated over lifetime (requirement from IEC 61400-6/AMD1).

#### `Loads.inclinationUnit`: string, optional

:   Unit for the [inclination value](#loadsinclinationvalue-number-optional).

    Valid values: `deg`, `mm_m` (case insensitive, default is `deg`)

    Note that `mm_m` is only valid for small angles, hence the default `deg` is preferred as input.

#### `Loads.dlcFilter`: string, optional

:   Filter to be applied on DLC names in ULS loads file to select subset of ULS loads.

    Leave empty to include all DLCs.
    For more information on how to used this filtering, see the [DLC filtering reference page](#404).

<!-- TODO: Link to DLC filtering reference page -->

## Miscellaneous

The following inputs are part of this section.

=== "Input parameters"

    ```yaml
    countryCode                       :
    ```

=== "Design for Japanese market"

    ```yaml
    countryCode                       : JPN
    ```

#### `countryCode`: string, optional

:   3-letter country code to indicate wind farm site location, for country specific rules and regulations.

    Valid values: `ROW`, `JPN` (case insensitive, default is `ROW`)

    * `ROW` = Rest of the world - "State-of-the-art", according to SGRE design brief
    * `JPN` = Japan - Include specific ULS failure mode calculations.

## Outputs settings

The output settings control where results are stored and how the tool run is named.
The following inputs are part of this section:

```yaml
targetDir                         :
runName                           :
```

#### `targetDir`: full path, optional

:   Output directory for result files

    If not set, a folder named `Res` will be created in the same directory as the input file.
    If this folder already exists, the existing folder content will not be removed.
    Result files are never overwritten.

#### `runName`: string, optional

:   Name of USAIN run.

    Although this input is optional, it is advised to name every run in a concise yet descriptive manner.

    The run name will be appended to the result files that are saved at the end of a USAIN run.
    Existing files will never be overwritten.
