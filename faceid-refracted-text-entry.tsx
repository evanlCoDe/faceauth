import { createRoot } from "react-dom/client";
import { RefractedText, type RefractedTextProps } from "./components/refracted-text";

const refractedTextOptions = {
  theme: "auto",
  topColor: "auto",
  bottomColor: "auto",
  beamColor: "auto",
  spectrumWarmColor: "auto",
  spectrumMiddleColor: "auto",
  spectrumCoolColor: "auto",
  reveal: true,
  stagger: 0.55,
  liftDuration: 1.75,
  ease: "power4.out",
  beamFollowsLift: false,
  animateBeam: true,
  openingDuration: 6.9,
  duration: 13.2,
  intensity: 1.2,
  dispersion: 1,
  colorIntensity: 1,
  beamPosition: 0.5,
  fixedBeam: false,
  paused: false,
  cursorMovesBeam: false,
  fontSize: "clamp(3.2rem, 7vw, 6rem)",
  fontFamily: '"SF Pro Display", "SF Pro Text", -apple-system, BlinkMacSystemFont, Helvetica, Arial, sans-serif',
  fontWeight: 700,
  letterSpacing: "-0.02em",
  extraBold: 0,
  fontHeight: 80,
  cornerRounding: 1,
} satisfies Omit<RefractedTextProps, "text">;

document.querySelectorAll<HTMLElement>("[data-refracted-title]").forEach((mount) => {
  const isVoice = mount.dataset.refractedTitle === "voice";

  createRoot(mount).render(
    <>
      <span className="hero-refracted-line">
        <RefractedText text={isVoice ? "Your Voice." : "Your face."} {...refractedTextOptions} />
      </span>
      <span className="hero-refracted-line hero-refracted-line--second">
        <RefractedText text="Your" {...refractedTextOptions} />
        <img
          src="ChatGPT Image Sep 18, 2026, 08_46_49 AM.png"
          className="hero-apple-icon"
          alt=""
        />
        <RefractedText text="Mac." {...refractedTextOptions} />
      </span>
    </>,
  );
});