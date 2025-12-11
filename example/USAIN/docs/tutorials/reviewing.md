# Reviewing a flange design run

This tutorial focusses on reviewing a performed USAIN run for a single flange connection.
There are multiple criteria which have to be satisfied in order to have a structurally sound flange design, all of these will be discussed in this tutorial.

!!! note "No review without results."
    Since this is a tutorial on reviewing results of a run, it's assumed that you have already performed a flange design run and have results to review. If not, please refer to the [first-run](../tutorials/first-run.md) tutorial.

!!! tip "What about the other flanges in the support structure?"
    A complete tower or support structure design will contain multiple flange connections.
    The overarching review sheet for all the flange connections in the structure can be found in this <a href="https://siemensgamesa.sharepoint.com/:f:/r/teams/OG01069/Shared%20Documents/Templates/Tower%20Design%20Review%20Checklist">SharePoint folder</a>.

## Starting the review

When USAIN runs, it writes a comprehensive log file which contains general information messages on the steps during the run, potentially warning messages and at the end a detailed overview of the selected/best flange design.
This log file is therefore the starting point for your review.
The log file is easily identified by the ".log" file-extension in the [targetDir](../reference/inputfile.md#targetdir-full-path-optional) where the results are stored.

## Going over the log file

The log file basically consists of four parts:

- Validation of the provided inputs.
- Evaluation of the design space.
- Re-evaluation of the selected/best design.
- Detailed overview of the selected/best design.

### Validation of provided inputs

When USAIN detects odd inputs, these will be reported with a warning message starting with "WARNING".
These odd inputs might be fine to use for this particular design, however will require some clarification and mutual agreement between the designer and reviewer.

!!! note "You also need to validate the inputs!"
    USAIN can't detect all possible odd input combinations, as such it is suggested to verify the inputs yourself as well.
    For example, if the flange should be designed for the Japanese market but all inputs are set according to the "Rest of World" settings, USAIN is not able to detect this.

### Evaluation of the design space

This part of the log file does not really require reviewing, a small comment is given for completeness on this part of the log file.
This part shows the design conditions which are evaluated and the number of feasible design points after the evaluation of each condition.
As such it can give a first hint if the selected/best design might be infeasible.

=== "Feasible designs found"

    ```
    INFO    : Evaluating design condition: Ultimate limit state
    INFO    : Finished evaluation in   1.234s. Number of feasible solutions:    8000 / 123456
    ```

=== "No feasible designs found"

    ```
    INFO    : Evaluating design condition: Ultimate limit state
    INFO    : Finished evaluation in   1.234s. Number of feasible solutions:       0 / 123456

    WARNING : No feasible flange design could be found for the provided inputs.
              ==> Selecting solution closest to feasible in evaluated, infeasible solution space.
    ```

### Re-evaluation of the selected/best design

This part of the log file is easily recognized by the text:

```
INFO    : Rebuilding model for selected design.
```

After the evaluation of the design space a single design point is selected.
For this selected design, all the design conditions are re-evaluated.
Since only a single design point is evaluated, all the conditions should indicate: "Number of feasible solutions: 1/1". If any of the condition indicate 0/1, the selected/best flange design is infeasible.

Any warning messages reported in this part of the log file should be dealt with carefully!

### Detailed overview of the selected/best design

This section provides a summary of the designed flange and if all conditions it needs to adhere to are met.
While not all subsections of the design summary are too relevant for the review, for completeness all subsections are treated briefly.
The important sections for the review will be more elaborate.
The design summary section starts with the text:

```
INFO    : R E P O R T I N G   D E S I G N   S U M M A R Y
```

#### Ultimate limit state

This table shows the critical failure mode and the corresponding force.
In general it's expected that failure mode B will govern the design, therefore this level will also always be printed, such that you'd have an easy reference if another mode is driving.

#### Flange neck bending

This table reports the PM-sum and equivalent SCFs at the flange neck.
In case of too high values, a warning is already reported in the re-evaluation of the selected design point with a hint on how to proceed.

#### Design space summary

This summary shows if the selected/best flange design is within internally calculated bounds.
The internal calculated bounds are set to avoid too large design spaces during calculations and omitting 'exotic' flange designs from the design space from the start of the run.
By running USAIN with default settings the design space checks will always be OK.
However, since it's possible to overrule these bounds using EXPERT_INPUTS, this summary will quickly show if this is the case and if the design is outside of the expected bounds.

!!! note "When trying to outsmart USAIN using EXPERT_INPUTS."
    When a design shows a "NOK" for the design space summary, this could potentially still be a valid design but will require some more attention.
    In particular the lower bound for the number of bolts used to be less strict in the past, therefore check runs for older flange connections (mainly for flanges higher up the structure) will likely indicate a "NOK" while it is actually feasible.
    This must be validated by checking the utilization summary.

#### Model and mass summary

These two tables show the main geometric properties of the flange and fasteners used.
Here you can perform a quick sanity check, e.g. if the correct fastener with tensioning method is selected.

#### Utilization summary

This section shows utilization ratio for all evaluated design criteria.
Here it is expected that as many criteria as possible are evaluated and satisfy the condition, hence are reported as "OK".
Only for conceptual design and projects in an early design stage it is acceptable to have less design criteria evaluated, it's suggested to handle these situations more cautiously.
As common practice try to evaluate all the design criteria.

!!! note "Some criteria are not always applicable."
    There is one exception to the rule, in general the ULTIMATE LIMIT STATE needs to be evaluated and ULTIMATE LIMIT STATE JAPAN shows "N.A.".
    This is obviously due to the fact that the latter is only applicable for the Japanese market.
    If you design/review for the Japanese market, it should be the other way around.

## Concluding the review

When all design criteria appear to be "OK" or can be justified the review can be concluded.
