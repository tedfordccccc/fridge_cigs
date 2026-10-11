import type { Metadata, Viewport } from "next";
import { Federo, Pinyon_Script } from "next/font/google";
import { ServiceWorker } from "@/components/service-worker";
import "./globals.css";

// Both fonts are SIL OFL. next/font downloads them at build time and serves them
// from our own domain, so visitors' browsers never call Google.
const pinyon = Pinyon_Script({ weight: "400", subsets: ["latin"], variable: "--font-pinyon" });
const federo = Federo({ weight: "400", subsets: ["latin"], variable: "--font-federo" });

export const metadata: Metadata = {
  title: "Fridge Cig Report",
  description:
    "Score the Diet Coke wherever you order it. Fizz, syrup ratio, chill and ice roll up into one weighted score, and every spot lands on the leaderboard.",
  applicationName: "Fridge Cig Report",
  appleWebApp: { capable: true, title: "Fridge Cig", statusBarStyle: "default" },
  icons: {
    icon: [{ url: "/icons/icon-192.png", sizes: "192x192", type: "image/png" }],
    apple: [{ url: "/icons/apple-touch-icon.png", sizes: "180x180" }],
  },
};

export const viewport: Viewport = {
  themeColor: "#c8102e",
  colorScheme: "light",
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${pinyon.variable} ${federo.variable}`}>
      <body>
        {children}
        <ServiceWorker />
      </body>
    </html>
  );
}
