# City plan: clusters (Yasin, 16 Nov 2026)

The city is grown from **cluster samples**, not from one block style.
- Each cluster is designed once as a sample: one junction plus its four corners.
- Yasin approves each sample, and it is locked.
- The city is then filled from a zoning map over Coronado's street skeleton, using each zone's pieces plus a few variants.
- Agents (ultracode) can fill zones in parallel once the samples are fixed.

| Cluster | Sample | Character |
|---|---|---|
| Residential | pilot hill rows `r_*` (Amber x 10th, east) | houses on terraces, parkway trees, driveways, back-lot power line |
| High street | pilot downtown blocks `b_*` | 1-2 storey shops, theatre, post office, pocket park, rear parking off alleys |
| City centre | `c_*` sample | whole-block 4-6 storey street walls, towers on key corners, buildings on the alleys too, plaza, construction site, no open rear lots, wires underground |
| Industrial | `i_*` + `j_ind`/`s_ind`/`w_ind` (locked 16 Nov) | warehouses, factory, yards behind chain-link, containers, docks, substation, heavy wear, no street trees |
| Later | | waterfront / marina, an apartments band between the centre and the houses |

Rules between zones:
- **Transitions, never hard jumps:** apartments between the centre and the houses; an alley, park or yard between industrial and residential.
- **Shared street sections:** every zone uses the same sections, so pieces always connect.
- **Phone check first:** the city centre is the heaviest cluster, so it goes on the Redmi before it is copied anywhere.

Order:
1. Lock the residential and high street samples.
2. City centre sample, then a Redmi check.
3. Industrial sample.
4. Zoning map.
5. Grow with agents.

## Status and order (Yasin 16 Nov, after locking industrial + the city-centre streets)
Locked: residential, high street, city centre (blocks + its own wide-sidewalk streets), industrial.
Next, samples first, phones later (map, streaming and the other systems get integrated before any Redmi run):
1. Commercial strip (arterial): DONE, locked 16 Nov (`j_strip`, `s_strip_*`, `m_*`, `w_strip`).
2. Apartment band (centre -> houses transition): built 17 Nov (`j_apt`, `s_apt`, `a_*`, `w_apt`), awaiting approval.
3. Civic / parks band, NEXT (Yasin 17 Nov: tennis courts and the park pieces are unused - they go in the
   transition areas): the 11 kit parks (tennis, skate, dog run, playground village, memorial green, succulent
   garden, town square ...),: city hall, courthouse, police, post office, library, schools,
   hospital, university, rec centre (the "gym"), stadium with its parking.
4. Gritty edge (industrial -> apartments): boarded / abandoned fronts, fire escapes, pawn, laundry, graffiti.
5. Waterfront: waits for Yasin's new parts (quay walls, piers, marina slips, boats ...).
Then: parks as lots, hero sites (hand-made, one of a kind, never grown by agents), zoning map, growth.
Unused kit pieces go into VARIANTS of the samples (extensions), not into the locked samples.
