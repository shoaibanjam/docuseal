const RTL_LANGUAGES = new Set(['ar', 'he'])

const directionForLocale = (locale) =>
  RTL_LANGUAGES.has(String(locale || '').split('-')[0]) ? 'rtl' : 'ltr'

export default class extends HTMLElement {
  connectedCallback () {
    this.select = this.querySelector('select[name="locale"]')
    this.form = this.querySelector('form.locale-switcher__form')

    if (this.select && this.form) {
      this.onChange = () => {
        this.applyLocale(this.select.value)
        this.form.requestSubmit()
      }
      this.select.addEventListener('change', this.onChange)
    }

    /*
     * Custom dropdown: do NOT mutate `dir` / `lang` on pointerdown (capture). That reflows the
     * whole UI mid–mouse-click; the locale button shifts under RTL/LTR swaps and the implicit
     * click + form submit often never completes (looks like “needs two clicks”).
     * Apply hints on `submit`, after the click sequence is finished, still before navigation.
     */
    this.onContainedFormSubmit = (event) => {
      const form = event.target
      if (!(form instanceof HTMLFormElement) || !this.contains(form)) return

      const submitter = event.submitter
      const localeAttr = submitter?.getAttribute?.('data-locale-switcher-submit')
      if (!localeAttr) return

      this.applyLocale(localeAttr)
    }
    this.addEventListener('submit', this.onContainedFormSubmit, true)
  }

  disconnectedCallback () {
    this.select?.removeEventListener('change', this.onChange)
    this.removeEventListener('submit', this.onContainedFormSubmit, true)
  }

  applyLocale (locale) {
    const direction = directionForLocale(locale)
    const root = document.documentElement

    root.setAttribute('lang', locale)
    root.setAttribute('dir', direction)
    document.body?.classList.toggle('is-rtl', direction === 'rtl')
  }
}
