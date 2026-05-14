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
            {{ t('condition') }} - {{ (defaultField ? (defaultField.title || item.title || item.name) : item.name) || buildDefaultName(item) }}
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
        <div
          v-if="!withConditions"
          class="tpl-new-form"
        >
          <p class="signature-editor__lead text-center">
            <a
              href="https://www.docuseal.com/pricing"
              target="_blank"
              class="link"
            >{{ t('available_in_pro') }}</a>
          </p>
        </div>
        <form
          class="tpl-new-form"
          @submit.prevent="validateSaveAndClose"
        >
          <div class="form-control mt-4">
            <div
              v-for="(condition, cindex) in conditions"
              :key="cindex"
              class="space-y-4 relative"
            >
              <div
                v-if="cindex > 0"
                class="divider -mb-2 mx-1"
              >
                <button
                  class="btn btn-xs btn-primary w-24"
                  @click.prevent="condition.operation === 'or' ? delete condition.operation : condition.operation = 'or'"
                >
                  {{ condition.operation === 'or' ? t('or') : t('and') }}
                </button>
              </div>
              <div
                v-if="conditions.length > 1"
                class="flex justify-between mx-1"
              >
                <label class="text-sm">
                  {{ t('condition') }} {{ cindex + 1 }}
                </label>
                <a
                  href="#"
                  class="link text-sm"
                  @click.prevent="conditions.splice(cindex, 1)"
                > {{ t('remove') }}</a>
              </div>
              <div class="form-control">
                <label
                  class="label"
                  :for="`condition-${cindex}-field`"
                >
                  {{ t('field') }}
                </label>
                <select
                  :id="`condition-${cindex}-field`"
                  class="base-select w-full"
                  :class="{ 'base-select--placeholder': !condition.field_uuid }"
                  required
                  @change="[
                    condition.field_uuid = $event.target.value || undefined,
                    delete condition.value,
                    delete condition.action
                  ]"
                >
                  <option
                    value=""
                    disabled
                    hidden
                    :selected="!condition.field_uuid"
                  >
                    {{ t('select_field_') }}
                  </option>
                  <option
                    v-for="f in fields"
                    :key="f.uuid"
                    :value="f.uuid"
                    class="text-base-content"
                    :selected="condition.field_uuid === f.uuid"
                  >
                    {{ f.name || buildDefaultName(f) }}
                  </option>
                </select>
              </div>
              <div class="form-control">
                <label
                  class="label"
                  :for="`condition-${cindex}-action`"
                >
                  {{ t('action') }}
                </label>
                <select
                  :id="`condition-${cindex}-action`"
                  class="base-select w-full"
                  :class="{ 'base-select--placeholder': !!condition.field_uuid && !condition.action }"
                  :disabled="!condition.field_uuid"
                  :required="!!condition.field_uuid"
                  @change="condition.action = $event.target.value || undefined"
                >
                  <option
                    v-if="!condition.field_uuid"
                    value=""
                    disabled
                    hidden
                    selected
                  ></option>
                  <option
                    v-else-if="!condition.action"
                    value=""
                    disabled
                    hidden
                    selected
                  >
                    {{ t('select_action_') }}
                  </option>
                  <option
                    v-for="action in conditionActions(condition)"
                    :key="action"
                    :value="action"
                    :selected="condition.action === action"
                  >
                    {{ t(action) }}
                  </option>
                </select>
              </div>
              <div
                v-if="['radio', 'select', 'multiple'].includes(conditionField(condition)?.type) && conditionField(condition)?.options"
                class="form-control"
              >
                <label
                  class="label"
                  :for="`condition-${cindex}-value`"
                >
                  {{ t('value') }}
                </label>
                <select
                  :id="`condition-${cindex}-value`"
                  v-model="condition.value"
                  class="base-select w-full"
                  :class="{ 'base-select--placeholder': !condition.value }"
                  required
                >
                  <option
                    value=""
                    disabled
                    hidden
                  >
                    {{ t('select_value_') }}
                  </option>
                  <option
                    v-for="(option, index) in conditionField(condition).options"
                    :key="option.uuid"
                    :value="option.uuid"
                    class="text-base-content"
                  >
                    {{ option.value || `${t('option')} ${index + 1}` }}
                  </option>
                </select>
              </div>
              <div
                v-else-if="conditionField(condition)?.type === 'number' && ['equal', 'not_equal', 'greater_than', 'less_than'].includes(condition.action)"
                class="form-control"
              >
                <label
                  class="label"
                  :for="`condition-${cindex}-value`"
                >
                  {{ t('value') }}
                </label>
                <input
                  :id="`condition-${cindex}-value`"
                  v-model="condition.value"
                  type="number"
                  step="any"
                  class="base-input w-full"
                  :placeholder="t('type_value')"
                  required
                >
              </div>
            </div>
          </div>
          <a
            href="#"
            class="inline float-right link text-right mb-3 px-2"
            @click.prevent="conditions.push({})"
          > + {{ t('add_condition') }}</a>
          <div class="form-control mt-1">
            <button class="base-button tpl-new-submit-btn">
              {{ t('save') }}
            </button>
          </div>
        </form>
        <div
          v-if="item.conditions?.[0]?.field_uuid"
          class="text-center w-full mt-4"
        >
          <button
            class="link"
            @click="[conditions = [], delete item.conditions, validateSaveAndClose()]"
          >
            {{ t('remove_condition') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { IconX } from '@tabler/icons-vue'

export default {
  name: 'ConditionModal',
  components: {
    IconX
  },
  inject: ['t', 'template', 'withConditions'],
  props: {
    item: {
      type: Object,
      required: true
    },
    defaultField: {
      type: Object,
      required: false,
      default: null
    },
    buildDefaultName: {
      type: Function,
      required: true
    },
    excludeFieldUuids: {
      type: Array,
      required: false,
      default: () => []
    }
  },
  emits: ['close', 'save'],
  data () {
    return {
      conditions: this.item.conditions?.[0] ? JSON.parse(JSON.stringify(this.item.conditions)) : [{}]
    }
  },
  computed: {
    excludeTypes () {
      return ['heading', 'strikethrough']
    },
    fields () {
      if (this.item.submitter_uuid) {
        return this.template.fields.reduce((acc, f) => {
          if (f !== this.item && !this.excludeTypes.includes(f.type) && !this.excludeFieldUuids.includes(f.uuid) && (!f.conditions?.length || !f.conditions.find((c) => c.field_uuid === this.item.uuid))) {
            acc.push(f)
          }

          return acc
        }, [])
      } else {
        return this.template.fields.filter((f) => !this.excludeFieldUuids.includes(f.uuid))
      }
    }
  },
  created () {
    this.item.conditions ||= []
  },
  mounted () {
    document.body.classList.add('overflow-hidden')
  },
  unmounted () {
    document.body.classList.remove('overflow-hidden')
  },
  methods: {
    conditionField (condition) {
      return this.fields.find((f) => f.uuid === condition.field_uuid)
    },
    conditionActions (condition) {
      return this.fieldActions(this.conditionField(condition))
    },
    fieldActions (field) {
      const actions = []

      if (!field) {
        return actions
      }

      if (field.type === 'checkbox') {
        actions.push('checked', 'unchecked')
      } else if (['radio', 'select'].includes(field.type)) {
        actions.push('equal', 'not_equal')
      } else if (['multiple'].includes(field.type)) {
        actions.push('contains', 'does_not_contain')
      } else if (field.type === 'number') {
        actions.push('not_empty', 'empty', 'equal', 'not_equal', 'greater_than', 'less_than')
      } else {
        actions.push('not_empty', 'empty')
      }

      return actions
    },
    validateSaveAndClose () {
      if (!this.withConditions) {
        return window.showToast(this.t('available_only_in_pro'))
      }

      if (this.conditions.find((f) => f.field_uuid)) {
        this.item.conditions = this.conditions
      } else {
        delete this.item.conditions
      }

      this.$emit('save')
      this.$emit('close')
    }
  }
}
</script>
