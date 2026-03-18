<template>
  <div>
    <div class="relative">
      <img
        :src="previewImage.url"
        :width="previewImage.metadata.width"
        :height="previewImage.metadata.height"
        class="rounded border"
        loading="lazy"
      >
      <div
        class="group flex justify-end cursor-pointer top-0 bottom-0 left-0 right-0 absolute p-1 hover:bg-black/10 transition-colors rounded"
        @click="$emit('scroll-to', item)"
      >
        <div
          v-if="editable"
          class="flex justify-between w-full"
        >
          <div
            style="width: 26px"
            class="flex flex-col"
          >
            <div>
              <button
                class="btn border-[#1f2937] bg-[#0b1a33] text-primary-content btn-xs rounded hover:text-secondary-content hover:bg-secondary hover:border-secondary w-full transition-colors p-0 document-control-button"
                @click.stop="isShowConditionsModal = true"
              >
                <IconRouteAltLeft
                  :width="14"
                  :stroke-width="1.6"
                />
              </button>
            </div>
          </div>
          <div class="">
            <ReplaceButton
              v-if="withReplaceButton"
              :template-id="template.id"
              :accept-file-types="acceptFileTypes"
              class="opacity-0 group-hover:opacity-100"
              @click.stop
              @success="$emit('replace', { replaceSchemaItem: item, ...$event })"
            />
          </div>
          <div
            class="flex flex-col justify-between opacity-0 group-hover:opacity-100"
          >
            <div>
              <button
                class="btn border-[#1f2937] bg-[#0b1a33] text-primary-content btn-xs rounded hover:text-secondary-content hover:bg-secondary hover:border-secondary w-full transition-colors document-control-button"
                style="width: 24px; height: 24px"
                @click.stop="$emit('remove', item)"
              >
                &times;
              </button>
            </div>
            <div
              class="flex flex-col space-y-1"
            >
              <span
                :data-tip="t('reorder_fields')"
                class="tooltip tooltip-left before:text-xs"
              >
                <button
                  class="btn border-[#1f2937] bg-[#0b1a33] text-primary-content btn-xs rounded hover:text-secondary-content hover:bg-secondary hover:border-secondary w-full transition-colors p-0 document-control-button"
                  @click.stop="$emit('reorder', item)"
                >
                  <IconSortDescending2
                    :width="18"
                    :height="18"
                    :stroke-width="1.6"
                  />
                </button>
              </span>
              <template v-if="withArrows">
                <button
                  class="btn border-[#1f2937] bg-[#0b1a33] text-primary-content btn-xs rounded hover:text-secondary-content hover:bg-secondary hover:border-secondary w-full transition-colors document-control-button"
                  style="width: 24px; height: 24px"
                  @click.stop="$emit('up', item)"
                >
                  &uarr;
                </button>
                <button
                  class="btn border-[#1f2937] bg-[#0b1a33] text-primary-content btn-xs rounded hover:text-secondary-content hover:bg-secondary hover:border-secondary w-full transition-colors document-control-button"
                  style="width: 24px; height: 24px"
                  @click.stop="$emit('down', item)"
                >
                  &darr;
                </button>
              </template>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="flex items-center gap-1 pb-2 pt-1.5 document-preview-name">
      <GoogleDriveDocumentSettings
        v-if="item.google_drive_file_id"
        :template-id="template.id"
        :google-drive-file-id="item.google_drive_file_id"
        @success="$emit('replace', { replaceSchemaItem: item, ...$event })"
      />
      <Contenteditable
        :model-value="item.name"
        :icon-width="16"
        :icon-inline="true"
        :float-icon="!item.google_drive_file_id"
        :hide-icon="!item.google_drive_file_id"
        :editable="editable"
        class="mx-auto"
        @update:model-value="onUpdateName"
      />
    </div>
    <Teleport
      v-if="isShowConditionsModal"
      :to="modalContainerEl"
    >
      <ConditionsModal
        :item="item"
        :build-default-name="buildDefaultName"
        @save="$emit('change')"
        @close="isShowConditionsModal = false"
      />
    </Teleport>
  </div>
</template>

<script>
import Contenteditable from './contenteditable'
import Upload from './upload'
import { IconRouteAltLeft, IconSortDescending2, IconDotsVertical, IconTrashX, IconBolt, IconInnerShadowTop } from '@tabler/icons-vue'
import ConditionsModal from './conditions_modal'
import ReplaceButton from './replace'
import GoogleDriveDocumentSettings from './google_drive_document_settings'
import Field from './field'
import FieldType from './field_type'
import { v4 } from 'uuid'

