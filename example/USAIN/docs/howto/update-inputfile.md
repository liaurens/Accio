# Update an input file for a new USAIN version

## Option 1: Start from scratch

The best way is to get a copy of a new USAIN input file template (using the `copy_inputfiles` method explained [here](../reference/commands.md).).

Once you have the new template, copy the relevant values from your old USAIN input file into your new one.
Always make sure to read the [release notes](../about/release-notes.md) to find out if any inputs are removed or [deprecated](#deprecated-inputs).

## Option 2: Update existing input file

Another way would be to update your existing USAIN input file. This is less robust, because you might overlook certain parameters.
Always make sure to read the [release notes](../about/release-notes.md) to find out if any inputs are removed or [deprecated](#deprecated-inputs).

### Updated existing input file to USAIN 4.0.0

The following table presents input file parameters that were [deprecated](#deprecated-inputs) prior to USAIN version 4.0.0, and have been removed completely since USAIN version 4.0.0. Also, a number of inputs have been removed completely.

Note that most of the listed inputs have been deprecated for a long time already. If you have kept your input files up-to-date, there's little to worry about.

| Removed parameter                                       | Replaced by                                                     |
| ------------------------------------------------------- | --------------------------------------------------------------- |
| `ALW_FLANGE_THICKN`                                     | `ALW_LOWER_FLANGE_THICKNESS`, `ALW_UPPER_FLANGE_THICKNESS` |
| `ALW_FLANGE_WIDTH`                                      | No replacement |
| `BEVEL_TYPE`                                            | `BEVEL_ANGLE`, `BEVEL_ROOT_FACE` |
| `BOLT_FORCE_MODEL`                                      | `BoltFls.BOLT_FORCE_MODEL` |
| `CUSTOM_PRELOAD`                                        | `BoltFls.CUSTOM_PRELOAD`, `FlangeGapping.CUSTOM_PRELOAD`, `SlsPretension.CUSTOM_PRELOAD`, `FlangeNeckScf.CUSTOM_PRELOAD` |
| `customWasherDiamIn`                                    | `CUSTOM_WASHER_DIAM_INNER` |
| `customWasherDiamOut`                                   | `CUSTOM_WASHER_DIAM_OUTER` |
| `customWasherThickn`                                    | `CUSTOM_WASHER_THICKNESS` |
| `diamOutFlange`                                         | `diamOutNeck` |
| `DO_ASSESS_FLANGE_NECK_YIELDING`                        | No replacement |
| `DOOR_STIFFNESS_FACTOR`                                 | `MACRO_GEOMETRIC_SCF` |
| `doorSegment.doInclude`                                 | `DOOR_SEGMENT.DO_INCLUDE` |
| `doorSegment.FACTOR_CAN_TO_DOOR_THICKNESS`              | `DOOR_SEGMENT.FACTOR_CAN_TO_DOOR_THICKNESS` |
| `doorSegment.MIN_CAN_TO_DOOR_DELTA_THICKNESS`           | `DOOR_SEGMENT.MIN_CAN_TO_DOOR_DELTA_THICKNESS` |
| `doorSegment.thickness`                                 | `DOOR_SEGMENT.THICKNESS` |
| `GLOBAL_MAX_FLANGE_WIDTH`                               | No replacement |
| `GLOBAL_MIN_FLANGE_THICKNESS`                           | No replacement |
| `internalsBracketBcd`                                   | `SECONDARY_HOLES_BCD` |
| `internalsBracketBh`                                    | `SECONDARY_HOLES_DIAMETER` |
| `Loads.inclinationAngle`                                | `Loads.inclinationValue` |
| `MIN_VISIBLE_THREAD_LENGTH_TENSION`                     | `MIN_VISIBLE_THREAD_LENGTH` |
| `MIN_VISIBLE_THREAD_LENGTH_TORQUE`                      | `MIN_VISIBLE_THREAD_LENGTH` |
| `PRELOAD_LOSS_FACTOR_FLS`                               | `BoltFls.PRELOAD_LOSS_FACTOR_FLS`, `FlangeNeckScf.PRELOAD_LOSS_FACTOR_FLS` |
| `PRICE_BASE`                                            | No replacement |
| `PRICE_DRILLING`                                        | No replacement |
| `PRICE_MACHINING`                                       | No replacement |
| `PRICE_RAW_MATR`                                        | No replacement |
| `PSF_BOLT_MATERIAL_FLS`                                 | `BoltFls.PSF_BOLT_MATERIAL_FLS` |
| `PSF_FAV_LOADS`                                         | `PSF_FAVORABLE_LOADS` |
| `SN_CURVE_BOLT`                                         | `BoltFls.SN_CURVE_BOLT` |
| `TARGET_PM_SUM`                                         | `BoltFls.TARGET_PM_SUM`, `FlangeNeckScf.TARGET_PM_SUM` |
| `THICKNESS_EXPONENT_BOLT`                               | `BoltFls.THICKNESS_EXPONENT_BOLT` |
| `TOL_FILLET_RADIUS`                                     | `TOL_FILLET_RADIUS_PLUS` |
| `TOL_FLANGE_THICKN`                                     | `TOL_FLANGE_THICKNESS_MINUS`, `TOL_FLANGE_THICKNESS_PLUS` |
| `toolDimensionCircDir`                                  | `TOOL_DIMENSION_CIRC_DIR` |
| `toolDimensionRadialDir`                                | `TOOL_DIMENSION_RADIAL_DIR` |

Secondly, the following input parameters have been added.

| New parameter                                           |
| ------------------------------------------------------- |
| `Loads.inclinationUnit`                                 |
| `TIGHTENING_SIDE_INSTALLATION`                          |
| `TIGHTENING_SIDE_TEMP_STAGES`                           |
| `OBJECTIVE_WEIGHT_FASTENER_DIAMETER`                    |
| `OBJECTIVE_WEIGHT_FLANGE_THICKNESS`                     |
| `OBJECTIVE_WEIGHT_FLANGE_WIDTH`                         |

Apart from `Loads.inclinationUnit`, none of these inputs are _required_ to be filled out in the input file.

## Deprecated inputs

In some USAIN updates, input file parameters are marked as *deprecated*.

If this is the case, the [release notes](../about/release-notes.md) will state this.

A deprecated input will still work and give the same results as for previous versions.
Internally, USAIN will map the deprecated input to the new input.

When USAIN stumbles upon a deprecated input, a warning will be thrown with more information.
Usually, it will be something like:

> Input "myOldParameter" is deprecated and will be removed in a future version: use "myNewParameter" instead.
> Continuing by assigning value for "myOldParameter" to "myNewParameter".

Deprecated input may be removed from USAIN at any given time, they are merely there to give a "grace period" in which you have time to update the USAIN input file(s) for your running project.
