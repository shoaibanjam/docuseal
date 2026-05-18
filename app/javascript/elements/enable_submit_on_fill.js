export default class extends HTMLElement {
  connectedCallback () {
    this.form = this.closest('form')
    if (!this.form) return

    this.button = this.querySelector('[type="submit"]') || this.form.querySelector('[type="submit"]')
    if (!this.button) return

    const selector = this.dataset.fields || 'input:not([type="hidden"]), textarea, select'
    this.fields = [...this.form.querySelectorAll(selector)]

    if (!this.fields.length) return

    this.onFieldChange = () => this.sync()
    this.onSubmit = () => {
      this.button.classList.add('auth-submit-btn--submitting')
      this.button.disabled = true
    }

    this.fields.forEach((field) => {
      field.addEventListener('input', this.onFieldChange)
      field.addEventListener('change', this.onFieldChange)
    })

    this.form.addEventListener('submit', this.onSubmit)
    this.sync()
  }

  disconnectedCallback () {
    if (!this.form) return

    this.fields?.forEach((field) => {
      field.removeEventListener('input', this.onFieldChange)
      field.removeEventListener('change', this.onFieldChange)
    })

    this.form.removeEventListener('submit', this.onSubmit)
  }

  sync () {
    const isComplete = this.fields.every((field) => field.value.trim().length > 0)

    this.button.disabled = !isComplete
  }
}
