const CONTAINER_ID = 'app-toast-container'
const DEFAULT_DURATION = 1500

const CLOSE_ICON_SVG =
  '<svg xmlns="http://www.w3.org/2000/svg" class="app-toast-close__icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" aria-hidden="true"><path d="M18 6l-12 12"></path><path d="M6 6l12 12"></path></svg>'

const getContainer = () => {
  let container = document.getElementById(CONTAINER_ID)

  if (!container) {
    container = document.createElement('div')
    container.id = CONTAINER_ID
    container.className = 'app-toast-container'
    document.body.appendChild(container)
  }

  return container
}

const removeToast = (container, toast) => {
  toast.classList.remove('is-visible')

  window.setTimeout(() => {
    toast.remove()

    if (!container.childElementCount) {
      container.remove()
    }
  }, 180)
}

export const showToast = (message, { type = 'error', duration = DEFAULT_DURATION } = {}) => {
  if (!message) return

  const container = getContainer()
  const toast = document.createElement('div')
  const messageEl = document.createElement('span')
  const closeButton = document.createElement('button')

  toast.className = `app-toast app-toast--${type}`
  toast.setAttribute('role', 'status')
  toast.setAttribute('aria-live', 'polite')
  messageEl.className = 'app-toast-message'
  messageEl.textContent = String(message)
  closeButton.type = 'button'
  closeButton.className = 'app-toast-close'
  closeButton.setAttribute('aria-label', 'Close notification')
  closeButton.innerHTML = CLOSE_ICON_SVG

  toast.append(messageEl, closeButton)

  container.appendChild(toast)

  requestAnimationFrame(() => {
    toast.classList.add('is-visible')
  })

  let isClosed = false

  const closeToast = () => {
    if (isClosed) return
    isClosed = true
    removeToast(container, toast)
  }

  closeButton.addEventListener('click', closeToast)
  window.setTimeout(closeToast, duration)
}

export const showConfirmToast = (message, { confirmText = 'OK', cancelText = 'Cancel' } = {}) => {
  return new Promise((resolve) => {
    const container = getContainer()
    const toast = document.createElement('div')
    const messageEl = document.createElement('span')
    const actionsEl = document.createElement('div')
    const cancelButton = document.createElement('button')
    const confirmButton = document.createElement('button')
    const closeButton = document.createElement('button')

    toast.className = 'app-toast app-toast--error app-toast--confirm'
    toast.setAttribute('role', 'alertdialog')
    toast.setAttribute('aria-live', 'polite')

    messageEl.className = 'app-toast-message'
    messageEl.textContent = String(message)

    actionsEl.className = 'app-toast-actions'

    cancelButton.type = 'button'
    cancelButton.className = 'app-toast-action app-toast-action--cancel'
    cancelButton.textContent = cancelText

    confirmButton.type = 'button'
    confirmButton.className = 'app-toast-action app-toast-action--confirm'
    confirmButton.textContent = confirmText

    closeButton.type = 'button'
    closeButton.className = 'app-toast-close'
    closeButton.setAttribute('aria-label', 'Close notification')
    closeButton.innerHTML = CLOSE_ICON_SVG

    actionsEl.append(cancelButton, confirmButton)
    toast.append(messageEl, actionsEl, closeButton)
    container.appendChild(toast)

    requestAnimationFrame(() => {
      toast.classList.add('is-visible')
    })

    let isResolved = false

    const closeWith = (result) => {
      if (isResolved) return
      isResolved = true
      resolve(result)
      removeToast(container, toast)
    }

    cancelButton.addEventListener('click', () => closeWith(false))
    closeButton.addEventListener('click', () => closeWith(false))
    confirmButton.addEventListener('click', () => closeWith(true))
  })
}
