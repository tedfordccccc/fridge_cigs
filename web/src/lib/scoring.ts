// Crispiness scoring, ported from prototype/fridge-cig-report.html.
// The database computes the stored score with the same weights (public.crispiness in
// supabase/migrations); keep the two in step if the weights ever change.

export const WEIGHTS = { fizz: 0.3, syrup: 0.3, chill: 0.25, ice: 0.15 } as const;
export type Criterion = keyof typeof WEIGHTS;
export const CRITERIA = Object.keys(WEIGHTS) as Criterion[];
export type SubScores = Record<Criterion, number>;

export function crispiness(s: SubScores): number {
  return CRITERIA.reduce((sum, k) => sum + (Number(s[k]) || 0) * WEIGHTS[k], 0);
}

export function tier(v: number): string {
  return v >= 9 ? "Elite pour" : v >= 7.5 ? "Solid" : v >= 6 ? "Passable" : v >= 4 ? "Flat-adjacent" : "Avoid";
}

// Database enum values → the labels shown in the prototype.
export const FORMATS = {
  fountain: "Fountain",
  can: "Can",
  plastic_bottle: "Plastic bottle",
  glass_bottle: "Glass bottle",
} as const;
export type Format = keyof typeof FORMATS;

export const ICE_TYPES = {
  nugget: "Nugget / pellet",
  crushed: "Crushed",
  cubed: "Cubed",
  crescent: "Crescent",
  shaved: "Shaved",
  none: "No ice",
} as const;
export type IceType = keyof typeof ICE_TYPES;
