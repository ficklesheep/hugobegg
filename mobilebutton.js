function initMenu() {
  const menuBtn = document.querySelector('.menu-btn');
  const menu = document.querySelector('.menu');

  if (!menuBtn || !menu) {
    // Elements not found yet, retry after 100ms
    setTimeout(initMenu, 100);
    return;
  }

  let menuOpen = false;

  menuBtn.addEventListener('click', () => {
    if (!menuOpen) {
      menuBtn.classList.add('open');
      menu.classList.add('open');
      menuOpen = true;
    } else {
      menuBtn.classList.remove('open');
      menu.classList.remove('open');
      menuOpen = false;
    }
  });

  // Resize animation stopper
  let resizeTimer;
  window.addEventListener('resize', () => {
    document.body.classList.add('resize-animation-stopper');
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => {
      document.body.classList.remove('resize-animation-stopper');
    }, 400);
  });
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', initMenu);
