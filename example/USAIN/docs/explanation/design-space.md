# The design space

This page covers one of the central pillars in USAIN: the design space.

## Definitions

* A *design variable* is a flange parameter that is altered in order for USAIN to find an optimal flange design.
* The *design space* are all the possible combinations of *design variables* that USAIN will evaluate.

## Design variables

!!! inline end info "More info in the Design Rules"
    Currently, the design variable limits (e.g., minimum and maximum flange width) are described in the Design Rules.
    In the future, that information might be moved to this documentation.
    If that happens, we'll make sure to notify you.
USAIN uses four design variables to describe a flange connection:

1. Flange width
2. Flange thickness
3. Number of bolts
4. Bolt type and size

All other parameters either have fixed values (e.g., flange thickness tolerance) or are depending on one or more design variables (e.g., washer geometry).

## Design space

As there are [four design variables](#design-variables), the design space is a 4D space.
The consequence of this is that the design space can quickly grow in size and therefore it is important to always pay attention to the minimum and maximum values set in the inputs.

??? question "How does USAIN handle inputs related to the design space?"
    Internally, USAIN has a fair idea on how a design space should look like.
    However, it could be that the inputs are conflicting. A special page for this situation can be found [here](./handling-bounds.md).
