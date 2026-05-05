/**
 * Live password strength meter for the profile password form.
 */
export default class extends HTMLElement {
  connectedCallback () {
    const idAttr = this.getAttribute('data-password-input-id')
    this.input =
      (idAttr && document.getElementById(idAttr)) ||
      (this.previousElementSibling?.type === 'password' ? this.previousElementSibling : null)
    if (!this.input?.matches?.('input[type="password"]')) {
      this.input = this.closest('.form-control')?.querySelector('input[type="password"]')
    }
    this.fill = this.querySelector('[data-password-strength-fill]')
    this.labelEl = this.querySelector('[data-password-strength-label]')
    if (!this.input || !this.fill || !this.labelEl) return

    this.i18n = {
      empty: this.dataset.i18nEmpty || 'Password strength',
      weak: this.dataset.i18nWeak || 'Weak',
      fair: this.dataset.i18nFair || 'Fair',
      good: this.dataset.i18nGood || 'Good',
      strong: this.dataset.i18nStrong || 'Strong'
    }

    this.meter = this.querySelector('.profile-password-strength-meter')

    this.onInput = () => this.update()
    this.input.addEventListener('input', this.onInput)
    this.update()
  }

  disconnectedCallback () {
    this.input?.removeEventListener('input', this.onInput)
  }

  scorePassword (value) {
    if (!value) return { score: 0, label: 'empty' }

    let p = 0
    if (value.length >= 8) p += 1
    if (value.length >= 12) p += 1
    if (/[a-z]/.test(value) && /[A-Z]/.test(value)) p += 1
    if (/\d/.test(value)) p += 1
    if (/[^A-Za-z0-9]/.test(value)) p += 1

    let tier = 1
    if (p >= 4) tier = 4
    else if (p === 3) tier = 3
    else if (p === 2) tier = 2

    const labelKeys = ['empty', 'weak', 'fair', 'good', 'strong']
    return { score: tier, label: labelKeys[tier] }
  }

  update () {
    const v = this.input.value
    const { score, label } = this.scorePassword(v)

    const pct = (score / 4) * 100
    this.fill.style.width = `${pct}%`
    this.fill.dataset.strengthLevel = label

    this.labelEl.textContent =
      label === 'empty'
        ? this.i18n.empty
        : (this.i18n[label] || this.i18n.weak)

    if (this.meter) {
      this.meter.setAttribute('aria-valuenow', String(score))
      this.meter.setAttribute('aria-valuetext', this.labelEl.textContent)
    }
  }
}
