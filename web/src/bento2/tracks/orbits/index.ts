// Orbits and spaceflight (track 8, code `or`): the header of curriculum/specs/bento2/orbits.md as data, and its 12 lessons.
import type { B2Track } from "../../model";
import { ORBITS_LESSONS } from "./lessons";

export const track: B2Track = {
  code: "or",
  pickerId: "orbit",
  name: "Orbits and spaceflight",
  about: "How gravity steers planets, moons and spacecraft. One rule, a pull that weakens with distance squared, explains every orbit, and a few well-timed burns get you from Earth to Mars.",
  build: {
    name: "A trip from Earth to Mars",
    goal: "Plan a real Earth-to-Mars mission with a Hohmann transfer: the parking orbit, the departure burn, the transfer orbit, the launch window, the flight time, the capture burn at Mars, the total Δv and how much of the ship must be propellant, all on one live mission card.",
  },
  units: [
    { n: 1, name: "Falling around", adds: "The parking orbit: circular speed and period 300 km above Earth, saved as v_LEO." },
    { n: 2, name: "Ellipses", adds: "The transfer orbit's shape and speeds: its semimajor axis, eccentricity, and the speeds at its two ends." },
    { n: 3, name: "Changing orbits", adds: "The engine: a trustworthy simulator, the rocket equation, and the two-burn plan, tested on Earth orbit to geostationary." },
    { n: 4, name: "To Mars", adds: "Timing and assembly: the launch window, leaving Earth and arriving at Mars, then the full mission card." },
  ],
  projects: [
    { id: "or-satellite", after: "b2-or-03", name: "Pick a satellite", makes: "Choose a job and an altitude: the card gives the radius, speed and period, and checks the job.", shelf: ["r_sat", "v_sat", "T_sat"], scene: { scene: "or-satellite", props: { project: true } } },
    { id: "or-comet", after: "b2-or-06", name: "Comet card", makes: "Type a comet's closest and farthest distances from the Sun: the card draws the ellipse and gives a, e, the period and the speeds at both ends.", shelf: [], scene: { scene: "or-comet", props: { project: true, near: 0.586, far: 35.1 } } },
    { id: "or-geo", after: "b2-or-09", name: "Geostationary delivery", makes: "From a 300 km parking orbit to geostationary radius: the two burns, the coast time and the propellant fraction with your engine. A dry run of the Mars plan.", shelf: ["dv_hohmann"], scene: { scene: "or-burn", props: { project: true, hohmann: true } } },
    { id: "or-mission", after: "b2-or-12", name: "The build: the Mars mission card", makes: "Every number of the trip on one card, live: change the parking orbit, the Mars orbit or the engine and it recomputes.", shelf: ["mission"], build: true, scene: { scene: "or-card", props: { project: true } } },
  ],
  tools: [
    { id: "or-sandbox", name: "Orbit sandbox", short: "Sandbox", star: true },
    { id: "or-cannon", name: "Newton's cannon", short: "Cannon" },
    { id: "or-kepler", name: "Kepler checker", short: "Kepler" },
    { id: "or-burn", name: "Burn planner", short: "Burns" },
    { id: "or-clock", name: "Mission clock", short: "Clock" },
    { id: "or-stack", name: "Rocket stack", short: "Rocket" },
    { id: "or-depart", name: "Departure view", short: "Depart" },
    { id: "or-card", name: "Mission card", short: "Mission" },
  ],
  buildPieces: ["v_LEO", "vratio_mars", "h_step", "ve", "dv_hohmann", "phase_mars", "dv_depart", "dv_capture", "mission"],
  lessons: ORBITS_LESSONS,
};
