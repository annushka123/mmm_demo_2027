// Phrase timing and a guard around the existing five ml.markov objects.
// This is not a replacement Markov algorithm. ml.markov still learns/generates.
autowatch = 1;
inlets = 1;
outlets = 9;
// 0 pitch, 1 velocity, 2 chord count, 3 onset interval ms, 4 duration ms;
// 5 common model commands; 6 generation control; 7 status; 8 memory start/stop.
var modeNumber = 1, killed = true, dspOn = false, ready = false, building = false;
var haveMode = false;
// Mode 2 only: bounded output followed by a random quiet gap.
// This clock does not detect live phrases or replace buffer-based learning.
var outputWindow = false, gapWaiting = false, midiRunning = false;
var windowTask = new Task(windowEnded, this);
var gapTask = new Task(gapEnded, this);
function randomPeriod() { return 10000 + Math.floor(Math.random() * 10001); }
function cancelOutputTiming() {
  windowTask.cancel(); gapTask.cancel(); outputWindow = false; gapWaiting = false;
}
function windowEnded() {
  outputWindow = false; gapWaiting = true; silence();
  status("state", "Mode 2 pause: 10-20 seconds; buffers keep learning");
  gapTask.schedule(randomPeriod());
}
function gapEnded() { gapWaiting = false; runIfReady(); }
function mayGenerate() {
  return !killed && dspOn && ready && !building &&
    (modeNumber === 3 || (modeNumber === 2 && outputWindow && !gapWaiting));
}
var phraseActive = false, activeNote = null, previousOnset = -1;
var pending = [], learned = 0, orderValue = 2;
// Completed buffers only. Mode 2 loads latestBuffer; Mode 3 loads history.
// Resetting the native chains for Mode 2 never clears the session archive.
var latestBuffer = [], history = [], completedBuffers = 0, activeModelNotes = 0;
var commitTask = new Task(commit, this);
var readyTask = new Task(built, this);
function now() { return new Date().getTime(); }
function bounded(n, lo, hi) { return Math.max(lo, Math.min(hi, n)); }
function status(key, value) { outlet(7, [key, value]); }
function control(key, value) { outlet(6, [key, value]); }
function loadbang() {
  outlet(5, ["order", orderValue]);
  outlet(5, ["dynamic", 1]);
  status("notes", 0); status("ready", 0); status("mode", 1);
  reportMemory();
  status("state", "Select a mode to start recording");
}
function silence() {
  midiRunning = false;
  control("run", 0);
  control("flush", "bang"); // Send note-offs BEFORE closing the gate/changing channel.
  control("gate", 0);
}
function runIfReady() {
  if (!killed && dspOn && ready && !building && modeNumber === 2 && !outputWindow && !gapWaiting) {
    outputWindow = true;
    windowTask.schedule(randomPeriod());
  }
  if (mayGenerate()) {
    if (!midiRunning) {
      midiRunning = true; control("gate", 1); control("run", 1);
    }
  } else if (midiRunning) silence();
}
function mode(n) {
  n = Number(n);
  if (!isFinite(n) || n !== Math.round(n) || n < 1 || n > 3) return;
  haveMode = true;
  if (n === modeNumber && !killed) return;
  cancelOutputTiming(); silence();
  modeNumber = n; killed = false;
  control("channel", n === 3 ? 3 : 1);
  status("mode", n);
  outlet(8, 1);
  rebuildSelectedMemory();
}
function dsp(n) {
  dspOn = n !== 0;
  if (!dspOn) { cancelOutputTiming(); silence(); }
  runIfReady();
}
function kill() {
  killed = true;
  cancelOutputTiming(); silence();
  outlet(8, 0);
  status("state", "Stopped; select a mode to resume");
}
function begin() {
  activeNote = null; previousOnset = -1; phraseActive = true;
}
function note(pitch, velocity) {
  if (!phraseActive) return;
  pitch = Math.round(pitch); velocity = Math.round(velocity);
  if (!isFinite(pitch) || !isFinite(velocity) || pitch < 48 || pitch > 100) return;
  var t = now();
  if (velocity > 0) {
    if (activeNote) finish(t);
    var interval = previousOnset < 0 ? 0 : t - previousOnset;
    activeNote = {pitch: pitch, velocity: bounded(velocity, 1, 127), start: t, interval: interval};
    previousOnset = t;
  } else if (activeNote && activeNote.pitch === pitch) finish(t);
}
function finish(t) {
  if (!activeNote) return;
  var duration = t - activeNote.start;
  if (duration >= 1) {
    // fzero~ is monophonic, so each tracked note has chord count 1.
    // Milliseconds are used throughout, without the old 20x seq multiplier.
    pending.push([
      activeNote.pitch, activeNote.velocity, 1,
      Math.round(bounded(activeNote.interval || duration, 1, 20000)),
      Math.round(bounded(duration, 1, 20000))
    ]);
    status("notes", learned + pending.length);
  }
  activeNote = null;
}
function end() {
  finish(now()); phraseActive = false;
  commitTask.cancel(); commitTask.schedule(10);
}
function reportMemory() {
  status("buffers", completedBuffers);
  status("latestnotes", latestBuffer.length);
  status("modelnotes", activeModelNotes);
}
function commit() {
  // Called once after each completed buffer, including buffers with no notes.
  // Empty/short latest snippets must not silently reuse an older Mode 2 model.
  latestBuffer = pending; pending = [];
  for (var i = 0; i < latestBuffer.length; i++) history.push(latestBuffer[i]);
  learned = history.length; completedBuffers++;
  status("notes", learned);
  rebuildSelectedMemory();
}
function rebuildSelectedMemory() {
  silence(); readyTask.cancel();
  ready = false; building = true; status("ready", 0);
  var observations = modeNumber === 2 ? latestBuffer : history;
  activeModelNotes = observations.length;
  reportMemory();
  // Same reset -> observations -> Build ordering as the working example.
  // Session history is separate, so switching back to Mode 3 restores it.
  outlet(5, "reset");
  outlet(5, ["order", orderValue]); outlet(5, ["dynamic", 1]);
  for (var i = 0; i < observations.length; i++) {
    for (var column = 0; column < 5; column++) outlet(column, observations[i][column]);
  }
  if (activeModelNotes < orderValue + 2) {
    building = false;
    // No output window should run against an empty/unbuilt latest model.
    // Keep any existing pause; it must not be shortened by a rebuild.
    if (modeNumber === 2 && outputWindow) {
      windowTask.cancel(); windowEnded();
    }
    status("state", modeNumber === 2 ?
      "Latest buffer has fewer than 4 notes; waiting for the next buffer" :
      "Session memory needs at least 4 tracked notes; keep playing");
    return;
  }
  outlet(5, "build");
  readyTask.schedule(1);
}
function built() {
  ready = true; building = false;
  status("ready", 1);
  status("state", killed ? "Model built; select a mode to resume" : (modeNumber === 2 && gapWaiting ? "Mode 2 pause: latest-buffer model rebuilt" : (modeNumber === 2 ? "Mode 2: playing latest-buffer model" : "Session-memory model built")));
  runIfReady();
}
function generate() {
  if (mayGenerate()) control("tick", "bang");
}
function build() { rebuildSelectedMemory(); }
function resetmodel() {
  cancelOutputTiming(); silence(); commitTask.cancel(); readyTask.cancel();
  activeNote = null; previousOnset = -1; phraseActive = false; pending = []; learned = 0;
  latestBuffer = []; history = []; completedBuffers = 0; activeModelNotes = 0;
  ready = false; building = false;
  outlet(5, "reset"); outlet(5, ["order", orderValue]); outlet(5, ["dynamic", 1]);
  status("notes", 0); status("ready", 0); reportMemory();
  status("state", "Memory cleared; play a new phrase");
}
function notifydeleted() { cancelOutputTiming(); commitTask.cancel(); readyTask.cancel(); }

// Mode inputs retain the baseline's two sources. There are no manual mode
// test buttons that could leave Max in a different mode from Processing.
function hardwaremode(n) {
  if (!validmode(n)) return;
  status("source", "Interface slider"); mode(n);
}
function processingmode(n) {
  if (!validmode(n)) return;
  status("source", "Processing autonomous slider");
  // Automatic changes must not undo a user's kill command.
  if (killed && haveMode) {
    modeNumber = Number(n);
    status("mode", modeNumber);
    status("state", "ML stopped; move the physical slider or click resume");
    return;
  }
  mode(n);
}
function validmode(n) {
  n = Number(n);
  return isFinite(n) && n === Math.round(n) && n >= 1 && n <= 3;
}
function resume() {
  if (!haveMode) {
    status("state", "Move the interface slider to establish its mode");
    return;
  }
  mode(modeNumber);
}
