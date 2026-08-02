# Automating a Seestar S50 with N.I.N.A.

The ZWO Seestar S50 is an all-in-one "smart telescope" - it has its own app that handles
GOTO, focus, stacking, and basic image processing on-device. That's great for casual use,
but it's a closed loop: no scheduling across multiple nights, no real sequencer, no
integration with the rest of a normal astrophotography pipeline (Siril, GraXpert, a
proper target-priority queue).

This project drives the S50 through [N.I.N.A.](https://nighttime-imaging.eu/) (Nighttime
Imaging 'N' Astronomy) instead - a real, full-featured capture sequencer - via NINA's HTTP
API, so a scheduler can plan and run a whole night across multiple targets unattended.

## Why this is possible at all

The S50 exposes itself as a set of standard ASCOM/Alpaca devices (camera, mount, focuser,
filter wheel), which is what lets NINA control it like any other telescope. The bridge to
NINA's own control surface is the community
[ninaAPI Advanced API plugin](https://github.com/christian-photo/ninaAPI) by
[christian-photo](https://github.com/christian-photo), which adds a full HTTP API on top of
NINA for capture, mount, focuser, and filter-wheel control, plate solving, and image
history/metadata - everything a scheduler needs, without touching NINA's UI at all.

## Architecture

```
Scheduler (target DB + priority-based night planner, astropy visibility curves)
    │
    ▼
Executor  ← drives NINA via the ninaAPI HTTP plugin, roof-status gated
    │
    ▼
N.I.N.A.  ← sequencer, autofocus, plate solving
    │  (ASCOM/Alpaca)
    ▼
ZWO Seestar S50  ← telescope + sensor + focuser + filter wheel (all-in-one)
```

The scheduler computes each target's altitude curve for the night (via
[astropy](https://www.astropy.org/)) and gives each one the widest still-unclaimed window
around its own peak, so a night's targets get scheduled by real visibility, not just a
fixed list.

### Not just a scheduled job - a real control surface

Worth calling out explicitly: the executor isn't only driven by the pre-planned nightly
schedule. The same code that runs a scheduled block is exposed as a control surface that a
Claude-based coding agent can drive conversationally too - "test the new centering logic on
NGC 6888 tonight, turn the dew heater on, it's humid" is a real request that kicks off the
exact same executor path described below, not a separate manual mode. The agent reads back
real telemetry (HFR, star counts, plate-solve results, mount state) while it runs, so it's
making judgment calls off actual data, not firing commands blind. Both paths - scheduled and
chat-triggered - go through identical code.

## Anatomy of one target block

Roughly in real order, whether triggered by the schedule or by chat:

1. **Roof status check.** Reads the remote observatory's own roof-status feed. Refuses to
   touch any equipment at all if it's not open - this gate runs again periodically
   throughout a long block too, in case the roof closes mid-session.
2. **Altitude re-check**, at the moment this target's turn actually comes up - not just
   when the night was originally planned. A target that's dropped below its minimum usable
   altitude by execution time either waits it out (if it's still rising) or gets skipped for
   the setting case.
3. **Connect equipment** - camera, focuser, filter wheel.
4. **Fresh darks for this target.** The S50's filter wheel has a real "Dark" position that
   physically blocks the optical path, so a real dark-frame library - matching this block's
   own exposure time and gain - gets captured automatically before every target, on top of
   (not instead of) the S50's own on-device dark subtraction.
5. **Switch to the imaging filter, slew to the target** (cable-wrap-aware - the S50's mount
   can wind its own power cable past a safe limit if not tracked carefully). The dew heater
   turns on right after the slew completes, when a session calls for it.
6. **Plate-solve-verified centering** - solve a frame, compare against the catalog
   coordinates, sync-and-re-slew if it's off by more than a couple of arcminutes, repeat
   until it converges. Runs *before* autofocus (see below for why).
7. **Autofocus.**
8. **The timed capture loop**, with two background checks running on their own independent
   cadence rather than every single frame:
   - every 5th frame, a plate-solve instead of a plain capture, to catch and correct real
     mount drift mid-session (see [Challenges](#challenges) below for why this exists)
   - every 20th frame, a check of the trailing focus-sharpness trend, auto-refocusing if
     it's drifted meaningfully worse since the last autofocus
9. **Cleanup, no matter how the block ended** (finished normally, aborted, or crashed) - the
   dew heater goes back off and the mount parks. A block never gets to leave hardware in an
   unknown or unsafe state.

## Challenges

Real problems hit (and fixed) building this - each gets its own writeup as the list grows:

- [No visible nebula despite hours of integration](challenges/no-visible-nebula.md) - a
  plate-solver database path bug with a 0% success rate, hiding behind a second GOTO-bias
  bug, for weeks.

## What this project doesn't do (on purpose)

- **Guiding/dithering** - handled entirely on-device by the S50 itself; nothing to add here.
- **Comet/non-sidereal tracking** - deliberately out of scope; would need a separate
  tracking and stacking path.
- **Flat-frame calibration** - not built, revisit only if real images show vignetting.

## Credits

- [ninaAPI Advanced API plugin](https://github.com/christian-photo/ninaAPI) by
  [christian-photo](https://github.com/christian-photo) - the HTTP bridge that makes
  scripted control of N.I.N.A. possible at all.
- [N.I.N.A. - Nighttime Imaging 'N' Astronomy](https://nighttime-imaging.eu/) - the
  sequencer/capture software itself.
- [ASTAP](https://www.hnsky.org/astap.htm) by Han Kleijn - the plate solver used for
  centering and drift correction.
- [Siril](https://siril.org/) and [GraXpert](https://www.graxpert.com/) - stacking and
  AI-based background extraction/denoising for the resulting subs (not covered in detail
  here, but part of the same pipeline).
