# C11 EdgeHD Imaging Train — Observatory Spec Sheet

*Rev. 2026-07-30 — Full order placed. No pricing shown — physical specs and dimensions only.*

Full parts list and backfocus stack for the second-scope build, for the observatory team to check against the pier, mount envelope, and cable routing.

## System Summary

| | |
|---|---|
| Aperture | 11" (279mm) |
| Focal Length | 2800mm · f/10 |
| Required Backfocus | 146.05mm ± 0.5mm |
| Est. Resting Load on AM7 | ~23kg |

## Full Parts Index

**Optical Tube**
- [Celestron EdgeHD 11" OTA (91050-XLT)](#celestron-edgehd-11-ota-91050-xlt)

**Mount**
- [ZWO AM7 Harmonic Drive EQ Head](#zwo-am7-harmonic-drive-eq-head)
- [Sky-Watcher AZ-EQ6 Counterweight, 11lb](#sky-watcher-az-eq6-counterweight-11lb)
- [Custom Pier Top Plate and Pier](#custom-pier-top-plate-and-pier)
- [William Optics Mini Vixen Mounting Base](#william-optics-mini-vixen-mounting-base)

**Focuser & Adapters**
- [PrimaLuceLab ESATTO 2" Standard Focuser](#primalucelab-esatto-2-standard-focuser)
- [ESATTO to Large SC Thread Adapter](#esatto-to-large-sc-thread-adapter)
- [M56 to M54 Adapter with Stop Ring](#m56-to-m54-adapter-with-stop-ring)
- [ZWO CAA Camera Angle Adjuster (rotator)](#zwo-caa-camera-angle-adjuster-rotator)
- [M54 Backfocus Spacer Set (Baader)](#m54-backfocus-spacer-set-baader)

**Camera, Filters & Guiding**
- [ZWO ASI6200MM Pro](#zwo-asi6200mm-pro)
- [ZWO EFW 2" 7-Position Filter Wheel](#zwo-efw-2-7-position-filter-wheel)
- [Antlia 3nm Narrowband and LRGB Filter Set](#antlia-3nm-narrowband-and-lrgb-filter-set)
- [ZWO OAG-L Off-Axis Guider](#zwo-oag-l-off-axis-guider)
- [ZWO ASI220MM Mini Guide Camera](#zwo-asi220mm-mini-guide-camera)
- [ZWO 12V 5A AC/DC Adapter (x2)](#zwo-12v-5a-acdc-adapter-x2)

**Automation & Power**
- [Pegasus Pocket Powerbox Micro](#pegasus-pocket-powerbox-micro)
- [Pegasus 12V 10A Power Supply](#pegasus-12v-10a-power-supply)
- [Deep Sky Dad C11 Aluminium Dewshield and OFP2 Flat Panel](#deep-sky-dad-c11-aluminium-dewshield-and-ofp2-flat-panel)
- [Celestron 11 Inch Dew Heater Ring](#celestron-11-inch-dew-heater-ring)
- [TEMP-est Active Cooling Fan System](#temp-est-active-cooling-fan-system)
- [XHF 5/8 Inch Adhesive Cable Wire Clips](#xhf-58-inch-adhesive-cable-wire-clips)

**Other**
- [Control Software](#control-software)
- [Open Items for the Observatory](#open-items-for-the-observatory)

## 1. Backfocus Stack (Telescope Thread to Sensor)

Target: **146.05mm ± 0.5mm** from the C11's rear SC thread to the sensor plane (Celestron EdgeHD spec). Tolerance window: 145.55–146.55mm.

| Component | mm |
|---|---:|
| ESATTO 2" (standard) | 67.0 |
| 3.3" SC thread adapter | 2.0 |
| M56 → M54 adapter | 4.0 |
| ZWO EFW 2" (7-position) | 20.0 |
| ZWO OAG-L | 17.5 |
| ASI6200MM Pro (bare) | 17.5 |
| **Stack subtotal** | **128.0** |
| ZWO CAA rotator | 16.5 |
| Baader fine-adjustment rings (1.0 + 0.5mm) | 1.5 |
| **Total** | **146.0** |

Lands dead center of the 145.55–146.55mm tolerance window. The CAA rotator (added 2026-07-30 for OAG guide-star acquisition) replaces the Baader 15mm extension originally planned - only 1.5mm of fine rings needed on top of it instead of 3.0mm, same final total. Four spare rings (two 0.3mm, one each of the unused 1.0/0.5mm) left over for fine trim once the physical stack is on hand. Full-frame note: EdgeHD's corrected flat field is ⌀42mm; the ASI6200's sensor diagonal is 43mm — right at the edge of the corrected circle, expect slight corner softening.

## 2. Optical Tube

#### Celestron EdgeHD 11" OTA (91050-XLT)

Aplanatic Schmidt-Cassegrain, no external corrector needed (correction built into the OTA).

| | |
|---|---|
| Aperture | 279mm (11") |
| Focal length | 2800mm f/10 |
| Tube L × D | 610 × 312mm |
| Weight | 13.0kg (28lb) |
| Dovetail | CGE / Losmandy |
| Rear thread | 3.3" SC |
| Corrected field | ⌀42mm flat |

**Condition:** used unit — **ordered 2026-07-30**, resolving the prior test-confirmation question.

## 3. Mount

#### ZWO AM7 Harmonic Drive EQ Head
- Rated payload: 66lb w/ 22lb counterweight (see note below — real order uses a lighter CW)
- Weight: 6.7kg
- Base footprint: **unpublished** — see [open items](#open-items-for-the-observatory)

#### Sky-Watcher AZ-EQ6 Counterweight, 11lb
25mm bore, fits stock AM7 shaft. **Real order (2026-07-30) — swapped from the originally-planned 22lb Apertura CW.** Same bore/compatible, but adds less capacity than the 66lb figure above assumed; re-check AM7's rated capacity with this lighter CW against the real train weight (~23kg/~50lb) before final assembly.

#### Custom Pier Top Plate and Pier
Site-provided.

#### William Optics Mini Vixen Mounting Base
Small dovetail/shoe base, clamps to 3.5"+ diameter tubes or flat surfaces. **Confirmed use (2026-07-30): mounts the Pegasus Powerbox to the OTA's rail.**

## 4. Focuser & Adapters

Robotic external focuser — locks the primary mirror and focuses via its own drawtube, eliminating the mirror-flop/image-shift the stock SCT focus knob has. Standard body, not the low-profile (LP) variant.

#### PrimaLuceLab ESATTO 2" Standard Focuser
- Thickness: 67mm
- Travel: 15mm
- Weight: 835g
- Payload rating: 5kg
- Resolution: 0.04µm/step
- Control: USB-C / WiFi

#### ESATTO to Large SC Thread Adapter
ESATTO 2" → 3.3" SC thread, 2mm thick. Large-thread variant for 11"/14" EdgeHD, not the 8"/9.25" adapter.

#### M56 to M54 Adapter with Stop Ring
4mm thick. Mates ESATTO's native M56 output to the EFW's M54 input.

#### ZWO CAA Camera Angle Adjuster (rotator)
Motorized field rotator, added 2026-07-30 - flagged by the observatory's equipment checklist for OAG guide-star acquisition (lets the whole camera+OAG assembly rotate to find a usable guide star at any framing). M54 both sides (M48 adapter included), 16.5mm thick, 465g, rated for up to 11lb of downstream camera+accessories (this train's EFW+OAG+camera is ~1.5kg/3.3lb - comfortable margin). USB-C control, 0.02°/step.

#### M54 Backfocus Spacer Set (Baader)
Two sets of Baader M54 fine-adjustment rings (0.3/0.5/1.0mm aluminium, six rings total) - **only 1.5mm needed now** (one 1.0mm + one 0.5mm ring) since the CAA rotator above replaces the originally-planned 15mm Baader extension tube in the stack. See [Section 1](#1-backfocus-stack-telescope-thread-to-sensor) for the full math.

## 5. Camera, Filters & Guiding

#### ZWO ASI6200MM Pro
- Sensor: 61MP full-frame
- Body: ⌀90 × 97mm
- Weight: 0.7kg
- Rear thread: M54
- To sensor: 17.5mm

#### ZWO EFW 2" 7-Position Filter Wheel
- Thickness: 20mm
- Weight: 650g
- Front thread: M54

#### Antlia 3nm Narrowband and LRGB Filter Set
2" mounted, Pro version. L, R, G, B, Hα, OIII, SII

#### ZWO OAG-L Off-Axis Guider
Bolts to EFW, contributes 17.5mm

#### ZWO ASI220MM Mini Guide Camera
Mounts in OAG-L helical focuser

#### ZWO 12V 5A AC/DC Adapter (x2)
**Confirmed use (2026-07-30):** one each for the ASI6200MM Pro and the AM7 mount, running both directly off dedicated AC power rather than the Powerbox's shared rail - isolates the two most brownout-sensitive loads from any voltage sag caused by the flat panel or dew heater cycling.

## 6. Automation & Power

#### Pegasus Pocket Powerbox Micro
- 12V outputs: 4, sharing **one 10A total budget** (single Smart Mosfet, not independent per-port)
- Dew channels: 2 × 5A independent
- USB: USB2 only

**Real order (2026-07-30) — swapped from the originally-planned Advance Gen3**, which had 4× independent 6A outputs (24A total) and USB3. With the camera and mount now on dedicated AC power (above), the Powerbox only ever carries the dew heater ring, flat panel, and TEMP-est fans - comfortably inside the 10A shared budget even with all three running at once. The earlier concern about the flat panel and dew heater overlapping no longer applies.

#### Pegasus 12V 10A Power Supply
2.1mm barrel — powers the Powerbox Micro above.

#### Deep Sky Dad C11 Aluminium Dewshield and OFP2 Flat Panel
- Illuminated ⌀: 305mm
- Purpose-built for C11/EdgeHD11/RASA11 — dew shield bundled in
- Power: 12V 3A, 5.5×2.1mm
- Includes its own dew heater per DSD's listing — check for overlap with the corrector ring below before wiring both
- **Ordered 2026-07-30**

#### Celestron 11 Inch Dew Heater Ring
- Draw: 2.5A max @ 12V
- Connector: 5.5/2.1mm barrel
- Mounts by replacing the corrector's retaining ring
- Fits all 11" EdgeHD/SCT/RASA tubes 2006+

#### TEMP-est Active Cooling Fan System
Dual filtered fans (one pulls air out, one pushes in) for the rear cell - speeds cooldown, reduces internal tube currents. Single 12VDC 2.1mm-barrel cable for both fans, draws off a spare Powerbox 12V port. **Ordered 2026-07-30** (previously just a noted possibility).

#### XHF 5/8 Inch Adhesive Cable Wire Clips
60-pack, adhesive-backed, no tools needed. For routing the OTA/mount cable runs (power + USB to the AM7, ESATTO, camera, EFW, flat panel) cleanly along the tube/pier. General-purpose, not telescope-specific.

## 7. Control Software

N.I.N.A. · ASCOM Platform · PHD2 · ASTAP + H18 · Pegasus Unity · PrimaLuceLab ESATTO driver

**USB planning note:** the Powerbox Micro has exactly one USB port (control/monitoring of itself only - no hub function for other devices). Six separate connections need to reach the mini-PC: main camera, mount, ESATTO (or WiFi instead), flat panel, the Powerbox itself, and the CAA rotator (USB-C only, no WiFi option). The guide camera and filter wheel don't need their own ports - they chain through the main camera's built-in hub. Plan for a powered USB hub at the mini-PC with real spare capacity.

## Open Items for the Observatory

1. **AM7 base bolt pattern** — not published anywhere by ZWO. Need it measured directly off the physical mount (or pulled from ZWO's manual) before the pier top plate can be finalized.
2. **AM7 capacity with the lighter 11lb counterweight** — the 66lb rated-capacity figure was based on a 22lb CW; the real order uses an 11lb Sky-Watcher CW instead. Real train weight (~23kg/~50lb) has margin either way, but worth confirming the actual capacity-with-this-CW number.

---
*Second-scope build — full history in scope.md. Compiled 2026-07-30.*
