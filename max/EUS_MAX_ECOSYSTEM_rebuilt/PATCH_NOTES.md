# EUS MAX ecosystem — rebuilt signal map

This copy keeps the current musical behaviour but replaces the obsolete
disk-based `mel_*.aiff` memory path with the five-buffer rolling memory.

## What each mode now does in Max

| Physical mode | Rolling memory | Markov MIDI | Logic MIDI channel |
| --- | --- | --- | --- |
| Mode 1 — user/direct | recording continues | muted | — |
| Mode 2 — shared | recording continues | enabled | 1 |
| Mode 3 — autonomous/memory | recording continues | enabled | 3 |

`kill_all` stops rolling-memory recording, stops Markov generation and closes
the Markov MIDI gate.

## Rolling-memory sequence

1. Selecting any mode sends `1` to `p rolling_memory`.
2. It records live `receive~ audio` into five rotating 10-second buffers.
3. Whenever a buffer completes, recording immediately moves to the next one.
4. The completed buffer plays silently into `p pitch_tracker_ML_mode`.
5. The pitch tracker receives `1` at playback start and `0` from the end bang
   of `play~`; those events delimit each training phrase.

The first completed phrase is available after approximately 10 seconds.

## MIDI and Logic Pro

The final `noteout 1` is assigned to the virtual port `from Max 1`.

- In Logic, select **from Max 1** as the MIDI input for the software-instrument
  track.
- Mode 2 sends on MIDI channel 1.
- Mode 3 sends on MIDI channel 3, so it can address a different Logic track or
  sound if desired.
- Mode 1 deliberately suppresses generated Markov notes.

## Audio effects

`p multi_effects` now takes the live violin bus (`receive~ audio`) rather than
Max's `demosound.maxpat` test source.

- Button 1 cycles the delay/flanger preset; its long press bypasses that path.
- Button 2 enables the pitch shifter; its long press bypasses that path.
- The existing delay/flanger and `pfft~ gizmo_loadme` pitch-shifting algorithms
  are otherwise unchanged.

The effects still reach the audio device from inside their effect subpatches.
This is independent of the virtual **from Max 1** MIDI connection to Logic.
Routing processed audio into Logic would require a separate audio-loopback or
aggregate-device setup and is not part of this rebuild.

## Quick test

1. Turn Max DSP on and confirm the live-input meter responds.
2. Select Mode 1 and wait 10 seconds. Confirm the rolling-memory waveform fills
   and the buffer index advances, but Logic receives no generated notes.
3. Select Mode 2. Confirm Logic receives notes on channel 1.
4. Select Mode 3. Confirm Logic receives notes on channel 3.
5. Press the kill-all control. Confirm recording and generated notes stop.
6. Test Button 1 and Button 2 separately at a low monitoring level.

