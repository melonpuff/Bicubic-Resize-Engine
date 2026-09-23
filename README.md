# Bicubic Resize Engine

A Verilog RTL design that enlarges a region of a 128 x 128 RGB image using bicubic
interpolation. It reads pixels from an image ROM, converts them to grayscale,
interpolates, and writes 8-bit results to a result SRAM in raster order. `done` is
raised when every output pixel has been written.

## Modules

| File | Role |
|---|---|
| `bicubic.v` | Top controller. Picks a case for each output pixel, routes the active submodule's signals to the ports, and writes the result to SRAM. |
| `case_1.v` | Vertical-only interpolation (4 pixels in one column). |
| `case_2.v` | Horizontal-only interpolation (4 pixels in one row). |
| `case_3.v` | No interpolation. Copies 1 pixel. |
| `general.v` | Full 2-D interpolation (4 x 4 pixels). |
| `to_gray.v` | RGB-to-grayscale converter used by all submodules. |

## Key Algorithms

**Coordinate mapping.** Output pixel `(sc_x, sc_y)` maps to source pixel
`p(0) = (x0 + sc_x * (original_w - 1) / (scaled_w - 1), y0 + ...)`, and the
remainder of that division gives the fractional offset `x`, kept in fixed point.

**Case selection.** If an output pixel lands exactly on a source column or row, the
engine skips interpolation in that direction:

| Column aligned | Row aligned | Case |
|:---:|:---:|---|
| yes | yes | `case_3` |
| no | yes | `case_2` |
| yes | no | `case_1` |
| no | no | `general` |

**Grayscale.** `gray = (9R + 19G + 3B) / 32`, rounded to nearest.

**Bicubic.** From four samples `p(-1)..p(2)`:

$$
\begin{aligned}
&p(x) = (a x^3 + b x^2 + c x + d) / 2 \\
&a = -p(-1) + 3p(0) - 3p(1) + p(2) \\
&b = 2p(-1) - 5p(0) + 4p(1) - p(2) \\
&c = -p(-1) + p(1) \\
&d = 2p(0)
\end{aligned}
$$

The result is rounded and clamped to `[0, 255]`.

**2-D interpolation.** `general` interpolates each of the four rows horizontally, then
interpolates the four row results vertically.

**Borders.** A neighbor outside the image is replaced by the nearest edge pixel.

## State Machines

### `bicubic.v`

| State | Action |
|---|---|
| `hold` | Raises `done` if all output pixels are written. |
| `set_case` | Chooses `case_1`, `case_2`, `case_3` or `general`. |
| `case_1` / `case_2` / `case_3` / `general` | Waits for the submodule's finish signal. |
| `write` | Writes the result to SRAM, moves to the next pixel, returns to `hold`. |

### `general.v`

| State | Action |
|---|---|
| `hold` | Resets the row counter. |
| `col_0` .. `col_3` | Read four pixels of the current row from ROM. |
| `calculate_0` | Computes coefficients `a, b, c, d`. |
| `calculate_1` | Evaluates the polynomial. |
| `round` | Rounds and clamps the result. |
| `round_write` | Stores the result, then goes to `col_0` for the next row, to `calculate_0` for the vertical pass after the fourth row, or to `write` when done. |
| `write` | Outputs the pixel and signals finish. |

### `case_1.v` / `case_2.v`

| State | Action |
|---|---|
| `find_start` | Computes the start address. Waits until the top controller selects this case. |
| `finish` | Enables ROM reads. |
| `waiting`, `col0` .. `col3` | Read four pixels from ROM. |
| `calculate` | Evaluates the polynomial. |
| `round` | Rounds and clamps the result. |
| `write` | Signals finish. |

### `case_3.v`

| State | Action |
|---|---|
| `find_start` | Computes the pixel address. Waits until the top controller selects this case. |
| `finish` | Enables ROM reads. |
| `waiting_1`, `waiting_2` | Read the pixel from ROM. |
| `calculate` | Converts it to grayscale. |
| `write` | Signals finish. |
