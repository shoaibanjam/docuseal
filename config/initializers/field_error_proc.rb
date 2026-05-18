# frozen_string_literal: true

ActionView::Base.field_error_proc = proc do |html_tag, instance|
  next html_tag if html_tag.starts_with?('<label')

  method_name = instance.instance_variable_get(:@method_name).to_s
  messages = instance.object.errors.full_messages_for(method_name)

  parsed_html_tag = Nokogiri::HTML::DocumentFragment.parse(html_tag)
  parsed_html_tag.children.add_class 'input-error'
  # rubocop:disable Rails/OutputSafety
  html_tag = parsed_html_tag.to_s.html_safe
  # rubocop:enable Rails/OutputSafety

  result = html_tag

  if messages.present?
    field_id = "#{ActionView::RecordIdentifier.dom_id(instance.object, method_name)}_error"

    result +=
      ApplicationController.render(
        partial: 'shared/field_error',
        locals: { messages:, field_id: }
      )
  end

  result
end
