import autocomplete from 'autocompleter'

export default class extends HTMLElement {
  connectedCallback () {
    if (this.dataset.enabled === 'false') return
    if (this.autocompleteInstance) return

    const menuInTplForm = !!this.input?.closest('.tpl-new-folder-picker')

    this.autocompleteInstance = autocomplete({
      input: this.input,
      className: menuInTplForm ? 'tpl-new-folder-autocomplete-menu' : '',
      customize: menuInTplForm ? this.alignPickerMenu : undefined,
      disableAutoSelect: menuInTplForm,
      preventSubmit: this.dataset.submitOnSelect === 'true' ? 0 : 1,
      minLength: 0,
      showOnFocus: !menuInTplForm,
      click: menuInTplForm ? ({ fetch }) => fetch() : undefined,
      onSelect: (item) => {
        this.onSelect(item)
        this.setPickerOpen(false)
      },
      render: this.render,
      fetch: this.fetch
    })

    if (menuInTplForm) {
      this.changeFolderLink = this.querySelector('.tpl-new-change-folder-link')
      this.changeFolderLink?.addEventListener('click', this.onChangeFolderClick)
      this.input.addEventListener('blur', this.onInputBlur)
    }
  }

  disconnectedCallback () {
    this.autocompleteInstance?.destroy()
    this.autocompleteInstance = null
    this.changeFolderLink?.removeEventListener('click', this.onChangeFolderClick)
    this.input?.removeEventListener('blur', this.onInputBlur)
  }

  onChangeFolderClick = () => {
    window.requestAnimationFrame(() => {
      this.autocompleteInstance?.fetch()
    })
  }

  onInputBlur = () => {
    window.setTimeout(() => {
      if (document.activeElement !== this.input) {
        this.setPickerOpen(false)
      }
    }, 200)
  }

  setPickerOpen = (open) => {
    const picker = this.input?.closest('.tpl-new-folder-picker')
    if (!picker) return

    picker.classList.toggle('tpl-new-folder-picker--open', open)
  }

  alignPickerMenu = (input, _inputRect, container, maxHeight) => {
    const picker = input.closest('.tpl-new-folder-picker')
    if (!picker) return

    const pickerRect = picker.getBoundingClientRect()
    const viewportSpace = window.innerHeight - pickerRect.bottom - 8

    container.style.position = 'fixed'
    container.style.width = `${pickerRect.width}px`
    container.style.left = `${pickerRect.left}px`
    container.style.top = `${pickerRect.bottom}px`
    container.style.maxHeight = `${Math.max(120, Math.min(maxHeight, viewportSpace))}px`
    container.style.zIndex = '10001'

    this.setPickerOpen(true)
  }

  onSelect = (item) => {
    this.input.value = this.dataset.parentName ? item.name : item.full_name
  }

  fetch = (text, resolve) => {
    const queryParams = new URLSearchParams({ q: text })

    if (this.dataset.parentName) {
      queryParams.append('parent_name', this.dataset.parentName)
    }

    fetch('/template_folders_autocomplete?' + queryParams).then(async (resp) => {
      const items = await resp.json()

      resolve(items)
    }).catch(() => {
      resolve([])
    })
  }

  render = (item) => {
    const div = document.createElement('div')

    div.setAttribute('dir', 'auto')

    div.textContent = this.dataset.parentName ? item.name : item.full_name

    return div
  }

  get input () {
    return this.querySelector('input')
  }
}
