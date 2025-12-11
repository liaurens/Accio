# Flange tilt calculations

For the SGRE2.0 bolt force model in USAIN, the mathematical implementation of computing the force required to close a tilted flange differs from the documentation in IEC 614000-6:2020/AMD1:2024.
This document is written to show the analogy and proof that the implementation in USAIN is equal to the formulation of IEC 614000-6/AMD1.

The symbols of the equations on this page are not explained, as it is irrelevant for its purpose.

## Generalization of IEC formulation

The formulation of IEC 614000-6/AMD1 is taken from G.3.3:

<equation>
$\begin{align}
\begin{bmatrix}
\frac{1}{2Kn^3} & \frac{1}{2Kn^2} \\
\frac{1}{2Kn^2} & \frac{1}{Kn}
\end{bmatrix}
\cdot
\left(
\begin{bmatrix}
\frac{1}{2Kn^3} + \frac{R_{shell}^2}{E \cdot w \cdot t} & \frac{1}{2Kn^2} \\
\frac{1}{2Kn^2} & \frac{1}{Kn} + \frac{12 R_{shell}^2}{E \cdot w \cdot t^3}
\end{bmatrix}^{-1}
\cdot
\begin{bmatrix}
0 \\
\frac{12 \cdot M_{incl} \cdot R_{shell}^2}{E \cdot w \cdot t^3}
\end{bmatrix}
\right)
=
\begin{bmatrix}
u_x \\
\alpha_S
\end{bmatrix}
\end{align}$
</equation>

The parameter of interest is $\alpha_S$, i.e. the flange tilt angle.

The full equation can be generalized as follows:

<equation>
$\begin{bmatrix}
c_{11} & c_{12} \\
c_{21} & c_{22}
\end{bmatrix}
\cdot
\left(
\begin{bmatrix}
\delta_{11} & \delta_{12} \\
\delta_{21} & \delta_{22}
\end{bmatrix}^{-1}
\begin{bmatrix}
\delta_{0,1} \\
\delta_{0,2}
\end{bmatrix}
\right)
=
\begin{bmatrix}
u_x \\
\alpha_S
\end{bmatrix}$
</equation>

## Implementation in USAIN

The inverse of matrix $\underline{\underline{\mathbf{\delta}}}$ can be written as:

<equation>
$\underline{\underline{\mathbf{\delta}}}^{-1} =
\begin{bmatrix}
\delta_{11} & \delta_{12} \\
\delta_{21} & \delta_{22}
\end{bmatrix}^{-1}
=
\frac{1}{\det{\underline{\underline{\mathbf{\delta}}}}}
\begin{bmatrix}
\delta_{22} & -\delta_{12} \\
-\delta_{21} & \delta_{11}
\end{bmatrix}$
</equation>

where

<equation>
$\det \underline{\underline{\mathbf{\delta}}} = \delta_{11} \delta_{22} - \delta_{12} \delta_{21}$
</equation>

When substituting this into the generalized formula from IEC 614000-6/AMD1 and noting that $\delta_{0,1} = 0$, a single equation can be formulated to solve for $\alpha_{s}$:

<equation>
$\alpha_S = \frac{\delta_{0,2}}{\det \underline{\underline{\mathbf{\delta}}}} \cdot
\left( c_{22} \delta_{11} - c_{12} \delta_{12} \right)$
</equation>

Further simplification of this formula is achieved by noting that $c_{12} = c_{21} = \delta_{12} = \delta_{21}$:

<equation>
$\alpha_S = \frac{\delta_{0,2} \cdot \left( c_{22} \delta_{11} - c_{12}^2 \right)}{\delta_{11} \delta_{22} - c_{12}^2}$
</equation>

The symbols in this equation are used as such in the source code, e.g. the variable for $\delta_{11}$ is named `d11`, etc.

Test `calc_tilt_closing_force__usain_implementation_equals_amd1` in `matlab\of\struct\USAIN\+usain\+sgre2\+test\FlangeTiltMechanics_Test.m` give proof that the implementation in USAIN is equal to solving the IEC 614000-6/AMD1 equations.

## Further information

The equation from G.3.3 in IEC 614000-6/AMD1 is derived from shell theory, and for ease of formulation it can be generalized as follows:

<equation>
$\underline{\mathbf{X}} = \underline{\underline{-\mathbf{\delta}}}^{-1}\underline{\mathbf{\delta_0}}=\begin{bmatrix}
v_1 \\
m_1
\end{bmatrix}$
</equation>

or

<equation>
$\begin{bmatrix}
\delta_{11} & \delta_{12} \\
\delta_{21} & \delta_{22}
\end{bmatrix}^{-1}
\begin{bmatrix}
\delta_{0,1} \\
\delta_{0,2}
\end{bmatrix}
=
\begin{bmatrix}
v_1 \\
m_1
\end{bmatrix}$
</equation>

Deflection and rotation of the flange follow as:

<equation>
$\begin{bmatrix}
c_{11} & c_{12} \\
c_{21} & c_{22}
\end{bmatrix}
\begin{bmatrix}
v_1 \\
m_1
\end{bmatrix}
=
\begin{bmatrix}
u_x \\
\alpha_S
\end{bmatrix}$
</equation>

Using the generalized formulation, the equation from IEC 614000-6/AMD1 can be written as:

<equation>
$\begin{bmatrix}
c_{11} & c_{12} \\
c_{21} & c_{22}
\end{bmatrix}
\cdot
\left(
\begin{bmatrix}
\delta_{11} & \delta_{12} \\
\delta_{21} & \delta_{22}
\end{bmatrix}^{-1}
\begin{bmatrix}
\delta_{0,1} \\
\delta_{0,2}
\end{bmatrix}
\right)
=
\begin{bmatrix}
u_x \\
\alpha_S
\end{bmatrix}$
</equation>

For sake of completeness, each generalized entry is fully described next:

<equation>
$\begin{align}
&c_{11} = \frac{1}{2Kn^3} & &\delta_{11} = \frac{1}{2Kn^3} + \frac{R_{shell}^2}{E \cdot w \cdot t} \\
&c_{12} = c_{21} = \frac{1}{2Kn^2} & &\delta_{12} = \delta_{21} = \frac{1}{2Kn^2}\\
&c_{22} = \frac{1}{Kn}    & &\delta_{22} = \frac{1}{Kn} + \frac{12 R_{shell}^2}{E \cdot w \cdot t^3}  \\
&                         & &\delta_{0,1} = 0 \\
&                         & &\delta_{0,2} = \frac{12 M_{incl} R_{shell}^2}{E \cdot w \cdot t^3} \\
\end{align}$
</equation>
