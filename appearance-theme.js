(() => {
  const storageKey = 'faceauth-appearance';
  const scrollStorageKey = 'faceauth-ultra-smooth-scrolling';
  const liquidGlassStorageKey = 'faceauth-liquid-glass';
  const motionBlurStorageKey = 'faceauth-motion-blur';
  const defaultNavigationGlassIntensity = 0.25;
  const transitionDuration = 420;
  const scrollFrameDuration = 1000 / 25;
  let mode = 'day';
  let ultraSmoothScrolling = true;
  let liquidGlassEnabled = true;
  let motionBlurEnabled = true;
  let navigationGlassIntensity = defaultNavigationGlassIntensity;
  let fallbackFrame = 0;
  let fallbackTimeout = 0;
  let pendingWheelDelta = 0;
  let scrollFrameTimeout = 0;
  let lastScrollUpdate = 0;

  try {
    mode = localStorage.getItem(storageKey) === 'night' ? 'night' : 'day';
  } catch {}

  try {
    ultraSmoothScrolling = localStorage.getItem(scrollStorageKey) !== 'false';
  } catch {}

  try {
    liquidGlassEnabled = localStorage.getItem(liquidGlassStorageKey) !== 'false';
  } catch {}

  try {
    motionBlurEnabled = localStorage.getItem(motionBlurStorageKey) !== 'false';
  } catch {}

  const applyMode = (nextMode, persist = false) => {
    mode = nextMode === 'night' ? 'night' : 'day';
    const root = document.documentElement;
    const theme = mode === 'night' ? 'dark' : 'light';
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const shouldTransition = root.dataset.theme && root.dataset.theme !== theme && !prefersReducedMotion;
    const updateTheme = () => {
      root.dataset.theme = theme;
      root.style.colorScheme = theme;
    };

    if (persist) {
      try {
        localStorage.setItem(storageKey, mode);
      } catch {}
    }

    if (!shouldTransition) {
      cancelAnimationFrame(fallbackFrame);
      clearTimeout(fallbackTimeout);
      root.classList.remove('theme-transitioning');
      updateTheme();
      return;
    }

    if (typeof document.startViewTransition === 'function') {
      document.startViewTransition(updateTheme);
      return;
    }

    root.classList.add('theme-transitioning');
    cancelAnimationFrame(fallbackFrame);
    clearTimeout(fallbackTimeout);
    fallbackFrame = requestAnimationFrame(() => {
      fallbackFrame = 0;
      updateTheme();
      fallbackTimeout = window.setTimeout(() => {
        root.classList.remove('theme-transitioning');
        fallbackTimeout = 0;
      }, transitionDuration + 30);
    });
  };

  window.faceAuthAppearance = Object.freeze({
    get mode() {
      return mode;
    },
    setMode(nextMode) {
      applyMode(nextMode, true);
    }
  });

  const setUltraSmoothScrolling = (enabled, persist = true) => {
    ultraSmoothScrolling = Boolean(enabled);
    const root = document.documentElement;

    if (ultraSmoothScrolling) {
      root.style.removeProperty('scroll-behavior');
      pendingWheelDelta = 0;
      clearTimeout(scrollFrameTimeout);
      scrollFrameTimeout = 0;
      lastScrollUpdate = 0;
    } else {
      root.style.scrollBehavior = 'auto';
    }

    if (persist) {
      try {
        localStorage.setItem(scrollStorageKey, String(ultraSmoothScrolling));
      } catch {}
    }
  };

  const canScrollWithinTarget = (target, deltaY) => {
    let element = target instanceof Element ? target : target?.parentElement;
    while (element && element !== document.body && element !== document.documentElement) {
      if (element.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].includes(element.tagName)) return true;
      const overflowY = getComputedStyle(element).overflowY;
      const maxScrollTop = element.scrollHeight - element.clientHeight;
      if (maxScrollTop > 1 && ['auto', 'scroll', 'overlay'].includes(overflowY)) {
        const canScrollUp = element.scrollTop > 0;
        const canScrollDown = element.scrollTop < maxScrollTop - 1;
        if (deltaY < 0 ? canScrollUp : canScrollDown) return true;
      }
      element = element.parentElement;
    }
    return false;
  };

  const flushWheelDelta = () => {
    scrollFrameTimeout = 0;
    if (ultraSmoothScrolling || pendingWheelDelta === 0) return;

    const elapsed = performance.now() - lastScrollUpdate;
    if (lastScrollUpdate && elapsed < scrollFrameDuration) {
      scrollFrameTimeout = window.setTimeout(flushWheelDelta, scrollFrameDuration - elapsed);
      return;
    }

    const deltaY = pendingWheelDelta;
    pendingWheelDelta = 0;
    const maxScrollTop = Math.max(0, document.documentElement.scrollHeight - window.innerHeight);
    const nextScrollTop = Math.max(0, Math.min(maxScrollTop, window.scrollY + deltaY));
    window.scrollTo(window.scrollX, nextScrollTop);
    lastScrollUpdate = performance.now();
  };

  window.addEventListener('wheel', (event) => {
    if (ultraSmoothScrolling || event.defaultPrevented || event.ctrlKey || event.shiftKey || event.deltaY === 0) return;
    if (canScrollWithinTarget(event.target, event.deltaY)) return;

    event.preventDefault();
    const deltaMultiplier = event.deltaMode === WheelEvent.DOM_DELTA_LINE
      ? 16
      : event.deltaMode === WheelEvent.DOM_DELTA_PAGE
        ? window.innerHeight
        : 1;
    pendingWheelDelta += event.deltaY * deltaMultiplier;
    if (!scrollFrameTimeout) flushWheelDelta();
  }, { passive: false });

  window.faceAuthScrolling = Object.freeze({
    get ultraSmoothEnabled() {
      return ultraSmoothScrolling;
    },
    setUltraSmoothEnabled(enabled) {
      setUltraSmoothScrolling(enabled);
    }
  });

  let motionBlurFilterPrimitive;
  let motionBlurFrame = 0;
  let motionBlurAmount = 0;
  let motionBlurTarget = 0;
  let lastMotionFrameTime = 0;
  let lastScrollY = window.scrollY;
  let lastScrollTime = performance.now();
  let lastMotionScrollTime = 0;

  const ensureMotionBlurFilter = () => {
    if (motionBlurFilterPrimitive) return;
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('width', '0');
    svg.setAttribute('height', '0');
    svg.setAttribute('aria-hidden', 'true');
    svg.style.cssText = 'position:fixed;top:0;left:0;width:0;height:0;pointer-events:none;z-index:-1;';
    const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
    const filter = document.createElementNS('http://www.w3.org/2000/svg', 'filter');
    filter.setAttribute('id', 'faceauth-motion-blur-filter');
    filter.setAttribute('x', '-10%');
    filter.setAttribute('y', '-10%');
    filter.setAttribute('width', '120%');
    filter.setAttribute('height', '120%');
    filter.setAttribute('color-interpolation-filters', 'sRGB');
    motionBlurFilterPrimitive = document.createElementNS('http://www.w3.org/2000/svg', 'feGaussianBlur');
    motionBlurFilterPrimitive.setAttribute('in', 'SourceGraphic');
    motionBlurFilterPrimitive.setAttribute('stdDeviation', '0 0');
    filter.appendChild(motionBlurFilterPrimitive);
    defs.appendChild(filter);
    svg.appendChild(defs);
    document.documentElement.appendChild(svg);
  };

  const animateMotionBlur = (timestamp) => {
    motionBlurFrame = 0;
    const elapsed = lastMotionFrameTime ? Math.min(32, timestamp - lastMotionFrameTime) : 16;
    lastMotionFrameTime = timestamp;
    const isReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const target = motionBlurEnabled && !isReducedMotion && timestamp - lastMotionScrollTime < 55
      ? motionBlurTarget
      : 0;
    const smoothing = 1 - Math.exp(-elapsed / (target > motionBlurAmount ? 35 : 40));
    motionBlurAmount += (target - motionBlurAmount) * smoothing;
    if (motionBlurAmount < 0.01 && target === 0) motionBlurAmount = 0;
    motionBlurFilterPrimitive?.setAttribute('stdDeviation', `0 ${motionBlurAmount.toFixed(2)}`);
    if (motionBlurAmount === 0 && target > 0) document.documentElement.classList.add('motion-blur-enabled');

    if (motionBlurAmount > 0 || target > 0 || timestamp - lastMotionScrollTime < 55) {
      motionBlurFrame = requestAnimationFrame(animateMotionBlur);
    } else {
      lastMotionFrameTime = 0;
      document.documentElement.classList.remove('motion-blur-enabled');
    }
  };

  const scheduleMotionBlur = () => {
    if (!motionBlurEnabled || window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    const now = performance.now();
    const currentScrollY = window.scrollY;
    const elapsed = Math.max(8, now - lastScrollTime);
    const velocity = Math.abs(currentScrollY - lastScrollY) / elapsed;
    motionBlurTarget = Math.min(3.75, Math.max(0, (velocity - 0.06) * 1.35));
    lastScrollY = currentScrollY;
    lastScrollTime = now;
    lastMotionScrollTime = now;
    if (motionBlurTarget > 0) document.documentElement.classList.add('motion-blur-enabled');
    if (!motionBlurFrame) motionBlurFrame = requestAnimationFrame(animateMotionBlur);
  };

  window.addEventListener('scroll', scheduleMotionBlur, { passive: true });

  const setMotionBlurEnabled = (enabled, persist = true) => {
    motionBlurEnabled = Boolean(enabled);
    const root = document.documentElement;
    if (motionBlurEnabled && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      ensureMotionBlurFilter();
      lastScrollY = window.scrollY;
      lastScrollTime = performance.now();
    } else {
      motionBlurTarget = 0;
      if (!motionBlurFrame && motionBlurAmount > 0) motionBlurFrame = requestAnimationFrame(animateMotionBlur);
      else if (!motionBlurAmount) root.classList.remove('motion-blur-enabled');
    }
    if (persist) {
      try {
        localStorage.setItem(motionBlurStorageKey, String(motionBlurEnabled));
      } catch {}
    }
  };

  window.faceAuthMotionBlur = Object.freeze({
    get enabled() {
      return motionBlurEnabled;
    },
    setEnabled(enabled) {
      setMotionBlurEnabled(enabled);
    }
  });

  const setLiquidGlassEnabled = (enabled, persist = true) => {
    liquidGlassEnabled = Boolean(enabled);
    const updateLiquidGlass = () => {
      document.documentElement.classList.toggle('liquid-glass-disabled', !liquidGlassEnabled);
      window.dispatchEvent(new Event('faceauth-liquid-glass-change'));
    };

    if (persist) {
      try {
        localStorage.setItem(liquidGlassStorageKey, String(liquidGlassEnabled));
      } catch {}
    }

    if (persist && document.visibilityState === 'visible' && !window.matchMedia('(prefers-reduced-motion: reduce)').matches && typeof document.startViewTransition === 'function') {
      document.startViewTransition(updateLiquidGlass);
    } else {
      updateLiquidGlass();
    }
  };

  window.faceAuthLiquidGlass = Object.freeze({
    get enabled() {
      return liquidGlassEnabled;
    },
    setEnabled(enabled) {
      setLiquidGlassEnabled(enabled);
    }
  });

  const setNavigationGlassIntensity = (intensity) => {
    const value = Number(intensity);
    if (!Number.isFinite(value)) return;
    navigationGlassIntensity = Math.min(1, Math.max(0, value));
    const root = document.documentElement;
    const opacityCurve = navigationGlassIntensity + navigationGlassIntensity * (1 - navigationGlassIntensity) * 0.5;
    const foregroundChannel = navigationGlassIntensity < 0.5 ? 0 : 255;
    root.classList.add('faceauth-navigation-glass-intensity');
    root.style.setProperty('--faceauth-glass-foreground', `rgb(${foregroundChannel}, ${foregroundChannel}, ${foregroundChannel})`);
    root.style.setProperty('--faceauth-nav-glass-light-opacity', String(opacityCurve * 0.94));
    root.style.setProperty('--faceauth-nav-glass-dark-opacity', String(opacityCurve * 0.96));
    window.dispatchEvent(new CustomEvent('faceauth-navigation-glass-intensity-change', {
      detail: { intensity: navigationGlassIntensity }
    }));

  };

  window.faceAuthNavigationGlass = Object.freeze({
    get intensity() {
      return navigationGlassIntensity;
    },
    setIntensity(intensity) {
      setNavigationGlassIntensity(intensity);
    }
  });

  applyMode(mode);
  setUltraSmoothScrolling(ultraSmoothScrolling, false);
  setMotionBlurEnabled(motionBlurEnabled, false);
  setLiquidGlassEnabled(liquidGlassEnabled, false);
  setNavigationGlassIntensity(navigationGlassIntensity);
})();