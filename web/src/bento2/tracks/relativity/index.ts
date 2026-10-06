// Relativity (track 9, code `re`): the header of curriculum/specs/bento2/relativity.md as data, and its 12 lessons.
import type { B2Track } from "../../model";
import { RELATIVITY_LESSONS } from "./lessons";

export const track: B2Track = {
  code: "re",
  pickerId: "relativity",
  name: "Relativity",
  about: "Time and space stretch depending on how fast you move and how strong gravity is. It's why GPS satellites need correcting every day.",
  build: {
    name: "The GPS checker",
    goal: "Work out why GPS needs relativity, to the microsecond: the satellite clock's speed and height effects, their net drift of about +38.5 μs a day, the 11.5 km of map error it would cause, and the orbit where the two cancel.",
  },
  units: [
    { n: 1, name: "Light sets the rules", adds: "Timing is distance: 1 ns of clock error is 30 cm of map error. Moving clocks run slow by γ." },
    { n: 2, name: "Spacetime", adds: "The boost as a matrix, the interval everyone agrees on, and the twin trip: two clocks, two paths, different ages." },
    { n: 3, name: "Energy and mass", adds: "E = mc², then the slow-speed rule. The satellite's speed part: −7.2 μs per day." },
    { n: 4, name: "Gravity and GPS", adds: "Higher clocks run fast. The height part, +45.7 μs per day, and the build: +38.5 μs per day and 11.5 km of error." },
  ],
  projects: [
    { id: "re-lightclock", after: "b2-re-03", name: "Your light clock", makes: "Pick a speed: it draws the zigzag, prints γ, and shows how far a muon gets before and after relativity.", shelf: ["gamma"], scene: { scene: "lightclock", props: { project: true, beta: 0.8 } } },
    { id: "re-twin", after: "b2-re-06", name: "Twin trip planner", makes: "Pick a star and a cruise speed: both worldlines on the spacetime diagram, and both ages on return.", shelf: ["twin"], scene: { scene: "twin", props: { project: true, D: 4.25, beta: 0.8 } } },
    { id: "re-clocks", after: "b2-re-09", name: "Clocks that travel", makes: "An airliner, the space station and a GPS satellite: how far each falls behind a ground clock per day from speed alone.", shelf: ["sr_drift"], scene: { scene: "clocks", props: { project: true } } },
    { id: "re-gps", after: "b2-re-12", name: "The build: GPS checker", makes: "Your satellite at any orbit radius: the speed bar, the height bar, the net drift, the map error after a day, and the cancel radius.", shelf: ["gr_drift", "gps_net"], build: true, scene: { scene: "gps", props: { project: true, r: 26571 / 6371 } } },
  ],
  tools: [
    { id: "spacetime", name: "Spacetime diagram", short: "Spacetime", star: true },
    { id: "lightclock", name: "Light clock", short: "Light clock" },
    { id: "twin", name: "Twin trip planner", short: "Twins" },
    { id: "adder", name: "Speed adder", short: "Speeds" },
    { id: "energy", name: "Energy triangle", short: "Energy" },
    { id: "well", name: "Gravity well", short: "Well" },
    { id: "gps", name: "GPS checker", short: "GPS" },
  ],
  buildPieces: ["c_light", "gamma", "boost", "twin", "sr_drift", "gr_drift", "gps_net"],
  lessons: RELATIVITY_LESSONS,
};
