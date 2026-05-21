const RTL_LANGUAGES = new Set(['ar', 'he'])

const directionForLocale = (locale) =>
  RTL_LANGUAGES.has(String(locale || '').split('-')[0]) ? 'rtl' : 'ltr'

export default class extends HTMLElement {
  connectedCallback () {
    this.trigger = this.querySelector('.locale-switcher__trigger')
    this.menu = this.querySelector('.locale-switcher__menu')
    this.select = this.querySelector('select[name="locale"]')
    this.form = this.querySelector('form.locale-switcher__form')

    if (this.select && this.form) {
      this.onChange = () => {
        this.applyLocale(this.select.value)
        this.form.requestSubmit()
      }
      this.select.addEventListener('change', this.onChange)
    }

    if (this.trigger) {
      this.onTriggerClick = (event) => {
        event.preventDefault()
        event.stopPropagation()
        this.toggleMenu()
      }
      this.trigger.addEventListener('click', this.onTriggerClick)
    }

    this.onDocumentClick = (event) => {
      if (!this.contains(event.target)) this.closeMenu()
    }
    document.addEventListener('click', this.onDocumentClick)

    this.onKeydown = (event) => {
      if (event.key === 'Escape') this.closeMenu()
    }
    this.addEventListener('keydown', this.onKeydown)

    /*
     * Menu option buttons: apply dir/lang on submit (after click), not on pointerdown,
     * so the trigger does not shift under RTL/LTR mid-click.
     */
    this.onContainedFormSubmit = (event) => {
      const form = event.target
      if (!(form instanceof HTMLFormElement) || !this.contains(form)) return

      const submitter = event.submitter
      const localeAttr = submitter?.getAttribute?.('data-locale-switcher-submit')
      if (!localeAttr) return

      this.applyLocale(localeAttr)
      this.closeMenu()
    }
    this.addEventListener('submit', this.onContainedFormSubmit, true)
  }

  disconnectedCallback () {
    this.select?.removeEventListener('change', this.onChange)
    this.trigger?.removeEventListener('click', this.onTriggerClick)
    document.removeEventListener('click', this.onDocumentClick)
    this.removeEventListener('keydown', this.onKeydown)
    this.removeEventListener('submit', this.onContainedFormSubmit, true)
  }

  toggleMenu () {
    if (this.classList.contains('is-open')) {
      this.closeMenu()
    } else {
      this.openMenu()
    }
  }

  openMenu () {
    this.classList.add('is-open')
    this.trigger?.setAttribute('aria-expanded', 'true')
  }

  closeMenu () {
    this.classList.remove('is-open')
    this.trigger?.setAttribute('aria-expanded', 'false')
  }

  applyLocale (locale) {
    const direction = directionForLocale(locale)
    const root = document.documentElement

    root.setAttribute('lang', locale)
    root.setAttribute('dir', direction)
    document.body?.classList.toggle('is-rtl', direction === 'rtl')
  }
}
