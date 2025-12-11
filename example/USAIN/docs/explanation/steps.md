# Steps during run

USAIN sequentially performs a given set of tasks during a run.
This page explains each of these steps.

## Overview

1. **Check input file**<br>
   Reads the input file and checks if all input values make sense.
   Warnings are logged in case unexpected inputs, or combinations, are found.
   Errors are logged in case faulty inputs are found.

2. **Load external files**<br>
   The external files are loads (StructuralModel, ULS/FLS loads)

3. **Perform cross-checks**<br>
   The inputs and the data from the external files are compared and checks.
   Warnings are logged in case unexpected inputs, or combinations, are found.
   Errors are logged in case faulty inputs are found.

4. **Set up design space**<br>
   Creates the design space as described [here](./design-space.md).

5. **Evaluate conditions**<br>
   Evaluates each design point for [a given set of conditions](#evaluating-conditions).
   Based on input [`DO_UPDATE_DESIGN_SPACE`](../reference/expert-inputs.md#do_update_design_space-boolean), the infeasible design points are either kept or discarded.

6. **Select best design**<br>
   The best design is selected by evaluating a cost model for the feasible design points.
   If all design points are infeasible, the design point closest to feasibility is selected.

7. **Check conditions**<a name="check-conditions"></a><br>
   Evaluates the same [set of conditions](#evaluating-conditions) as before, but then only for the selected best design point.

8. **Report design summary**<br>
   Intermediate results are logged for a quick overview of the performance of the selected flange design.

9. **Update StructuralModel**<br>
   Writes a new StructuralModel file, reflecting the updated flange geometry (height) and mass.
   This step is only executed if a StructuralModel was provided in the inputs ([`structureInpFilePath`](../reference/inputfile.md#structureinpfilepath-full-file-path)).

10. **Write .usn file**<br>
    Writes a binary .usn file with all relevant results, for use in DOCTOR.

11. **Write selected model input file**<br>
    Writes a *selected model input file*, which can be used to reproduce the results of the selected flange design.

## Evaluating conditions

The order of evaluation of the conditions evaluated by USAIN is fixed as well:

1. **Thread requirements**<br>
   Checks thread requirements of stud/bolt in flange connection (both visible and gripped thread).
   A design is considered infeasible if any of he thread requirements is not satisfied.

2. **Bolt force model applicability**<br>
   The geometry check for applicability of the Schmidt-Neuper bolt force model.
   If the check fails, a design is considered infeasible.

3. **Preload loss from flange plasticity**<br>
   Checks for plastic strain development around the bolt hole to prevent preload losses.

4. **Preload loss from bolt plasticity**<br>
   Checks for plastic strain development in the bolt to prevent preload losses.

5. **Ultimate limit state**<br>
   Evaluates the ULS failure modes and computes a utilization based on the ratio with the applied ULS segment force.

6. **Ultimate limit state (Japan)**<br>
   The same as the previous step, but specifically for the failure modes defined in the Japanese design guidelines.

7. **SLS pretension loss**<br>
   A Von Mises yield check is performed for the flange material around the bolt hole circumference, while applying the maximum FLS load.
   This condition is only evaluated during the '[check conditions](#check-conditions)' step.
   Hence, the flange connection is not optimized for this condition.

8. **Flange gapping under FLS loading**<br>
   Applies a segment load equal to the maximum FLS load and checks if the flange connection opens up to the bolts.
   If opening beyond the bolts occurs, the design is considered infeasible.
   This condition is only evaluated during the '[check conditions](#check-conditions)' step.
   Hence, the flange connection is not optimized for this condition.

9. **Fatigue limit state**<br>
   Computes the PM-sum fatigue damage on the fasteners.
   Feasible designs have a PM-sum that is less than or equal to the target PM-sum.

10. **Flange neck SCF**<br>
   Calculation of the bending stress SCF in the flange neck.
   This condition is only evaluated during the '[check conditions](#check-conditions)' step.
   Hence, the flange connection is not optimized for this condition.
   <br>
   When this condition is active in a TEXACO run, USAIN will transfer the calculated (equivalent) flange neck bending
   SCF to STIFT automatically. In STIFT, this SCF is then combined with the SCF(s) computed by STIFT and STIFT then
   takes care of the damage calculation in the flange-to-can weld. In case of multiple fatigue load sets, the maximum
   SCF will be transferred.
