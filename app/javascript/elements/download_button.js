import { target, targetable } from '@github/catalyst/lib/targetable'

export default targetable(class extends HTMLElement {
  static [target.static] = ['defaultButton', 'loadingButton']

  connectedCallback () {
    this.addEventListener('click', () => this.downloadFiles())
  }

  toggleState () {
    this.defaultButton?.classList?.toggle('hidden')
    this.loadingButton?.classList?.toggle('hidden')
  }

  resolveDownloadFileUrl (url) {
    if (!url) return url

    try {
      const base = new URL(window.location.href)
      const resolved = new URL(String(url), base)

      if (resolved.pathname.startsWith('/file/')) {
        return `${base.origin}${resolved.pathname}${resolved.search}`
      }
    } catch (_) {}

    return url
  }

  downloadFiles () {
    if (!this.dataset.src) return

    this.toggleState()

    fetch(this.dataset.src).then(async (response) => {
      if (response.ok) {
        const urls = await response.json()
        const isMobileSafariIos = 'ontouchstart' in window && navigator.maxTouchPoints > 0 && /AppleWebKit/i.test(navigator.userAgent)
        const isSafariIos = isMobileSafariIos || /iPhone|iPad|iPod/i.test(navigator.userAgent)

        if (isSafariIos && urls.length > 1) {
          this.downloadSafariIos(urls)
        } else {
          this.downloadUrls(urls)
        }
      } else {
        alert('Failed to download files')
        this.toggleState()
      }
    }).catch(() => {
      alert('Failed to download files')
      this.toggleState()
    })
  }

  downloadUrls (urls) {
    const fileRequests = urls.map((url) => {
      return () => {
        const fileUrl = this.resolveDownloadFileUrl(url)

        return fetch(fileUrl).then(async (resp) => {
          if (!resp.ok) throw new Error('download_failed')

          const blobUrl = URL.createObjectURL(await resp.blob())
          const link = document.createElement('a')

          link.href = blobUrl
          link.setAttribute('download', decodeURI(fileUrl.split('/').pop()))

          link.click()

          URL.revokeObjectURL(blobUrl)
        })
      }
    })

    fileRequests.reduce(
      (prevPromise, request) => prevPromise.then(() => request()),
      Promise.resolve()
    ).catch(() => {
      alert('Failed to download files')
    }).finally(() => {
      this.toggleState()
    })
  }

  downloadSafariIos (urls) {
    const fileRequests = urls.map((url) => {
      const fileUrl = this.resolveDownloadFileUrl(url)

      return fetch(fileUrl).then(async (resp) => {
        if (!resp.ok) throw new Error('download_failed')

        const blob = await resp.blob()
        const blobUrl = URL.createObjectURL(blob.slice(0, blob.size, 'application/octet-stream'))
        const link = document.createElement('a')

        link.href = blobUrl
        link.setAttribute('download', decodeURI(fileUrl.split('/').pop()))

        return link
      })
    })

    Promise.all(fileRequests).then((links) => {
      links.forEach((link, index) => {
        setTimeout(() => {
          link.click()

          URL.revokeObjectURL(link.href)
        }, index * 50)
      })
    }).catch(() => {
      alert('Failed to download files')
    }).finally(() => {
      this.toggleState()
    })
  }
})
