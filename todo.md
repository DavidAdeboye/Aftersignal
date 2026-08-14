# Godot Editor & Testing Checklist (`todo.md`)

All 3D story terminals, wall inspection points, and airlock transition triggers have been **pre-positioned directly in the scene code** for you! No manual 3D dragging is needed in the Godot Editor.

---

## 1. Pre-Positioned Scene Objects (`landing_bay.tscn`)

- [x] **`CrewRosterTerminal` (Computer Manifest):** Positioned on the desk near spawn (`1.45, 0.40, 13.86`).
- [x] **`MissingRoomGap` (Wall Inspection Node):** Mounted on the hab corridor wall (`1.85, 1.20, -11.15`).
- [x] **`DrFarrowLog1` (Day 12 Audio Log):** Positioned on the storage corridor desk (`3.20, 0.40, -2.50`).
- [x] **`DrFarrowLog2` (Day 28 Research Memo):** Positioned on the Science Lab main desk (`-18.50, 0.60, -7.50`).
- [x] **`ResearchLabsAirlock` (Act 2 Level Transition):** Mounted on the exit airlock doorway (`-22.50, 1.20, -15.50`).

---

## 2. In-Game Testing Steps (`F5` in Godot)

Run `main_menu.tscn` and click **Host Game**:

- [x] **Step 1 — Read Crew Manifest:**
  - Walk up to the `CrewRosterTerminal` near spawn and press `E`.
  - Verify top HUD banner updates to `"OBJECTIVE: Cross-reference Manifest in Habitation Quarters"` and radio chatter plays.

- [x] **Step 2 — Inspect Missing Room 12 Wall:**
  - Walk down the hab corridor past Room 11 and press `E` near `MissingRoomGap`.
  - Verify HUD banner updates to `"OBJECTIVE: Access Science Lab & Investigate Dr. Farrow's Research"` and radio chatter triggers (*"Room 12 was never built!"*).

- [x] **Step 3 — Read Dr. Farrow's Research Logs:**
  - Enter the Science Lab and press `E` at Dr. Farrow's research desk (`DrFarrowLog2`).
  - Verify radio subtitles play (*"Organic-silicate crystal..."*) and HUD banner updates to `"OBJECTIVE: Proceed through Research Labs Airlock"`.

- [x] **Step 4 — Cycle Research Labs Airlock:**
  - Walk down the end hallway to `ResearchLabsAirlock` and press `E`.
  - Verify airlock cycling notification and transition to Act 2 (`02_research_labs.tscn`).


## RESOLVED ISSUES:
- [x] **Radio Chatter Subtitles & Objective Updates Fixed:** Fixed `dialog_timer` countdown and connected `DialogManager` and `ObjectiveManager` signals in `player_controller.gd`. When you press `E` at `CrewRosterTerminal`, the top HUD banner updates to `"OBJECTIVE: Cross-reference Manifest in Habitation Quarters"` and the radio subtitle banner displays at the bottom of the screen!

---

## 3. Science Lab 3D Model Asset Wishlist (For Downloading Props)

Here is the complete list of 3D models needed to furnish the Science Lab:

### A. Primary Workstations & Furniture
- [x] **Lead Research Desk (Dr. Farrow's Desk):** Low-poly sci-fi computer desk (`low-_poly_sci-_fi_computer_desk.glb`) & modern PC table positioned at Dr. Farrow's station.
- [x] **Modular Lab Workbenches:** Stainless-steel modular lab workbench (`workbench.glb`) placed at Dr. Farrow's main workstation (`-18.5, 0, -7.5`).
- [x] **Sci-Fi Operator Chairs:** Ergonomic swivel lab chairs (`lab_chair.glb`) positioned at primary lab desks (`-18.5, 0, -6.6` & `-17.5, 0, -12.6`).
- [ ] **Wall Instrument Shelves:** Metal floating wall shelves for holding beakers, samples, and diagnostics.

### B. Scientific & Exobiology Equipment
- [x] **Crystalline Sample Containment Chamber:** Bioluminescent glowing crystal specimen (`crystal_low_noise_material.glb`) with cyan emission light & incubator pump unit (`simple_centrifugal_pump_model.glb`) at `(-19, 0.8, -12)`.
- [x] **Digital Electron Microscope:** Desktop microscope console (`microscope.glb`) placed on the main lab workbench (`-18.5, 0.82, -7.4`).
- [ ] **Mass Spectrometer / Gas Chromatograph:** Boxy lab diagnostic machine with LED indicators.
- [x] **Acoustic Wave / Frequency Analyzer:** Oscilloscope terminal (`oscillograph.glb`) placed on the lab workbench for 440 Hz resonance lore.
- [x] **Centrifuge & Incubator Unit:** Centrifugal pump unit (`simple_centrifugal_pump_model.glb`) integrated with the crystal sample containment chamber.

### C. Specimen Storage & Chemical Containment
- [x] **Vertical Cryo-Storage Cylinders:** Tall cryogenic freezer tanks with frost effect / status screens. Already in the scene.
- [ ] **Hazardous Reagent Cabinet:** Heavy metal storage locker with yellow/black biohazard decals.
- [ ] **Sample Trays & Vials:** Racks holding glowing liquid test tubes, syringes, and glass petri dishes.

### D. Environment & Safety Props
- [ ] **Wall-Mounted Diagnostic Screens:** Flat holographic or CRT monitor panels showing station bio-telemetry.
- [ ] **Emergency Eyewash & Decontamination Basin:** Wall-mounted emergency shower nozzle & stainless basin.
- [ ] **Biohazard Waste Bins:** Bright yellow/orange heavy foot-pedal biohazard waste containers.
- [ ] **Articulated Task Lighting:** Ceiling-mounted or desk-clamped adjustable inspection lamps.
