# Mode 3 — transformative memory

Mode 3 no longer responds directly to the newest Wekinator message. It reads a
rolling window of approximately ten seconds and turns that history into a
slowly changing ecosystem. The aim is to make the system recognisably related
to performer/audience behaviour without simply replaying their control.

| Remembered source | Visual consequence | Autonomous departure |
| --- | --- | --- |
| Performer volume | ecosystem energy and bee population | slow internal variation alters speed |
| Performer density | flower population and swarm agitation | blended into a longer-lived mood |
| Performer pitch | preferred vertical flower height | slow drift can move to a neighbouring height |
| Audience movement | a smaller contribution to energy | cannot dictate the swarm speed directly |
| Audience left/centre/right | 30% of horizontal target | 70% comes from slow system movement |
| Audience heat/neutral/storm | 65% of remembered climate | 35% comes from slow system climate drift |

## Why `noise()` rather than `random()`

`random()` chooses an unrelated new number on every call, which made the old
autonomous decision liable to flicker. Processing's `noise()` produces nearby
values as its input changes, so it behaves more like a slowly wandering line.
It remains unpredictable over time but is continuous enough to perceive as
intentional behaviour.

## Why `lerp()` is used

`lerp(current, target, amount)` moves only part of the distance to the target on
each frame. Small amounts such as `0.012` give the system inertia: new memories
influence it gradually instead of switching the weather, colour or swarm state
immediately.

## Quick test

1. Stay in Mode 1 for at least ten seconds and deliberately create a strong,
   recognisable history—for example loud/dense playing, repeated storm tilt,
   and repeated movement to the left.
2. Move to Mode 3.
3. Expect more/faster bees and a storm tendency, but not an exact copy: the
   horizontal swarm target should wander and only lean towards the remembered
   left side.
4. Repeat with quiet/sparse playing, heat tilt and movement to the right.
5. Watch the console every five seconds for `energy`, `mood`, `heat`, and
   `storm`. These values should move gradually rather than jump.

Button 3's former manual/autonomous mode messages are now ignored by Processing
so that a two-second Button 3 hold can be used safely for Arduino calibration.
The physical slider remains the sole selector for Modes 1, 2 and 3.
