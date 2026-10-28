(() => {
  // Development-only example allocations; these are not verified analytics.
  const exampleCounts = Object.freeze({
    USA: 5400,
    CAN: 850,
    CHN: 900,
    AUS: 500,
    MEX: 600,
    ITA: 450,
    IND: 850,
    GBR: 550,
    DEU: 500,
    FRA: 400,
    BRA: 450,
    JPN: 350,
    ESP: 300,
    NLD: 250,
    NZL: 200,
    KOR: 250,
    SWE: 200,
    CHE: 150,
    IRL: 150,
    ZAF: 200
  });
  const countryNames = Object.freeze({
    USA: 'United States',
    CAN: 'Canada',
    CHN: 'China',
    AUS: 'Australia',
    MEX: 'Mexico',
    ITA: 'Italy',
    IND: 'India',
    GBR: 'United Kingdom',
    DEU: 'Germany',
    FRA: 'France',
    BRA: 'Brazil',
    JPN: 'Japan',
    ESP: 'Spain',
    NLD: 'Netherlands',
    NZL: 'New Zealand',
    KOR: 'South Korea',
    SWE: 'Sweden',
    CHE: 'Switzerland',
    IRL: 'Ireland',
    ZAF: 'South Africa'
  });
  const formatter = new Intl.NumberFormat('en-US');
  const map = document.querySelector('.download-world-map');
  const mapWrap = document.querySelector('.download-map-wrap');
  const tooltip = document.querySelector('.download-map-tooltip');
  const countryDetail = document.querySelector('.download-map-country-detail');
  const countrySelect = document.querySelector('#download-map-country-select');
  const totalElement = document.querySelector('.download-map-total');
  const countryCountElement = document.querySelector('.download-map-country-count');
  const counter = document.querySelector('.download-counter');
  const overlay = document.querySelector('#download-map-overlay');
  const dialog = overlay.querySelector('.download-map-dialog');
  const closeButton = overlay.querySelector('.download-map-close');
  const geometry = window.faceAuthWorldMapGeometry;
  const countryElements = new Map();
  const svgNamespace = 'http://www.w3.org/2000/svg';
  let selectedCode = '';
  let previousBodyOverflow = '';

  if (!Array.isArray(geometry)) {
    throw new Error('The local world map boundary data did not load.');
  }

  const totalDownloads = Object.values(exampleCounts).reduce((total, count) => total + count, 0);
  totalElement.textContent = `${formatter.format(totalDownloads)}+`;
  countryCountElement.textContent = formatter.format(Object.keys(exampleCounts).length);

  const setTooltip = (country, x, y) => {
    const name = countryNames[country.id];
    const count = exampleCounts[country.id];
    tooltip.textContent = `${name} · ${formatter.format(count)}+ total downloads`;
    tooltip.classList.add('is-visible');
    const mapBounds = mapWrap.getBoundingClientRect();
    const tooltipWidth = tooltip.offsetWidth;
    const tooltipHeight = tooltip.offsetHeight;
    const left = Math.max(8, Math.min(x + 12, mapBounds.width - tooltipWidth - 8));
    const top = Math.max(8, Math.min(y - tooltipHeight - 8, mapBounds.height - tooltipHeight - 8));
    tooltip.style.left = `${left}px`;
    tooltip.style.top = `${top}px`;
  };

  const showCountry = (country, path) => {
    const name = countryNames[country.id];
    const count = exampleCounts[country.id];
    const mapBounds = mapWrap.getBoundingClientRect();
    const pathBounds = path.getBoundingClientRect();
    countryDetail.textContent = `${name} · ${formatter.format(count)}+ total downloads`;
    setTooltip(
      country,
      pathBounds.left + pathBounds.width / 2 - mapBounds.left,
      pathBounds.top + pathBounds.height / 2 - mapBounds.top
    );
  };

  const selectCountry = (country, path) => {
    if (selectedCode) {
      const previousPath = countryElements.get(selectedCode);
      previousPath.classList.remove('is-active');
      previousPath.setAttribute('aria-pressed', 'false');
    }

    selectedCode = country.id;
    path.classList.add('is-active');
    path.setAttribute('aria-pressed', 'true');
    countrySelect.value = country.id;
    showCountry(country, path);
  };

  const placeTooltipAtPointer = (country, event) => {
    const mapBounds = mapWrap.getBoundingClientRect();
    setTooltip(country, event.clientX - mapBounds.left, event.clientY - mapBounds.top);
  };

  geometry.forEach((country) => {
    const path = document.createElementNS(svgNamespace, 'path');
    path.setAttribute('d', country.d);
    path.setAttribute('class', 'map-country');
    path.setAttribute('fill-rule', 'evenodd');
    path.dataset.country = country.id;
    path.setAttribute('aria-label', country.name);

    if (exampleCounts[country.id]) {
      const count = exampleCounts[country.id];
      path.classList.add('has-downloads');
      path.dataset.tier = count >= 500 ? 'high' : count >= 300 ? 'medium' : 'low';
      path.setAttribute('role', 'button');
      path.setAttribute('tabindex', '0');
      path.setAttribute('aria-pressed', 'false');
      path.setAttribute('aria-label', `${countryNames[country.id]}: ${formatter.format(count)}+ total downloads`);
      countryElements.set(country.id, path);

      const option = document.createElement('option');
      option.value = country.id;
      option.textContent = countryNames[country.id];
      countrySelect.append(option);

      path.addEventListener('pointerenter', (event) => placeTooltipAtPointer(country, event));
      path.addEventListener('pointermove', (event) => placeTooltipAtPointer(country, event));
      path.addEventListener('pointerleave', () => {
        if (document.activeElement !== path) tooltip.classList.remove('is-visible');
      });
      path.addEventListener('focus', () => showCountry(country, path));
      path.addEventListener('blur', () => tooltip.classList.remove('is-visible'));
      path.addEventListener('click', () => selectCountry(country, path));
      path.addEventListener('keydown', (event) => {
        if (event.key !== 'Enter' && event.key !== ' ') return;
        event.preventDefault();
        selectCountry(country, path);
      });
    }

    map.append(path);
  });

  countrySelect.addEventListener('change', () => {
    const path = countryElements.get(countrySelect.value);
    if (!path) return;
    selectCountry({ id: countrySelect.value }, path);
  });

  const openMap = () => {
    previousBodyOverflow = document.body.style.overflow;
    overlay.classList.add('is-open');
    overlay.setAttribute('aria-hidden', 'false');
    document.body.style.overflow = 'hidden';
    closeButton.focus({ preventScroll: true });
  };

  const closeMap = () => {
    overlay.classList.remove('is-open');
    overlay.setAttribute('aria-hidden', 'true');
    document.body.style.overflow = previousBodyOverflow;
    tooltip.classList.remove('is-visible');
    counter.focus({ preventScroll: true });
  };

  counter.addEventListener('click', openMap);
  closeButton.addEventListener('click', closeMap);
  overlay.addEventListener('click', (event) => {
    if (event.target === overlay) closeMap();
  });

  document.addEventListener('keydown', (event) => {
    if (!overlay.classList.contains('is-open')) return;

    if (event.key === 'Escape') {
      event.preventDefault();
      closeMap();
      return;
    }

    if (event.key !== 'Tab') return;
    const focusable = [...dialog.querySelectorAll('button:not([disabled]), select:not([disabled]), [tabindex="0"]')];
    const first = focusable[0];
    const last = focusable[focusable.length - 1];

    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  });
})();
