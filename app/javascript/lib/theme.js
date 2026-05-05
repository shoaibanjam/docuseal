const STORAGE_KEY = 'cybros-theme'
const COOKIE_KEY = 'cybros-theme'
const DARK_THEME = 'docuseal-dark'
const LIGHT_THEME = 'docuseal-light'
const LEGACY_DARK_THEME = 'docuseal'

const normalizeTheme = (themeName) => {
  if (themeName === LIGHT_THEME) return LIGHT_THEME
  if (themeName === LEGACY_DARK_THEME) return DARK_THEME

  return DARK_THEME
}

export const getCurrentTheme = () => normalizeTheme(document.documentElement.getAttribute('data-theme'))

export const applyTheme = (themeName, { persist = true } = {}) => {
  const normalizedTheme = normalizeTheme(themeName)
  const root = document.documentElement

  root.setAttribute('data-theme', normalizedTheme)
  root.style.colorScheme = normalizedTheme === LIGHT_THEME ? 'light' : 'dark'

  if (persist) {
    try {
      window.localStorage.setItem(STORAGE_KEY, normalizedTheme)
    } catch (_) {}
  }

  try {
    document.cookie = `${COOKIE_KEY}=${normalizedTheme}; Path=/; Max-Age=31536000; SameSite=Lax`
  } catch (_) {}

  window.dispatchEvent(new CustomEvent('cybros:theme-changed', { detail: { theme: normalizedTheme } }))

  return normalizedTheme
}

export const toggleTheme = () => {
  const nextTheme = getCurrentTheme() === LIGHT_THEME ? DARK_THEME : LIGHT_THEME
  return applyTheme(nextTheme)
}

export const initTheme = () => {
  let savedTheme

  try {
    savedTheme = window.localStorage.getItem(STORAGE_KEY)
  } catch (_) {}

  const defaultTheme = document.documentElement.getAttribute('data-theme')

  return applyTheme(savedTheme || defaultTheme || DARK_THEME, { persist: false })
}

export default class extends HTMLElement {
  connectedCallback () {
    this.button = this.querySelector('button')

    if (!this.button) return

    this.sunIcon = this.querySelector('[data-theme-icon="sun"]')
    this.moonIcon = this.querySelector('[data-theme-icon="moon"]')

    this.onClick = (event) => {
      event.preventDefault()
      toggleTheme()
      this.syncIcons()
    }

    this.onThemeChanged = () => this.syncIcons()

    this.button.addEventListener('click', this.onClick)
    window.addEventListener('cybros:theme-changed', this.onThemeChanged)

    this.syncIcons()
  }

  disconnectedCallback () {
    this.button?.removeEventListener('click', this.onClick)
    window.removeEventListener('cybros:theme-changed', this.onThemeChanged)
  }

  syncIcons () {
    const isLight = getCurrentTheme() === LIGHT_THEME

    if (this.sunIcon) this.sunIcon.classList.toggle('hidden', isLight)
    if (this.moonIcon) this.moonIcon.classList.toggle('hidden', !isLight)

    if (this.button) {
      this.button.setAttribute('aria-pressed', String(isLight))
      this.button.dataset.theme = isLight ? LIGHT_THEME : DARK_THEME
    }
  }
}
