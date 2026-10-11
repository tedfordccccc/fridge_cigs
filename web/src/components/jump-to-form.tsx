"use client";

export function JumpToForm() {
  return (
    <button
      className="btn cream"
      type="button"
      onClick={() => {
        const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
        document.getElementById("fh")?.scrollIntoView({ behavior: reduce ? "auto" : "smooth" });
        document.getElementById("place")?.focus({ preventScroll: true });
      }}
    >
      Rate a pour
    </button>
  );
}
