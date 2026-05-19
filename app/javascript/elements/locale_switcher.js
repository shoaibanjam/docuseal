const RTL_LANGUAGES = new Set(['ar', 'he'])

const directionForLocale = (locale) =>
  RTL_LANGUAGES.has(String(locale || '').split('-')[0]) ? 'rtl' : 'ltr'

export default class extends HTMLElement {
  connectedCallback () {
    this.select = this.querySelector('select[name="locale"]')
    this.form = this.querySelector('form')

    if (!this.select || !this.form) return

    this.onChange = () => {
      this.applyLocale(this.select.value)
      this.form.requestSubmit()
    }

    this.select.addEventListener('change', this.onChange)
  }

  disconnectedCallback () {
    this.select?.removeEventListener('change', this.onChange)
  }

  applyLocale (locale) {
    const direction = directionForLocale(locale)
    const root = document.documentElement

    root.setAttribute('lang', locale)
    root.setAttribute('dir', direction)
    document.body?.classList.toggle('is-rtl', direction === 'rtl')
  }
}
