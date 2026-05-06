import { actionable } from '@github/catalyst/lib/actionable'
import { showConfirmModal } from '../lib/confirm_modal'

export default actionable(class extends HTMLElement {
  connectedCallback () {
    document.body.classList.add('overflow-hidden')

    this.addEventListener('click', this.onClick)
    document.addEventListener('keyup', this.onEscKey)
    document.addEventListener('turbo:before-cache', this.close)

    if (this.dataset.closeAfterSubmit !== 'false') {
      document.addEventListener('turbo:submit-end', this.onSubmit)
    }
  }

  disconnectedCallback () {
    document.body.classList.remove('overflow-hidden')

    this.removeEventListener('click', this.onClick)
    document.removeEventListener('keyup', this.onEscKey)
    document.removeEventListener('turbo:submit-end', this.onSubmit)
    document.removeEventListener('turbo:before-cache', this.close)
  }

  onClick = async (e) => {
    const isCloseButton = e.target.closest('[data-turbo-modal-close]')
    const isOutsideContent = !e.target.closest('[data-turbo-modal-content]')
    if (!(isCloseButton || isOutsideContent)) {
      return
    }

    e.preventDefault()
    e.stopPropagation()

    if (!(await this.confirmDiscardIfNeeded())) {
      return
    }

    this.close()
  }

  onSubmit = (e) => {
    if (e.detail.success && e.detail?.formSubmission?.formElement?.dataset?.closeOnSubmit !== 'false') {
      this.close()
    }
  }

  onEscKey = async (e) => {
    if (e.code !== 'Escape') return

    e.preventDefault()
    e.stopPropagation()

    if (document.querySelector('.app-confirm-modal')) {
      return
    }

    if (!(await this.confirmDiscardIfNeeded())) {
      return
    }

    this.close()
  }

  close = (e) => {
    e?.preventDefault()

    this.remove()
  }

  async confirmDiscardIfNeeded () {
    if (this.dataset.unsavedSignature !== 'true') return true

    const message = this.dataset.unsavedClosePrompt || ''

    if (!message) return true

    return showConfirmModal(message, {
      title: this.dataset.unsavedCloseTitle || '',
      confirmText: this.dataset.unsavedCloseConfirm || 'OK',
      cancelText: this.dataset.unsavedCloseCancel || 'Cancel',
      variant: 'neutral'
    })
  }
})
