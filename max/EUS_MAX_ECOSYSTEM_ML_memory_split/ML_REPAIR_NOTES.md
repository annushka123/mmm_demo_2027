# Latest-buffer learning in Mode 2; accumulated memory in Mode 3

Open EUS_ECO.maxpat with the two supplied JavaScript files beside it.
Close the earlier ecosystem copy first.

## Approved change

Mode 2 resets the five native ml.markov chains, trains them with the latest
completed buffer's notes, and sends Build before allowing generation. This
restores the reset/retrain approach found in your working EUS_MARKOV example.
The audio-buffer analysis path remains in place; the example's old MIDI-file
recording and 44-second scheduler have not been substituted for it.

Mode 3 uses all completed buffers' note observations accumulated during this
session. They are stored separately from the native chains. Switching to Mode 2
therefore does not destroy Mode 3's history. Switching modes reloads and rebuilds
the appropriate data. Mode 1 continues recording and collecting observations,
with ML MIDI muted.

An empty latest buffer clears Mode 2's old model and leaves it silent. A buffer
with fewer than four usable note events waits for the next buffer, rather than
silently playing an older Mode 2 model. The existing order-2/four-note readiness
requirement remains. Mode 3 can still use earlier nonempty recordings.

The replacement's 50-ms duration filter and 80-ms onset floor have been removed.
Positive measured note durations and spacing are retained down to 1 ms, up to
20 seconds. This removes a later processing restriction; it does not guarantee
that fzero~ will detect every fast or overlapping note.

## Timing and routing preserved

- Recorded snippets remain random 10–20 seconds, in five rotating buffers.
- Mode 2 output remains 10–20 seconds followed by 10–20 seconds of pause.
- A new model rebuild does not cancel a pending pause.
- Mode 3 remains autonomous on channel 3; Mode 2 uses channel 1.
- Recording and buffer-based analysis continue in all modes and during pauses.
- Kill and audio-off stop generation and release held MIDI notes.
- No live-input phrase detector has been added.
- All non-ML root objects, connections, effects, and the six companion Max files
  are preserved from the uploaded ecosystem baseline. Arduino, Wekinator,
  Processing, audio devices and Logic routing have not been changed.

## Check that new buffers are being used

Inside p ml_mode, there are now three counters on the right:

1. Completed buffers: increases when a buffer finishes analysis.
2. Notes in latest buffer: note events extracted from that buffer.
3. Notes in active model: in Mode 2, matches the latest-buffer count; in Mode 3,
   includes all session history.

Play at least four distinct notes for a full recording and analysis cycle.
Then play a contrasting phrase. In Mode 2, the active model is replaced when
that new buffer finishes analysis. It is not updated immediately from the live
microphone. Empty or insufficient buffer data leaves Mode 2 silent.

If Completed buffers increases but Notes in latest buffer stays at zero, the
remaining issue is upstream note extraction/input, not the memory selection.
The model counters describe data sent for training, not an external model's
acknowledgement that it trained successfully.

## Validation and limits

Simulations verified two disjoint note sequences: Mode 2's second model contains
only the second buffer, while Mode 3 restores both. Also checked short notes,
empty buffers, cumulative Mode 1 learning, mode changes during buffer analysis,
manual rebuilds, pauses during training, kill during Build, audio-off and reset.
Native model commands are ordered reset -> order/dynamic -> data -> Build.
Checked nested patchline endpoints and preserved non-ML content. The recorder
helper is byte-for-byte unchanged from the pause version.

Max, ml.star, Logic and your hardware could not be run here. These are code and
message-sequence checks, not a live audio test. Session memory is temporary and
is lost when the patch closes or the explicit resetmodel command is used.
