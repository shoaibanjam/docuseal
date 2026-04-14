const CONTAINER_ID = 'app-toast-container'
const DEFAULT_DURATION = 3500

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
  closeButton.innerHTML = '&times;'

  toast.append(messageEl, closeButton)

  container.appendChild(toast)

  requestAnimationFrame(() => {
    toast.classList.add('is-visible')
  })

  let isClosed = false

  const closeToast = () => {
    if (isClosed) return
    isClosed = true
    toast.classList.remove('is-visible')

    window.setTimeout(() => {
      toast.remove()

      if (!container.childElementCount) {
        container.remove()
      }
    }, 180)
  }

  closeButton.addEventListener('click', closeToast)
  window.setTimeout(closeToast, duration)
}
