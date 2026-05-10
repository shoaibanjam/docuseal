import AOS from 'aos'
import 'aos/dist/aos.css'
import Lenis from 'lenis'
import 'lenis/dist/lenis.css'
import Typed from 'typed.js'
import VanillaTilt from 'vanilla-tilt'
import Splide from '@splidejs/splide'
import '@splidejs/splide/css'

let aosStarted = false
let lenisInstance = null
let typedInstance = null
let tiltBound = false
let logosSplide = null
let landingNavObserver = null

function prefersReducedMotion () {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches
}

function prefersFinePointer () {
  return window.matchMedia('(pointer: fine)').matches
}

function parseTypedStrings (raw) {
  if (!raw) return null
  try {
    const parsed = JSON.parse(raw)
    return Array.isArray(parsed) && parsed.length ? parsed : null
  } catch {
    return null
  }
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
  if (typedInstance) {
    typedInstance.destroy()
    typedInstance = null
  }
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

  const typedEl = document.getElementById('landing-hero-typed')
  const typedStrings = parseTypedStrings(typedEl?.dataset?.landingTypedStrings)
  if (
    !reduceMotion &&
    typedEl &&
    typedStrings &&
    !typedInstance
  ) {
    typedInstance = new Typed(typedEl, {
      strings: typedStrings,
      typeSpeed: 52,
      backSpeed: 38,
      backDelay: 2200,
      startDelay: 400,
      loop: true,
      smartBackspace: true,
      showCursor: true,
      cursorChar: '|'
    })
  }

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
  setupLandingNavSpy()
}
