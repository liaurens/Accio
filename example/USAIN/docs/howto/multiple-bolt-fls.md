# Perform multiple bolt fatigue assessments in a single USAIN run

In this how-to guide, we explain how to perform multiple bolt fatigue assessments using different bolt force models.
Please revert to the [version 3.8.0 notes](../about/version-notes.md#380) for background information.

## Inputs

In this section the relevant inputs for one or multiple bolt fatigue assessments are described.
The relevant inputs are grouped in a "block" and therefore all starting with `BoltFls`.
To define multiple assessments copy/paste the entire block for each additional assessment.

=== "Single bolt fatigue set"

    ```yaml
    BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
    BoltFls.CUSTOM_PRELOAD          :
    BoltFls.PRELOAD_LOSS_FACTOR_FLS :
    BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
    BoltFls.SN_CURVE_BOLT           : EC3_DC36*
    BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
    BoltFls.TARGET_PM_SUM           : 0.90
    ```

=== "Multiple bolt fatigue sets"

    ```yaml
    BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
    BoltFls.CUSTOM_PRELOAD          :
    BoltFls.PRELOAD_LOSS_FACTOR_FLS :
    BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
    BoltFls.SN_CURVE_BOLT           : EC3_DC36*
    BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
    BoltFls.TARGET_PM_SUM           : 0.90

    BoltFls.BOLT_FORCE_MODEL        : sgre2
    BoltFls.CUSTOM_PRELOAD          :
    BoltFls.PRELOAD_LOSS_FACTOR_FLS :
    BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
    BoltFls.SN_CURVE_BOLT           : EC3_DC50
    BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
    BoltFls.TARGET_PM_SUM           : 1.00
    ```

!!! note "Activate FLS assessment"
    Since the assessment relates to bolt fatigue, it is required to set `DO_ASSESS_FLS = true`.
    This is done by default.

Next to the bolt fatigue assessment there are other assessments which require the preload value:

- `FlangeGapping.CUSTOM_PRELOAD` (default: empty)
- `SlsPretension.CUSTOM_PRELOAD` (default: empty)
- `FlangeNeckScf.CUSTOM_PRELOAD` (default: empty)

### Preload selection

This section describes how the expert input for the (custom) preload is used within USAIN and how it should be defined for the separate assessments.
A distinction is made between the `BoltFls` block(s) and the other three assessments, being `FlangeGapping`, `SlsPretention` and `FlangeNeckScf`.
These three assessments are expected to all have the same (custom) preload defined and this value should be matching to the value of one of the `BoltFls` assessments.

??? info "Examples of the equality condition of the other assessments"

    === "Uniform"

        ```yaml
        FlangeGapping.CUSTOM_PRELOAD : 1234
        SlsPretension.CUSTOM_PRELOAD : 1234
        FlangeNeckScf.CUSTOM_PRELOAD : 1234
        ```
        This is <span style="color:green">OK</span> since all have an equal value defined.

    === "Empty"

        ```yaml
        FlangeGapping.CUSTOM_PRELOAD :
        SlsPretension.CUSTOM_PRELOAD :
        FlangeNeckScf.CUSTOM_PRELOAD :
        ```
        This is <span style="color:green">OK</span> since all are not defined, which would indicate that the default value from the catalog would be used.

    === "Partially defined"

        ```yaml
        FlangeGapping.CUSTOM_PRELOAD : 1234
        SlsPretension.CUSTOM_PRELOAD : 1234
        FlangeNeckScf.CUSTOM_PRELOAD :
        ```
        This is <span style="color:red">not OK</span> and will result in an error, it is expected to all be defined.

    === "Non-uniform"

        ```yaml
        FlangeGapping.CUSTOM_PRELOAD : 1234
        SlsPretension.CUSTOM_PRELOAD : 2345
        FlangeNeckScf.CUSTOM_PRELOAD : 2345
        ```
        This is <span style="color:red">not OK</span> and will result in an error, it is expected that they're all equal.

As indicated before, in addition to these other assessment having to be equal to each other, the value should match with one of the `BoltFls` assessment blocks.
There are four scenarios possible:

1. None of the `BoltFls` blocks nor the other three have `CUSTOM_PRELOAD` defined.
2. None of the `BoltFls` blocks has `CUSTOM_PRELOAD` defined, the other three have `CUSTOM_PRELOAD` defined.
3. At least one `BoltFls` blocks does not have `CUSTOM_PRELOAD` defined, the other three are not defined.
4. At least one `BoltFls` blocks has `CUSTOM_PRELOAD` defined and the other three are defined.

#### 1. None of the `BoltFls` blocks nor the other three have `CUSTOM_PRELOAD` defined

In this scenario the default preload value will be extracted from the [fastener properties table](../reference/fastener-props.md#tightening-tools) and applied for each assessment.

??? info "Example of this scenario"

    ```yaml
    BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
    BoltFls.CUSTOM_PRELOAD          :
    BoltFls.PRELOAD_LOSS_FACTOR_FLS :
    BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
    BoltFls.SN_CURVE_BOLT           : EC3_DC36*
    BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
    BoltFls.TARGET_PM_SUM           : 0.90

    BoltFls.BOLT_FORCE_MODEL        : sgre2
    BoltFls.CUSTOM_PRELOAD          :
    BoltFls.PRELOAD_LOSS_FACTOR_FLS :
    BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
    BoltFls.SN_CURVE_BOLT           : EC3_DC50
    BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
    BoltFls.TARGET_PM_SUM           : 1.00

    % ...

    FlangeGapping.CUSTOM_PRELOAD    :
    SlsPretension.CUSTOM_PRELOAD    :
    FlangeNeckScf.CUSTOM_PRELOAD    :
    FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS :
    ```

#### 2. None of the `BoltFls` blocks has `CUSTOM_PRELOAD` defined, the other three have `CUSTOM_PRELOAD` defined

This scenario will result in an error, as `CUSTOM_PRELOAD` for the other three assessments are expected to be empty as well.
The error is thrown even when the provided value matches with the value which would be extracted from the bolt catalog.
This is done to have a cleaner and more easy implementation for an edge case.

??? info "Examples of this scenario"

    === "Example 1"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS :
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 0.90

        BoltFls.BOLT_FORCE_MODEL        : sgre2
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS :
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
        BoltFls.TARGET_PM_SUM           : 1.00

        % ...

        FlangeGapping.CUSTOM_PRELOAD    : 1234
        SlsPretension.CUSTOM_PRELOAD    : 1234
        FlangeNeckScf.CUSTOM_PRELOAD    : 1234
        FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS : 0.90
        ```
        This will result in an error, it is expected that none of the other three have `CUSTOM_PRELOAD` defined.

    === "Example 2"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS :
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 0.90

        BoltFls.BOLT_FORCE_MODEL        : sgre2
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS :
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
        BoltFls.TARGET_PM_SUM           : 1.00

        % ...

        FlangeGapping.CUSTOM_PRELOAD    : 1234
        SlsPretension.CUSTOM_PRELOAD    : 1234
        FlangeNeckScf.CUSTOM_PRELOAD    :
        FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS :
        ```
        This will result in an error, it is expected that none of the other three have `CUSTOM_PRELOAD` defined.
        Additionally, when values would be provided for the other three it is expected to all be defined.

    === "Example 3"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS :
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 0.90

        BoltFls.BOLT_FORCE_MODEL        : sgre2
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS :
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
        BoltFls.TARGET_PM_SUM           : 1.00

        % ...

        FlangeGapping.CUSTOM_PRELOAD    : 1234
        SlsPretension.CUSTOM_PRELOAD    : 2345
        FlangeNeckScf.CUSTOM_PRELOAD    : 2345
        FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS : 0.90
        ```
        This will result in an error, it is expected that none of the other three have `CUSTOM_PRELOAD` defined.
        Additionally, when values would be provided for the other three it is expected that they're all equal.

#### 3. At least one `BoltFls` blocks does not have `CUSTOM_PRELOAD` defined, the other three are not defined

The `BoltFls` block with `CUSTOM_PRELOAD` defined will obviously use that `CUSTOM_PRELOAD` in the bolt fatigue assessment.
The other `BoltFls` blocks which do not have the `CUSTOM_PRELOAD` defined will extract the default value from the [fastener properties table](../reference/fastener-props.md#tightening-tools).
The other assessments will also extract the default value from the [fastener properties table](../reference/fastener-props.md#tightening-tools).

??? info "Example of this scenario"

    ```yaml
    BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
    BoltFls.CUSTOM_PRELOAD          :
    BoltFls.PRELOAD_LOSS_FACTOR_FLS :
    BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
    BoltFls.SN_CURVE_BOLT           : EC3_DC36*
    BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
    BoltFls.TARGET_PM_SUM           : 0.90

    BoltFls.BOLT_FORCE_MODEL        : sgre2
    BoltFls.CUSTOM_PRELOAD          : 1234
    BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.90
    BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
    BoltFls.SN_CURVE_BOLT           : EC3_DC50
    BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
    BoltFls.TARGET_PM_SUM           : 1.00

    % ...

    FlangeGapping.CUSTOM_PRELOAD    :
    SlsPretension.CUSTOM_PRELOAD    :
    FlangeNeckScf.CUSTOM_PRELOAD    :
    FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS :
    ```
    Here the other three assessments would be linked to the first block containing the SchmidtNeuper model.

#### 4. At least one `BoltFls` blocks has `CUSTOM_PRELOAD` defined and the other three are defined

In this scenario USAIN assumes that one of the `BoltFls` blocks which has the `CUSTOM_PRELOAD` defined will correspond to the other three assessments.
The `CUSTOM_PRELOAD` provided for the other three assessment must be identical each other and to (at least) one of the `BoltFls` block.
It is allowed that multiple or all `BoltFls` blocks contain a value (even the same), as long as there would be a match with the other three assessments.
If there is not a match an error is thrown.
For undefined `BoltFls` block the default preload will be extracted from the catalog and applied.

??? info "Examples of this scenario"

    === "Example 1"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS :
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 0.90

        BoltFls.BOLT_FORCE_MODEL        : sgre2
        BoltFls.CUSTOM_PRELOAD          : 1234
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.90
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
        BoltFls.TARGET_PM_SUM           : 1.00

        % ...

        FlangeGapping.CUSTOM_PRELOAD    : 1234
        SlsPretension.CUSTOM_PRELOAD    : 1234
        FlangeNeckScf.CUSTOM_PRELOAD    : 1234
        FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS : 0.90
        ```
        Here the other three assessments would be linked to the second block containing the `sgre2` model.

    === "Example 2"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          : 1234
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.90
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 0.90

        BoltFls.BOLT_FORCE_MODEL        : sgre2
        BoltFls.CUSTOM_PRELOAD          : 4321
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.90
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
        BoltFls.TARGET_PM_SUM           : 1.00

        % ...

        FlangeGapping.CUSTOM_PRELOAD    : 1234
        SlsPretension.CUSTOM_PRELOAD    : 1234
        FlangeNeckScf.CUSTOM_PRELOAD    : 1234
        FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS : 0.90
        ```
        Here the other three assessments would be linked to the first block containing the SchmidtNeuper model.

    === "Example 3"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          : 1234
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.90
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 0.90

        BoltFls.BOLT_FORCE_MODEL        : sgre2
        BoltFls.CUSTOM_PRELOAD          : 4321
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.90
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
        BoltFls.TARGET_PM_SUM           : 1.00

        % ...

        FlangeGapping.CUSTOM_PRELOAD    : 4321
        SlsPretension.CUSTOM_PRELOAD    : 4321
        FlangeNeckScf.CUSTOM_PRELOAD    : 4321
        FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS : 0.90
        ```
        Here the other three assessments would be linked to the second block containing the `sgre2` model.

    === "Example 4"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          : 1234
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.90
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 0.90

        BoltFls.BOLT_FORCE_MODEL        : sgre2
        BoltFls.CUSTOM_PRELOAD          : 1234
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.90
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
        BoltFls.TARGET_PM_SUM           : 1.00

        % ...

        FlangeGapping.CUSTOM_PRELOAD    : 1234
        SlsPretension.CUSTOM_PRELOAD    : 1234
        FlangeNeckScf.CUSTOM_PRELOAD    : 1234
        FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS : 0.90
        ```
        Here the other three assessments are not directly linked to one of the blocks, the assessments will all simply use the same `CUSTOM_PRELOAD`.

### Multiple bolt options

It is possible to perform multiple fatigue assessments for multiple bolt options.
All examples and details as described up to this point in this How-to guide are focussed on a single bolt option.
They are still applicable for multiple bolt options, however there is an additional condition.
In case of multiple bolt options and you'd like to define a `CUSTOM_PRELOAD`, it must be set for each bolt option individually, for all related inputs.
For completeness the accepted options are:

- `CUSTOM_PRELOAD` = empty -> the default is taken from the catalog for each bolt option.
- `CUSTOM_PRELOAD` = [values] (vector) -> the vector must be of the same size as the number of bolt options and each value is applied for it's corresponding bolt option.

??? info "Examples of this scenario"

    === "Example 1"

        ```yaml
        boltOptions                     : ISO_M64x480   ISO_M72

        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS :
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 0.90

        BoltFls.BOLT_FORCE_MODEL        : sgre2
        BoltFls.CUSTOM_PRELOAD          : 1234
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.90
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
        BoltFls.TARGET_PM_SUM           : 1.00

        % ...

        FlangeGapping.CUSTOM_PRELOAD    : 1234
        SlsPretension.CUSTOM_PRELOAD    : 1234
        FlangeNeckScf.CUSTOM_PRELOAD    : 1234
        FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS : 0.90
        ```
        This results in an error since there is only one value defined for the `CUSTOM_PRELOAD` while there are two bolt options.


    === "Example 2"

        ```yaml
        boltOptions                     : ISO_M64x480   ISO_M72

        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS :
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 0.90

        BoltFls.BOLT_FORCE_MODEL        : sgre2
        BoltFls.CUSTOM_PRELOAD          : 1234          4321
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.90
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
        BoltFls.TARGET_PM_SUM           : 1.00

        % ...

        FlangeGapping.CUSTOM_PRELOAD    :
        SlsPretension.CUSTOM_PRELOAD    :
        FlangeNeckScf.CUSTOM_PRELOAD    :
        FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS :
        ```
        This is a valid set of inputs.
        Here the fatigue assessment with the Schmidt-Neuper model would make use of the default catalog values for the two bolt options ISO_M64 and ISO_M72 respectively.
        The fatigue assessment with the `sgre2` model will make use of the defined `CUSTOM_PRELOAD` with the respective values for each bolt option.
        Here the other three assessments would be linked to the first block containing the Schmidt-Neuper model and also make use of the catalog values.

    === "Example 3"

        ```yaml
        boltOptions                     : ISO_M64x480   ISO_M72

        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS :
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 0.90

        BoltFls.BOLT_FORCE_MODEL        : sgre2
        BoltFls.CUSTOM_PRELOAD          : 1234          4321
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.90
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.10
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.10
        BoltFls.TARGET_PM_SUM           : 1.00

        % ...

        FlangeGapping.CUSTOM_PRELOAD    : 1234          4321
        SlsPretension.CUSTOM_PRELOAD    : 1234          4321
        FlangeNeckScf.CUSTOM_PRELOAD    : 1234          4321
        FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS : 0.90
        ```
        This is a valid set of inputs.
        Here the fatigue assessment with the Schmidt-Neuper model would make use of the default catalog values for the two bolt options ISO_M64 and ISO_M72 respectively.
        The fatigue assessment with the `sgre2` model and the other three assessments would be linked, each both bolt option has its respective `CUSTOM_PRELOAD` defined.

## Outputs

### Log file (.log)

There are two separate locations in the log file which contain information on the performed bolt fatigue assessment(s).
Both are located towards the end file, after the clear indication:

```
INFO    : 		R E P O R T I N G   D E S I G N   S U M M A R Y
```

First, details are provided on the applied bolt model(s), this section is easily found by the header:

```
INFO    : BOLT FATIGUE LIMIT STATE - INTERMEDIATE RESULTS
```

Depending on which bolt model is used for the assessment(s), the output may be different.
For each assessment the intermediate results are printed sequentially.

The next location is at the very end of the log file, starting with:

```
INFO    : 		U T I L I Z A T I O N   S U M M A R Y
```

The results for each `BoltFls` assessment will be added as separate rows in the overview.    ```

### Data file (.usn)

Only the first `BoltFls` input block will be stored in the output .usn file.
Hence, this first block defines the FLS assessment that will be reported by DOCTOR.

Typically, it is desired to define an FLS assessment according the Design Brief (and IEC 61400-6) in this first block:

- Schmidt-Neuper bolt force model
- No custom preload
- Default PSF and S-N curve settings
- Target PM-sum of 0.90

## Backward compatibility

With this update some of the inputs are refactored, in particular by grouping the relevant inputs.
To ensure backward compatibility, USAIN will internally update deprecated inputs to this new format.
More information is provided at the dedicated section [deprecated inputs](../howto/update-inputfile.md#deprecated-inputs).

## TEXACO integration

Similar to other inputs, the bolt fatigue assessment inputs can be assigned for specific flanges via TEXACO, for more details refer to this [tutorial](../tutorials/texaco.md).
When using the overrides via TEXACO, all the **job specific** `BoltFls` inputs from the base USAIN input file will be deleted and the overrides from the TEXACO input file are inserted.

??? info "Example of TEXACO integration"

    === "Example 1"

        ```yaml
        usain.BoltFls.BOLT_FORCE_MODEL(3)         : schmidtneuper
        usain.BoltFls.CUSTOM_PRELOAD(3)           :
        usain.BoltFls.PRELOAD_LOSS_FACTOR_FLS(3)  :
        usain.BoltFls.PSF_BOLT_MATERIAL_FLS(3)    : 1.25
        usain.BoltFls.SN_CURVE_BOLT(3)            : EC3_DC36*
        usain.BoltFls.THICKNESS_EXPONENT_BOLT(3)  : 0.25
        usain.BoltFls.TARGET_PM_SUM(3)            : 0.90

        usain.BoltFls.BOLT_FORCE_MODEL(4)         : schmidtneuper
        usain.BoltFls.CUSTOM_PRELOAD(4)           :
        usain.BoltFls.PRELOAD_LOSS_FACTOR_FLS(4)  :
        usain.BoltFls.PSF_BOLT_MATERIAL_FLS(4)    : 1.25
        usain.BoltFls.SN_CURVE_BOLT(4)            : EC3_DC36*
        usain.BoltFls.THICKNESS_EXPONENT_BOLT(4)  : 0.25
        usain.BoltFls.TARGET_PM_SUM(4)            : 0.90

        usain.BoltFls.BOLT_FORCE_MODEL(4)         : sgre2
        usain.BoltFls.CUSTOM_PRELOAD(4)           : 1234
        usain.BoltFls.PRELOAD_LOSS_FACTOR_FLS(4)  : 0.90
        usain.BoltFls.PSF_BOLT_MATERIAL_FLS(4)    : 1.10
        usain.BoltFls.SN_CURVE_BOLT(4)            : EC3_DC50
        usain.BoltFls.THICKNESS_EXPONENT_BOLT(4)  : 0.10
        usain.BoltFls.TARGET_PM_SUM(4)            : 1.00


        ```
        For this example, flange connection three will be assigned a single `BoltFls` block to be assessed.
        Flange connection four will get two assessments.
        Other flange connections in the structure being designed in the TEXACO run, will evaluate bolt fatigue based on inputs provided in the USAIN base input file.
