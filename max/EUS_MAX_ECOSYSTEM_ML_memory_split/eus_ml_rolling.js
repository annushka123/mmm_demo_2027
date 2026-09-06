// Max's ordinary js object (ES5). Audio remains in record~/play~.
autowatch = 1;
inlets = 1;
outlets = 4; // record commands, play commands, analysis 1/0, diagnostics
var requested = false, dspOn = false, recording = false, playing = 0;
var slot = 1, queue = [], captureMs = 10000;
function randomCaptureMs() { return 10000 + Math.floor(Math.random() * 10001); }
var rotateTask = new Task(rotate, this);
var nextPlayTask = new Task(playNext, this);
function report(key, value) { outlet(3, [key, value]); }
function msg_int(n) {
  requested = n !== 0;
  if (requested && dspOn) start();
  else if (!requested) halt();
}
function dsp(n) {
  dspOn = n !== 0;
  if (!dspOn) halt();
  else if (requested) start();
}
function start() {
  if (recording) return;
  recording = true;
  beginSlot();
  rotateTask.schedule(captureMs); // Wait for the whole recorded snippet.
}
function beginSlot() {
  // Do not read a buffer while overwriting it, even after a scheduler delay.
  var kept = [];
  for (var i = 0; i < queue.length; i++) if (queue[i].slot !== slot) kept.push(queue[i]);
  queue = kept;
  if (playing === slot) {
    outlet(1, "stop");
    playing = 0;
    outlet(2, 0);
  }
  captureMs = randomCaptureMs();
  outlet(0, ["set", "memory_" + slot]);
  outlet(0, "reset");
  outlet(0, 1);
  report("buffer", slot);
  report("recording", 1);
}
function rotate() {
  if (!recording || !dspOn) return;
  outlet(0, 0);
  queue.push({slot:slot, duration:captureMs});
  slot = slot % 5 + 1;
  beginSlot();
  if (!playing) playNext();
  rotateTask.schedule(captureMs);
}
function playNext() {
  if (!recording || !dspOn || playing || !queue.length) return;
  var snippet = queue.shift();
  playing = snippet.slot;
  outlet(1, ["set", "memory_" + playing]);
  outlet(2, 1); // Reset the note tracker before any playback audio.
  report("playing", playing);
  outlet(1, ["start", 0, snippet.duration]);
}
function done() {
  if (!playing) return;
  playing = 0;
  outlet(2, 0); // Flush the last note before building this phrase.
  report("playing", 0);
  // Let note-off and model-build messages finish before the next phrase.
  nextPlayTask.schedule(20);
}
function halt() {
  rotateTask.cancel();
  nextPlayTask.cancel();
  recording = false;
  outlet(0, 0);
  outlet(1, "stop");
  if (playing) outlet(2, 0);
  playing = 0;
  queue = [];
  report("recording", 0);
  report("playing", 0);
}
function notifydeleted() { rotateTask.cancel(); nextPlayTask.cancel(); }
