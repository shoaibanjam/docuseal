<template>
  <label
    v-if="!error"
    class="label text-xl sm:text-2xl py-0 mb-2 sm:mb-3.5 field-name-label"
  >
    <MarkdownContent
      v-if="field.title"
      :string="field.title"
    />
    <template v-else>{{ field.name || t('knowledge_based_authentication') }}</template>
    <span
      v-if="questions"
      class="float-right font-normal text-neutral-500 mt-1 whitespace-nowrap text-right text-sm"
    >
      <span>{{ t('question_progress').replace('{current}', currentQuestionIndex + 1).replace('{total}', questions.length) }}</span>
      <span
        v-if="timeLeftSeconds !== null"
        class="block"
      >
        {{ t('time_left').replace('{time}', formattedTimeLeft) }}
      </span>
    </span>
  </label>
  <div
    v-if="field.description"
    dir="auto"
    class="mb-4 px-1 field-description-text"
  >
    <MarkdownContent :string="field.description" />
  </div>
  <div
    v-if="isRequiredFieldEmpty"
    class="px-1 field-description-text"
  >
    {{ t('complete_all_required_fields_to_proceed_with_identity_verification') }}
  </div>
  <div
    v-if="error"
    class="mb-4 text-center"
  >
    <div class="text-xl mb-4">
      {{ error }}
    </div>
    <button
      class="base-button w-full flex justify-center submit-form-button"
      @click="restartKba"
    >
      {{ questions ? t('restart_kba') : t('retry') }}
    </button>
  </div>
  <div
    v-if="isLoading"
    class="w-full flex space-x-2 justify-center mb-2"
  >
    <IconInnerShadowTop
      width="40"
      class="animate-spin h-10"
    />
  </div>
  <div v-else-if="questions && !error">
    <form @submit.prevent="nextQuestion">
      <div class="mb-6 px-1">
        <p class="font-semibold mb-4 text-lg">
          {{ currentQuestion.prompt }}
        </p>
        <div class="space-y-3.5 mx-auto">
          <div
            v-for="(answer, index) in currentQuestion.answers"
            :key="`${currentQuestion.id}_${index}`"
          >
            <label
              :for="`${currentQuestion.id}_${index}`"
              class="flex items-center space-x-3 radio-label"
            >
              <input
                :id="`${currentQuestion.id}_${index}`"
                v-model="answers[currentQuestion.id]"
                type="radio"
                :name="currentQuestion.id"
                :value="answer.text"
                class="base-radio !h-7 !w-7"
                required
              >
              <span class="text-xl">{{ answer.text }}</span>
            </label>
          </div>
        </div>
      </div>
      <div class="mt-6">
        <button
          type="submit"
          class="base-button w-full flex justify-center submit-form-button"
          :disabled="isSubmitting || !answers[currentQuestion.id]"
        >
          <span class="flex">
            <IconInnerShadowTop
              v-if="isSubmitting"
              class="mr-1 animate-spin"
            />
            <span>
              {{ isLastQuestion ? (isSubmitting ? t('submitting_') : t('complete')) : t('next') }}
            </span><span
              v-if="isSubmitting"
              class="w-6 flex justify-start mr-1"
            ><span>...</span></span>
          </span>
        </button>
      </div>
    </form>
  </div>
  <div v-else-if="!error && !isRequiredFieldEmpty">
    <form @submit.prevent="startKba">
      <div class="grid grid-cols-6 gap-x-2 md:gap-x-4 md:gap-y-2 mb-4">
        <div class="col-span-3">
          <label
            for="kba_fn"
            class="label text-sm md:text-base"
          >{{ t('first_name') }}</label>
          <input
            id="kba_fn"
            v-model="form.fn"
            type="text"
            class="input input-bordered !h-10 w-full bg-white text-neutral-900 border-neutral-300 placeholder:text-neutral-900"
            required
          >
        </div>
        <div class="col-span-3">
          <label
            for="kba_ln"
            class="label text-sm md:text-base"
          >{{ t('last_name') }}</label>
          <input
            id="kba_ln"
            v-model="form.ln"
            type="text"
            class="input input-bordered !h-10 w-full bg-white text-neutral-900 border-neutral-300 placeholder:text-neutral-900"
            required
          >
        </div>
        <div class="col-span-6">
          <label
            for="kba_addr"
            class="label text-sm md:text-base"
          >{{ t('address') }}</label>
          <input
            id="kba_addr"
            v-model="form.addr"
            type="text"
            class="input input-bordered !h-10 w-full bg-white text-neutral-900 border-neutral-300 placeholder:text-neutral-900"
            required
          >
        </div>
        <div class="col-span-2">
          <label
            for="kba_city"
            class="label text-sm md:text-base"
          >{{ t('city') }}</label>
          <input
            id="kba_city"
            v-model="form.city"
            type="text"
            class="input input-bordered !h-10 w-full bg-white text-neutral-900 border-neutral-300 placeholder:text-neutral-900"
            required
          >
        </div>
        <div class="col-span-2">
          <label
            for="kba_state"
            class="label text-sm md:text-base"
          >{{ t('state') }}</label>
          <select
            id="kba_state"
            v-model="form.state"
            class="select select-bordered !h-10 min-h-[2.5rem] w-full bg-white text-neutral-900 border-neutral-300 font-normal !text-base"
            required
          >
            <option
              value=""
              disabled
            >
              {{ t('select_state') }}
            </option>
            <option
              v-for="state in states"
              :key="state.code"
              :value="state.code"
            >
              {{ state.name }}
            </option>
          </select>
        </div>
        <div class="col-span-2">
          <label
            for="kba_zip"
            class="label text-sm md:text-base"
          >{{ t('zip') }}</label>
          <input
            id="kba_zip"
            v-model="form.zip"
            type="text"
            dir="ltr"
            class="input input-bordered !h-10 w-full bg-white text-neutral-900 border-neutral-300 placeholder:text-neutral-900"
            required
          >
        </div>
        <div class="col-span-3">
          <label
            for="kba_phone"
            class="label text-sm md:text-base"
          >{{ t('phone') }}</label>
          <input
            id="kba_phone"
            v-model="form.phone"
            type="text"
            dir="ltr"
            class="input input-bordered !h-10 w-full bg-white text-neutral-900 border-neutral-300 placeholder:text-neutral-900"
            required
          >
        </div>
        <div class="col-span-3">
          <label
            for="kba_email"
            class="label text-sm md:text-base"
          >{{ t('email') }}</label>
          <input
            id="kba_email"
            v-model="form.email"
            type="email"
            class="input input-bordered !h-10 w-full bg-white text-neutral-900 border-neutral-300 placeholder:text-neutral-900"
            required
          >
        </div>
        <div class="col-span-3">
          <label
            for="kba_dob"
            class="label text-sm md:text-base"
          >{{ t('dob') }}</label>
          <input
            id="kba_dob"
            v-model="form.dob"
            type="date"
            dir="ltr"
            class="input input-bordered !h-10 md:w-full bg-white text-neutral-900 border-neutral-300 placeholder:text-neutral-900"
            required
          >
        </div>
        <div class="col-span-3">
          <label
            for="kba_ssn"
            class="label text-sm md:text-base"
          >{{ t('ssn') }}</label>
          <input
            id="kba_ssn"
            v-model="form.ssn"
            type="text"
            dir="ltr"
            class="input input-bordered !h-10 w-full bg-white text-neutral-900 border-neutral-300 placeholder:text-neutral-900"
            required
          >
        </div>
      </div>
      <div class="mt-6">
        <button
          type="submit"
          class="base-button w-full flex justify-center submit-form-button"
          :disabled="isLoading"
        >
          <span class="flex">
            <IconInnerShadowTop
              v-if="isLoading"
              class="mr-1 animate-spin"
            />
            <span>
              {{ isLoading ? t('loading_') : t('start_verification') }}
            </span><span
              v-if="isLoading"
              class="w-6 flex justify-start mr-1"
            ><span>...</span></span>
          </span>
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import MarkdownContent from './markdown_content'
import { IconInnerShadowTop } from '@tabler/icons-vue'

