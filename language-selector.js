(() => {
  const languages = [
    ['English', 'en'],
    ['简体中文', 'zh-CN'],
    ['繁體中文', 'zh-TW'],
    ['Español', 'es'],
    ['हिन्दी', 'hi'],
    ['Français', 'fr'],
    ['Português', 'pt'],
    ['Русский', 'ru'],
    ['日本語', 'ja'],
    ['한국어', 'ko']
  ];

  const selector = document.querySelector('.language-selector');
  if (!selector) return;

  const toggle = selector.querySelector('.language-toggle');
  const menu = selector.querySelector('.language-menu');
  const options = selector.querySelectorAll('.language-option');

  options.forEach((option) => {
    option.addEventListener('click', () => {
      selector.dataset.language = option.dataset.language;
      toggle.textContent = option.textContent;
      options.forEach((item) => {
        const isSelected = item === option;
        item.classList.toggle('is-selected', isSelected);
        item.setAttribute('aria-selected', String(isSelected));
      });
      selector.classList.remove('is-open');
      toggle.setAttribute('aria-expanded', 'false');
    });
  });

  toggle.addEventListener('click', () => {
    const isOpen = selector.classList.toggle('is-open');
    toggle.setAttribute('aria-expanded', String(isOpen));
  });

  document.addEventListener('click', (event) => {
    if (selector.contains(event.target)) return;
    selector.classList.remove('is-open');
    toggle.setAttribute('aria-expanded', 'false');
  });

  document.addEventListener('keydown', (event) => {
    if (event.key !== 'Escape') return;
    selector.classList.remove('is-open');
    toggle.setAttribute('aria-expanded', 'false');
  });

  selector.dataset.language = languages[0][1];
})();
