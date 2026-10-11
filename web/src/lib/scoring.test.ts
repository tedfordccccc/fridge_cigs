import { describe, expect, it } from "vitest";
import { crispiness, tier } from "./scoring";

describe("crispiness", () => {
  it("weights fizz 30, syrup 30, chill 25, ice 15", () => {
    expect(crispiness({ fizz: 10, syrup: 9, chill: 8, ice: 10 })).toBeCloseTo(9.2);
    expect(crispiness({ fizz: 7, syrup: 7, chill: 7, ice: 7 })).toBeCloseTo(7);
    expect(crispiness({ fizz: 1, syrup: 1, chill: 1, ice: 1 })).toBeCloseTo(1);
  });
});

describe("tier", () => {
  it.each([
    [10, "Elite pour"], [9, "Elite pour"], [8.99, "Solid"], [7.5, "Solid"],
    [7.49, "Passable"], [6, "Passable"], [5.99, "Flat-adjacent"], [4, "Flat-adjacent"],
    [3.99, "Avoid"], [1, "Avoid"],
  ])("%s → %s", (v, t) => expect(tier(v)).toBe(t));
});
