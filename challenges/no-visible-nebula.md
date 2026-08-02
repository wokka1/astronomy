[← back to the NINA automation overview](../nina-automation.md)

# Challenge: no visible nebula despite hours of integration

For weeks, real sessions on compact targets (nebulae, small galaxies) kept coming back with
no visible structure, despite hours of real integration time. Stars always looked fine in
the subs - which turned out to be the actual clue. Stars fill the whole field of view and
don't care about a pointing error; a compact nebula does.

## Root cause

A periodic plate-solve/recenter check (meant to catch and correct mount drift mid-session)
had a **0% solve success rate** the entire time it had been running.
[ASTAP](https://www.hnsky.org/astap.htm) (the plate solver, running under Wine on the Mac
mini that hosts NINA) was looking for its star database in its own install directory only -
one level up from where the actual database files lived. Every drift check silently failed,
for every session, for every target. This was a pure pointing problem, not a signal,
exposure, or processing one - which is exactly why bright stars always looked normal while
faint extended objects didn't.

Several other theories were tested and ruled out first before landing on this: camera gain,
Bayer pattern handling, denoising, stacking normalization, sensor bit depth, bad-pixel
correction. All real dead ends, not skipped steps.

## A second bug, hiding behind the first

Fixing the solver's database path exposed a second, subtler bug: even once plate-solving
started working, the corrective slew barely moved the mount despite the solve reporting
15-20+ arcminutes of real drift. The recenter logic was re-issuing a GOTO to the same
catalog coordinates every time - but if the mount's own internal position model is what's
biased, a repeated GOTO from that same wrong reference just lands in the same wrong place
again. The fix: **sync the mount to the plate-solved position first**, correcting its
internal model, *then* issue the GOTO - so the next slew actually lands where it should.

## Independent proof

Separately from the code investigation, a real side-by-side test nailed down that this
really was a pointing problem and nothing else: manually slewing to the target via the
Seestar's own app (not NINA) and shooting it for a few minutes showed the nebula clearly, in
contrast to NINA's own multi-hour stack of the same target showing nothing. The measured
offset between the app's corrected position and the catalog RA/Dec was large enough to push
a compact target off the S50's narrow field of view entirely.

## The fix: centering before autofocus

N.I.N.A.'s own recommended sequence structure is Slew-and-Center → Autofocus → imaging -
plate solving doesn't need sharp focus to work (it just needs detectable star centroids),
so centering the mount properly *before* autofocus means a stale or de-focused starting
point never gets in the way of finding the target in the first place. The executor now runs
a real solve → sync → re-slew loop immediately after the initial GOTO, repeating until the
solved position is within tolerance, before autofocus ever starts.

An HFR-trend-based mid-block refocus trigger was added alongside this - the first frame
after autofocus sets a reference sharpness value, and if the trailing average HFR later
drifts more than 10% above that reference (e.g. from a real temperature swing during a long
session), autofocus re-runs automatically without any user intervention.

## Live result

The fix chain above was validated on real hardware the same night it was built. Slew-and-
center converged before autofocus ran; once autofocus completed, the star-detection HFR (a
lower number means sharper focus) dropped from an early, still-centering value of ~6 down to
a steady 1.7-2.1, with 250-300 stars detected per frame (up from ~30 while the mount was
still off-target). The target nebula was visible in the live capture preview before
autofocus had even finished - the first time that had happened on this setup, after weeks of
sessions that came back with nothing.
