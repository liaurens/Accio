# Fastener properties

This section gives an overview of the properties of the various fastener components (bolts, nuts, etc.) and tightening tools used within USAIN.

!!! warning "Preliminary values for M90 and M100 studs"
    The tables below list data for M90 and M100 components (studs, ISRs, etc.).
    The values are preliminary and may change in the future.
    Use M90 and M100 only after alignment with the topic owners!

## Bolts and studs

Bolts and studs are similarly modelled in USAIN.
That means that a stud is simply a bolt without a head (zero length), and with the thread length symmetrically on both sides.

{{ macro_bolt_catalog_bolts(bolt_catalog) }}

## Nuts

In USAIN, round nuts and hexagon nuts are modelled in the same manner.
The width-across-flats of a hexagon nut is not used; merely the diameter (which, for a hexagon nut equals the width-across-corners).

{{ macro_bolt_catalog_nuts(bolt_catalog) }}

## Washers

The following table presents the various washers that USAIN is able to select internally.

!!! note "No washers when using round nuts"
    If round nuts are used (i.e. if input [`tighteningMethod`](./inputfile.md#tighteningmethod-string-required) is set to `tension`), USAIN uses the washer with label `NO_WASHER`.
    As you can see in the table, this is a washer with zero dimensions.

{{ macro_bolt_catalog_washers(bolt_catalog) }}

## Extenders

If a bolt extender is needed (see also input [`lengthBoltExtender`](./inputfile.md#lengthboltextender-number-optional)) the following table presents the geometry of the bolt extenders that can be used.

!!! warning "Bolt extenders with enlarged bolt holes"
    If enlarged bolt holes are used in the design, the following extender geometries might not be able to bear the surface pressure.
    In this case, special care needs to be taken.
    Assess the integrity of the extender and flange surface and, if needed, design a custom bolt extender.
    This cannot be modelled in USAIN, so the BCD and bolt distance need to be determined manually.

{{ macro_bolt_catalog_extenders(bolt_catalog) }}

## Tightening tools

!!! inline end "No thin sockets for installation"
    For installation (high torque levels), thin-walled torque sockets are not preferred because they break more easily.
    USAIN will always select normal sockets for installation when input [`tighteningMethod`](./inputfile.md#tighteningmethod-string-required) is set to `torque`.

The following table gives an overview of the tightening tools known to USAIN.
The table includes tools for temporary stages and for installation.

The label of the tool reflects the applicable bolt/stud (type and size), type of tool and the type of the site (onshore/offshore).

The tool sizes may differ in radial and circumferential direction; the former is used for the BCD calculations and the latter for bolt distance calculations.
For more info, see the inputs [`TOOL_DIMENSION_RADIAL_DIR`](./expert-inputs.md#tooldimensionradialdir-number) and [`TOOL_DIMENSION_CIRC_DIR`](./expert-inputs.md#tooldimensioncircdir-number).

The listed preload values correspond to the *nominal preload* ($F_V$).
For tension-tightened fasteners, the preload values may need to be penalized for *intended* flange tilt.
If this is the case, use the [`BoltFLs.CUSTOM_PRELOAD`](./expert-inputs.md#boltflscustompreload-number) and related inputs to provide reduced preload values.

{{ macro_bolt_catalog_tools(bolt_catalog) }}
