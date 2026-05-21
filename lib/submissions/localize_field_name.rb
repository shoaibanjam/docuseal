# frozen_string_literal: true

module Submissions
  module LocalizeFieldName
    FIELD_TYPE_KEYS = %w[
      text signature initials date number image file select checkbox
      multiple radio cells stamp payment phone verification kba
    ].freeze

    module_function

    def call(name, locale: I18n.locale)
      return name if name.blank?

      english_labels_by_type.each do |type, en_label|
        next if en_label.blank?

        match = name.match(/\A#{Regexp.escape(en_label)}\s+(\d+)\z/i)
        next unless match

        key = "#{type}_field"
        return "#{I18n.t(key, locale:, default: name)} #{match[1]}"
      end

      name
    end

    def english_labels_by_type
      @english_labels_by_type ||= FIELD_TYPE_KEYS.index_with do |type|
        key = "#{type}_field"
        I18n.t(key, locale: :'en-US', default: I18n.t(key, locale: :en, default: nil))
      end.compact_blank
    end
  end
end
