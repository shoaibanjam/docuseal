export default class extends HTMLElement {
  connectedCallback () {
    const eventType = this.dataset.on || this.dataset.eventType || 'click'
    const timeoutMs = parseInt(this.dataset.timeoutMs || '0', 10)
    const selector = document.getElementById(this.dataset.selectorId) || this
    const eventElement = eventType === 'submit' ? this.querySelector('form') : this

    if (eventType === 'timeout') {
      window.setTimeout(() => selector.remove(), timeoutMs > 0 ? timeoutMs : 3000)
      return
    }

    eventElement.addEventListener(eventType, (event) => {
      if (eventType === 'click') {
        event.preventDefault()
      }

      selector.remove()
    })
  }
}
