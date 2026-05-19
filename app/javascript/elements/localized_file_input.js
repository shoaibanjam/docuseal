export default class extends HTMLElement {
  connectedCallback () {
    this.input = this.querySelector('input[type="file"]')
    this.fileName = this.querySelector('[data-localized-file-name]')

    if (!this.input || !this.fileName) return

    this.emptyText = this.fileName.dataset.emptyText || this.fileName.textContent
    this.onChange = () => this.updateFileName()

    this.input.addEventListener('change', this.onChange)
    this.updateFileName()
  }

  disconnectedCallback () {
    this.input?.removeEventListener('change', this.onChange)
  }

  updateFileName () {
    const files = Array.from(this.input.files || [])
    this.fileName.textContent = files.length
      ? files.map((file) => file.name).join(', ')
      : this.emptyText
  }
}
