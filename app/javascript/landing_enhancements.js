import AOS from 'aos'
import 'aos/dist/aos.css'
import Lenis from 'lenis'
import 'lenis/dist/lenis.css'
import VanillaTilt from 'vanilla-tilt'
import Splide from '@splidejs/splide'
import '@splidejs/splide/css'

let aosStarted = false
let lenisInstance = null
let heroWordRotatorTimer = null
let tiltBound = false
let logosSplide = null
let landingNavObserver = null

function prefersReducedMotion () {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches
}

function prefersFinePointer () {
  return window.matchMedia('(pointer: fine)').matches
}

function parseLandingWordList (raw) {
  if (!raw) return null
  try {
    const parsed = JSON.parse(raw)
    return Array.isArray(parsed) && parsed.length ? parsed : null
  } catch {
    return null
  }
}

function teardownHeroWordRotator () {
  if (heroWordRotatorTimer) {
    clearTimeout(heroWordRotatorTimer)
    heroWordRotatorTimer = null
  }
  document.getElementById('landing-hero-rotating-word')?.classList.remove('landing-hero-rotating-word--fading')
}

function bootHeroWordRotator (reduceMotion) {
  teardownHeroWordRotator()

  const el = document.getElementById('landing-hero-rotating-word')
  const words = parseLandingWordList(el?.dataset?.landingRotatingWords)
  if (!el || !words?.length) return

  el.textContent = words[0]

  if (reduceMotion) return

  const fadeMs = 600
  const holdMs = 2800
  let index = 0

  const schedule = (delay, fn) => {
    heroWordRotatorTimer = window.setTimeout(fn, delay)
  }

  const rotate = () => {
    el.classList.add('landing-hero-rotating-word--fading')

    schedule(fadeMs, () => {
      index = (index + 1) % words.length
      el.textContent = words[index]
      el.classList.remove('landing-hero-rotating-word--fading')
      schedule(holdMs, rotate)
    })
  }

  schedule(holdMs, rotate)
}

function teardownLandingNavSpy () {
  landingNavObserver?.disconnect()
  landingNavObserver = null

  document.querySelectorAll('.landing-nav-link--active').forEach((el) => {
    el.classList.remove('landing-nav-link--active')
    el.removeAttribute('aria-current')
  })
}

function setupLandingNavSpy () {
  teardownLandingNavSpy()

  const nav = document.querySelector('.landing-nav')
  if (!nav) return

  const links = [
    ...nav.querySelectorAll('a.landing-nav-link[href^="#"]')
  ]
  if (!links.length) return

  const sectionById = new Map()
  for (const link of links) {
    const id = link.getAttribute('href')?.slice(1)
    if (!id) continue
    const section = document.getElementById(id)
    if (section) sectionById.set(id, section)
  }
  if (!sectionById.size) return

  const setActiveById = (id) => {
    for (const link of links) {
      const hrefId = link.getAttribute('href')?.slice(1)
      const active = Boolean(id && hrefId === id)
      link.classList.toggle('landing-nav-link--active', active)
      if (active) link.setAttribute('aria-current', 'true')
      else link.removeAttribute('aria-current')
    }
  }

  landingNavObserver = new IntersectionObserver(
    (entries) => {
      const visible = entries
        .filter((e) => e.isIntersecting && e.target.id)
        .sort((a, b) => b.intersectionRatio - a.intersectionRatio)

      if (visible[0]?.target?.id) {
        setActiveById(visible[0].target.id)
      }
    },
    {
      root: null,
      rootMargin: '-76px 0px -55% 0px',
      threshold: [0, 0.08, 0.2, 0.35]
    }
  )

  for (const section of sectionById.values()) {
    landingNavObserver.observe(section)
  }
}

export function resetLandingAos () {
  aosStarted = false
}

export function teardownLandingScroll () {
  if (lenisInstance) {
    lenisInstance.destroy()
    lenisInstance = null
  }
  teardownHeroWordRotator()
  if (logosSplide) {
    logosSplide.destroy()
    logosSplide = null
  }
  teardownLandingNavSpy()

  document.querySelectorAll('.landing-tilt').forEach((el) => {
    el.vanillaTilt?.destroy?.()
  })
  tiltBound = false

  document.querySelectorAll('.landing-logos-splide').forEach((el) => {
    el.classList.remove('landing-logos-splide--static')
  })
}

