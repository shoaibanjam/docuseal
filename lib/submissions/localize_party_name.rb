# frozen_string_literal: true

module Submissions
  module LocalizePartyName
    PARTY_KEYS = %i[
      first_party second_party third_party fourth_party fifth_party
      sixth_party seventh_party eighth_party ninth_party tenth_party
      eleventh_party twelfth_party thirteenth_party fourteenth_party fifteenth_party
      sixteenth_party seventeenth_party eighteenth_party nineteenth_party twentieth_party
    ].freeze

    ENGLISH_PARTY_NAMES = [
      'First Party', 'Second Party', 'Third Party', 'Fourth Party', 'Fifth Party',
      'Sixth Party', 'Seventh Party', 'Eighth Party', 'Ninth Party', 'Tenth Party',
      'Eleventh Party', 'Twelfth Party', 'Thirteenth Party', 'Fourteenth Party',
      'Fifteenth Party', 'Sixteenth Party', 'Seventeenth Party', 'Eighteenth Party',
      'Nineteenth Party', 'Twentieth Party'
    ].freeze

    # Template builder locale strings not yet present in every Rails locale file.
    TEMPLATE_BUILDER_PARTY_VARIANTS = {
      'Primera Parte' => 'First Party', 'Segunda Parte' => 'Second Party', 'Tercera Parte' => 'Third Party',
      'Cuarta Parte' => 'Fourth Party', 'Quinta Parte' => 'Fifth Party', 'Sexta Parte' => 'Sixth Party',
      'Séptima Parte' => 'Seventh Party', 'Octava Parte' => 'Eighth Party', 'Novena Parte' => 'Ninth Party',
      'Décima Parte' => 'Tenth Party', 'Undécimo Partido' => 'Eleventh Party',
      'Duodécimo Partido' => 'Twelfth Party', 'Decimotercer Partido' => 'Thirteenth Party',
      'Catorceavo Partido' => 'Fourteenth Party', 'Quinceavo Partido' => 'Fifteenth Party',
      'Dieciséisavo Partido' => 'Sixteenth Party', 'Diecisieteavo Partido' => 'Seventeenth Party',
      'Dieciochoavo Partido' => 'Eighteenth Party', 'Decimonovena Fiesta' => 'Nineteenth Party',
      'Vigésima Fiesta' => 'Twentieth Party',
      'Prima parte' => 'First Party', 'Seconda parte' => 'Second Party', 'Terza parte' => 'Third Party',
      'Quarta parte' => 'Fourth Party', 'Quinta parte' => 'Fifth Party', 'Sesta parte' => 'Sixth Party',
      'Settima parte' => 'Seventh Party', 'Ottava parte' => 'Eighth Party', 'Nona parte' => 'Ninth Party',
      'Decima parte' => 'Tenth Party', 'Undicesima parte' => 'Eleventh Party',
      'Dodicesima parte' => 'Twelfth Party', 'Tredicesima parte' => 'Thirteenth Party',
      'Quattordicesima parte' => 'Fourteenth Party', 'Quindicesima parte' => 'Fifteenth Party',
      'Sedicesima parte' => 'Sixteenth Party', 'Diciassettesima parte' => 'Seventeenth Party',
      'Diciottesima parte' => 'Eighteenth Party', 'Diciannovesima parte' => 'Nineteenth Party',
      'Ventesima parte' => 'Twentieth Party',
      'Primeira Parte' => 'First Party', 'Terceira Parte' => 'Third Party',
      'Sétima Parte' => 'Seventh Party', 'Oitava Parte' => 'Eighth Party', 'Nona Parte' => 'Ninth Party',
      'Décima Primeira Parte' => 'Eleventh Party', 'Décima Segunda Parte' => 'Twelfth Party',
      'Décima Terceira Parte' => 'Thirteenth Party', 'Décima Quarta Parte' => 'Fourteenth Party',
      'Décima Quinta Parte' => 'Fifteenth Party', 'Décima Sexta Parte' => 'Sixteenth Party',
      'Décima Sétima Parte' => 'Seventeenth Party', 'Décima Oitava Parte' => 'Eighteenth Party',
      'Décima Nona Parte' => 'Nineteenth Party', 'Vigésima Parte' => 'Twentieth Party',
      'Première partie' => 'First Party', 'Deuxième partie' => 'Second Party', 'Troisième partie' => 'Third Party',
      'Quatrième partie' => 'Fourth Party', 'Cinquième partie' => 'Fifth Party', 'Sixième partie' => 'Sixth Party',
      'Septième partie' => 'Seventh Party', 'Huitième partie' => 'Eighth Party', 'Neuvième partie' => 'Ninth Party',
      'Dixième partie' => 'Tenth Party', 'Onzième partie' => 'Eleventh Party',
      'Douzième partie' => 'Twelfth Party', 'Treizième partie' => 'Thirteenth Party',
      'Quatorzième partie' => 'Fourteenth Party', 'Quinzième partie' => 'Fifteenth Party',
      'Seizième partie' => 'Sixteenth Party', 'Dix-septième partie' => 'Seventeenth Party',
      'Dix-huitième partie' => 'Eighteenth Party', 'Dix-neuvième partie' => 'Nineteenth Party',
      'Vingtième partie' => 'Twentieth Party',
      'Erste Partei' => 'First Party', 'Zweite Partei' => 'Second Party', 'Dritte Partei' => 'Third Party',
      'Vierte Partei' => 'Fourth Party', 'Fünfte Partei' => 'Fifth Party', 'Sechste Partei' => 'Sixth Party',
      'Siebte Partei' => 'Seventh Party', 'Achte Partei' => 'Eighth Party', 'Neunte Partei' => 'Ninth Party',
      'Zehnte Partei' => 'Tenth Party', 'Elfte Partei' => 'Eleventh Party', 'Zwölfte Partei' => 'Twelfth Party',
      'Dreizehnte Partei' => 'Thirteenth Party', 'Vierzehnte Partei' => 'Fourteenth Party',
      'Fünfzehnte Partei' => 'Fifteenth Party', 'Sechzehnte Partei' => 'Sixteenth Party',
      'Siebzehnte Partei' => 'Seventeenth Party', 'Achtzehnte Partei' => 'Eighteenth Party',
      'Neunzehnte Partei' => 'Nineteenth Party', 'Zwanzigste Partei' => 'Twentieth Party',
      'Eerste partij' => 'First Party', 'Tweede partij' => 'Second Party', 'Derde partij' => 'Third Party',
      'Vierde partij' => 'Fourth Party', 'Vijfde partij' => 'Fifth Party', 'Zesde partij' => 'Sixth Party',
      'Zevende partij' => 'Seventh Party', 'Achtste partij' => 'Eighth Party', 'Negende partij' => 'Ninth Party',
      'Tiende partij' => 'Tenth Party', 'Elfde partij' => 'Eleventh Party', 'Twaalfde partij' => 'Twelfth Party',
      'Dertiende partij' => 'Thirteenth Party', 'Veertiende partij' => 'Fourteenth Party',
      'Vijftiende partij' => 'Fifteenth Party', 'Zestiende partij' => 'Sixteenth Party',
      'Zeventiende partij' => 'Seventeenth Party', 'Achttiende partij' => 'Eighteenth Party',
      'Negentiende partij' => 'Nineteenth Party', 'Twintigste partij' => 'Twentieth Party',
      'الطرف الأول' => 'First Party', 'الطرف الثاني' => 'Second Party', 'الطرف الثالث' => 'Third Party',
      'الطرف الرابع' => 'Fourth Party', 'الطرف الخامس' => 'Fifth Party', 'الطرف السادس' => 'Sixth Party',
      'الطرف السابع' => 'Seventh Party', 'الطرف الثامن' => 'Eighth Party', 'الطرف التاسع' => 'Ninth Party',
      'الطرف العاشر' => 'Tenth Party', 'الطرف الحادي عشر' => 'Eleventh Party',
      'الطرف الثاني عشر' => 'Twelfth Party', 'الطرف الثالث عشر' => 'Thirteenth Party',
      'الطرف الرابع عشر' => 'Fourteenth Party', 'الطرف الخامس عشر' => 'Fifteenth Party',
      'الطرف السادس عشر' => 'Sixteenth Party', 'الطرف السابع عشر' => 'Seventeenth Party',
      'الطرف الثامن عشر' => 'Eighteenth Party', 'الطرف التاسع عشر' => 'Nineteenth Party',
      'الطرف العشرون' => 'Twentieth Party'
    }.freeze

    GENERATED_PARTY_SUFFIXES = {
      en: 'Party', es: 'Parte', it: 'parte', pt: 'Parte', fr: 'partie', de: 'Partei', nl: 'partij', ar: 'طرف'
    }.freeze

    module_function

    def call(name, locale: I18n.locale)
      return name if name.blank?

      canonical = canonical_name_by_variant[name] || name
      index = ENGLISH_PARTY_NAMES.index(canonical)

      return I18n.t(PARTY_KEYS[index], locale:, default: name) if index

      match = canonical.match(/\A(\d+)(st|nd|rd|th) Party\z/i)
      return "#{match[1]}#{match[2]} #{I18n.t(:party, locale:)}" if match

      name
    end

    def canonical_name_by_variant
      @canonical_name_by_variant ||= build_canonical_name_by_variant
    end

    def build_canonical_name_by_variant
      map = ENGLISH_PARTY_NAMES.index_by(&:itself)

      PARTY_KEYS.each_with_index do |key, index|
        canonical = ENGLISH_PARTY_NAMES[index]

        I18n.available_locales.each do |locale|
          translation = I18n.t(key, locale:, default: nil)
          map[translation] = canonical if translation.present?
        end
      end

      TEMPLATE_BUILDER_PARTY_VARIANTS.each { |localized, canonical| map[localized] = canonical }

      GENERATED_PARTY_SUFFIXES.each_value do |suffix|
        map.keys.grep(/\A\d+(?:st|nd|rd|th) #{Regexp.escape(suffix)}\z/).each do |localized|
          match = localized.match(/\A(\d+)(st|nd|rd|th) /)
          map[localized] = "#{match[1]}#{match[2]} Party" if match
        end
      end

      map
    end
  end
end
