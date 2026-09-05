# Audience interface v3 — Button 3 calibration

| Action | Meaning | NeoPixel |
| --- | --- | --- |
| Normal operation | calibrated and ready | green |
| Hold Button 3 for two seconds | recalibrate accelerometer | blue |
| Press Button 4 | send the existing kill-all control to Max | red while held |

For calibration, hold Button 3 until the light turns blue, release it, place
the interface in the intended neutral position, and keep it still. Calibration
does not begin until the button is actually released. The firmware then waits
half a second for your hand to settle and averages 60 readings (about two
seconds). The light turns green when the new neutral position is ready.

Button 4 is no longer used for calibration. Its existing serial message remains
`button_4 1` while pressed, so the Max kill-all routing does not need to change.
