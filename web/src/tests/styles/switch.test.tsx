import { fireEvent, render, screen } from "@testing-library/react";
import { useState } from "react";
import { describe, expect, it } from "vitest";
import { OSwitch } from "../../components/Masters";
import { MASTERS } from "../../styles/masters";

/**
 * The switch (UI model v66, Review settings-c): one master for every on/off in the app. A slider with an Off and an On
 * stop, or a checkbox of its own, is a second on/off and fails here with its file.
 */
const fsName = "node:fs";
const fs = (await import(/* @vite-ignore */ fsName)) as { readFileSync(p: URL, enc: "utf8"): string };
const ui = Object.keys(import.meta.glob(["../../app/**/*.tsx", "../../components/**/*.tsx", "../../screens/**/*.tsx"]))
  .map(f => [f.replace("../../", ""), fs.readFileSync(new URL(f, import.meta.url), "utf8")] as [string, string]);

describe("the switch master", () => {
  it("is registered once, in masters.ts", () => {
    expect(MASTERS.filter(m => m.classes.includes("o-tg")).map(m => m.name)).toEqual(["O switch"]);
  });

  it("is a real switch, named by its setting, and flips", () => {
    const Box = () => { const [on, set] = useState(false); return <OSwitch on={on} onChange={set} label="Sounds" />; };
    render(<Box />);
    const sw = screen.getByRole("switch", { name: "Sounds" });
    expect(sw).toHaveAttribute("aria-checked", "false");
    fireEvent.click(sw);
    expect(sw).toHaveAttribute("aria-checked", "true");
  });

  it("is the only on/off: no Off/On slider and no checkbox anywhere else", () => {
    const off = ui.filter(([, t]) => /label:\s*"Off"|label:\s*"On"|type="checkbox"|role="switch"/.test(t)).map(([f]) => f);
    expect(off).toEqual(["components/Masters.tsx"]);
  });
});
