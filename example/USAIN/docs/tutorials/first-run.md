# First run

Welcome!
In this tutorial we will design a flange connections with a minimal amount of inputs.
We are going to assume you have Matlab running and access to all PST tools.

## Prepare inputs

!!! info inline end
    The files in the `_data` folder can be ignored.

Download [this .zip file](files/first-run.zip) and extract it somewhere you like (where you can use Matlab).
These files will serve as the basis for this tutorial.

Open the USAIN input file in your favorite text editor and have a look!
Some inputs are already filled out. Next, we'll do the rest.

## Completing the input file

In this tutorial, we are trying to find a design for FC3 (i.e. the third flange connection counted from tower top).
As already filled out in the input file, this connection lives at z = -57.96m (meaning, 57.96m above interface level).

Let's complete the input file in two simple steps:

1. Scroll all the way to the bottom of the input file.
    You'll find two inputs that related to the outputs USAIN will produce: `targetDir` and `runName`.
    Change them to your liking, for example:

    ```yaml
    targetDir :
    runName   : 'My first run'
    ```

    ??? tip "Default target directory"
        If input `targetDir` is left empty, a folder named `Res` will be created in the same directory as the input file.
        If this folder already exists, the existing folder content will not be removed.
        Result files are never overwritten.

2. Input some bolt options for USAIN to choose from.
    As we have no good idea about the tower structure and the loads, let's give a couple of options:

    ```yaml
    boltOptions       : ISO_M56 ISO_M64
    tighteningMethod  : tension
    ```

    We'll leave the rest of the input file as is.
    Because we have provided the inputs `zFlange` and `structureInpFilePath`, USAIN will be able to grab a lot of information from StructuralModel.

## Run USAIN

We're ready to run USAIN now!
Go to Matlab and execute `USAIN.run('path/to/your/inputfile.inp')`.

## Check results

The next tutorial, [Review results](./reviewing.md), describes how to compare the newly obtained results.

## What's next?

Feel free to play around with the input file and re-run USAIN.
If you lack inspiration, here are a couple of variations you could try:

- Try to increase the load scaling (inputs `Loads.flsScalingFactor` and `Loads.ulsScalingFactor`) and see how that affects your flange design.
- Clear the input `structureInpFilePath` and try to fill out the complete input file yourself. This will give you an idea on how USAIN and StructuralModel interact.
- Limit the design space by setting values for inputs `minNBolts`, `maxNBolts`, `minFlangeWidth`, `maxFlangeWidth`, `minFlangeThickn` and/or `maxFlangeThickn`.

!!! warning "Leave the z-coordinate"
    Do not change the value for input `zFlange`; the tutorial files contain loads only for that elevation level.
