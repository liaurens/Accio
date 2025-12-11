# Welcome to USAIN - v{{ usain_changelog.changelog[0].version }}

Welcome to **USAIN**: the **U**ser interface for **S**tub **A**ssemblies with **I**mmense **N**uts!

![USAIN logo](img/logo.png){: style="height:150px"}

!!! question "Looking for help on commands and inputs?"
    See [Reference guides](./reference/index.md)

## Contents

A high-level overview of the structure of this documentation:

- [Tutorials](./tutorials/index.md) (start here): For the new USAIN users, a hands-on introduction to the tool
- [How-to guides](./howto/index.md): Guides and recipes for common problems and tasks
- [Reference](./reference/index.md): Covers USAIN inputs and commands
- [Explanation](./explanation/index.md): Explanation and discussion of key topics and concepts
- [About](./about/index.md): Changelog and background info on changes

## The basic concept

USAIN is an engineering tool for designing or checking support structure L- and T-flange connections.
Using analytical models, several design criteria are evaluated.
For example: ultimate capacity of the flange, fatigue capacity of the bolts and several "soft-criteria" like bolt thread requirements.

The output will be a cost-optimal flange connection design, where the flange thickness, flange width, number of bolts and bolt type are used as design parameters.

The tool is able to operate stand-alone, decoupled from StructuralModel.
Providing a StructuralModel is possible and greatly simplifies the inputs that are needed.
Also, USAIN will then automatically update the StructuralModel with the updated flange geometry and mass.

Since USAIN is part of the TEXACO design tool chain, it can be used *in the loop* for support structure design optimisation.
