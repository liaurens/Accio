# Closed from solution derivation of ULS failure modes

The ULS failure modes B, D and E need to be solved iteratively when using the formulation from literature (and the Design Brief).
In USAIN however, a closed-form solution is derived and implemented.
The main reason for doing so is that solving the closed-form equations is significantly faster.

The following sections show the derivation of these closed-form expressions, as the equations can otherwise not easily be compared to the usual formulation in literature.

## L-flange failure modes

For an L-flange, the expression for failure mode B, D and E may be generalized as follows:

$$
[1]
F_{U,i} = \frac{M_i + M_{pl,3}}{L_i}
$$

where

$$
[2]
M_{pl,3} = \left[1 - \left(\frac{F_{U,i}}{f_y \cdot t_s \cdot c^*}\right)^2\right] \cdot \frac{f_y \cdot t_s^2 \cdot c^*}{4}
$$

In [1], $M_i$ and $L_i$ differ for all three failure modes. For example for failure mode B, $M_B = F_{tR,d} \cdot a'$ and $L_B = a' + b_B$.

To find a closed form solution, the goal is to rewrite this into a quadratic equations which can be solved for $F_{U,i}$.

First, the expression for $M_{pl,3}$ in [2] is substituted in [1]:

$$
[3]
F_{U,i} = \frac{M_i + \left[1 - \left(\frac{F_{U,i}}{f_y \cdot t_s \cdot c^*}\right)^2\right] \cdot \frac{f_y \cdot t_s^2 \cdot c^*}{4}}{L_i}
$$

Expanding the terms in the right hand side of the equation gives:

$$
[4]
F_{U,i} = \frac{M_i}{L_i} + \frac{f_y \cdot t_s^2 \cdot c^*}{4 L_i} - \frac{F_{U,i}^2}{4 f_y \cdot c^* \cdot L_i}
$$

Rewriting [4] to quadratic from $ax^2+bx+c=0$:

$$
[5]
\frac{F_{U,i}^2}{4 f_y \cdot c^* \cdot L_i} + F_{U,i} - \frac{M_i}{L_i} - \frac{f_y \cdot t_s^2 \cdot c^*}{4L_i} = 0
$$

The solutions to this equation are found by solving:

$$
[6]
F_{U,i} = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
$$

where the coefficients in [6] are:

$$
\begin{align*}
a &= \frac{1}{4 f_y \cdot c^* \cdot L_i}\\
b &= 1 \\
c &= - \frac{M_i}{L_i} - \frac{f_y \cdot t_s^2 \cdot c^*}{4L_i}
\end{align*}
$$

For failure mode B, D and E, the generic terms $M_i$ and $L_i$ can be replaced by:

$$
\begin{matrix}
M_B = F_{tR,d} \cdot a'  & \qquad M_D = M'_{pl,2} + \Delta M_{pl,2} & \qquad M_E = M_{pl,2} \\
L_B = a' + b_B           & \qquad L_D = b_D                         & \qquad L_E = b_E
\end{matrix}
$$

## T-flange failure modes

For T-flanges, the expressions for failure mode B, D and E may be generally denoted as follows, where the term for $M_{pl,3}$ is already expanded:

$$
[1]
F_{U,i} = 2 \cdot \frac{M_i + \sqrt{1 - \left(\frac{F_{U,i} / 2}{\frac{1}{\sqrt{3}} \cdot f_y \cdot t_f \cdot c^*}\right)^2} \cdot \frac{f_y \cdot t_f^2 \cdot c^*}{4}}{L_i}
$$

where $M_i$ and $L_i$ differ for all three failure modes.

The generic equation in [1] will be rewritten into a quadratic from $ax^2+bx+c=0$.

First raising both sides of the equation to the power of two, noting that $(a + b)^2 = a^2 + 2ab + b^2$.

$$
[2]
F_{U,i}^2 = \frac{4 M_i^2}{L_i^2}
+ 2 \cdot \frac{2 M_i}{L_i}  \left( \sqrt{1 - \left(\frac{F_{U,i} / 2}{\frac{1}{\sqrt{3}} \cdot f_y \cdot t_f \cdot c^*}\right)^2} \cdot \frac{f_y \cdot t_f^2 \cdot c^*}{2 L_i}\right)
+ \left( 1 - \left(\frac{F_{U,i} / 2}{\frac{1}{\sqrt{3}} \cdot f_y \cdot t_f \cdot c^*}\right)^2  \right)\cdot \frac{f_y^2 \cdot t_f^4 \cdot c^{*2}}{4L_i^2}
$$

Working out the last term to simplify the equation.

$$
[3]
F_{U,i}^2 = \frac{4 M_i^2}{L_i^2}
+ 2 \cdot \frac{2 M_i}{L_i}  \left( \sqrt{1 - \left(\frac{F_{U,i} / 2}{\frac{1}{\sqrt{3}} \cdot f_y \cdot t_f \cdot c^*}\right)^2} \cdot \frac{f_y \cdot t_f^2 \cdot c^*}{2 L_i}\right)
+  \frac{f_y^2 \cdot t_f^4 \cdot c^{*2}}{4L_i^2}  - \frac{3 \cdot F_{U,i}^2 \cdot t_f^2}{16 \cdot L_i^2}
$$

The second term on the right hand side is similar to equation [1], so substitute the part indicated in between brackets.

$$
[4]
F_{U,i}^2 = \frac{4 M_i^2}{L_i^2}
+ 2 \cdot \frac{2 M_i}{L_i} \cdot \left( F_{U,i} - \frac{2 M_i}{L_i} \right)
+  \frac{f_y^2 \cdot t_f^4 \cdot c^{*2}}{4L_i^2}  - \frac{3 \cdot F_{U,i}^2 \cdot t_f^2}{16 \cdot L_i^2}
$$

Furthermore, expanding all terms and re-ordering would lead to

$$
[5]
\left(\frac{3 \cdot t_f^2}{16 \cdot L_i^2} + 1\right) F_{U,i}^2
- \frac{4 M_i}{L_i} F_{U,i}
+ \frac{4 M_i^2}{L_i^2} - \frac{f_y^2 \cdot t_f^4 \cdot c^{*2}}{4L_i^2} = 0
$$

As this is a quadratic equation $ax^2+bx+c=0$, the solutions to equation [5] are found by solving:

$$
[6]
F_{U,i} = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
$$

where the coefficients in [6] are:

$$
\begin{align*}
a &= \frac{3 \cdot t_f^2}{16 \cdot L_i^2} + 1 \\
b &= -\frac{4 M_i}{L_i} \\
c &= \frac{4 M_i^2}{L_i^2} - \frac{f_y^2 \cdot t_f^4 \cdot c^{*2}}{4L_i^2}
\end{align*}
$$

For failure mode B, D and E, the generic terms $M_i$ and $L_i$ can be replaced by:

$$
\begin{matrix}
M_B = F_{tR,d} \cdot a'  & \qquad M_D = M'_{pl,2} + \Delta M_{pl,2} & \qquad M_E = M_{pl,2} \\
L_B = a' + b_B           & \qquad L_D = b_D                         & \qquad L_E = b_E
\end{matrix}
$$

## Selecting physical solution

Two solutions (roots) will be found for the closed-form solution, similar to the fact that $x^2 = 4$ has two solutions $x = 2$ and $x = -2$.
Only one of these solutions is physically correct for a failure mode. Selecting the physically correct value is done as follows:

1. In case one of the solutions is a complex number, the other is selected. In the rare case both are complex numbers, USAIN will eventually error.
2. In case both solutions are real numbers, the maximum value is selected. Usually in this case, one value is negative and one is positive.
