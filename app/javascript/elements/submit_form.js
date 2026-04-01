export default class extends HTMLElement {
  connectedCallback () {
    const form = this.querySelector('form') || (this.querySelector('input, button, select') || this.lastElementChild).form

    if (this.dataset.interval) {
      this.interval = setInterval(() => {
        form.requestSubmit()
      }, parseInt(this.dataset.interval))
    } else if (this.dataset.on) {
      this.lastElementChild.addEventListener(this.dataset.on, (event) => {
        const target = event.target

        if (this.dataset.disable === 'true') {
          form.querySelector('[type="submit"]')?.setAttribute('disabled', true)
        }

        if (this.dataset.submitIfValue === 'true') {
          if (event.target.value) {
            form.requestSubmit()
          }
        } else {
          form.requestSubmit()
        }

        // Toggle/checkbox controls can keep a temporary focused visual state
        // after submit; clear focus so appearance is immediately consistent.
        if (target && typeof target.blur === 'function') {
          requestAnimationFrame(() => target.blur())
        }
      })
    } else {
      form.requestSubmit()
    }
  }

  disconnectedCallback () {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }
}
