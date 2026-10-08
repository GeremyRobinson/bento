import { IDBFactory } from "fake-indexeddb";
import { loadAll, LEGACY_KEYS } from "../../persistence/load";
import { makeBackup, readBackup } from "../../persistence/backup";
import { emptyProgress } from "../../engine/mastery/progress";

function memoryStorage(data: Record<string, string>): Storage {
  return { getItem: k => data[k] ?? null, setItem: (k, v) => { data[k] = v; }, removeItem: k => { delete data[k]; },
    clear: () => {}, key: () => null, get length() { return Object.keys(data).length; } } as Storage;
}

describe("storage", () => {
  it("starts empty on a new device", async () => {
    const r = await loadAll({ factory: new IDBFactory(), storage: memoryStorage({}) });
    expect(r.progress).toEqual(emptyProgress());
    expect(r.imported).toBe(false);
  });

  it("imports the current app's save once, keeping scores for lessons not rebuilt yet", async () => {
    const factory = new IDBFactory();
    const legacy = { grade: 5, chosen: 1, xp: 340, streak: 3, last: "Thu Oct 01 2026", done: 4,
      scores: { "g5-mult2": { last: 3, best: 4, pct: 0.8, date: 1 }, "g6-gcf": { last: 2, best: 2, pct: 0.6, date: 2 } },
      lessons: { "g5-mult2": 2 }, tests: {}, log: [], gxp: { 5: 340 } };
    const storage = memoryStorage({ [LEGACY_KEYS.save]: JSON.stringify(legacy) });
    const first = await loadAll({ factory, storage });
    expect(first.imported).toBe(true);
    expect(first.progress).toMatchObject({ grade: 5, chosen: true, xp: 340, streak: 3, done: 4 });
    expect(first.progress.scores["g6-gcf"]).toMatchObject({ last: 2 });
    // second load reads IndexedDB, and leaves the old keys alone
    const second = await loadAll({ factory, storage });
    expect(second.imported).toBe(false);
    expect(second.progress.xp).toBe(340);
    expect(storage.getItem(LEGACY_KEYS.save)).not.toBeNull();
  });

  it("saves and reads progress and reports", async () => {
    const factory = new IDBFactory();
    const { store } = await loadAll({ factory, storage: null });
    await store!.putProgress({ ...emptyProgress(), xp: 99 });
    const again = await loadAll({ factory, storage: null });
    expect(again.progress.xp).toBe(99);
  });

  it("round-trips a backup and rejects other files", () => {
    const b = JSON.stringify(makeBackup({ ...emptyProgress(), xp: 5 }, {}, 1));
    expect(readBackup(b).progress.xp).toBe(5);
    expect(() => readBackup("{}")).toThrow("That file isn't an Obento backup.");
    expect(() => readBackup("not json")).toThrow();
  });
});

describe("storage that never answers", () => {
  it("gives up after a moment and runs without saving", async () => {
    const silent = { open: () => ({}) } as unknown as IDBFactory;
    const { openDb } = await import("../../persistence/db");
    await expect(openDb(silent, "x", 20)).rejects.toThrow("storage did not open");
  });
});
