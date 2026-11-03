import { createRoot } from "react-dom/client";
import { createPortal } from "react-dom";
import { useEffect, useReducer, useRef, useState, type ReactNode } from "react";
import {
  SoapBubbleMaterial,
  SoapBubbleSearch,
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

function findPageMatches(query: string): Range[] {
  const needle = query.trim().toLowerCase();
  if (!needle) return [];

  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      const parent = node.parentElement;
      if (
        !parent ||
        parent.closest(
          "script, style, noscript, input, textarea, select, button, [hidden], [inert], [aria-hidden='true'], [contenteditable='true'], .faceauth-site-search",
        )
      ) {
        return NodeFilter.FILTER_REJECT;
      }
      return NodeFilter.FILTER_ACCEPT;
    },
  });
  const ranges: Range[] = [];

  for (let node = walker.nextNode(); node; node = walker.nextNode()) {
    const text = node.textContent ?? "";
    const lowerText = text.toLowerCase();
    let start = 0;
    while ((start = lowerText.indexOf(needle, start)) !== -1) {
      const range = document.createRange();
      range.setStart(node, start);
      range.setEnd(node, start + needle.length);
      if (range.getClientRects().length > 0) ranges.push(range);
      start += needle.length;
    }
  }
  return ranges;
}

function showPageMatches(query: string): () => void {
  const ranges = findPageMatches(query);
  if (!ranges.length) return () => {};

  const registry = typeof CSS !== "undefined" ? CSS.highlights : undefined;
  if (registry && typeof Highlight !== "undefined") {
    registry.set("faceauth-search-match", new Highlight(...ranges));
    ranges[0].startContainer.parentElement?.scrollIntoView({
      behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth",
      block: "center",
    });
    return () => registry.delete("faceauth-search-match");
  }

  const range = ranges[0];
  const marker = document.createElement("mark");
  marker.className = "faceauth-search-match-fallback";
  range.surroundContents(marker);
  marker.scrollIntoView({
    behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth",
    block: "center",
  });
  return () => {
    const parent = marker.parentNode;
    if (!parent) return;
    parent.replaceChild(document.createTextNode(marker.textContent ?? ""), marker);
    parent.normalize();
  };
}

function SettingsToggles({
  popup,
  hosts,
  sliderHosts,
  searchButtonHost,
}: {
  popup: HTMLElement;
  hosts: Array<{ name: SettingsToggleName; element: HTMLElement }>;
  sliderHosts: Array<{ name: SettingsSliderName; element: HTMLElement }>;
  searchButtonHost: HTMLElement | null;
}) {
  const [, refresh] = useReducer((version: number) => version + 1, 0);
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const searchHost = useRef<HTMLDivElement>(null);
  const searchButton = useRef<HTMLButtonElement>(null);
  const restoreSearchFocus = useRef(false);

  useEffect(() => {
    const observer = new MutationObserver(refresh);
    observer.observe(popup, {
      attributes: true,
      attributeFilter: ["aria-label"],
      subtree: true,
    });
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["data-theme"],
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

  useEffect(() => {
    if (!searchButtonHost) return;
    searchButtonHost.dataset.expanded = String(searchOpen);
    const controls = searchButtonHost.parentElement;
    if (controls) controls.dataset.searchOpen = String(searchOpen);
    return () => {
      delete searchButtonHost.dataset.expanded;
      if (controls) delete controls.dataset.searchOpen;
    };
  }, [searchButtonHost, searchOpen]);

  useEffect(() => {
    const host = searchHost.current;
    if (!searchOpen || !host) return;
    const input = host.querySelector<HTMLInputElement>("input[type='search']");
    input?.focus();
    const onPointerDown = (event: PointerEvent) => {
      if (!host.contains(event.target as Node)) setSearchOpen(false);
    };
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key !== "Escape") return;
      restoreSearchFocus.current = true;
      setSearchOpen(false);
    };
    document.addEventListener("pointerdown", onPointerDown);
    document.addEventListener("keydown", onKeyDown);
    return () => {
      document.removeEventListener("pointerdown", onPointerDown);
      document.removeEventListener("keydown", onKeyDown);
    };
  }, [searchOpen]);

  useEffect(() => {
    if (!searchOpen && restoreSearchFocus.current) {
      searchButton.current?.focus();
      restoreSearchFocus.current = false;
    }
  }, [searchOpen]);

  useEffect(() => {
    if (!searchOpen || !searchQuery.trim()) return;
    let clearMatches = () => {};
    const timeout = window.setTimeout(() => {
      clearMatches = showPageMatches(searchQuery);
    }, 250);
    return () => {
      window.clearTimeout(timeout);
      clearMatches();
    };
  }, [searchOpen, searchQuery]);

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

  const darkTheme = document.documentElement.dataset.theme === "dark";
  const searchControl = searchButtonHost
    ? createPortal(
        <SoapBubbleMaterial
          backdrop={document.body}
          glass={0.95}
          iridescence={darkTheme ? 2 : 0.5}
          filmScale={4.85}
          oilOpacity={1}
          oilCoverage={darkTheme ? 1 : 0.73}
          oilEdge={18}
          oilEdgeFade={darkTheme ? 1 : 2.33}
          clearCenter={darkTheme ? 0.73 : 0.57}
          thickness={480}
          drainage={0.35}
          swirl={0.5}
          reflectivity={1.3}
          refraction={0.15}
          dispersion={1}
          bevel={14}
          environment="auto"
          windowLength={1.3}
          windowMargin={0.85}
          windowBend={0.75}
          windowSize={0.75}
          windowWidth={0.8}
          windowGradient={0.96}
          windowHead={0.7}
          windowTail={0.6}
          glintSize={1.65}
          glintIntensity={0}
          glintDistance={-0.45}
          glintHeight={0.65}
          windowIntensity={0.85}
          windowTwin={false}
          bottomShade
          bottomShadeColor={darkTheme ? "#ffffff00" : "#ffffff"}
        >
          <div
            ref={searchHost}
            className="faceauth-site-search"
            data-expanded={searchOpen}
          >
            <button
              ref={searchButton}
              className="faceauth-site-search-trigger"
              aria-label="Search this site"
              aria-expanded={searchOpen}
              aria-controls="faceauth-site-search-field"
              type="button"
              tabIndex={searchOpen ? -1 : 0}
              aria-hidden={searchOpen}
              disabled={searchOpen}
              onClick={() => setSearchOpen(true)}
            >
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.8"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <circle cx="10.8" cy="10.8" r="6.8" />
                <path d="m16 16 4.2 4.2" />
              </svg>
            </button>
            <div
              id="faceauth-site-search-field"
              className="faceauth-site-search-field"
              role="search"
              aria-hidden={!searchOpen}
            >
              <SoapBubbleSearch
                aria-label="Search this site"
                placeholder="Search this site"
                value={searchQuery}
                disabled={!searchOpen}
                onChange={(event) => setSearchQuery(event.currentTarget.value)}
              />
            </div>
          </div>
        </SoapBubbleMaterial>,
        searchButtonHost,
        "product-search",
      )
    : null;

  return (
    <SoapBubbleMaterial backdrop={popup}>
      <>
        {toggles}
        {searchControl}
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
  <SettingsToggles
    popup={popup}
    hosts={hosts}
    sliderHosts={sliderHosts}
    searchButtonHost={document.querySelector<HTMLElement>(
      "#faceauth-product-search-button-host",
    )}
  />,
);
