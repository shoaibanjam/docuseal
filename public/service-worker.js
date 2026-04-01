self.addEventListener('install', () => {
  console.log('Trustseal App installed')
})

self.addEventListener('activate', () => {
  console.log('Trustseal App activated')
})

self.addEventListener('fetch', (event) => {
  event.respondWith(fetch(event.request))
})
