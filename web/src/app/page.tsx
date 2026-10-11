import { Header } from "@/components/header";
import { LegalFooter } from "@/components/legal-footer";
import { supabaseConfigured } from "@/lib/supabase/env";

// Step 1 shell: design system, header and footer are final. The live leaderboard and the
// pour form get wired to Supabase in the next steps.
export default function Home() {
  return (
    <div className="wrap">
      <Header />
      {!supabaseConfigured && (
        <div className="note">
          Not connected to a database yet. Add the Supabase URL and publishable key to .env.local to load the
          leaderboard.
        </div>
      )}

      <div className="grid">
        <section aria-labelledby="lbh">
          <h2 id="lbh">
            Leaderboard <small />
          </h2>
          <div className="board">
            <div className="empty">
              <b>No pours yet</b>
              <p>
                Ranked spots show up here once someone logs a Diet Coke. Rate your next one with the form
                <span className="below-only"> below</span>: fizz, syrup ratio, chill and ice, scored 1 to 10.
              </p>
            </div>
          </div>
        </section>

        <section aria-labelledby="fh">
          <h2 id="fh">Rate a pour</h2>
          <div className="empty">
            <b>Coming next</b>
            <p>The pour form arrives once sign-in is set up.</p>
          </div>
        </section>
      </div>
      <LegalFooter />
    </div>
  );
}
