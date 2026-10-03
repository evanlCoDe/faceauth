(() => {
  'use strict';

  const userAgent = navigator.userAgent;
  const isSafari = /Safari/i.test(userAgent)
    && !/(Chrome|Chromium|CriOS|Edg\/|EdgiOS|OPR|OPiOS|Opera|FxiOS|Firefox)/i.test(userAgent);
  const isMobileSafari = isSafari && (
    /iPhone|iPad/i.test(userAgent)
    || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)
  );
  const isMobileOrTablet = /Android|iPhone|iPad|iPod|Tablet|PlayBook|Silk|Kindle|Mobile|Windows Phone|IEMobile|BlackBerry/i.test(userAgent)
    || navigator.userAgentData?.mobile === true
    || navigator.userAgentData?.formFactors?.includes('Tablet')
    || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  if (isSafari) document.documentElement.classList.add('faceauth-safari-glass');
  if (isMobileSafari) document.documentElement.classList.add('faceauth-ios-safari');
  if (isMobileOrTablet) document.documentElement.classList.add('faceauth-mobile-device');

  const SWITCHER_CONFIG = Object.freeze({
    glassThickness: 30,
    bezelWidth: 40,
    ior: 1.4,
    scaleRatio: 1,
    blur: 0,
    specularOpacity: 0.5,
    specularSat: 0,
    tintColor: '255,255,255',
    tintOpacity: 0,
    innerShadow: 'rgba(255,255,255,0)',
    innerShadowBlur: 0,
    innerShadowSpread: 0,
    balancedSpecular: true
  });
  const ACTIVE_BUBBLE_CONFIG = Object.freeze({
    ...SWITCHER_CONFIG,
    tintColor: '0,128,255',
    tintOpacity: 0.14,
    innerShadow: 'rgba(0,128,255,0.2)',
    innerShadowBlur: 2
  });

  const targets = new Map();
  let defs;

  window.addEventListener('faceauth-liquid-glass-change', () => {
    targets.forEach((target) => target.rebuild());
  });
  window.addEventListener('faceauth-navigation-glass-strength-change', () => {
    targets.forEach((target) => target.updateConfig());
  });

  const clamp = (value, min, max) => Math.min(max, Math.max(min, value));

  function navigationGlassConfig() {
    const intensity = clamp(window.faceAuthNavigationGlass?.intensity ?? 0.25, 0, 1);
    return {
      ...SWITCHER_CONFIG,
      scaleRatio: (0.45 + intensity * 0.55) * 5,
      blur: intensity * 2.6,
      specularOpacity: 0.36 + intensity * 0.34,
      tintOpacity: intensity * 0.04,
      innerShadow: 'rgba(255,255,255,0.22)',
      innerShadowBlur: 0.5 + intensity * 1.5
    };
  }

  function withGlassStrength(config) {
    const strength = clamp(window.faceAuthNavigationGlass?.strength ?? 1, 0, 1);
    const edgeStrength = 0.25 + strength * 1.5;
    return {
      ...config,
      scaleRatio: config.scaleRatio * (0.2 + strength * 2.3),
      specularOpacity: clamp(config.specularOpacity * (0.2 + strength * 1.2), 0, 1),
      specularSat: clamp(config.specularSat + strength * 0.55, 0, 1),
      tintOpacity: config.tintOpacity * (1.15 - strength * 0.9),
      innerShadowBlur: config.innerShadowBlur * edgeStrength,
      innerShadowSpread: config.innerShadowSpread * edgeStrength
    };
  }

  function surfaceFn(x) {
    return Math.pow(1 - Math.pow(1 - x, 4), 0.25);
  }

  function calcRefractionProfile(glassThickness, bezelWidth, ior, samples = 128) {
    const eta = 1 / ior;
    const profile = new Float64Array(samples);

    function refract(nx, ny) {
      const dot = ny;
      const k = 1 - eta * eta * (1 - dot * dot);
      if (k < 0) return null;
      const root = Math.sqrt(k);
      return [-(eta * dot + root) * nx, eta - (eta * dot + root) * ny];
    }

    for (let index = 0; index < samples; index += 1) {
      const x = index / samples;
      const y = surfaceFn(x);
      const delta = x < 1 ? 0.0001 : -0.0001;
      const derivative = (surfaceFn(x + delta) - y) / delta;
      const magnitude = Math.sqrt(derivative * derivative + 1);
      const refracted = refract(-derivative / magnitude, -1 / magnitude);
      profile[index] = refracted ? refracted[0] * ((y * bezelWidth + glassThickness) / refracted[1]) : 0;
    }

    return profile;
  }

  function generateDisplacementMap(width, height, radius, bezelWidth, profile, maxDisplacement) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const context = canvas.getContext('2d');
    if (!context) return '';

    const image = context.createImageData(width, height);
    const pixels = image.data;
    for (let index = 0; index < pixels.length; index += 4) {
      pixels[index] = 128;
      pixels[index + 1] = 128;
      pixels[index + 2] = 0;
      pixels[index + 3] = 255;
    }

    const radiusSquared = radius * radius;
    const outerRadiusSquared = (radius + 1) ** 2;
    const innerRadiusSquared = Math.max(radius - bezelWidth, 0) ** 2;
    const widthBody = width - radius * 2;
    const heightBody = height - radius * 2;
    const sampleCount = profile.length;

    for (let y1 = 0; y1 < height; y1 += 1) {
      for (let x1 = 0; x1 < width; x1 += 1) {
        const x = x1 < radius ? x1 - radius : x1 >= width - radius ? x1 - radius - widthBody : 0;
        const y = y1 < radius ? y1 - radius : y1 >= height - radius ? y1 - radius - heightBody : 0;
        const distanceSquared = x * x + y * y;
        if (distanceSquared > outerRadiusSquared || distanceSquared < innerRadiusSquared) continue;

        const distance = Math.sqrt(distanceSquared);
        if (distance === 0) continue;
        const fromSide = radius - distance;
        const opacity = distanceSquared < radiusSquared
          ? 1
          : 1 - (distance - Math.sqrt(radiusSquared)) / (Math.sqrt(outerRadiusSquared) - Math.sqrt(radiusSquared));
        if (opacity <= 0) continue;

        const sample = Math.min(((fromSide / bezelWidth) * sampleCount) | 0, sampleCount - 1);
        const displacement = profile[sample] || 0;
        const offsetX = (-x / distance * displacement) / maxDisplacement;
        const offsetY = (-y / distance * displacement) / maxDisplacement;
        const pixelIndex = (y1 * width + x1) * 4;
        pixels[pixelIndex] = 128 + offsetX * 127 * opacity;
        pixels[pixelIndex + 1] = 128 + offsetY * 127 * opacity;
      }
    }

    context.putImageData(image, 0, 0);
    return canvas.toDataURL();
  }

  function generateSpecularMap(width, height, radius, bezelWidth, balanced) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const context = canvas.getContext('2d');
    if (!context) return '';

    const image = context.createImageData(width, height);
    const pixels = image.data;
    const angle = Math.PI / 3;
    const radiusSquared = radius * radius;
    const outerRadiusSquared = (radius + 1) ** 2;
    const innerRadiusSquared = Math.max(radius - bezelWidth, 0) ** 2;
    const widthBody = width - radius * 2;
    const heightBody = height - radius * 2;
    const lightVectorX = Math.cos(angle);
    const lightVectorY = Math.sin(angle);

    for (let y1 = 0; y1 < height; y1 += 1) {
      for (let x1 = 0; x1 < width; x1 += 1) {
        const x = x1 < radius ? x1 - radius : x1 >= width - radius ? x1 - radius - widthBody : 0;
        const y = y1 < radius ? y1 - radius : y1 >= height - radius ? y1 - radius - heightBody : 0;
        const distanceSquared = x * x + y * y;
        if (distanceSquared > outerRadiusSquared || distanceSquared < innerRadiusSquared) continue;

        const distance = Math.sqrt(distanceSquared);
        if (distance === 0) continue;
        const fromSide = radius - distance;
        const opacity = distanceSquared < radiusSquared
          ? 1
          : 1 - (distance - Math.sqrt(radiusSquared)) / (Math.sqrt(outerRadiusSquared) - Math.sqrt(radiusSquared));
        if (opacity <= 0) continue;

        const normalX = x / distance;
        const normalY = -y / distance;
        const dot = balanced ? 1 : Math.abs(normalX * lightVectorX + normalY * lightVectorY);
        const edge = Math.sqrt(Math.max(0, 1 - (1 - fromSide) ** 2));
        const coefficient = dot * edge;
        const color = (255 * coefficient) | 0;
        const pixelIndex = (y1 * width + x1) * 4;
        pixels[pixelIndex] = color;
        pixels[pixelIndex + 1] = color;
        pixels[pixelIndex + 2] = color;
        pixels[pixelIndex + 3] = (color * coefficient * opacity) | 0;
      }
    }

    context.putImageData(image, 0, 0);
    return canvas.toDataURL();
  }

  function svgElement(tag, attributes) {
    const element = document.createElementNS('http://www.w3.org/2000/svg', tag);
    Object.entries(attributes).forEach(([key, value]) => element.setAttribute(key, value));
    return element;
  }

  function ensureDefs() {
    const existing = document.getElementById('faceauth-liquid-glass-defs');
    if (existing && document.documentElement.contains(existing)) {
      defs = existing;
      return;
    }

    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('width', '0');
    svg.setAttribute('height', '0');
    svg.style.cssText = 'position:fixed;top:0;left:0;width:0;height:0;pointer-events:none;z-index:-1;';
    defs = svgElement('defs', { id: 'faceauth-liquid-glass-defs' });
    svg.appendChild(defs);
    document.documentElement.appendChild(svg);
  }

  function buildFilter(id, width, height, radius, config) {
    const bezel = Math.max(0, Math.min(config.bezelWidth, radius - 1, Math.min(width, height) / 2 - 1));
    const profile = calcRefractionProfile(config.glassThickness, bezel, config.ior);
    const maxDisplacement = Math.max(...Array.from(profile).map(Math.abs)) || 1;
    const displacementUrl = generateDisplacementMap(width, height, radius, bezel, profile, maxDisplacement);
    const specularUrl = generateSpecularMap(width, height, radius, bezel * 2.5, config.balancedSpecular);
    const scale = maxDisplacement * config.scaleRatio;
    const padding = config.balancedSpecular ? 0.36 : 0;
    const x = Math.round(-width * padding);
    const y = Math.round(-height * padding);
    const filter = svgElement('filter', {
      id,
      x: String(x),
      y: String(y),
      width: String(Math.round(width * (1 + padding * 2))),
      height: String(Math.round(height * (1 + padding * 2))),
      filterUnits: 'userSpaceOnUse',
      primitiveUnits: 'userSpaceOnUse',
      'color-interpolation-filters': 'sRGB'
    });
    filter.dataset.maxDisplacement = String(maxDisplacement);

    const blur = svgElement('feGaussianBlur', { in: 'SourceGraphic', stdDeviation: config.blur, result: 'blurred' });
    const displacementImage = svgElement('feImage', { href: displacementUrl, x: 0, y: 0, width, height, result: 'displacement-map' });
    const displacement = svgElement('feDisplacementMap', {
      in: 'blurred',
      in2: 'displacement-map',
      scale,
      xChannelSelector: 'R',
      yChannelSelector: 'G',
      result: 'refracted'
    });
    const saturation = svgElement('feColorMatrix', {
      in: 'refracted',
      type: 'saturate',
      values: config.specularSat,
      result: 'refracted-saturation'
    });
    const specularImage = svgElement('feImage', { href: specularUrl, x: 0, y: 0, width, height, result: 'specular-map' });
    const composite = svgElement('feComposite', {
      in: 'refracted-saturation',
      in2: 'specular-map',
      operator: 'in',
      result: 'specular-mask'
    });
    const transfer = svgElement('feComponentTransfer', { in: 'specular-map', result: 'faded-specular' });
    transfer.appendChild(svgElement('feFuncA', { type: 'linear', slope: config.specularOpacity }));
    const blendSaturation = svgElement('feBlend', { in: 'specular-mask', in2: 'refracted', mode: 'normal', result: 'glass-surface' });
    const blendSpecular = svgElement('feBlend', { in: 'faded-specular', in2: 'glass-surface', mode: 'normal' });

    [blur, displacementImage, displacement, saturation, specularImage, composite, transfer, blendSaturation, blendSpecular]
      .forEach((primitive) => filter.appendChild(primitive));
    return filter;
  }

  function applyGlass(element, configGetter) {
    if (targets.has(element)) return;
    if (getComputedStyle(element).position === 'static') element.style.position = 'relative';

    const refractiveLayer = document.createElement('div');
    refractiveLayer.className = 'lg-layer lg-refract';
    const tintLayer = document.createElement('div');
    tintLayer.className = 'lg-layer lg-tint';
    element.insertBefore(tintLayer, element.firstChild);
    element.insertBefore(refractiveLayer, element.firstChild);

    let filterNode = null;
    let timer = null;

    function elevateContent() {
      Array.from(element.children).forEach((child) => {
        if (child === refractiveLayer || child === tintLayer) return;
        if (getComputedStyle(child).position === 'static') child.style.position = 'relative';
        if (!child.style.zIndex) child.style.zIndex = '1';
      });
    }

    function rebuild() {
      const isIntensityControlledNavigation = element.matches('#faceauth-site-nav .nav-inner');
      if (document.documentElement.classList.contains('liquid-glass-disabled') && !isIntensityControlledNavigation) {
        if (filterNode) filterNode.remove();
        filterNode = null;
        refractiveLayer.style.removeProperty('backdrop-filter');
        refractiveLayer.style.removeProperty('-webkit-backdrop-filter');
        return;
      }

      if (!isSafari) ensureDefs();
      const rect = element.getBoundingClientRect();
      const width = Math.round(element.offsetWidth || rect.width);
      const height = Math.round(element.offsetHeight || rect.height);
      if (width < 4 || height < 4) return;

      const config = withGlassStrength(configGetter());
      const dataRadius = parseFloat(element.getAttribute('data-radius') || '0');
      const cssRadius = parseFloat(getComputedStyle(element).borderTopLeftRadius || '0');
      const radius = Math.max(2, Math.min(dataRadius || cssRadius || 24, width / 2, height / 2));
      if (isSafari) {
        if (filterNode) filterNode.remove();
        filterNode = null;
        refractiveLayer.style.removeProperty('backdrop-filter');
        refractiveLayer.style.removeProperty('-webkit-backdrop-filter');
      } else {
        if (filterNode) filterNode.remove();

        const id = `faceauth-liquid-${Math.random().toString(36).slice(2, 10)}`;
        filterNode = buildFilter(id, width, height, radius, config);
        if (filterNode.querySelector('feImage')?.getAttribute('href')) {
          defs.appendChild(filterNode);
          refractiveLayer.style.backdropFilter = `url(#${id})`;
          refractiveLayer.style.webkitBackdropFilter = `url(#${id})`;
        }
      }

      refractiveLayer.style.borderRadius = `${radius}px`;
      tintLayer.style.borderRadius = `${radius}px`;
      tintLayer.style.backgroundColor = `rgba(${config.tintColor},${config.tintOpacity})`;
      tintLayer.style.boxShadow = `inset 0 0 ${config.innerShadowBlur}px ${config.innerShadowSpread}px ${config.innerShadow}`;
      elevateContent();
    }

    function updateConfig(config = configGetter()) {
      config = withGlassStrength(config);
      if (filterNode) {
        const blur = filterNode.querySelector('feGaussianBlur');
        const displacement = filterNode.querySelector('feDisplacementMap');
        const specularAlpha = filterNode.querySelector('feFuncA');
        const saturation = filterNode.querySelector('feColorMatrix');
        const maxDisplacement = Number(filterNode.dataset.maxDisplacement) || 0;
        blur?.setAttribute('stdDeviation', String(config.blur));
        displacement?.setAttribute('scale', String(maxDisplacement * config.scaleRatio));
        specularAlpha?.setAttribute('slope', String(config.specularOpacity));
        saturation?.setAttribute('values', String(config.specularSat));
      }
      tintLayer.style.backgroundColor = `rgba(${config.tintColor},${config.tintOpacity})`;
      tintLayer.style.boxShadow = `inset 0 0 ${config.innerShadowBlur}px ${config.innerShadowSpread}px ${config.innerShadow}`;
    }

    function scheduleRebuild() {
      clearTimeout(timer);
      timer = setTimeout(rebuild, 16);
    }

    const resizeObserver = new ResizeObserver(scheduleRebuild);
    resizeObserver.observe(element);
    const instance = {
      rebuild,
      updateConfig,
      destroy() {
        clearTimeout(timer);
        resizeObserver.disconnect();
        if (filterNode) filterNode.remove();
        refractiveLayer.remove();
        tintLayer.remove();
      }
    };
    targets.set(element, instance);
    rebuild();
  }

  function injectSharedNavigation() {
    const oldNavs = Array.from(document.querySelectorAll('nav'));
    const nav = document.querySelector('body > nav') || document.createElement('nav');
    oldNavs.forEach((oldNav) => {
      if (oldNav !== nav) oldNav.remove();
    });

    nav.id = 'faceauth-site-nav';
    nav.setAttribute('aria-label', 'Primary navigation');
    nav.innerHTML = `
      <div class="nav-inner" data-radius="24">
        <div class="glass-indicator" data-radius="16" aria-hidden="true"></div>
        <div class="nav-actions">
          <div class="nav-links">
            <a class="glass-nav-link" data-nav="home" href="index.html#top"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3.5 10.5 12 3l8.5 7.5v8.2a1.8 1.8 0 0 1-1.8 1.8H5.3a1.8 1.8 0 0 1-1.8-1.8v-8.2Z"/><path d="M9 20.5v-6h6v6"/></svg><span>Home</span></a>
            <a class="glass-nav-link" data-nav="design" href="index.html#design"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m12 3 8 4.5v9L12 21l-8-4.5v-9L12 3Z"/><path d="m4 7.5 8 4.5 8-4.5M12 12v9"/></svg><span>Design</span></a>
            <a class="glass-nav-link" data-nav="security" href="index.html#security"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3 20 6v5.5c0 4.5-3.2 7.7-8 9.5-4.8-1.8-8-5-8-9.5V6l8-3Z"/><path d="m8.5 12 2.2 2.2 4.8-4.8"/></svg><span>Security</span></a>
            <a class="glass-nav-link" data-nav="support" href="index.html#support"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20.5 11.5a8.5 8.5 0 0 1-12.8 7.3L3.5 20l1.2-4.1a8.5 8.5 0 1 1 15.8-4.4Z"/><path d="M9.7 9.2a2.3 2.3 0 0 1 4.5.7c0 1.7-2.2 1.9-2.2 3.4m0 2.2h.01"/></svg><span>Support</span></a>
            <a class="glass-nav-link" data-nav="faq" href="faq.html"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="8.5"/><path d="M9.3 9.2c.2-1.4 1.3-2.3 2.8-2.3 1.7 0 2.9 1 2.9 2.5 0 1.3-.7 2.1-1.8 2.8-.9.6-1.3 1.1-1.3 2.2"/><circle cx="12" cy="17.7" r=".8" fill="currentColor" stroke="none"/></svg><span>FAQ</span></a>
          </div>
        </div>
      </div>`;
    if (!nav.isConnected) document.body.insertAdjacentElement('afterbegin', nav);
    document.body.classList.add('faceauth-nav-enabled');

    return nav;
  }

  function injectSettingsButton() {
    const button = document.createElement('button');
    const popup = document.createElement('div');
    button.type = 'button';
    button.className = 'faceauth-settings-button';
    button.dataset.radius = '999';
    button.setAttribute('aria-label', 'Settings');
    button.setAttribute('aria-controls', 'faceauth-settings-popup');
    button.setAttribute('aria-expanded', 'false');
    button.innerHTML = `
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M10 2.75h4l.55 2.35a7.7 7.7 0 0 1 1.7.98l2.2-.99 2 3.46-1.65 1.8a7.5 7.5 0 0 1 0 2.1l1.65 1.8-2 3.46-2.2-.99a7.7 7.7 0 0 1-1.7.98L14 20.05h-4l-.55-2.35a7.7 7.7 0 0 1-1.7-.98l-2.2.99-2-3.46 1.65-1.8a7.5 7.5 0 0 1 0-2.1l-1.65-1.8 2-3.46 2.2.99a7.7 7.7 0 0 1 1.7-.98L10 2.75Z" />
        <circle cx="12" cy="11.4" r="2.65" />
      </svg>`;
    popup.id = 'faceauth-settings-popup';
    popup.className = 'faceauth-settings-popup';
    popup.dataset.radius = '18';
    popup.setAttribute('role', 'dialog');
    popup.setAttribute('aria-label', 'Settings');
    popup.setAttribute('aria-hidden', 'true');
    const controls = document.createElement('div');
    controls.className = 'assistant-window-controls';
    controls.setAttribute('role', 'group');
    controls.setAttribute('aria-label', 'Settings window controls');
    controls.innerHTML = '<button class="assistant-window-control assistant-window-control-close" type="button" aria-label="Close Settings"></button>';
    const [redButton] = controls.children;
    popup.append(controls);
    document.body.insertAdjacentElement('afterbegin', button);
    document.body.insertAdjacentElement('afterbegin', popup);
    const closeWindow = (returnFocus = false) => {
      popup.classList.remove('is-open');
      button.setAttribute('aria-expanded', 'false');
      popup.setAttribute('aria-hidden', 'true');
      if (returnFocus) button.focus();
    };
    button.addEventListener('click', () => {
      const isOpen = popup.classList.toggle('is-open');
      button.setAttribute('aria-expanded', String(isOpen));
      popup.setAttribute('aria-hidden', String(!isOpen));
      if (isOpen) popup.dispatchEvent(new Event('faceauth-settings-open'));
    });
    redButton.addEventListener('click', () => closeWindow(true));
    document.addEventListener('click', (event) => {
      if (!popup.classList.contains('is-open') || popup.contains(event.target) || button.contains(event.target)) return;
      closeWindow();
    });
    document.addEventListener('keydown', (event) => {
      if (event.key !== 'Escape' || !popup.classList.contains('is-open')) return;
      closeWindow(true);
    });
    applyGlass(button, navigationGlassConfig);
    applyGlass(popup, navigationGlassConfig);
    window.addEventListener('faceauth-navigation-glass-intensity-change', () => {
      const config = navigationGlassConfig();
      targets.get(button)?.updateConfig(config);
      targets.get(popup)?.updateConfig(config);
    });
    popup.addEventListener('faceauth-settings-open', () => {
      if (!popup.querySelector('.lg-refract')?.style.backdropFilter) targets.get(popup)?.rebuild();
    });
  }

  function injectCompatibilityButton() {
    const button = document.createElement('button');
    const popup = document.createElement('div');
    button.type = 'button';
    button.className = 'faceauth-settings-button faceauth-compatibility-button';
    button.dataset.radius = '999';
    button.setAttribute('aria-label', 'Check Compatibility');
    button.setAttribute('aria-controls', 'faceauth-compatibility-popup');
    button.setAttribute('aria-expanded', 'false');
    button.innerHTML = `
      <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <path d="M3 12h4l2-6 4 12 2-6h6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
      </svg>`;
    popup.id = 'faceauth-compatibility-popup';
    popup.className = 'faceauth-settings-popup faceauth-compatibility-popup';
    popup.dataset.radius = '18';
    popup.setAttribute('role', 'dialog');
    popup.setAttribute('aria-label', 'Check Compatibility');
    popup.setAttribute('aria-hidden', 'true');
    popup.innerHTML = `
      <div class="faceauth-compatibility-content">
        <div class="faceauth-compatibility-heading">
          <h2>Check Compatibility</h2>
        </div>
        <p class="faceauth-compatibility-checking" role="status" aria-live="polite">Checking your Mac…</p>
        <div class="faceauth-compatibility-results" aria-live="polite">
          <p><span class="faceauth-compatibility-symbol" aria-hidden="true">✓</span>macOS detected</p>
          <p><span class="faceauth-compatibility-symbol" aria-hidden="true">⚠</span>macOS version unavailable</p>
        </div>
        <section class="faceauth-compatibility-requirements" aria-labelledby="faceauth-compatibility-requirements-title">
          <h3 id="faceauth-compatibility-requirements-title">System requirements</h3>
          <ul>
            <li>macOS 15 Sequoia or later</li>
            <li>Apple silicon or Intel Mac</li>
            <li>Built-in or external camera</li>
            <li>FaceAuth app installed</li>
            <li>Not available for Windows</li>
          </ul>
        </section>
      </div>`;
    const controls = document.createElement('div');
    controls.className = 'assistant-window-controls';
    controls.setAttribute('role', 'group');
    controls.setAttribute('aria-label', 'Check Compatibility window controls');
    controls.innerHTML = '<button class="assistant-window-control assistant-window-control-close" type="button" aria-label="Close Check Compatibility"></button>';
    const [redButton] = controls.children;
    popup.append(controls);
    const settingsButton = document.querySelector('.faceauth-settings-button:not(.faceauth-compatibility-button)');
    if (settingsButton) {
      settingsButton.insertAdjacentElement('afterend', button);
    } else {
      document.body.insertAdjacentElement('afterbegin', button);
    }
    document.body.insertAdjacentElement('afterbegin', popup);

    const checking = popup.querySelector('.faceauth-compatibility-checking');
    const results = popup.querySelector('.faceauth-compatibility-results');
    let checkRequestId = 0;

    function detectMacPlatform() {
      const hintedPlatform = navigator.userAgentData?.platform;
      if (hintedPlatform) return /^macOS$/i.test(hintedPlatform);

      const isIPad = navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1;
      return !isIPad && (
        /^Mac/i.test(navigator.platform)
        || /Macintosh|Mac OS X/i.test(navigator.userAgent)
      );
    }

    async function detectMacVersion() {
      if (typeof navigator.userAgentData?.getHighEntropyValues !== 'function') return null;
      try {
        const { platformVersion } = await navigator.userAgentData.getHighEntropyValues(['platformVersion']);
        if (typeof platformVersion !== 'string' || !/^\d+(?:\.\d+){0,2}$/.test(platformVersion)) return null;
        return {
          version: platformVersion,
          compatible: Number(platformVersion.split('.')[0]) >= 15
        };
      } catch {
        return null;
      }
    }

    function addResult(symbol, message, className = '') {
      const row = document.createElement('p');
      row.className = className;
      const indicator = document.createElement('span');
      indicator.className = 'faceauth-compatibility-symbol';
      indicator.setAttribute('aria-hidden', 'true');
      indicator.textContent = symbol;
      row.append(indicator, document.createTextNode(message));
      results.appendChild(row);
    }

    function showLoadingSpinner() {
      const spinner = document.createElement('span');
      spinner.className = 'faceauth-compatibility-spinner';
      spinner.setAttribute('role', 'status');
      spinner.setAttribute('aria-label', 'Checking compatibility');
      results.replaceChildren(spinner);
      results.hidden = false;
    }

    async function runCompatibilityCheck(requestId) {
      await new Promise((resolve) => window.setTimeout(resolve, 2000));
      if (requestId !== checkRequestId || !popup.classList.contains('is-open')) return;

      results.replaceChildren();
      const isMac = detectMacPlatform();
      let isSupportedMac = false;
      if (!isMac) {
        addResult('✕', 'macOS detected');
        addResult('⚠', 'macOS version unavailable');
      } else {
        addResult('✓', 'macOS detected');
        const detectedVersion = await detectMacVersion();
        if (requestId !== checkRequestId || !popup.classList.contains('is-open')) return;
        if (!detectedVersion) {
          addResult('⚠', 'macOS version unavailable');
        } else if (detectedVersion.compatible) {
          addResult('✓', 'macOS version compatible');
          addResult('✓', 'Ready To Install', 'faceauth-compatibility-ready');
          isSupportedMac = true;
        } else {
          addResult('✕', 'macOS version not compatible');
        }
      }

      if (!isSupportedMac) {
        const note = document.createElement('p');
        note.className = 'faceauth-compatibility-note faceauth-compatibility-unavailable';
        note.textContent = 'FaceAuth is not available on this device.';
        results.appendChild(note);
      }

      checking.hidden = true;
      results.hidden = false;
    }

    function closePopup(returnFocus = false) {
      popup.classList.remove('is-open');
      button.setAttribute('aria-expanded', 'false');
      popup.setAttribute('aria-hidden', 'true');
      checkRequestId += 1;
      if (returnFocus) button.focus();
    }

    button.addEventListener('click', () => {
      const isOpen = popup.classList.toggle('is-open');
      button.setAttribute('aria-expanded', String(isOpen));
      popup.setAttribute('aria-hidden', String(!isOpen));
      if (!isOpen) {
        checkRequestId += 1;
        return;
      }
      checkRequestId += 1;
      checking.hidden = false;
      showLoadingSpinner();
      runCompatibilityCheck(checkRequestId);
    });
    redButton.addEventListener('click', () => closePopup(true));
    document.addEventListener('click', (event) => {
      if (!popup.classList.contains('is-open') || popup.contains(event.target) || button.contains(event.target)) return;
      closePopup();
    });
    document.addEventListener('keydown', (event) => {
      if (event.key !== 'Escape' || !popup.classList.contains('is-open')) return;
      checkRequestId += 1;
      closePopup(true);
    });

    applyGlass(button, navigationGlassConfig);
    applyGlass(popup, navigationGlassConfig);
    window.addEventListener('faceauth-navigation-glass-intensity-change', () => {
      const config = navigationGlassConfig();
      targets.get(button)?.updateConfig(config);
      targets.get(popup)?.updateConfig(config);
    });
  }

  function initializeNavigation(nav) {
    const surface = nav.querySelector('.nav-inner');
    const indicator = nav.querySelector('.glass-indicator');
    const links = Array.from(nav.querySelectorAll('.glass-nav-link'));
    const pathParts = location.pathname.split('/').filter(Boolean);
    const pageName = location.pathname.endsWith('/') ? 'index.html' : pathParts.pop()?.toLowerCase() || 'index.html';

    function currentItem() {
      if (pageName === 'faq.html') return 'faq';
      if (pageName === '' || pageName === 'index.html') {
        const currentHash = decodeURIComponent(location.hash.slice(1));
        if (['design', 'security', 'support'].includes(currentHash)) return currentHash;
        return 'home';
      }
      return 'home';
    }

    let selected = currentItem();
    let focusedTarget = null;
    let alignmentObserver;
    let pointerId = null;
    let pressX = 0;
    let pressY = 0;
    let pressWidth = 0;
    let dragTarget = null;
    let isDragging = false;
    let suppressClick = false;
    let glassRebuildQueued = false;
    let scrollUpdateQueued = false;
    let indicatorAnimationFrame = 0;
    let indicatorAnimationTime = 0;
    let indicatorTargetLeft = 0;
    let indicatorTargetWidth = 0;
    let pendingScrollDestination = null;
    let scrollDestinationTimer = 0;

    function setActiveLink(link, ariaCurrent = 'page') {
      if (!link) return;
      links.forEach((item) => {
        const isCurrent = item === link;
        item.classList.toggle('is-active', isCurrent);
        if (isCurrent) item.setAttribute('aria-current', ariaCurrent);
        else item.removeAttribute('aria-current');
      });
    }

    function updateCurrentState() {
      cancelPendingScrollDestination();
      selected = currentItem();
      const currentHash = decodeURIComponent(location.hash.slice(1));
      const currentLink = links.find((link) => link.dataset.nav === selected);
      setActiveLink(currentLink, ['design', 'security', 'support'].includes(currentHash) ? 'location' : 'page');
      moveIndicator(focusedTarget || links.find((link) => link.dataset.nav === selected), true);
    }

    function stopIndicatorAnimation() {
      if (indicatorAnimationFrame) cancelAnimationFrame(indicatorAnimationFrame);
      indicatorAnimationFrame = 0;
      indicatorAnimationTime = 0;
      surface.classList.remove('is-scroll-following');
    }

    function moveIndicator(link, immediate = false) {
      stopIndicatorAnimation();
      if (!link) {
        indicator.style.opacity = '0';
        return;
      }

      const surfaceRect = surface.getBoundingClientRect();
      const linkRect = link.getBoundingClientRect();
      const left = linkRect.left - surfaceRect.left - parseFloat(getComputedStyle(surface).borderLeftWidth || '0');
      indicator.style.opacity = '1';
      if (immediate) {
        indicator.style.transition = 'none';
        indicator.style.left = `${left}px`;
        indicator.style.width = `${linkRect.width}px`;
        indicator.offsetWidth;
        indicator.style.transition = '';
      } else {
        indicator.style.left = `${left}px`;
        indicator.style.width = `${linkRect.width}px`;
      }
      targets.get(indicator)?.rebuild();
    }

    function animateScrollIndicator(link) {
      if (!link) return;
      const target = itemMetrics(link);
      indicatorTargetLeft = target.left;
      indicatorTargetWidth = target.width;
      indicator.style.opacity = '1';

      if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
        stopIndicatorAnimation();
        indicator.style.left = `${target.left}px`;
        indicator.style.width = `${target.width}px`;
        targets.get(indicator)?.rebuild();
        return;
      }

      surface.classList.add('is-scroll-following');
      if (indicatorAnimationFrame) return;

      indicatorAnimationTime = performance.now();
      function animateFrame(timestamp) {
        const elapsed = Math.min(32, Math.max(1, timestamp - indicatorAnimationTime));
        indicatorAnimationTime = timestamp;
        const easing = 1 - Math.exp(-elapsed / 72);
        const currentLeft = parseFloat(indicator.style.left) || 0;
        const currentWidth = parseFloat(indicator.style.width) || indicatorTargetWidth;
        const left = currentLeft + (indicatorTargetLeft - currentLeft) * easing;
        const width = currentWidth + (indicatorTargetWidth - currentWidth) * easing;
        indicator.style.left = `${left}px`;
        indicator.style.width = `${width}px`;

        if (Math.abs(indicatorTargetLeft - left) < 0.3 && Math.abs(indicatorTargetWidth - width) < 0.3) {
          indicator.style.left = `${indicatorTargetLeft}px`;
          indicator.style.width = `${indicatorTargetWidth}px`;
          indicatorAnimationFrame = 0;
          indicatorAnimationTime = 0;
          surface.classList.remove('is-scroll-following');
          targets.get(indicator)?.rebuild();
          return;
        }

        indicatorAnimationFrame = requestAnimationFrame(animateFrame);
      }

      indicatorAnimationFrame = requestAnimationFrame(animateFrame);
    }

    function itemMetrics(link) {
      const surfaceRect = surface.getBoundingClientRect();
      const linkRect = link.getBoundingClientRect();
      return {
        left: linkRect.left - surfaceRect.left - parseFloat(getComputedStyle(surface).borderLeftWidth || '0'),
        width: linkRect.width,
        center: linkRect.left - surfaceRect.left + linkRect.width / 2
      };
    }

    function nearestLink(clientX) {
      const surfaceRect = surface.getBoundingClientRect();
      const localX = clientX - surfaceRect.left;
      return links.reduce((nearest, link) => {
        if (!nearest) return link;
        return Math.abs(itemMetrics(link).center - localX) < Math.abs(itemMetrics(nearest).center - localX) ? link : nearest;
      }, null);
    }

    function queueGlassRebuild() {
      if (glassRebuildQueued) return;
      glassRebuildQueued = true;
      requestAnimationFrame(() => {
        glassRebuildQueued = false;
        targets.get(indicator)?.rebuild();
      });
    }

    function dragIndicator(clientX) {
      const surfaceRect = surface.getBoundingClientRect();
      const width = pressWidth || itemMetrics(dragTarget || links[0]).width;
      const localX = clientX - surfaceRect.left;
      const min = 0;
      const max = Math.max(min, surface.clientWidth - width);
      const left = clamp(localX - width / 2, min, max);
      indicator.style.left = `${left}px`;
      indicator.style.width = `${width}px`;
      const bubbleCenter = surfaceRect.left + left + width / 2;
      const nextTarget = nearestLink(bubbleCenter);
      if (nextTarget !== dragTarget) {
        dragTarget = nextTarget;
        setActiveLink(dragTarget);
      }
      queueGlassRebuild();
    }

    function activate(link) {
      stopIndicatorAnimation();
      selected = link.dataset.nav;
      setActiveLink(link);
      moveIndicator(link);
    }

    function positionForUrl(url) {
      const targetId = decodeURIComponent(url.hash.slice(1));
      const textTargets = {
        design: '[data-design-target]',
        security: '[data-security-target]'
      };
      return document.querySelector(textTargets[targetId]) || document.getElementById(targetId);
    }

    const scrollSections = pageName === 'index.html'
      ? links
        .filter((link) => link.dataset.nav !== 'faq')
        .map((link) => ({ link, target: positionForUrl(new URL(link.href, location.href)) }))
        .filter((section) => section.target)
        .sort((first, second) => first.target.compareDocumentPosition(second.target) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1)
      : [];

    function updateActiveSectionFromScroll() {
      if (!scrollSections.length || pendingScrollDestination || isDragging || pointerId !== null) return;

      const scrollLine = window.scrollY + window.innerHeight * 0.42;
      const hysteresis = Math.min(48, window.innerHeight * 0.06);
      const positions = scrollSections.map((section) => section.target.getBoundingClientRect().top + window.scrollY);
      const isAtBottom = window.scrollY + window.innerHeight >= document.documentElement.scrollHeight - 2;
      let candidateIndex = isAtBottom ? scrollSections.length - 1 : 0;
      if (!isAtBottom) {
        positions.forEach((position, index) => {
          if (position <= scrollLine) candidateIndex = index;
        });
      }

      let activeIndex = scrollSections.findIndex((section) => section.link.dataset.nav === selected);
      if (activeIndex < 0) activeIndex = candidateIndex;
      if (candidateIndex > activeIndex) {
        while (activeIndex < candidateIndex && positions[activeIndex + 1] <= scrollLine - hysteresis) activeIndex += 1;
      } else if (candidateIndex < activeIndex) {
        while (activeIndex > candidateIndex && positions[activeIndex] > scrollLine + hysteresis) activeIndex -= 1;
      }

      const activeSection = scrollSections[activeIndex];
      if (!activeSection || activeSection.link.dataset.nav === selected) return;
      selected = activeSection.link.dataset.nav;
      focusedTarget = null;
      setActiveLink(activeSection.link, 'location');
      animateScrollIndicator(activeSection.link);
    }

    function queueScrollSectionUpdate() {
      if (scrollUpdateQueued) return;
      scrollUpdateQueued = true;
      requestAnimationFrame(() => {
        scrollUpdateQueued = false;
        updateActiveSectionFromScroll();
      });
    }

    function finishScrollToDestination() {
      if (!pendingScrollDestination) return;
      clearTimeout(scrollDestinationTimer);
      scrollDestinationTimer = 0;
      const destination = pendingScrollDestination;
      pendingScrollDestination = null;
      const link = links.find((item) => item.dataset.nav === destination);
      if (!link) return;
      selected = destination;
      focusedTarget = null;
      setActiveLink(link, 'location');
      moveIndicator(link);
    }

    function scheduleScrollDestinationFinish(delay = 160) {
      clearTimeout(scrollDestinationTimer);
      scrollDestinationTimer = window.setTimeout(finishScrollToDestination, delay);
    }

    function cancelPendingScrollDestination() {
      if (!pendingScrollDestination) return;
      pendingScrollDestination = null;
      clearTimeout(scrollDestinationTimer);
      scrollDestinationTimer = 0;
    }

    function handlePageScroll() {
      if (pendingScrollDestination) {
        scheduleScrollDestinationFinish();
        return;
      }
      queueScrollSectionUpdate();
    }

    function navigate(link, event) {
      if (event) event.preventDefault();
      activate(link);
      const url = new URL(link.href, location.href);
      if (url.pathname !== location.pathname || !url.hash) {
        location.assign(url.href);
        return;
      }
      const target = positionForUrl(url);
      if (!target) return;

      history.pushState(null, '', `${url.pathname}${url.search}${url.hash}`);
      const targetRect = target.getBoundingClientRect();
      const top = link.dataset.nav === 'home'
        ? 0
        : window.scrollY + targetRect.top - (window.innerHeight - targetRect.height) / 2;
      const behavior = matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth';
      pendingScrollDestination = link.dataset.nav;
      window.scrollTo({
        top: Math.max(0, top),
        behavior
      });
      if (behavior === 'instant') finishScrollToDestination();
      else scheduleScrollDestinationFinish(500);
    }

    surface.addEventListener('pointerdown', (event) => {
      const link = event.target.closest('.glass-nav-link');
      if (!link || !event.isPrimary || event.button !== 0 || pointerId !== null) return;
      stopIndicatorAnimation();
      event.preventDefault();
      pointerId = event.pointerId;
      pressX = event.clientX;
      pressY = event.clientY;
      pressWidth = itemMetrics(link).width;
      dragTarget = link;
      isDragging = false;
      surface.setPointerCapture?.(pointerId);
      link.classList.add('is-pressed');
      indicator.classList.add('is-pressed');
    });

    surface.addEventListener('pointermove', (event) => {
      if (event.pointerId !== pointerId) return;
      const moved = Math.hypot(event.clientX - pressX, event.clientY - pressY);
      if (!isDragging && moved > 6) {
        isDragging = true;
        surface.classList.add('is-dragging');
        indicator.classList.remove('is-pressed');
        dragTarget = null;
      }
      if (isDragging) dragIndicator(event.clientX);
    });

    function finishPointer(event, cancelled = false) {
      if (event.pointerId !== pointerId) return;
      surface.releasePointerCapture?.(pointerId);
      links.forEach((link) => link.classList.remove('is-pressed'));
      indicator.classList.remove('is-pressed');
      surface.classList.remove('is-dragging');
      if (!cancelled) {
        // Pointer down is prevented to avoid text selection. Complete both a tap
        // and a drag here, then ignore the browser's follow-up click event.
        suppressClick = true;
        const target = isDragging ? dragTarget : nearestLink(pressX);
        if (target) {
          moveIndicator(target);
          queueGlassRebuild();
          navigate(target);
        }
      } else if (isDragging) {
        const target = links.find((link) => link.dataset.nav === selected);
        if (target) {
          setActiveLink(target);
          moveIndicator(target);
          queueGlassRebuild();
        }
      }
      pointerId = null;
      isDragging = false;
      dragTarget = null;
    }

    surface.addEventListener('pointerup', (event) => finishPointer(event));
    surface.addEventListener('pointercancel', (event) => finishPointer(event, true));
    links.forEach((link) => {
      link.addEventListener('focus', () => {
        focusedTarget = link;
        moveIndicator(link, matchMedia('(prefers-reduced-motion: reduce)').matches);
      });
      link.addEventListener('blur', () => {
        requestAnimationFrame(() => {
          const activeLink = document.activeElement.closest('.glass-nav-link');
          focusedTarget = activeLink && surface.contains(activeLink) ? activeLink : null;
          moveIndicator(
            focusedTarget || links.find((item) => item.dataset.nav === selected),
            matchMedia('(prefers-reduced-motion: reduce)').matches
          );
        });
      });
    });
    surface.addEventListener('click', (event) => {
      const link = event.target.closest('.glass-nav-link');
      if (!link) return;
      if (suppressClick) {
        suppressClick = false;
        event.preventDefault();
        return;
      }
      navigate(link, event);
    });

    window.addEventListener('resize', () => moveIndicator(focusedTarget || links.find((link) => link.dataset.nav === selected), true));
    window.addEventListener('faceauth-navigation-glass-intensity-change', () => {
      targets.get(surface)?.updateConfig(navigationGlassConfig());
    });
    window.addEventListener('scroll', handlePageScroll, { passive: true });
    window.addEventListener('scrollend', finishScrollToDestination);
    window.addEventListener('wheel', cancelPendingScrollDestination, { passive: true });
    window.addEventListener('touchstart', cancelPendingScrollDestination, { passive: true });
    window.addEventListener('pointerdown', (event) => {
      if (!event.target.closest('#faceauth-site-nav')) cancelPendingScrollDestination();
    }, { passive: true });
    window.addEventListener('keydown', (event) => {
      if (['ArrowUp', 'ArrowDown', 'PageUp', 'PageDown', 'Home', 'End', ' '].includes(event.key)) {
        cancelPendingScrollDestination();
      }
    });
    window.addEventListener('popstate', updateCurrentState);
    window.addEventListener('hashchange', updateCurrentState);

    alignmentObserver = new ResizeObserver(() => {
      moveIndicator(focusedTarget || links.find((link) => link.dataset.nav === selected), true);
    });
    alignmentObserver.observe(surface);
    links.forEach((link) => alignmentObserver.observe(link));

    indicator.style.zIndex = '2';
    nav.querySelector('.nav-actions').style.zIndex = '3';
    applyGlass(surface, navigationGlassConfig);
    moveIndicator(links.find((link) => link.dataset.nav === selected), true);
    applyGlass(indicator, () => ACTIVE_BUBBLE_CONFIG);
    document.fonts?.ready.then(() => moveIndicator(links.find((link) => link.dataset.nav === selected), true));
    updateCurrentState();

    const initialHash = decodeURIComponent(location.hash.slice(1));
    if (['design', 'security', 'support'].includes(initialHash)) {
      const target = positionForUrl(new URL(location.href));
      if (target) {
        requestAnimationFrame(() => {
          const rect = target.getBoundingClientRect();
          const top = window.scrollY + rect.top - (window.innerHeight - rect.height) / 2;
          window.scrollTo({
            top: Math.max(0, top),
            behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth'
          });
        });
      }
    }
  }

  function injectSafariNotice() {
    if (!isSafari) return;

    const dismissalKey = 'faceauth-mobile-safari-notice-dismissed';
    if (isMobileSafari) {
      try {
        if (sessionStorage.getItem(dismissalKey) === 'true') return;
      } catch {}
    }

    const notice = document.createElement('aside');
    notice.className = 'faceauth-glass-notice';
    notice.dataset.radius = '24';
    notice.setAttribute('aria-label', 'Browser recommendation');
    notice.innerHTML = `
      <button class="faceauth-glass-notice-close" type="button" aria-label="Dismiss notification">×</button>
      <div class="faceauth-glass-notice-copy">
        <strong>For the best Liquid Glass experience</strong>
        <p>We recommend using Google Chrome.</p>
      </div>`;
    const dismissButton = notice.querySelector('.faceauth-glass-notice-close');
    dismissButton.style.zIndex = '3';
    dismissButton.addEventListener('click', () => {
      if (isMobileSafari) {
        try {
          sessionStorage.setItem(dismissalKey, 'true');
        } catch {}
      }
      notice.classList.remove('is-visible');
      notice.classList.add('is-dismissed');
    });
    if (isMobileOrTablet) {
      document.documentElement.classList.add('faceauth-safari-notice-active');
      notice.addEventListener('transitionend', (event) => {
        if (event.propertyName === 'opacity' && notice.classList.contains('is-dismissed')) {
          document.documentElement.classList.remove('faceauth-safari-notice-active');
        }
      });
    }

    document.body.appendChild(notice);
    applyGlass(notice, navigationGlassConfig);
    window.addEventListener('faceauth-navigation-glass-intensity-change', () => {
      targets.get(notice)?.updateConfig(navigationGlassConfig());
    });
    requestAnimationFrame(() => notice.classList.add('is-visible'));
  }

  function injectMobileNotice() {
    if (!isMobileOrTablet) return;

    const dismissalKey = 'faceauth-mobile-device-notice-dismissed';
    try {
      if (sessionStorage.getItem(dismissalKey) === 'true') return;
    } catch {}

    const notice = document.createElement('aside');
    notice.className = 'faceauth-glass-notice faceauth-mobile-notice';
    notice.dataset.radius = '24';
    notice.setAttribute('aria-label', 'Mobile and tablet experience recommendation');
    notice.innerHTML = `
      <button class="faceauth-glass-notice-close" type="button" aria-label="Dismiss mobile experience notice">×</button>
      <div class="faceauth-glass-notice-copy">
        <strong>For the best experience</strong>
        <p>FaceAuth is designed for a computer. For the best experience, we recommend viewing this website on a Mac, PC, or other computer.</p>
      </div>`;
    const dismissButton = notice.querySelector('.faceauth-glass-notice-close');
    dismissButton.style.zIndex = '3';
    dismissButton.addEventListener('click', () => {
      try {
        sessionStorage.setItem(dismissalKey, 'true');
      } catch {}
      notice.classList.remove('is-visible');
      notice.classList.add('is-dismissed');
    });

    document.body.appendChild(notice);
    applyGlass(notice, navigationGlassConfig);
    window.addEventListener('faceauth-navigation-glass-intensity-change', () => {
      targets.get(notice)?.updateConfig(navigationGlassConfig());
    });
    requestAnimationFrame(() => notice.classList.add('is-visible'));
  }

  function initializeAssistantGlass() {
    const panel = document.querySelector('.assistant-panel');
    if (!panel) return;
    applyGlass(panel, navigationGlassConfig);
    window.addEventListener('faceauth-navigation-glass-intensity-change', () => {
      targets.get(panel)?.updateConfig(navigationGlassConfig());
    });
  }

  function initializeAssistantToggleGlass() {
    const toggle = document.querySelector('.assistant-toggle');
    if (!toggle) return;
    applyGlass(toggle, navigationGlassConfig);
    window.addEventListener('faceauth-navigation-glass-intensity-change', () => {
      targets.get(toggle)?.updateConfig(navigationGlassConfig());
    });
  }

  const nav = injectSharedNavigation();
  initializeNavigation(nav);
  injectSettingsButton();
  injectCompatibilityButton();
  initializeAssistantGlass();
  initializeAssistantToggleGlass();
  injectSafariNotice();
  injectMobileNotice();
})();