export default {
  name: 'DocumentPreview',
  components: {
    Contenteditable,
    IconInnerShadowTop,
    IconRouteAltLeft,
    ConditionsModal,
    ReplaceButton,
    GoogleDriveDocumentSettings,
    IconSortDescending2,
    IconDotsVertical,
    IconTrashX,
    IconBolt
  },
  inject: ['t', 'getFieldTypeIndex', 'baseFetch'],
  props: {
    item: {
      type: Object,
      required: true
    },
    template: {
      type: Object,
      required: true
    },
    document: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    acceptFileTypes: {
      type: String,
      required: false,
      default: 'image/*, application/pdf, application/zip, application/json'
    },
    withReplaceButton: {
      type: Boolean,
      required: true,
      default: true
    },
    dynamicDocuments: {
      type: Array,
      required: true
    },
    withDynamicDocuments: {
      type: Boolean,
      required: false,
      default: false
    },
    withArrows: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  emits: ['scroll-to', 'change', 'remove', 'up', 'down', 'replace', 'reorder'],
  data () {
    return {
      isShowConditionsModal: false,
      isMakeDynamicLoading: false,
      renderDropdown: false
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldLabels: FieldType.computed.fieldLabels,
    previewImage () {
      return [...this.document.preview_images].sort((a, b) => parseInt(a.filename) - parseInt(b.filename))[0]
    },
    modalContainerEl () {
      return this.$el.getRootNode().querySelector('#docuseal_modal_container')
    }
  },
  methods: {
    upload: Upload.methods.upload,
    buildDefaultName: Field.methods.buildDefaultName,
    closeDropdown () {
      this.$el.getRootNode().activeElement.blur()
    },
    makeDynamic () {
      this.isMakeDynamicLoading = true

      Promise.all([
        this.baseFetch(`/templates/${this.template.id}/dynamic_documents`, {
          method: 'POST',
          body: JSON.stringify({ uuid: this.document.uuid }),
          headers: {
            'Content-Type': 'application/json'
          }
        }),
        import(/* webpackChunkName: "dynamic-editor" */ './dynamic_document')
      ]).then(async ([resp, _]) => {
        const dynamicDocument = await resp.json()

        this.template.schema.find((item) => item.attachment_uuid === dynamicDocument.uuid).dynamic = true

        this.removeFieldAreas()

        if (dynamicDocument.fields?.length) {
          this.addDynamicFields(dynamicDocument.fields)
        }

        if (dynamicDocument.uuid) {
          delete dynamicDocument.fields

          this.dynamicDocuments.push(dynamicDocument)
        }

        this.$emit('change')
      }).finally(() => {
        this.isMakeDynamicLoading = false
      })
    },
    removeFieldAreas () {
      this.template.fields.forEach((field) => {
        if (field.areas?.length) {
          field.areas = field.areas.filter((a) => a.attachment_uuid !== this.document.uuid)
        }
      })

      this.template.fields = this.template.fields.filter((field) => field.areas?.length)
    },
    addDynamicFields (fields) {
      const submittersNameIndex = this.template.submitters.reduce((acc, submitter) => {
        acc[submitter.name] = submitter

        return acc
      }, {})

      fields.forEach((field) => {
        const roleName = field.role || this.template.submitters[0]?.name || this.t('first_party')

        let submitter = submittersNameIndex[roleName]

        if (!submitter) {
          submitter = { name: roleName, uuid: v4() }

          this.template.submitters.push(submitter)

          submittersNameIndex[roleName] = submitter
        }

        const existingField = this.template.fields.find((f) => {
          return f.name && f.name === field.name && f.type === (field.type || 'text') && f.submitter_uuid === submitter.uuid
        })

        if (existingField) {
          field.areas.forEach((area) => {
            area.attachment_uuid = this.document.uuid

            existingField.areas = existingField.areas || []
            existingField.areas.push(area)
          })
        } else {
          field.submitter_uuid = submitter.uuid

          delete field.role

          field.areas.forEach((area) => {
            area.attachment_uuid = this.document.uuid
          })

          this.template.fields.push(field)
        }
      })
    },
    onUpdateName (value) {
      this.item.name = value

      this.$emit('change')
    }
  }
}
</script>
