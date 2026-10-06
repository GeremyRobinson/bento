// The learner's own message, shared by the Shrinker's projects and the bit counter: one tool state, so every project
// and lesson picks up the sentence typed last.
import { useB2 } from "../../../ui/useB2";

export const DEFAULT_MESSAGE = "the cat sat on the mat and the dog sat on the log";
const KEY = "in-message";

export function useMessage(): [string, (t: string) => void] {
  const { tool, setToolState } = useB2();
  const text = tool<{ text: string }>(KEY, { text: DEFAULT_MESSAGE }).text;
  return [text, (t: string) => setToolState(KEY, { text: t.slice(0, 400) })];
}
