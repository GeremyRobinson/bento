// The live pictures. Each track keeps its own at tracks/<name>/scenes.tsx (exporting `scenes`), and a lesson stage,
// a tool panel or a project names one by its scene name. A track tool's id is the name of the scene it opens.
import type { ComponentType } from "react";

export type SceneValues = Record<string, number | string | boolean>;

export interface SceneProps {
  props: SceneValues;
  /** where the picture sits: a lesson stage, a tool panel or a project (which can save) */
  place: "lesson" | "tool" | "project";
  /** a point guess's marker, in the picture's own coordinates, and where it moves to */
  marker?: [number, number];
  onMarker?: (p: [number, number]) => void;
}
/** `liveReveal`: the scene follows its props as they change (it reads its flags each render and slides any value a
 *  prop seeded), so a Guess reveal updates it in place instead of starting it over */
export type SceneComponent = ComponentType<SceneProps> & { liveReveal?: boolean };

const modules = import.meta.glob<{ scenes: Record<string, SceneComponent> }>("./tracks/*/scenes.tsx", { eager: true });
// gathered on first use, not at import: a track's pictures import this file, so gathering at import could run before
// that track's own table exists and drop it
let ALL: Record<string, SceneComponent> | undefined;
const all = () => (ALL ??= Object.assign({}, ...Object.values(modules).map(m => m.scenes)));

export const sceneByName = (name: string): SceneComponent | undefined => all()[name];
export const sceneNames = () => Object.keys(all());

/** reads a scene value with a default */
export const num = (p: SceneValues, k: string, d: number) => (typeof p[k] === "number" ? (p[k] as number) : d);
export const flag = (p: SceneValues, k: string) => p[k] === true;
export const str = <T extends string>(p: SceneValues, k: string, d: T): T => (typeof p[k] === "string" ? (p[k] as T) : d);
