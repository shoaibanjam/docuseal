export default class extends HTMLElement {
  connectedCallback () {
    this.clearChecked()

    this.addEventListener('click', (e) => {
      const text = this.dataset.text || this.innerText.trim()

      if (navigator.clipboard) {
        navigator.clipboard.writeText(text)
      } else {
        if (e.target.tagName !== 'INPUT') {
          const message = this.dataset.unavailableMessage || document.documentElement.dataset.i18nClipboardUnavailable || "Clipboard not available. Make sure you're using https:// Copy text: {text}"

          window.showToast(message.replace('%{text}', text).replace('{text}', text))
        }
      }
    })
  }

  clearChecked () {
    this.querySelectorAll('input').forEach((e) => {
      e.checked = false
    })
  }
}
