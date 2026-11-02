import { createRoot } from "react-dom/client";
import { createPortal } from "react-dom";
import { useEffect, useReducer, type ReactNode } from "react";
import {
  SoapBubbleMaterial,
  SoapBubbleSlider,
  SoapBubbleToggle,
} from "./components/soap-bubble";

type SettingsToggleName = "appearance" | "scrolling" | "motion-blur";
type SettingsSliderName = "intensity" | "strength";

declare global {
  interface Window {
    faceAuthAppearance?: {
      mode: string;
      setMode: (mode: string) => void;
    };
    faceAuthScrolling?: {
      ultraSmoothEnabled: boolean;
      setUltraSmoothEnabled: (enabled: boolean) => void;
    };
    faceAuthMotionBlur?: {
      enabled: boolean;
      setEnabled: (enabled: boolean) => void;
    };
    faceAuthNavigationGlass?: {
      intensity: number;
      strength: number;
      setIntensity: (intensity: number, persist?: boolean) => void;
      setStrength: (strength: number, persist?: boolean) => void;
    };
  }
}

function readSetting(name: SettingsToggleName): boolean {
  switch (name) {
    case "appearance":
      return requireSettingsApi(window.faceAuthAppearance, "appearance").mode === "night";
    case "scrolling":
      return requireSettingsApi(window.faceAuthScrolling, "scrolling").ultraSmoothEnabled;
    case "motion-blur":
      return requireSettingsApi(window.faceAuthMotionBlur, "motion blur").enabled;
  }
}

function changeSetting(name: SettingsToggleName, enabled: boolean): void {
  switch (name) {
    case "appearance":
      requireSettingsApi(window.faceAuthAppearance, "appearance").setMode(
        enabled ? "night" : "day",
      );
      return;
    case "scrolling":
      requireSettingsApi(window.faceAuthScrolling, "scrolling").setUltraSmoothEnabled(enabled);
      return;
    case "motion-blur":
      requireSettingsApi(window.faceAuthMotionBlur, "motion blur").setEnabled(enabled);
      return;
  }
}

function requireSettingsApi<T>(api: T | undefined, name: string): T {
  if (!api) throw new Error(`FaceAuth ${name} settings are unavailable`);
  return api;
}

function readSlider(name: SettingsSliderName): number {
  const settings = requireSettingsApi(window.faceAuthNavigationGlass, "glass");
  return name === "intensity" ? settings.intensity : settings.strength;
}

function changeSlider(name: SettingsSliderName, value: number, persist = false): void {
  const settings = requireSettingsApi(window.faceAuthNavigationGlass, "glass");
  if (name === "intensity") settings.setIntensity(value, persist);
  else settings.setStrength(value, persist);
}

function SettingsToggles({
  popup,
  hosts,
  sliderHosts,
}: {
  popup: HTMLElement;
  hosts: Array<{ name: SettingsToggleName; element: HTMLElement }>;
  sliderHosts: Array<{ name: SettingsSliderName; element: HTMLElement }>;
}) {
  const [, refresh] = useReducer((version: number) => version + 1, 0);

  useEffect(() => {
    const observer = new MutationObserver(refresh);
    observer.observe(popup, {
      attributes: true,
      attributeFilter: ["aria-label"],
      subtree: true,
    });
    const refreshSliders = () => refresh();
    window.addEventListener("faceauth-navigation-glass-intensity-change", refreshSliders);
    window.addEventListener("faceauth-navigation-glass-strength-change", refreshSliders);
    return () => {
      observer.disconnect();
      window.removeEventListener(
        "faceauth-navigation-glass-intensity-change",
        refreshSliders,
      );
      window.removeEventListener(
        "faceauth-navigation-glass-strength-change",
        refreshSliders,
      );
    };
  }, [popup]);

  const toggles: ReactNode[] = hosts.map(({ name, element }) => {
    const checked = readSetting(name);
    return createPortal(
      <SoapBubbleToggle
        aria-label={element.getAttribute("aria-label") ?? ""}
        checked={checked}
        iridescence={checked ? undefined : 0}
        oilOpacity={checked ? undefined : 0}
        onCheckedChange={(enabled) => {
          changeSetting(name, enabled);
          refresh();
        }}
        scale={0.68}
      />,
      element,
      name,
    );
  });

  const sliders: ReactNode[] = sliderHosts.map(({ name, element }) =>
    createPortal(
      <SoapBubbleSlider
        className="faceauth-settings-slider"
        aria-label={element.getAttribute("aria-label") ?? ""}
        label={
          element.getAttribute("aria-label") ??
          element.closest(".liquid-glass-setting")?.querySelector(".liquid-glass-label")?.textContent ??
          "Glass setting"
        }
        min={0}
        max={1}
        step={0.001}
        value={readSlider(name)}
        from="#0a84ff"
        scale={0.65}
        onValueChange={(value) => {
          changeSlider(name, value);
          refresh();
        }}
        onPointerUp={() => changeSlider(name, readSlider(name), true)}
        onPointerCancel={() => changeSlider(name, readSlider(name), true)}
        onKeyUp={() => changeSlider(name, readSlider(name), true)}
        onBlur={() => changeSlider(name, readSlider(name), true)}
      />,
      element,
      name,
    ),
  );

  return (
    <SoapBubbleMaterial backdrop={popup}>
      <>
        {toggles}
        <SoapBubbleMaterial
          backdrop={null}
          iridescence={0}
          oilOpacity={0}
          lightTheme={true}
          environment="studio"
        >
          {sliders}
        </SoapBubbleMaterial>
      </>
    </SoapBubbleMaterial>
  );
}

const popup = document.querySelector<HTMLElement>("#faceauth-settings-popup");
if (!popup) throw new Error("FaceAuth Settings popup was not initialized");

const hosts = Array.from(
  popup.querySelectorAll<HTMLElement>("[data-setting-toggle]"),
).map((element) => {
  const name = element.dataset.settingToggle;
  if (
    name !== "appearance" &&
    name !== "scrolling" &&
    name !== "motion-blur"
  ) {
    throw new Error(`Unknown FaceAuth settings toggle: ${name ?? "(missing)"}`);
  }
  const toggleName: SettingsToggleName = name;
  return { name: toggleName, element };
});

if (hosts.length !== 3) {
  throw new Error(`Expected three FaceAuth settings toggles, found ${hosts.length}`);
}

const sliderHosts = Array.from(
  popup.querySelectorAll<HTMLElement>("[data-setting-slider]"),
).map((element) => {
  const name = element.dataset.settingSlider;
  if (name !== "intensity" && name !== "strength") {
    throw new Error(`Unknown FaceAuth settings slider: ${name ?? "(missing)"}`);
  }
  const sliderName: SettingsSliderName = name;
  return { name: sliderName, element };
});

if (sliderHosts.length !== 2) {
  throw new Error(`Expected two FaceAuth settings sliders, found ${sliderHosts.length}`);
}

const mount = document.createElement("div");
mount.hidden = true;
popup.append(mount);
createRoot(mount).render(
  <SettingsToggles popup={popup} hosts={hosts} sliderHosts={sliderHosts} />,
);
