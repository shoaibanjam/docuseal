export default class extends HTMLElement {
  connectedCallback () {
    const input = document.createElement('input')

    input.type = 'hidden'
    input.name = 'password'
    input.value = prompt(document.documentElement.dataset.i18nEnterPdfPassword || 'Enter PDF password')

    this.form.append(input)

    this.form.requestSubmit()

    this.remove()
  }

  get form () {
    return this.closest('form')
  }
}
