(() => {
  const overlay = document.querySelector('#beta-modal-overlay');
  if (!overlay) return;
  const close = () => {
    overlay.classList.remove('is-open');
    overlay.setAttribute('aria-hidden', 'true');
    document.body.style.overflow = '';
  };
  document.querySelectorAll('.download-action').forEach((button) => button.addEventListener('click', (event) => {
    event.preventDefault();
    overlay.classList.add('is-open');
    overlay.setAttribute('aria-hidden', 'false');
    document.body.style.overflow = 'hidden';
  }));
  overlay.querySelector('.beta-back')?.addEventListener('click', close);
  overlay.addEventListener('click', (event) => { if (event.target === overlay) close(); });
  document.addEventListener('keydown', (event) => { if (event.key === 'Escape') close(); });
})();
