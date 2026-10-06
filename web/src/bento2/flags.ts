// Which Bento² tracks are open. A track listed here shows "Open" on picker D's Bento² side and opens its track screen;
// every other track stays "Coming later". Ship a track by adding its picker id (app/tracks.ts) once its lessons pass.
export const B2_TRACKS_LIVE: readonly string[] = ["relativity", "linear", "orbit", "quantum", "change", "hills"];

export const isTrackLive = (pickerId: string) => B2_TRACKS_LIVE.includes(pickerId);
