<template>
  <div class="modal modal-open modal--signature-editor !animate-none overflow-y-auto">
    <div
      class="turbo-modal-backdrop absolute inset-0 cursor-pointer z-0"
      aria-hidden="true"
      @click.prevent="$emit('close')"
    />
    <div class="modal-box pt-4 pb-6 px-6 mt-20 max-h-none relative z-10 w-full modal-box--signature-editor modal-box--decline">
      <header class="signature-modal__header">
        <div class="signature-modal__title-row">
          <h2 class="signature-modal__title">
            {{ (defaultField ? (defaultField.title || field.title || field.name) : field.name) || buildDefaultName(field) }}
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
          class="tpl-new-form"
          @submit.prevent="saveAndClose"
        >
          <div class="form-control">
            <label
              dir="auto"
              class="label"
              for="description_field"
            >
              {{ t('description') }}
            </label>
            <textarea
              id="description_field"
              ref="textarea"
              v-model="description"
              dir="auto"
              class="base-input w-full"
              :placeholder="t('description')"
              :readonly="!editable"
              @input="resizeTextarea"
            />
          </div>
          <div class="form-control">
            <label
              dir="auto"
              class="label"
              for="title_field"
            >
              {{ t('display_title') }} ({{ t('optional') }})
            </label>
            <input
              id="title_field"
              v-model="title"
              dir="auto"
              :readonly="!editable"
              class="base-input w-full"
              :placeholder="t('display_title')"
            >
          </div>
          <div class="form-control mt-1">
            <button class="base-button tpl-new-submit-btn">
              {{ t('save') }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import { IconX } from '@tabler/icons-vue'

export default {
  name: 'DescriptionModal',
  components: {
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
      description: this.field.description,
      title: this.field.title
    }
  },
  mounted () {
    document.body.classList.add('overflow-hidden')
    this.resizeTextarea()
  },
  unmounted () {
    document.body.classList.remove('overflow-hidden')
  },
  methods: {
    saveAndClose () {
      this.field.description = this.description
      this.field.title = this.title

      this.$emit('save')
      this.$emit('close')
    },
    resizeTextarea () {
      const textarea = this.$refs.textarea

      textarea.style.height = 'auto'
      textarea.style.height = textarea.scrollHeight + 'px'
    }
  }
}
</script>
