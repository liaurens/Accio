# Handling design space bounds

This page describes how USAIN handles conflicts between internally computed design variable bounds and bounds given as input.

## Definitions

* Internally, USAIN calculates design space bounds.
  These bounds are referred to as *calculated bounds*.

* Optionally, the user can input design space bounds.
  These bounds are referred to as *input bounds*.
  An example of this are inputs [`minFlangeWidth`](../reference/inputfile.md#minflangewidth-number-optional) and [`maxFlangeWidth`](../reference/inputfile.md#maxflangewidth-number-optional).

## Scenarios

Let's assess three different scenarios to see how USAIN behaves:

1. Input bounds are fully within calculated bounds
2. Input bounds are partly within calculated bounds
3. Input bounds are outside calculated bounds

??? question "What if an input bound is not set?"
    USAIN will use the calculated bounds when an input bound is not set (or if only one of the bounds is set).
    For example, if the calculated min. and max. number of bolts are respectively 100 and 150, the input min. is not set and the input max. is 140, USAIN continues with min. 100 and max. 140.

### Input bounds are fully within calculated bounds

To keep things simple, we will look at a single design variable: the number of bolts.
We will use some ascii-sketching to visualize the calculated bounds and input bounds.

```text
                          min.       max.
                           ↓          ↓
Calculated bounds:         [----------]     - e.g., min. = 100, max. = 150
Input bounds:                [------]       - e.g., min. = 110, max. = 140
```

By default, USAIN uses the part of the input bounds that are contained within the calculated bounds.
Setting expert input `DO_TRIM_DESIGN_SPACE` to `false`, USAIN will use the input bounds even if they do not overlap with the calculate bounds.
In this case, that would yield the same result as the default behavior.

=== "With trimming"

    ```text
                              min.       max.
                              ↓          ↓
    Calculated bounds:         [----------]     - e.g., min. = 100, max. = 150
    Input bounds:                [------]       - e.g., min. = 110, max. = 140
    Used bounds:                 [------]       →       min. = 110, max. = 140
    ```

=== "Without trimming"

    ```text
                              min.       max.
                              ↓          ↓
    Calculated bounds:         [----------]     - e.g., min. = 100, max. = 150
    Input bounds:                [------]       - e.g., min. = 110, max. = 140
    Used bounds:                 [------]       →       min. = 110, max. = 140
    ```

    With input `DO_TRIM_DESIGN_SPACE` set to `false`, you'll get the same result because the input bounds are fully contained within the calculated bounds.

### Input bounds are partly within calculated bounds

If the input bounds partly overlap with the calculated bounds, the default behavior is exactly the same as in the [previous scenario](#input-bounds-are-fully-within-calculated-bounds).
It changes however, when design space trimming is disabled.

=== "With trimming"

    ```text
                              min.       max.
                              ↓          ↓
    Calculated bounds:         [----------]     - e.g., min. = 100, max. = 150
    Input bounds:          [------]             - e.g., min. = 80,  max. = 110
    Used bounds:               [--]             →       min. = 100, max. = 110
    ```

=== "Without trimming"

    ```text
                              min.       max.
                              ↓          ↓
    Calculated bounds:         [----------]     - e.g., min. = 100, max. = 150
    Input bounds:          [------]             - e.g., min. = 80,  max. = 110
    Used bounds:           [------]             →       min. = 80,  max. = 110
    ```

### Input bounds are outside calculated bounds

By default, USAIN will exit with an error if the input bounds do not overlap with the calculated bounds.

If expert input `DO_TRIM_DESIGN_SPACE` (default = `true`) is set to `false` (i.e., trimming is disabled), USAIN will continue with the potentially infeasible input bounds.
At the end of a run, you will get a warning that the selected flange design is infeasible.
In some cases, this might be acceptable.

=== "With trimming"

    ```text
                              min.       max.
                              ↓          ↓
    Calculated bounds:         [----------]     - e.g., min. = 100, max. = 150
    Input bounds:           [-]                 - e.g., min. = 80,  max. =  95
    Used bounds:                  ERROR
    ```

=== "Without trimming"

    ```text
                              min.       max.
                              ↓          ↓
    Calculated bounds:         [----------]     - e.g., min. = 100, max. = 150
    Input bounds:           [-]                 - e.g., min. = 80,  max. =  95
    Used bounds:            [-]                 →       min. = 80,  max. =  95
    ```
