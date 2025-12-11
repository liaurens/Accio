# SCFs and load scaling

There are a multitude of ways of scaling loads and applying SCFs, especially for fatigue assessments.
This page explain the implementation in USAIN.

## FLS

For FLS, scaling loads is done with inputs `Loads.flsScalingFactor` and `Loads.flsScalingLevel`.
These scaling factors are applied on the ranges of the Markov matrix.

Applying an SCF for FLS assessments should be done using the input `MACRO_GEOMETRIC_SCF`.
The macro-geometric SCF considers the effect of e.g. the door frame or jacket legs, which lead to locally increased stresses.
The macro-geometric SCF is applied on ranges and mean values from the Markov matrix, as well as on the dead weight for the segment (i.e. making dead weight more favorable for SCFs > 1.0).
The latter is done because it is assumed that the stress concentration is valid for the meridional stress in the tower shell, irrespective of whether those are caused by external loading or dead weight.
This is also ensures that the SGRE2.0 bolt force curve returns exactly the preload for zero external load.

For legacy reasons, there's also an input `ADDITIONAL_SCF_FLS`.
If used, this SCF is applied on the bolt stresses only (not on the flange neck bending stresses).
Generally, using this input is not advised.

## ULS

For ULS, scaling loads is done with inputs `Loads.ulsScalingFactor` and `Loads.ulsScalingLevel`.

Applying an SCF for ULS assessments is generally not needed (justified by the redistribution effects under ULS conditions).
Still, if needed the input `ADDITIONAL_SCF_ULS` can be used.
This factor is then applied on ULS segment force and therefore affects the failure mode utilization ratios.

## SLS

For SLS, scaling loads is done with inputs `Loads.S1ScalingFactor` and `Loads.S1ScalingLevel`.

Same as for [FLS](#fls), applying an SCF for SLS assessments should be done using the input `MACRO_GEOMETRIC_SCF`.