export default {
  name: 'KbaStep',
  components: {
    MarkdownContent,
    IconInnerShadowTop
  },
  inject: ['baseUrl', 't'],
  props: {
    field: {
      type: Object,
      required: true
    },
    submitter: {
      type: Object,
      required: true
    },
    submitterSlug: {
      type: String,
      required: true
    },
    emptyValueRequiredStep: {
      type: Object,
      required: false,
      default: null
    },
    values: {
      type: Object,
      required: true
    }
  },
  emits: ['submit'],
  data () {
    return {
      isLoading: false,
      isSubmitting: false,
      questions: null,
      currentQuestionIndex: 0,
      token: null,
      reference: null,
      answers: {},
      error: null,
      timeLeftSeconds: null,
      countdownIntervalId: null,
      form: {
        fn: '',
        ln: '',
        addr: '',
        city: '',
        state: '',
        zip: '',
        dob: '',
        ssn: '',
        phone: '',
        email: ''
      }
    }
  },
  computed: {
    currentQuestion () {
      return this.questions ? this.questions[this.currentQuestionIndex] : null
    },
    isRequiredFieldEmpty () {
      return this.emptyValueRequiredStep && this.emptyValueRequiredStep[0] !== this.field
    },
    kbaTimeLimitSeconds () {
      return 90
    },
    states () {
      return [
        { code: 'AL', name: 'Alabama' },
        { code: 'AK', name: 'Alaska' },
        { code: 'AZ', name: 'Arizona' },
        { code: 'AR', name: 'Arkansas' },
        { code: 'CA', name: 'California' },
        { code: 'CO', name: 'Colorado' },
        { code: 'CT', name: 'Connecticut' },
        { code: 'DE', name: 'Delaware' },
        { code: 'DC', name: 'District of Columbia' },
        { code: 'FL', name: 'Florida' },
        { code: 'GA', name: 'Georgia' },
        { code: 'HI', name: 'Hawaii' },
        { code: 'ID', name: 'Idaho' },
        { code: 'IL', name: 'Illinois' },
        { code: 'IN', name: 'Indiana' },
        { code: 'IA', name: 'Iowa' },
        { code: 'KS', name: 'Kansas' },
        { code: 'KY', name: 'Kentucky' },
        { code: 'LA', name: 'Louisiana' },
        { code: 'ME', name: 'Maine' },
        { code: 'MD', name: 'Maryland' },
        { code: 'MA', name: 'Massachusetts' },
        { code: 'MI', name: 'Michigan' },
        { code: 'MN', name: 'Minnesota' },
        { code: 'MS', name: 'Mississippi' },
        { code: 'MO', name: 'Missouri' },
        { code: 'MT', name: 'Montana' },
        { code: 'NE', name: 'Nebraska' },
        { code: 'NV', name: 'Nevada' },
        { code: 'NH', name: 'New Hampshire' },
        { code: 'NJ', name: 'New Jersey' },
        { code: 'NM', name: 'New Mexico' },
        { code: 'NY', name: 'New York' },
        { code: 'NC', name: 'North Carolina' },
        { code: 'ND', name: 'North Dakota' },
        { code: 'OH', name: 'Ohio' },
        { code: 'OK', name: 'Oklahoma' },
        { code: 'OR', name: 'Oregon' },
        { code: 'PA', name: 'Pennsylvania' },
        { code: 'RI', name: 'Rhode Island' },
        { code: 'SC', name: 'South Carolina' },
        { code: 'SD', name: 'South Dakota' },
        { code: 'TN', name: 'Tennessee' },
        { code: 'TX', name: 'Texas' },
        { code: 'UT', name: 'Utah' },
        { code: 'VT', name: 'Vermont' },
        { code: 'VA', name: 'Virginia' },
        { code: 'WA', name: 'Washington' },
        { code: 'WV', name: 'West Virginia' },
        { code: 'WI', name: 'Wisconsin' },
        { code: 'WY', name: 'Wyoming' }
      ]
    },
    isLastQuestion () {
      return this.questions && this.currentQuestionIndex === this.questions.length - 1
    },
    formattedTimeLeft () {
      if (this.timeLeftSeconds === null) return ''

      const minutes = Math.floor(this.timeLeftSeconds / 60)
      const seconds = this.timeLeftSeconds % 60

      return `${minutes}:${String(seconds).padStart(2, '0')}`
    }
  },
  beforeUnmount () {
    this.clearCountdown()
  },
  methods: {
    clearCountdown () {
      if (this.countdownIntervalId) {
        clearInterval(this.countdownIntervalId)
        this.countdownIntervalId = null
      }

      this.timeLeftSeconds = null
    },
    startCountdown () {
      this.clearCountdown()

      this.timeLeftSeconds = this.kbaTimeLimitSeconds

      this.countdownIntervalId = setInterval(() => {
        if (this.timeLeftSeconds === null) return

        this.timeLeftSeconds -= 1

        if (this.timeLeftSeconds <= 0) {
          this.handleTimeout()
        }
      }, 1000)
    },
    handleTimeout () {
      this.clearCountdown()

      this.questions = null
      this.token = null
      this.reference = null
      this.answers = {}
      this.currentQuestionIndex = 0
      this.error = this.t('kba_timeout').replace('{seconds}', this.kbaTimeLimitSeconds)
    },
    nextQuestion () {
      if (this.isLastQuestion) {
        this.$emit('submit')
      } else {
        this.currentQuestionIndex++
      }
    },
    restartKba () {
      this.clearCountdown()

      this.questions = null
      this.token = null
      this.reference = null
      this.answers = {}
      this.currentQuestionIndex = 0
      this.error = null
    },
    async startKba () {
      this.isLoading = true
      this.error = null
      this.clearCountdown()

      try {
        const payload = { ...this.form, submitter_slug: this.submitterSlug }

        if (payload.dob) {
          payload.dob = payload.dob.replace(/-/g, '')
        }

        if (payload.ssn) {
          payload.ssn = payload.ssn.replace(/\D/g, '')
        }

        if (payload.phone) {
          payload.phone = payload.phone.replace(/^\+1/, '')
        }

        const resp = await fetch(this.baseUrl + '/api/kba', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        })

        const data = await resp.json()

        if (!resp.ok) throw new Error(data.error || this.t('failed_to_start_kba'))

        if (data.result && data.result.action === 'FAIL') {
          if (data.result.detail === 'NO MATCH') {
            throw new Error(this.t('kba_no_match'))
          }

          throw new Error(data.result.detail || this.t('kba_start_failed'))
        }

        if (data.output && data.output.questions && data.output.questions.questions) {
          this.questions = data.output.questions.questions
          this.token = data.continuations.questions.template.token
          this.reference = data.meta.reference

          this.questions.forEach(q => {
            this.answers[q.id] = null
          })

          this.startCountdown()
        } else {
          throw new Error(this.t('invalid_kba_response'))
        }
      } catch (e) {
        this.error = e.message
      } finally {
        this.isLoading = false
      }
    },
    async submit () {
      this.clearCountdown()

      this.isSubmitting = true
      this.error = null

      const formattedAnswers = Object.keys(this.answers).reduce((acc, key) => {
        acc[key] = [this.answers[key]]

        return acc
      }, {})

      try {
        const resp = await fetch(this.baseUrl + `/api/kba/${this.field.uuid}`, {
          method: 'PUT',
          body: JSON.stringify({
            token: this.token,
            answers: formattedAnswers,
            reference: this.reference,
            submitter_slug: this.submitterSlug
          }),
          headers: { 'Content-Type': 'application/json' }
        })

        const data = await resp.json()

        if (data.result?.action !== 'PASS') {
          if (data.result?.issues?.length) {
            this.error = this.t('kba_failed_details').replace('{issues}', data.result.issues.join(', '))
          } else {
            this.error = this.t('kba_failed_answers')
          }

          throw new Error(this.t('kba_failed'))
        }

        if (!resp.ok) {
          this.error = this.t('failed_to_submit_answers')

          throw new Error(this.t('failed_to_submit_answers'))
        }

        return resp
      } finally {
        this.isSubmitting = false
      }
    }
  }
}
</script>
