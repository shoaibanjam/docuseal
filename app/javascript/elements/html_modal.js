import { actionable } from '@github/catalyst/lib/actionable'

export default actionable(class extends HTMLElement {
  connectedCallback () {
    this.toggle = this.querySelector('.modal-toggle')
    this.modal = this.querySelector('.modal')
    if (!this.toggle) return

    this.onToggleChange = this.onToggleChange.bind(this)
    this.onEscKey = this.onEscKey.bind(this)

    this.toggle.addEventListener('change', this.onToggleChange)
    this.syncOpenState()
  }

  disconnectedCallback () {
    this.toggle?.removeEventListener('change', this.onToggleChange)
    document.removeEventListener('keyup', this.onEscKey)
    this.modal?.classList.remove('modal-open')
    this.unlockBody()
  }

  syncOpenState () {
    if (this.toggle.checked) {
      this.modal?.classList.add('modal-open')
      this.lockBody()
      document.addEventListener('keyup', this.onEscKey)
    } else {
      this.modal?.classList.remove('modal-open')
      this.unlockBody()
      document.removeEventListener('keyup', this.onEscKey)
    }
  }

  onToggleChange () {
    this.syncOpenState()
  }

  onEscKey (e) {
    if (e.code !== 'Escape') return
    if (document.querySelector('.app-confirm-modal')) return

    e.preventDefault()
    e.stopPropagation()

    this.toggle.checked = false
    this.toggle.dispatchEvent(new Event('change'))
  }

  lockBody () {
    document.body.classList.add('overflow-hidden')
  }

  unlockBody () {
    document.body.classList.remove('overflow-hidden')
  }
})
