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

  toast.className = `app-toast app-toast--${type}`
  toast.setAttribute('role', 'status')
  toast.setAttribute('aria-live', 'polite')
  toast.textContent = String(message)

  container.appendChild(toast)

  requestAnimationFrame(() => {
    toast.classList.add('is-visible')
  })

  const closeToast = () => {
    toast.classList.remove('is-visible')

    window.setTimeout(() => {
      toast.remove()

      if (!container.childElementCount) {
        container.remove()
      }
    }, 180)
  }

  window.setTimeout(closeToast, duration)
}
