import { en } from './i18n'

const FIELD_TYPES = [
  'text', 'signature', 'initials', 'date', 'number', 'image', 'file', 'select', 'checkbox',
  'multiple', 'radio', 'cells', 'stamp', 'payment', 'phone', 'verification', 'kba', 'redact'
]

const ENGLISH_FIELD_LABEL_BY_TYPE = Object.fromEntries(
  FIELD_TYPES.map((type) => {
    const key = type === 'verification' ? 'verify_id' : `${type}_field`

    return [type, en[key]]
  }).filter(([, label]) => label)
)

function escapeRegex (value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

export function localizeFieldName (name, type, t) {
  if (!name || !type) return name

  const enLabel = ENGLISH_FIELD_LABEL_BY_TYPE[type]

  if (!enLabel) return name

  const match = name.match(new RegExp(`^${escapeRegex(enLabel)}\\s+(\\d+)$`, 'i'))

  if (!match) return name

  const key = type === 'verification' ? 'verify_id' : `${type}_field`
  const localized = t(key)

  return localized !== key ? `${localized} ${match[1]}` : name
}