function formatLandingCounter (value) {
  return new Intl.NumberFormat(document.documentElement.lang || undefined).format(value)
}

function animateLandingSignedCounter (valueEl, target, duration = 2200) {
  const start = performance.now()

  const tick = (now) => {
    const progress = Math.min((now - start) / duration, 1)
    const eased = 1 - Math.pow(1 - progress, 3)
    const current = Math.round(target * eased)

    valueEl.textContent = formatLandingCounter(current)

    if (progress < 1) requestAnimationFrame(tick)
    else valueEl.textContent = formatLandingCounter(target)
  }

  requestAnimationFrame(tick)
}

function bootLandingSignedCounter (reduceMotion) {
  const root = document.querySelector('[data-landing-signed-counter]')
  if (!root) return

  const valueEl = root.querySelector('[data-landing-counter-value]')
  const target = Number.parseInt(root.dataset.count || '', 10)

  if (!valueEl || !Number.isFinite(target) || target < 1) return

  if (reduceMotion) {
    valueEl.textContent = formatLandingCounter(target)
    return
  }

  let started = false
  const observer = new IntersectionObserver(
    (entries) => {
      if (started || !entries.some((entry) => entry.isIntersecting)) return

      started = true
      observer.disconnect()
      animateLandingSignedCounter(valueEl, target)
    },
    { threshold: 0.35, rootMargin: '0px 0px -10% 0px' }
  )

  observer.observe(root)
}

function bootLandingLogosSplide (reduceMotion) {
  const root = document.querySelector('.landing-logos-splide')
  if (!root) return

  if (reduceMotion) {
    root.classList.add('landing-logos-splide--static')
    return
  }

  root.classList.remove('landing-logos-splide--static')

  if (logosSplide) {
    logosSplide.destroy()
    logosSplide = null
  }

  logosSplide = new Splide(root, {
    type: 'loop',
    drag: true,
    focus: 'center',
    arrows: false,
    pagination: false,
    gap: '2.5rem',
    autoWidth: true,
    autoplay: true,
    interval: 4200,
    pauseOnHover: true,
    pauseOnFocus: true,
    speed: 950,
    easing: 'cubic-bezier(0.25, 1, 0.5, 1)',
    reducedMotion: {
      autoplay: false,
      speed: 0
    }
  })

  logosSplide.mount()
}

export function bootLandingAos () {
  if (!document.querySelector('.landing-page')) return

  const reduceMotion = prefersReducedMotion()

  if (!aosStarted) {
    aosStarted = true
    AOS.init({
      once: true,
      duration: 700,
      easing: 'ease-out-cubic',
      offset: 48,
      delay: 0,
      anchorPlacement: 'top-bottom',
      disable: reduceMotion
    })
  } else {
    AOS.refresh()
  }

  if (!reduceMotion && !lenisInstance) {
    lenisInstance = new Lenis({
      autoRaf: true,
      lerp: 0.088,
      wheelMultiplier: 0.92,
      touchMultiplier: 1.05,
      anchors: {
        offset: -76,
        duration: 1.15
      }
    })
    let aosScrollTick = false
    lenisInstance.on('scroll', () => {
      if (aosScrollTick) return
      aosScrollTick = true
      requestAnimationFrame(() => {
        aosScrollTick = false
        AOS.refresh()
      })
    })
  }

  bootHeroWordRotator(reduceMotion)

  if (!reduceMotion && prefersFinePointer() && !tiltBound) {
    const cards = document.querySelectorAll('.landing-tilt')
    if (cards.length) {
      VanillaTilt.init(Array.from(cards), {
        max: 7,
        speed: 420,
        glare: true,
        'max-glare': 0.2,
        scale: 1.02,
        gyroscope: false
      })
      tiltBound = true
    }
  }

  bootLandingLogosSplide(reduceMotion)
  bootLandingSignedCounter(reduceMotion)
  setupLandingNavSpy()
}
