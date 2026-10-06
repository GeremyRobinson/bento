// Multivariable calculus and optimization (track 3, code `mv`): the header of curriculum/specs/bento2/multivariable.md
// as data, and its 20 lessons. The picker calls it "Hills and finding the best" (app/tracks.ts, id `hills`).
import type { B2Track } from "../../model";
import { MV_LESSONS } from "./lessons";

export const track: B2Track = {
  code: "mv",
  pickerId: "hills",
  name: "Multivariable calculus and optimization",
  about: "Calculus for things that depend on more than one input, like the height of a hill at every spot. First you read and add up landscapes and flows; then you find the best: gradients, rolling downhill, fences, and knowing when the lowest point you found is the lowest there is.",
  build: {
    name: "The valley finder",
    goal: "A tool that finds the lowest point on any landscape: give it f(x, y) and an optional fence, and it returns the lowest point with its height, says how it knows (Hessian test, convexity or the restart count), and shows the lake that would collect there.",
  },
  units: [
    { n: 1, name: "Landscapes", adds: "The landscape itself: contour map, a hiker who reads height, the two slopes, the local tangent plane and the rate of climb along a trail." },
    { n: 2, name: "Adding up over space", adds: "The lake: fill the basin around a low point to a chosen level and read the water's volume and surface area." },
    { n: 3, name: "Fields and flow", adds: "The water: a flow layer showing where water runs and spins, and a work meter for hauling a cart along a trail." },
    { n: 4, name: "Which way is down", adds: "The compass and the ball: gradient arrows, a stop classifier (peak, pit or pass) and gradient descent with a step-size dial." },
    { n: 5, name: "Fences", adds: "The fence: search only inside a boundary or along a road, with the Lagrange readout, and fit a model by finding the bottom of its error bowl." },
    { n: 6, name: "Hard landscapes", adds: "The guarantee and the escape: a convexity check, a fix for narrow valleys and random restarts with noise, so the finder reports the lowest point, not just a low one." },
  ],
  projects: [
    { id: "mv-land", after: "b2-mv-04", name: "My landscape", makes: "Type a formula or sculpt a terrain. Get its contour map and a hiker readout: height, f_x, f_y, and the rate of climb on a trail.", shelf: ["land"], scene: { scene: "myland", props: { project: true } } },
    { id: "mv-lake", after: "b2-mv-08", name: "Fill the lake", makes: "Pick a low spot and a water level. The volume builder fills the basin and reports the lake's volume and surface area.", shelf: ["lakeVolume", "lakeArea"], scene: { scene: "lake", props: { project: true } } },
    { id: "mv-rain", after: "b2-mv-12", name: "Rain map", makes: "Rain falls on your landscape. Streams follow −∇f, each spot is colored by the valley it drains to, and the passes between basins are marked.", shelf: ["basins"], scene: { scene: "rain", props: { project: true } } },
    { id: "mv-park", after: "b2-mv-16", name: "Best spot in the park", makes: "Draw a park fence on your landscape. Find the lowest spot inside it (for a pond) and the lowest spot along a road, with λ shown.", shelf: ["fencedBest"], scene: { scene: "park", props: { project: true } } },
    { id: "mv-valley", after: "b2-mv-20", name: "The build: the valley finder", makes: "Any f(x, y) and an optional fence: 20 restarts and a slow cool find the lowest point, the Hessian test confirms it, and the lake that would collect there fills in.", shelf: ["lowest"], build: true, scene: { scene: "valley", props: { project: true } } },
  ],
  tools: [
    { id: "surface", name: "Surface explorer", short: "Surface", star: true },
    { id: "slice", name: "Slice tool", short: "Slice" },
    { id: "hiker", name: "Hiker on a trail", short: "Hiker" },
    { id: "volume", name: "Volume builder", short: "Volume" },
    { id: "warp", name: "Grid warper", short: "Warper" },
    { id: "field", name: "Vector field painter", short: "Field" },
    { id: "gradient", name: "Gradient arrows", short: "Gradient" },
    { id: "rain", name: "Rain map", short: "Rain" },
    { id: "morph", name: "Shape morpher", short: "Morpher" },
    { id: "finder", name: "Best-choice finder", short: "Finder" },
    { id: "bowl", name: "Error bowl", short: "Error bowl" },
  ],
  buildPieces: ["land", "slabVolume", "pondVolume", "lakeVolume", "lakeArea", "basins", "bestSoFar", "fencedBest", "lowest"],
  lessons: MV_LESSONS,
};
