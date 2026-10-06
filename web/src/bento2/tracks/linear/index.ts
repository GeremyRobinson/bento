// Linear algebra (track 1, code `la`): the header of curriculum/specs/bento2/linear-algebra.md as data, and its 20
// lessons.
import type { B2Track } from "../../model";
import { LA_LESSONS } from "./lessons";
import { S } from "./unit12";

export const track: B2Track = {
  code: "la",
  pickerId: "linear",
  name: "Linear algebra",
  about: "The math of arrows and grids of numbers. It is how a computer moves, stretches and squeezes pictures, 3D worlds and data, and it is the base of all AI.",
  build: {
    name: "An image compressor",
    goal: "Compress a picture with a few numbers: split it into layers with the singular value decomposition, keep the top k with a slider, and watch the file size and the picture quality trade off.",
  },
  units: [
    { n: 1, name: "Arrows", adds: "A picture is numbers: your 8 × 8 grid img, each row a vector. How alike two rows are, and how many rows are truly different." },
    { n: 2, name: "Matrices as moves", adds: "The picture is a matrix. A column times a row makes the first layer, layer1." },
    { n: 3, name: "Solving and fitting", adds: "Rank: how many layers rebuild the picture exactly. Least squares: the squared error the compressor reports." },
    { n: 4, name: "Eigen", adds: "Pixel pairs as average and difference. A symmetric matrix's perpendicular main directions, which is where the layers come from." },
    { n: 5, name: "SVD and the build", adds: "Orthonormal layers, the SVD itself, energy kept and error dropped, the PCA view, and storage cost k(m + n + 1): the compressor." },
  ],
  projects: [
    { id: "la-grid", after: "b2-la-04", name: "Your own grid", makes: "Pick two basis arrows. The plane redraws in your grid, and three target points are written in your coordinates.", shelf: ["basis"], scene: { scene: S.vec, props: { mode: "basis", project: true } } },
    { id: "la-filter", after: "b2-la-08", name: "Filter and undo", makes: "Chain a turn, a shear and a scale into one filter for an 8 × 8 sprite. Read how much it changes area, then undo it.", shelf: ["M", "Minv"], scene: { scene: S.play, props: { mode: "filter", project: true } } },
    { id: "la-fit", after: "b2-la-11", name: "Line through the noise", makes: "Type 4 to 8 measured points, such as phone battery against minutes, and fit the least-squares line.", shelf: ["fit"], scene: { scene: S.res, props: { project: true } } },
    { id: "la-forecast", after: "b2-la-14", name: "Long-run forecaster", makes: "A two-station bike share or two-state weather: set the move chances and see where things settle, as a number and as dots flowing.", shelf: ["steady"], scene: { scene: S.flow, props: { project: true } } },
    { id: "la-plaid", after: "b2-la-18", name: "Plaid from layers", makes: "Build a 6 × 6 plaid from two or three column-times-row layers, then check its rank and its storage cost.", shelf: ["plaid"], scene: { scene: S.comp, props: { mode: "plaid", project: true } } },
    { id: "la-build", after: "b2-la-20", name: "The build: image compressor", makes: "A photo, compressed to a size you choose, with the k you chose and the energy you kept.", shelf: ["k", "sigma"], build: true, scene: { scene: S.comp, props: { mode: "build", project: true } } },
  ],
  tools: [
    { id: S.play, name: "Transformation playground", short: "Playground", star: true },
    { id: S.vec, name: "Vector board", short: "Vectors" },
    { id: S.space, name: "3D space", short: "3D space" },
    { id: S.eig, name: "Eigen finder", short: "Eigen" },
    { id: S.comp, name: "Image compressor", short: "Compressor" },
    { id: S.flow, name: "Two-state flow", short: "Flow" },
    { id: S.res, name: "Residual squares", short: "Residuals" },
    { id: S.cloud, name: "Data cloud", short: "Cloud" },
  ],
  buildPieces: ["img", "basis", "shear", "layer1", "M", "Minv", "fit", "lam", "steady", "sigmaM", "plaid", "k", "sigma"],
  lessons: LA_LESSONS,
};
