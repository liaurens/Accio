# TEXACO integration

!!! inline end info "Scope of this tutorial"
    This is not a hands-on tutorial on running TEXACO.
    That will be part of the [TEXACO first run tutorial](../../TEXACO/tutorials/first_run.md) at the TEXACO documentation.

This tutorial will teach you how to integrate USAIN into your TEXACO run.

## Iterations setup

Assuming you just got a fresh copy of a TEXACO input file (with command `TEXACO.copy_inputfiles`), it's time to define the iteration setup.

In a TEXACO iteration, USAIN is the last tool that is able to modify `StructuralModel`.
When designing flange connections with USAIN in a TEXACO run, multiple TEXACO iterations need to be defined: USAIN might modify the structure, after which other tools (e.g. STIFT, SEAGUL) need to re-assess it.
Therefore, ensure that in the last iteration of your TEXACO run you set `Tool.USAIN.run_batch` to ***0***, even when you specify `doForceCheckAtLastIteration` to be ***true***!

??? example "Example setup"

    The top of your TEXACO input file might look something like this.
    Note that USAIN is deactivated in the last iteration.

    ```yaml
    Tool.IDEA.run                : 0 0 0
    Tool.FUEL.run                : 0 0 0
    Tool.STIFT.run               : 1 1 1
    Tool.SCAM.run                : 0 0 0
    Tool.MEATLOAF.run            : 0 0 0
    Tool.SEAGUL.run              : 1 1 1
    Tool.DUCK.run                : 0 0 0
    Tool.PILS.cheers             : 0 0 0
    Tool.USAIN.run_batch         : 1 1 0
    Tool.PANCAKE.run             : 0 0 1
    Tool.DOCTOR.run              : 0 0 1
    ...
    doForceCheckAtLastIteration  : true
    ```

## USAIN specific inputs

If you have defined the iterations setup, you can use the `TEXACO.setup_new_run` or `TEXACO.update_run_inputfile` command to have the USAIN specific inputs added to that file.
All inputs related to USAIN will be prefixed with `usain.`.
This prefix is omitted in the remainder of this tutorial to improve readability and avoid repetition.

A support structure typically has multiple L- and T-flange connections.
TEXACO will be able to run USAIN multiple times in one iteration: one USAIN run for each L- or T-flange connection.

USAIN inputs applicable to all flange connections, as well as to specific flange connections, can be defined in the TEXACO input file.

### Inputs applicable to all flanges

The first few USAIN inputs are generically applicable to all USAIN runs in a TEXACO iteration.

```yaml
usain.usainBaseInpFilePath : c:\path\to\InputFile_USAIN.inp
usain.structureInpFilePath :
usain.ulsMeatloafFilePath  :

usain.targetDir            :
usain.runName              :
```

* The most important input is `usainBaseInpFilePath`, where you specify the USAIN *base* input file.
  This is a normal USAIN input file that contains input settings that will be applied to all USAIN runs in your TEXACO iteration.
* Input `structureInpFilePath` can typically be left empty.
  TEXACO will fill this out for you.
* Input `ulsMeatloafFilePath` is only needed if you also run `MEATLOAF` in your TEXACO run (for monopile designs only).
  If `MEATLOAF` is not active, leave this empty and define your ULS loads file in the USAIN *base* input file.
* Inputs `targetDir` and `runName` can typically be left empty.

### Flange specific inputs

Flange specific inputs are provided using the format `usain.specificInput(#)`, where `(#)` indicates the flange connection number for which this input needs to be set.
Flange connection numbers are counted from tower top.
Typically, the first flange connection we design is denoted with number `2`: the connection between the top and first middle tower section (*middle flange connection 1*).

For example:

!!! inline end info "Number of USAIN jobs"
    The `usain.zFlange` will dictate how many USAIN runs will be performed in a TEXACO iteration.
    In the example on the left, USAIN will be run three times.

```yaml
usain.zFlange(2)           : -98.76
usain.zFlange(3)           : -40.45
usain.zFlange(4)           : 0.00

usain.maxFlangeWidth(4)    : 600
```

TEXACO will take these inputs and add them to a copy of the *base* input file (the one assigned to input `usain.usainBaseInpFilePath`).
If the base input file already contains a value, TEXACO will override that value.

In the example above, TEXACO will:

* Make a copy of the *base* input file for flange connection #2 and assign a value `-98.76` to input `zFlange` in that copied input file.
* Make a copy of the *base* input file for flange connection #3 and assign a value `-40.45` to input `zFlange` in that copied input file.
* Make a copy of the *base* input file for flange connection #4, assign `0.00` to input `zFlange` and `600` to input `maxFlangeWidth`.
