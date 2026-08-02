# C11 EdgeHD Imaging Train — Observatory Spec Sheet

*Rev. 2026-07-29 — OTA decision: finalized. No pricing shown — physical specs and dimensions only.*

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
- [Apertura 22lb Counterweight for AM7](#apertura-22lb-counterweight-for-am7)
- [Custom Pier Top Plate and Pier](#custom-pier-top-plate-and-pier)

**Focuser & Adapters**
- [PrimaLuceLab ESATTO 2" Standard Focuser](#primalucelab-esatto-2-standard-focuser)
- [ESATTO to Large SC Thread Adapter](#esatto-to-large-sc-thread-adapter)
- [M56 to M54 Adapter with Stop Ring](#m56-to-m54-adapter-with-stop-ring)
- [M54 Backfocus Spacer Set (ZWO)](#m54-backfocus-spacer-set-zwo)

**Camera, Filters & Guiding**
- [ZWO ASI6200MM Pro](#zwo-asi6200mm-pro)
- [ZWO EFW 2" 7-Position Filter Wheel](#zwo-efw-2-7-position-filter-wheel)
- [Antlia 3nm Narrowband and LRGB Filter Set](#antlia-3nm-narrowband-and-lrgb-filter-set)
- [ZWO OAG-L Off-Axis Guider](#zwo-oag-l-off-axis-guider)
- [ZWO ASI220MM Mini Guide Camera](#zwo-asi220mm-mini-guide-camera)

**Automation & Power**
- [Pegasus Pocket Powerbox Advance Gen3](#pegasus-pocket-powerbox-advance-gen3)
- [Pegasus 12V 10A Power Supply](#pegasus-12v-10a-power-supply)
- [Deep Sky Dad C11 Aluminium Dewshield and OFP2 Flat Panel](#deep-sky-dad-c11-aluminium-dewshield-and-ofp2-flat-panel)
- [Celestron 11 Inch Dew Heater Ring](#celestron-11-inch-dew-heater-ring)

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
| ZWO M54-M54 16.5mm extension | 16.5 |
| ZWO fine-adjustment spacers (approx.) | 1.4 |
| **Total** | **≈145.9** |

Lands inside the 145.55–146.55mm tolerance window. Full-frame note: EdgeHD's corrected flat field is ⌀42mm; the ASI6200's sensor diagonal is 43mm — right at the edge of the corrected circle, expect slight corner softening.

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

**Condition:** used unit sourced via telescopes.net — *pending test confirmation*.

## 3. Mount

#### ZWO AM7 Harmonic Drive EQ Head
- Rated payload: 66lb w/ counterweight
- Weight: 6.7kg
- Base footprint: **unpublished** — see [open items](#open-items-for-the-observatory)

#### Apertura 22lb Counterweight for AM7
25mm bore, fits stock AM7 shaft.

#### Custom Pier Top Plate and Pier
Site-provided.

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

#### M54 Backfocus Spacer Set (ZWO)
ZWO M54-M54 16.5mm extension + ~1.4mm from ZWO's fine-adjustment spacer set (0.4/0.6/1.0mm rings). Combined ≈17.9mm — closes the backfocus gap (see [Section 1](#1-backfocus-stack-telescope-thread-to-sensor)). Confirm exact figure once parts are physically in hand.

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

## 6. Automation & Power

#### Pegasus Pocket Powerbox Advance Gen3
- 12V outputs: 4 × 6A switched
- Dew channels: 2 × PWM
- USB: 4×USB3-A, 2×USB2-C

#### Pegasus 12V 10A Power Supply
2.1mm barrel — ~60% headroom over real draw

#### Deep Sky Dad C11 Aluminium Dewshield and OFP2 Flat Panel
- Illuminated ⌀: 305mm
- Purpose-built for C11/EdgeHD11/RASA11 — dew shield bundled in
- Power: 12V 3A, 5.5×2.1mm
- Includes its own dew heater per DSD's listing — check for overlap with the corrector ring below before wiring both

#### Celestron 11 Inch Dew Heater Ring
- Draw: 2.5A max @ 12V
- Connector: 5.5/2.1mm barrel
- Mounts by replacing the corrector's retaining ring
- Fits all 11" EdgeHD/SCT/RASA tubes 2006+

## 7. Control Software

N.I.N.A. · ASCOM Platform · PHD2 · ASTAP + H18 · Pegasus Unity · PrimaLuceLab ESATTO driver

## Open Items for the Observatory

1. **Used OTA condition** — the C11 EdgeHD above is a used unit; waiting on confirmation it's been tested before it's finalized. Will update once confirmed.
2. **AM7 base bolt pattern** — not published anywhere by ZWO. Need it measured directly off the physical mount (or pulled from ZWO's manual) before the pier top plate can be finalized.

---
*Second-scope build — full history in scope.md. Compiled 2026-07-29.*
