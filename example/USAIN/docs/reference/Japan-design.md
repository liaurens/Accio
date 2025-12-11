# Input file description for Japanese specific designs

This section describes the USAIN inputs which are specifically applicable to design flanges for the Japanese market.
As such, this will only cover the different settings for a Japanese design run compared to a "rest of the world" design.
An exhaustive list, including the ones indicated here, can be found for [main inputs](../reference/inputfile.md) and [expert inputs](../reference/expert-inputs.md) at their respective pages.

!!! important "Potential discrepancies with design rules?"
    The design rules is always the main source and therefore leading.
    The list here is merely to get a quick overview of differences between `ROW` and `JPN` designs.

| Input | Value | Short description |
| ----- | ------- | ----------------- |
| [`countryCode`](../reference/inputfile.md#countrycode-string-optional) | `JPN` | To include specific Japanese checks and internal validations. |
| [`boltOptions`](../reference/inputfile.md#boltoptions-list-of-strings) | `JIS_M**` | Japanese bolts have labels starting with JIS, valid size options are: `M42`, `M48`, `M56`, `M64` and `M72`. |
| [`lengthBoltExtender`](../reference/inputfile.md#lengthboltextender-number-optional) | 0 | Bolt extenders are not allowed in Japan. |
| [`Loads.tag`](../reference/inputfile.md#loadstag-string) | | Event tag for ULS subset, valid options are: `shortTerm`, `longTerm` and `seismic` |
| [`E_BOLT`](../reference/expert-inputs.md#ebolt-number) | 205 | Elastic modulus for bolt material. Deviates from `ROW` |
| [`E_FLANGE`](../reference/expert-inputs.md#eflange-number) | 205 | Elastic modulus for flange material. Deviates from `ROW` |
| [`FLANGE_STEEL_TYPE`](../reference/expert-inputs.md#flangesteeltype-string) | `SF520` | Steel type of flange. Deviates from `ROW` |
| [`REACTION_DISTANCE_METHOD`](../reference/expert-inputs.md#reactiondistancemethod-string) | `tobinaga` | Only `tobinaga` is allowed. |
| [`DO_ASSESS_ULS_JPN`](../reference/expert-inputs.md#doassessulsjpn-boolean) | `true` | Toggle to perform extreme load resistance check. |
| [`PSF_BOLT_RESISTANCE_JPN_TAG`](../reference/expert-inputs.md#psfboltresistancejpntag-string) | `shortTerm longTerm seismic` | (Optional)Loads tag to indicate different subsets to the PSF on bolt tension resistance ($F,tRd$). |
|[`PSF_BOLT_RESISTANCE_JPN`](../reference/expert-inputs.md#psfboltresistancejpn-number) | 1.25 1.875 1.0 | PSF on bolt tension resistance ($F,tRd$), for each linked loads tag in `PSF_BOLT_RESISTANCE_JPN_TAG`. |
