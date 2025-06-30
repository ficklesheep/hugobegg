const menuBtn = document.querySelector('.menu-btn');
const menu = document.querySelector('.menu');
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





let resizeTimer;
window.addEventListener("resize", () => {
    document.body.classList.add("resize-animation-stopper");
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => {
        document.body.classList.remove("resize-animation-stopper");
    }, 400);
});