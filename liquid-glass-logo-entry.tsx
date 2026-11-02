import { createRef } from "react";
import { createRoot } from "react-dom/client";
import { LiquidGlassLogo, type LiquidGlassLogoHandle } from "./components/liquid-glass-logo";
import CreditCard from "./components/shared-assets/credit-card/credit-card";

const logos = [
  { id: "faceauth-liquid-glass-logo", logo: "./faceauth-hero-logo.png", label: "FaceAuth logo" },
  { id: "voiceid-liquid-glass-logo", logo: "./voiceid-hero-logo.png", label: "VoiceID logo" },
].map((logo) => ({ ...logo, ref: createRef<LiquidGlassLogoHandle>() }));

logos.forEach(({ id, logo, label, ref }) => {
  const mount = document.getElementById(id);
  if (!mount) return;

  createRoot(mount).render(
    <LiquidGlassLogo
      ref={ref}
      logo={logo}
      ending="logo"
      theme="light"
      depth={2.9}
      background="rgba(255, 255, 255, 0)"
      logoColor="original"
      logoSize={180}
      finalLogoScale={0.88}
      style={{ height: "min(240px, 30svh)", minHeight: 0 }}
      aria-label={label}
    />,
  );
});

const creditCardMount = document.getElementById("faceauth-free-card");
if (creditCardMount) {
  createRoot(creditCardMount).render(<CreditCard type="gray-strip" />);
}

window.addEventListener("faceauth-product-change", () => {
  const activeLogoId = document.body.classList.contains("faceauth-voiceid-active")
    ? "voiceid-liquid-glass-logo"
    : "faceauth-liquid-glass-logo";
  logos.find(({ id }) => id === activeLogoId)?.ref.current?.replay();
});
