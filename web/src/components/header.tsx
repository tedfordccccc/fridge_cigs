import { WORDMARK_SVG } from "./wordmark-svg";
import { JumpToForm } from "./jump-to-form";

// Red enamel sign header, markup and copy as in the prototype.
export function Header() {
  return (
    <header className="can">
      <div className="sign">
        <div className="eyebrow">Soda fountain field notes · fountain, can &amp; bottle</div>
        <div className="hdr-row">
          <div>
            <div className="kicker">A Diet Coke rating guide</div>
            <h1 dangerouslySetInnerHTML={{ __html: WORDMARK_SVG }} />
            <p className="sub">
              Score the Diet Coke wherever you order it. Fizz, syrup ratio, chill and ice roll up into one
              weighted score, and every spot lands on the leaderboard.
            </p>
          </div>
          <JumpToForm />
        </div>
      </div>
    </header>
  );
}
