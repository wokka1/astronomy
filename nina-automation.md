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
fixed list. The executor then runs each planned block: roof-status check, connect
equipment, per-target dark-frame capture, cable-wrap-guarded slew, plate-solve-verified
centering, autofocus, and a timed capture loop with periodic re-centering.

## The bug hunt: why nothing showed up

For weeks, real sessions on compact targets (nebulae, small galaxies) kept coming back with
no visible structure, despite hours of real integration time. Stars always looked fine in
the subs - which turned out to be the actual clue. Stars fill the whole field of view and
don't care about a pointing error; a compact nebula does.

**Root cause:** a periodic plate-solve/recenter check (meant to catch and correct mount
drift mid-session) had a **0% solve success rate** the entire time it had been running.
[ASTAP](https://www.hnsky.org/astap.htm) (the plate solver, running under Wine on the Mac
mini that hosts NINA) was looking for its star database in its own install directory only -
one level up from where the actual database files lived. Every drift check silently failed,
for every session, for every target. This was a pure pointing problem, not a signal,
exposure, or processing one - which is exactly why bright stars always looked normal while
faint extended objects didn't. (Several other theories - camera gain, Bayer pattern
handling, denoising, stacking normalization, sensor bit depth, bad-pixel correction - were
tested and ruled out first before landing on this.)

Fixing the solver's database path exposed a second, subtler bug: even once plate-solving
started working, the corrective slew barely moved the mount despite the solve reporting
15-20+ arcminutes of real drift. The recenter logic was re-issuing a GOTO to the same
catalog coordinates every time - but if the mount's own internal position model is what's
biased, a repeated GOTO from that same wrong reference just lands in the same wrong place
again. The fix: **sync the mount to the plate-solved position first**, correcting its
internal model, *then* issue the GOTO - so the next slew actually lands where it should.

## Slew-and-center, before autofocus

N.I.N.A.'s own recommended sequence structure is Slew-and-Center → Autofocus → imaging -
plate solving doesn't need sharp focus to work (it just needs detectable star centroids),
so centering the mount properly *before* autofocus means a stale or de-focused starting
point never gets in the way of finding the target in the first place. This project's
executor now runs a real solve → sync → re-slew loop immediately after the initial GOTO,
repeating until the solved position is within tolerance, before autofocus ever starts.

An HFR-trend-based mid-block refocus trigger was added too - the first frame after autofocus
sets a reference sharpness value, and if the trailing average HFR later drifts more than
10% above that reference (e.g. from a real temperature swing during a long session),
autofocus re-runs automatically without any user intervention.

## Live result

The fix chain above was validated on real hardware the same night it was built. Slew-and-
center converged before autofocus ran; once autofocus completed, the star-detection HFR
(a lower number means sharper focus) dropped from an early, still-centering value of ~6 down
to a steady 1.7-2.1, with 250-300 stars detected per frame (up from ~30 while the mount was
still off-target). The target nebula was visible in the live capture preview before
autofocus had even finished - the first time that had happened on this setup, after weeks of
sessions that came back with nothing.

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
