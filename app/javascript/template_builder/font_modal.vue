<template>
  <div class="modal modal-open modal--signature-editor !animate-none overflow-y-auto">
    <div
      class="turbo-modal-backdrop absolute inset-0 cursor-pointer z-0"
      aria-hidden="true"
      @click.prevent="$emit('close')"
    />
    <div class="modal-box pt-4 pb-6 px-6 mt-20 max-h-none relative z-10 w-full modal-box--signature-editor modal-box--font-field">
      <header class="signature-modal__header">
        <div class="signature-modal__title-row">
          <h2 class="signature-modal__title">
            {{ t('font') }} - {{ (defaultField ? (defaultField.title || field.title || field.name) : field.name) || buildDefaultName(field) }}
          </h2>
          <button
            type="button"
            class="signature-modal__close"
            :aria-label="t('close', 'Close')"
            @click.prevent="$emit('close')"
          >
            <IconX
              class="w-5 h-5"
              stroke-width="1.75"
            />
          </button>
        </div>
        <div
          class="signature-modal__head-divider"
          aria-hidden="true"
        />
      </header>
      <div class="signature-modal__body">
        <form
          class="tpl-new-form font-modal"
          @submit.prevent="saveAndClose"
        >
          <div class="font-modal__toolbar">
            <div class="font-modal__toolbar-row">
              <div class="dropdown font-modal__font-dropdown">
                <label
                  tabindex="0"
                  class="base-input font-modal__font-select"
                  :class="fonts.find((f) => f.value === preferences.font)?.class"
                >
                  <span class="font-modal__font-select-label">
                    {{ preferences.font || 'Default' }}
                  </span>
                  <IconChevronDown
                    class="font-modal__font-select-icon"
                    width="18"
                    height="18"
                  />
                </label>
                <div
                  tabindex="0"
                  class="dropdown-content font-modal__dropdown-menu menu z-10"
                >
                  <div
                    v-for="(font, index) in fonts"
                    :key="index"
                    :value="font.value"
                    :class="{ 'font-modal__dropdown-item--active': preferences.font == font.value, [font.class]: true }"
                    class="font-modal__dropdown-item"
                    @click="[font.value ? preferences.font = font.value : delete preferences.font, closeDropdown()]"
                  >
                    {{ font.label }}
                  </div>
                </div>
              </div>

              <div class="font-modal__size-field">
                <select
                  class="base-select font-modal__size-select"
                  @change="$event.target.value ? preferences.font_size = parseInt($event.target.value) : delete preferences.font_size"
                >
                  <option
                    :selected="!preferences.font_size"
                    value=""
                  >
                    Auto
                  </option>
                  <option
                    v-for="size in sizes"
                    :key="size"
                    :value="size"
                    :selected="size === preferences.font_size"
                  >
                    {{ size }}
                  </option>
                </select>
                <span class="font-modal__size-suffix">pt</span>
              </div>

              <div
                class="font-modal__tool-group"
                role="group"
                :aria-label="t('font_style', 'Font style')"
              >
                <button
                  v-for="(type, index) in types"
                  :key="index"
                  type="button"
                  class="font-modal__tool-btn"
                  :class="{ 'font-modal__tool-btn--active': preferences.font_type?.includes(type.value) }"
                  @click="setFontType(type.value)"
                >
                  <component :is="type.icon" />
                </button>
              </div>
            </div>

            <div class="font-modal__toolbar-row">
              <div
                class="font-modal__tool-group"
                role="group"
                :aria-label="t('alignment', 'Alignment')"
              >
                <button
                  v-for="(align, index) in aligns"
                  :key="index"
                  type="button"
                  class="font-modal__tool-btn"
                  :class="{ 'font-modal__tool-btn--active': preferences.align === align.value }"
                  @click="align.value && preferences.align != align.value ? preferences.align = align.value : delete preferences.align"
                >
                  <component :is="align.icon" />
                </button>
              </div>

              <div class="dropdown font-modal__valign-dropdown">
                <label
                  tabindex="0"
                  class="font-modal__tool-btn font-modal__tool-btn--menu"
                >
                  <component :is="valigns.find((v) => v.value === (preferences.valign || 'center'))?.icon" />
                </label>
                <div
                  tabindex="0"
                  class="dropdown-content font-modal__dropdown-menu font-modal__dropdown-menu--compact menu z-10"
                >
                  <div
                    v-for="(valign, index) in valigns"
                    :key="index"
                    :value="valign.value"
                    :class="{ 'font-modal__dropdown-item--active': preferences.valign == valign.value }"
                    class="font-modal__dropdown-item font-modal__dropdown-item--icon"
                    @click="[valign.value ? preferences.valign = valign.value : delete preferences.valign, closeDropdown()]"
                  >
                    <component :is="valign.icon" />
                  </div>
                </div>
              </div>

              <select
                class="base-select font-modal__color-select"
                @change="$event.target.value ? preferences.color = $event.target.value : delete preferences.color"
              >
                <option
                  v-for="(color, index) in colors"
                  :key="index"
                  :value="color.value"
                  :selected="color.value == preferences.color"
                >
                  {{ color.label }}
                </option>
              </select>
            </div>
          </div>

          <div
            class="font-modal__preview"
            :class="[{
              'font-modal__preview--white-text': preferences.color === 'white'
            }, textClasses]"
            :style="previewStyle"
          >
            <span
              contenteditable="true"
              class="font-modal__preview-text"
            >
              {{ field.default_value || field.name || buildDefaultName(field) }}
            </span>
          </div>

          <div class="form-control mt-1">
            <button class="base-button profile-settings-btn-primary tpl-new-submit-btn">
              {{ t('save') }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import { IconChevronDown, IconBold, IconItalic, IconAlignLeft, IconAlignRight, IconAlignCenter, IconAlignBoxCenterTop, IconAlignBoxCenterBottom, IconAlignBoxCenterMiddle, IconX } from '@tabler/icons-vue'

const previewColorMap = {
  black: '#111827',
  white: '#ffffff',
  blue: '#2563eb',
  red: '#dc2626'
}

export default {
  name: 'FontModal',
  components: {
    IconChevronDown,
    IconX
  },
  inject: ['t', 'template'],
  props: {
    field: {
      type: Object,
      required: true
    },
    defaultField: {
      type: Object,
      required: false,
      default: null
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    buildDefaultName: {
      type: Function,
      required: true
    }
  },
  emits: ['close', 'save'],
  data () {
    return {
      preferences: {}
    }
  },
  computed: {
    fonts () {
      return [
        { value: null, label: 'Default' },
        { value: 'Times', label: 'Times', class: 'font-times' },
        { value: 'Courier', label: 'Courier', class: 'font-courier' }
      ]
    },
    types () {
      return [
        { icon: IconBold, value: 'bold' },
        { icon: IconItalic, value: 'italic' }
      ]
    },
    aligns () {
      return [
        { icon: IconAlignLeft, value: 'left' },
        { icon: IconAlignCenter, value: 'center' },
        { icon: IconAlignRight, value: 'right' }
      ]
    },
    valigns () {
      return [
        { icon: IconAlignBoxCenterTop, value: 'top' },
        { icon: IconAlignBoxCenterMiddle, value: 'center' },
        { icon: IconAlignBoxCenterBottom, value: 'bottom' }
      ]
    },
    sizes () {
      return [...Array(23).keys()].map(i => i + 6)
    },
    colors () {
      return [
        { label: '⬛', value: 'black' },
        { label: '⬜', value: 'white' },
        { label: '🟦', value: 'blue' },
        { label: '🟥', value: 'red' }
      ]
    },
    previewStyle () {
      const style = {
        fontSize: `${this.preferences.font_size || 11}pt`
      }

      if (this.preferences.color && previewColorMap[this.preferences.color]) {
        style.color = previewColorMap[this.preferences.color]
      }

      return style
    },
    textClasses () {
      return {
        'font-courier': this.preferences.font === 'Courier',
        'font-times': this.preferences.font === 'Times',
        'justify-center': this.preferences.align === 'center',
        'justify-start': this.preferences.align === 'left',
        'justify-end': this.preferences.align === 'right',
        'items-center': !this.preferences.valign || this.preferences.valign === 'center',
        'items-start': this.preferences.valign === 'top',
        'items-end': this.preferences.valign === 'bottom',
        'font-bold': ['bold_italic', 'bold'].includes(this.preferences.font_type),
        italic: ['bold_italic', 'italic'].includes(this.preferences.font_type)
      }
    },
    keys () {
      return ['font_type', 'font_size', 'color', 'align', 'valign', 'font']
    }
  },
  created () {
    this.preferences = this.keys.reduce((acc, key) => {
      acc[key] = this.field.preferences?.[key]

      return acc
    }, {})
  },
  mounted () {
    document.body.classList.add('overflow-hidden')
  },
  unmounted () {
    document.body.classList.remove('overflow-hidden')
  },
  methods: {
    closeDropdown () {
      this.$el.getRootNode().activeElement.blur()
    },
    setFontType (value) {
      if (value === 'bold') {
        if (this.preferences.font_type === 'bold') {
          delete this.preferences.font_type
        } else if (this.preferences.font_type === 'italic') {
          this.preferences.font_type = 'bold_italic'
        } else if (this.preferences.font_type === 'bold_italic') {
          this.preferences.font_type = 'italic'
        } else {
          this.preferences.font_type = value
        }
      }

      if (value === 'italic') {
        if (this.preferences.font_type === 'italic') {
          delete this.preferences.font_type
        } else if (this.preferences.font_type === 'bold') {
          this.preferences.font_type = 'bold_italic'
        } else if (this.preferences.font_type === 'bold_italic') {
          this.preferences.font_type = 'bold'
        } else {
          this.preferences.font_type = value
        }
      }
    },
    saveAndClose () {
      this.field.preferences ||= {}

      this.keys.forEach((key) => delete this.field.preferences[key])

      Object.assign(this.field.preferences, this.preferences)

      this.$emit('save')
      this.$emit('close')
    }
  }
}
</script>
