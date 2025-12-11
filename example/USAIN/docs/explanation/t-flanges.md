# Designing T-flanges in USAIN

The majority of tower flanges, in both onshore and offshore WTGs, are L-flanges.
For that reason literature and standards are often tailored to the assessment of L-flanges, and so is USAIN.
This page explains notable differences (to inputs, internal choices in USAIN, etc.) for T-flange USAIN runs.

## Inputs

Through input [`flangeType`](../reference/inputfile.md#flangetype-string-optional), USAIN knows whether to design an L-flange or a T-flange.

!!! tip "New in v4.0.0"

    The inputs [`minFlangeWidth`](../reference/inputfile.md#minflangewidth-number-optional) and [`maxFlangeWidth`](../reference/inputfile.md#maxflangewidth-number-optional) represent, intuitively, the physical flange width.
    Prior to v4.0.0, the value for these inputs needed to be set as if an L-flange was designed.

    === "v4.0.0"

        ```
                  |     |
         _________|     |_________
        |                         |
        |       T-flange          |
        |                         |
        |_________________________|

        <------------------------->
          flange width
        ```

    === "Prior to v4.0.0"

        ```
                  |     |
         _________|     |_________
        |                         |
        |       T-flange          |
        |                         |
        |_________________________|

        <--------------->
          flange width
        ```

## Internal choices

When USAIN determines the design space in which it should find a solution (for more, read [here](design-space.md)), it uses different rules for the width of L- and T-flanges.

**Minimum flange width**<br>
The minimum width for L-flanges and T-flanges is based on the a/b ratio of the the flange.

- The minimum width for L-flanges is based on Tobinaga's criterion: a/b ≥ 1.25.
- For T-flanges, Tobinaga's method does not apply. The minimum width for T-flanges is therefore set such that the bolt holes are ≥ 1.2 times the bolt hole diameter away for the edges of the flange.

**Flange width-to-thickness ratio**<br>

Additionally, constraints on the minimum width-to-thickness (w/t) ratio apply:

- For L-flanges, this is limited to w/t ≥ 1.2.
- For T-flanges, this is limited to w/t ≥ 2.

The maximum width for L-flanges and T-flanges is based on the width-to-thickness (w/t) ratio of the the flange.

- For L-flanges, this is limited to w/t ≤ 3.
- For T-flanges, this is limited to w/t ≤ 4.

!!! note "Engineering judgement applies"

    These ratios are based on engineering judgement.
    Although unlikely, it may happen that a more optimal design can be found by exceeding the constraints above.
    As a safeguard for this, USAIN will throw a warning whenever a design is selected with this minimum or maximum width-to-thickness ratio.
    In such a scenario, the user may overrule the imposed width-to-thickness ratio by setting specific values for the inputs [`minFlangeWidth`](../reference/inputfile.md#minflangewidth-number-optional) and/or [`maxFlangeWidth`](../reference/inputfile.md#maxflangewidth-number-optional).

## Calculations

Not all conditions that are evaluated in a USAIN run, as listed [here](./steps.md#evaluating-conditions), apply to T-flanges.
The following conditions will be ignored by USAIN when designing or checking T-flanges:

1. Preload loss from flange plasticity
2. Flange gapping under FLS loading
3. Flange neck SCF
4. SLS pretension loss

For example, the input [`DO_ASSESS_SLS_PRETENSION`](../reference/expert-inputs.md#do_assess_sls_pretension-boolean) is simply forced to `false` for T-flanges.

## Automatic switch from L-flange to T-flange

When the input `DO_ALLOW_SWITCH_L_TO_T` is set to `true`, USAIN will design a T-flange in case an L-flange is infeasible.
To perform this switch, USAIN will make some assumptions to manipulate the inputs and re-run the design.
The internal manipulations on the inputs are described here.

- [`flangeType`](../reference/inputfile.md#flangetype-string-optional) will be set to `T`.
- [`FILLET_RADIUS`](../reference/expert-inputs.md#fillet_radius-number) will be set as the minimum expected value for a T-flange (15mm) unless a higher value was provided as input.
- [`FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS`](../reference/expert-inputs.md#flangeneckscfpreload_loss_factor_fls-number) will be set to the minimum value used for `BoltFls.PRELOAD_LOSS_FACTOR_FLS`. Note that this will be set after underneath manipulations to the BoltFls block(s) have been performed.
- [`minFlangeWidth`](../reference/inputfile.md#minflangewidth-number-optional) and [`maxFlangeWidth`](../reference/inputfile.md#maxflangewidth-number-optional) (if defined) will be increased to consider the outer stub symmetrically.
- The [`BoltFls.*`](../reference/expert-inputs.md#fls-assessment) input blocks which describe the `sgre2` bolt force model will not be updated and will be transfered to the new inputs for the T-flange design. Block(s) containing the `schmidtneuper` model will be set in line with expected requirements for onshore T-flange design.

Please see the three examples underneath which demonstrates how the `BoltFls.*` inputs are manipulated.

### Example 1 - single `BoltFls` block with `schmidtneuper` model defined

??? info "Example of this scenario"

    === "Original inputs"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.9
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 1.0
        ```

    === "Manipulated inputs"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : petersen
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.7
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 1.0

        BoltFls.BOLT_FORCE_MODEL        : petersen
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.5
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.15
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 1.00
        ```

### Example 2 - multiple `BoltFls` blocks with `schmidtneuper` model defined

??? info "Example of this scenario"

    === "Original inputs"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.9
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 1.0

        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.7
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.15
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 1.00
        ```

    === "Manipulated inputs"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : petersen
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.7
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 1.0

        BoltFls.BOLT_FORCE_MODEL        : petersen
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.5
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.15
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 1.00
        ```

### Example 3 - multiple `BoltFls` blocks with both `schmidtneuper` and `sgre2` modeld defined

??? info "Example of this scenario"

    === "Original inputs"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.7
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.15
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 1.00

        BoltFls.BOLT_FORCE_MODEL        : sgre2
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.9
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.1
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT :
        BoltFls.TARGET_PM_SUM           : 1.0

        BoltFls.BOLT_FORCE_MODEL        : schmidtneuper
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.9
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 1.0
        ```

    === "Manipulated inputs"

        ```yaml
        BoltFls.BOLT_FORCE_MODEL        : petersen
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.7
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.25
        BoltFls.SN_CURVE_BOLT           : EC3_DC36*
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 1.0

        BoltFls.BOLT_FORCE_MODEL        : petersen
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.5
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.15
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT : 0.25
        BoltFls.TARGET_PM_SUM           : 1.00

        BoltFls.BOLT_FORCE_MODEL        : sgre2
        BoltFls.CUSTOM_PRELOAD          :
        BoltFls.PRELOAD_LOSS_FACTOR_FLS : 0.9
        BoltFls.PSF_BOLT_MATERIAL_FLS   : 1.1
        BoltFls.SN_CURVE_BOLT           : EC3_DC50
        BoltFls.THICKNESS_EXPONENT_BOLT :
        BoltFls.TARGET_PM_SUM           : 1.0
        ```
