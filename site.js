/* Nuwah Interiors — scroll-reveal animations.
   Elements are only hidden once this script runs, so if JS fails the page shows normally. */
(function () {
  if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  if (!('IntersectionObserver' in window)) return;

  // What animates, and from which direction.
  var groups = [
    { sel: '.hero .eyebrow, .hero h1, .hero .lede, .hero-actions', dir: 'left',  stagger: 110 },
    { sel: '.hero-img',                                             dir: 'right', stagger: 0, delay: 200 },
    { sel: '.band .stat',                                           dir: 'up',    stagger: 90 },
    { sel: '.section .eyebrow, .section h1, .section h2, .section .lede, .section-tight .eyebrow, .section-tight h2', dir: 'up', stagger: 80, skipIn: '.split, .form-card, .card, .tier' },
    { sel: '.grid-3 > .card, .grid-2 > .card, .tiers > .tier, .extras > .extra, .values > *', dir: 'up', stagger: 110 },
    { sel: '.split > .img',                                         dir: 'left',  stagger: 0 },
    { sel: '.split > div:not(.img)',                                dir: 'right', stagger: 0, delay: 120 },
    { sel: '.gallery figure, .home-gallery > a',                    dir: 'up',    stagger: 70, wrap: 6 },
    { sel: '.strip span',                                           dir: 'up',    stagger: 30 },
    { sel: '.form-card, .tier-tabs, .profile, .hint',               dir: 'up',    stagger: 0, skipIn: '.form-card .hint' },
    { sel: '.section .btn',                                         dir: 'up',    stagger: 0, delay: 150, skipIn: '.tier, .card' }
  ];

  var seen = new Set();
  groups.forEach(function (g) {
    var els = document.querySelectorAll(g.sel);
    var perParent = new Map();   // stagger counts restart for each container (e.g. each package tab)
    els.forEach(function (el) {
      if (seen.has(el)) return;
      if (g.skipIn && el.closest && el.closest(g.skipIn)) return;   // already animates with its parent card
      seen.add(el);
      var dir = g.dir;
      // in a reversed split (image on the right) swap the slide directions
      if (el.closest && el.closest('.split.rev') && dir !== 'up') dir = dir === 'left' ? 'right' : 'left';
      el.classList.add('rv', 'rv-' + dir);
      var p = el.parentNode, k = perParent.get(p) || 0;
      perParent.set(p, k + 1);
      var i = g.wrap ? (k % g.wrap) : k;
      el.style.transitionDelay = ((g.delay || 0) + i * g.stagger) + 'ms';
    });
  });

  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
    });
  }, { threshold: 0.12, rootMargin: '0px 0px -6% 0px' });

  // Let the browser paint the hidden state first, otherwise on a first (uncached) visit
  // the start and end states land in the same frame and nothing animates.
  void document.body.offsetHeight;
  requestAnimationFrame(function () {
    requestAnimationFrame(function () {
      document.querySelectorAll('.rv').forEach(function (el) { io.observe(el); });
    });
  });

  // Safety net: anything still hidden after 4s (e.g. off-screen grid quirks) is shown.
  setTimeout(function () {
    document.querySelectorAll('.rv:not(.in)').forEach(function (el) {
      var r = el.getBoundingClientRect();
      if (r.top < window.innerHeight && r.bottom > 0) el.classList.add('in');
    });
  }, 4000);
})();
