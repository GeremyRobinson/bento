import type { TeaserId } from "../components/TeaserPics";

/** Bento²'s ten tracks as the grade screen's switch shows them (Design's Bento / Bento² switch, G 2026-10-06).
 *  This is the preview side only: every track is "Coming later" until the grades are finished. */
export interface Track { id: TeaserId; name: string; about: string; part: "spine" | "branch" }

export const TRACKS: Track[] = [
  { id: "linear", part: "spine", name: "Linear algebra", about: "Arrows and grids of numbers. It's how a computer moves pictures, games and data, and it's the base of all AI." },
  { id: "prob", part: "spine", name: "Probability and statistics", about: "How likely things are, and what data can and can't tell you. Every prediction starts here." },
  { id: "hills", part: "spine", name: "Hills and finding the best", about: "Surfaces with many directions, and how to walk downhill to the lowest point. It's how machines learn." },
  { id: "info", part: "spine", name: "Information", about: "How much a message really says, measured in bits. Surprise, compression and codes." },
  { id: "comp", part: "spine", name: "Computation", about: "Logic, steps and algorithms: what a computer can work out, and how fast." },
  { id: "ai", part: "spine", name: "The math behind AI", about: "Everything on the spine, put together: how a network learns, and where AI is going." },
  { id: "change", part: "branch", name: "Change over time", about: "Equations that describe change, from a cooling cup of cocoa to a growing population." },
  { id: "orbit", part: "branch", name: "Orbits and spaceflight", about: "Why planets move in ellipses, and how to plan a path to the Moon." },
  { id: "relativity", part: "branch", name: "Relativity", about: "Space and time as one shape, bent by everything with mass." },
  { id: "quantum", part: "branch", name: "Quantum", about: "Waves of chance that decide where things are, and how they lead to quantum computers." },
];

export const TRACK_PARTS = [
  { part: "spine", label: "The spine · the math thinking machines are built from" },
  { part: "branch", label: "The branches · the sciences that use it" },
] as const;
