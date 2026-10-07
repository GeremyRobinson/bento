// Export and import: one JSON file holding everything saved on this device.
import type { Progress } from "../engine/mastery/progress";
import type { SessionReport } from "../engine/session/types";
import { migrateProgress } from "./migrations";

export const BACKUP_FORMAT = "bento-backup";

export interface Backup {
  format: typeof BACKUP_FORMAT;
  version: 1;
  exportedAt: number;
  progress: Progress;
  reports: Record<string, SessionReport>;
}

export const makeBackup = (progress: Progress, reports: Record<string, SessionReport>, now: number): Backup =>
  ({ format: BACKUP_FORMAT, version: 1, exportedAt: now, progress, reports });

/** Reads a backup file's text. Throws a readable error when the file isn't a Bento backup. */
export function readBackup(json: string): { progress: Progress; reports: Record<string, SessionReport> } {
  let data: unknown;
  try { data = JSON.parse(json); } catch { throw new Error("That file isn't an Obento backup."); }
  const d = data as Partial<Backup>;
  if (!d || d.format !== BACKUP_FORMAT || typeof d.progress !== "object") throw new Error("That file isn't an Obento backup.");
  if ((d.version ?? 0) > 1) throw new Error("That backup is from a newer version of Obento.");
  return { progress: migrateProgress(d.progress), reports: d.reports && typeof d.reports === "object" ? d.reports : {} };
}
