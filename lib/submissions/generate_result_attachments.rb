# frozen_string_literal: true

module Submissions
  module GenerateResultAttachments
    FONT_SIZE = 11
    FONT_PATH = '/fonts/LiberationSans-Regular.ttf'
    FONT_NAME = if File.exist?(FONT_PATH)
                  FONT_PATH
                else
                  'Helvetica'
                end

    INFO_CREATOR = "#{Docuseal.product_name} (#{Docuseal::PRODUCT_URL})".freeze
    SIGN_REASON = 'Signed by %<email>s with DocuSeal.co'

    TEXT_LEFT_MARGIN = 1
    TEXT_TOP_MARGIN = 1

    A4_SIZE = [595, 842].freeze
    SUPPORTED_IMAGE_TYPES = ['image/png', 'image/jpeg'].freeze

    module_function

    # rubocop:disable Metrics
    def call(submitter)
      cell_layouter = HexaPDF::Layout::TextLayouter.new(valign: :center, align: :center)

      template = submitter.submission.template

      account = submitter.submission.template.account
      pkcs = Accounts.load_signing_pkcs(account)

      pdfs_index = build_pdfs_index(submitter)

      submitter.submission.template_fields.each do |field|
        next if field['submitter_uuid'] != submitter.uuid

        field.fetch('areas', []).each do |area|
          pdf = pdfs_index[area['attachment_uuid']]

          page = pdf.pages[area['page']]
          page.rotate(0, flatten: true) if page[:Rotate] != 0

          page[:Annots] ||= []
          page[:Annots] = page[:Annots].reject { |e| e[:A] && e[:A][:URI].to_s.starts_with?('file:///docuseal_field') }

          width = page.box.width
          height = page.box.height
          font_size = ((page.box.width / A4_SIZE[0].to_f) * FONT_SIZE).to_i

          layouter = HexaPDF::Layout::TextLayouter.new(valign: :center, font: pdf.fonts.add(FONT_NAME), font_size:)

          value = submitter.values[field['uuid']]

          if !field['type']=='redact'
            next if Array.wrap(value).compact_blank.blank?
          end

          canvas = page.canvas(type: :overlay)
          canvas.font(FONT_NAME, size: font_size)

          case field['type']
          when 'image', 'signature', 'initials'
            attachment = submitter.attachments.find { |a| a.uuid == value }

            image = Vips::Image.new_from_buffer(attachment.download, '').autorot

            scale = [(area['w'] * width) / image.width,
                     (area['h'] * height) / image.height].min

            io = StringIO.new(image.resize([scale * 4, 1].min).write_to_buffer('.png'))

            canvas.image(
              io,
              at: [
                (area['x'] * width) + (area['w'] * width / 2) - ((image.width * scale) / 2),
                height - (area['y'] * height) - (image.height * scale / 2) - (area['h'] * height / 2)
              ],
              width: image.width * scale,
              height: image.height * scale
            )
          when 'file'
            items = Array.wrap(value).each_with_object([]) do |uuid, acc|
              attachment = submitter.attachments.find { |a| a.uuid == uuid }

              acc << HexaPDF::Layout::InlineBox.create(width: font_size, height: font_size,
                                                       margin: [0, 1, -2, 0]) do |cv, box|
                cv.image(PdfIcons.paperclip_io, at: [0, 0], width: box.content_width)
              end

              acc << HexaPDF::Layout::TextFragment.create("#{attachment.filename}\n", font: pdf.fonts.add(FONT_NAME),
                                                                                      font_size:)
            end

            lines = layouter.fit(items, area['w'] * width, height).lines

            box_height = lines.sum(&:height)
            height_diff = [0, box_height - (area['h'] * height)].max

            lines.each_with_index.reduce(0) do |acc, (line, index)|
              next acc unless line.items.first.is_a?(HexaPDF::Layout::InlineBox)

              attachment_uuid = Array.wrap(value)[acc]
              attachment = submitter.attachments.find { |a| a.uuid == attachment_uuid }

              next_index =
                lines[(index + 1)..].index { |l| l.items.first.is_a?(HexaPDF::Layout::InlineBox) } || (lines.size - 1)

              page[:Annots] << pdf.add(
                {
                  Type: :Annot, Subtype: :Link,
                  Rect: [
                    (area['x'] * width) + TEXT_LEFT_MARGIN,
                    height - (area['y'] * height) - lines[...index].sum(&:height) + height_diff,
                    (area['x'] * width) + (area['w'] * width) + TEXT_LEFT_MARGIN,
                    height - (area['y'] * height) - lines[..next_index].sum(&:height) + height_diff
                  ],
                  A: { Type: :Action, S: :URI,
                       URI: h.rails_blob_url(attachment, **Docuseal.default_url_options) }
                }
              )

              acc + 1
            end

            layouter.fit(items, area['w'] * width, height_diff.positive? ? box_height : area['h'] * height)
                    .draw(canvas, (area['x'] * width) + TEXT_LEFT_MARGIN,
                          height - (area['y'] * height) + height_diff - TEXT_TOP_MARGIN)
          when 'checkbox'
            next unless value == true

            scale = [(area['w'] * width) / PdfIcons::WIDTH, (area['h'] * height) / PdfIcons::HEIGHT].min

            canvas.image(
              PdfIcons.check_io,
              at: [
                (area['x'] * width) + (area['w'] * width / 2) - (PdfIcons::WIDTH * scale / 2),
                height - (area['y'] * height) - (area['h'] * height / 2) - (PdfIcons::HEIGHT * scale / 2)
              ],
              width: PdfIcons::WIDTH * scale,
              height: PdfIcons::HEIGHT * scale
            )
          when 'cells'
            cell_width = area['cell_w'] * width

            value.chars.each_with_index do |char, index|
              text = HexaPDF::Layout::TextFragment.create(char, font: pdf.fonts.add(FONT_NAME),
                                                                font_size:)

              cell_layouter.fit([text], cell_width, area['h'] * height)
                           .draw(canvas, ((area['x'] * width) + (cell_width * index)),
                                 height - (area['y'] * height))
            end
          when 'redact'
            x = area['x'] * width
            y = height - (area['y'] * height) - (area['h'] * height)
            w = area['w'] * width
            h = area['h'] * height
          
            canvas.fill_color(0, 0, 0) # Set fill color to black
            canvas.rectangle(x, y, w, h)
            canvas.fill
          else
            value = I18n.l(Date.parse(value), format: :default, locale: account.locale) if field['type'] == 'date'

            text = HexaPDF::Layout::TextFragment.create(Array.wrap(value).join(', '), font: pdf.fonts.add(FONT_NAME),
                                                                                      font_size:)

            lines = layouter.fit([text], area['w'] * width, height).lines
            box_height = lines.sum(&:height)
            height_diff = [0, box_height - (area['h'] * height)].max

            layouter.fit([text], area['w'] * width, height_diff.positive? ? box_height : area['h'] * height)
                    .draw(canvas, (area['x'] * width) + TEXT_LEFT_MARGIN,
                          height - (area['y'] * height) + height_diff - TEXT_TOP_MARGIN)
          end
        end
      end

      image_pdfs = []
      original_documents = template.documents.preload(:blob)

      results =
        submitter.submission.template_schema.map do |item|
          pdf = pdfs_index[item['attachment_uuid']]

          attachment = save_signed_pdf(pdf:, submitter:, pkcs:, uuid: item['attachment_uuid'], name: item['name'])

          image_pdfs << pdf if original_documents.find { |a| a.uuid == item['attachment_uuid'] }.image?

          attachment
        end

      return results if image_pdfs.size < 2

      images_pdf =
        image_pdfs.each_with_object(HexaPDF::Document.new) do |pdf, doc|
          pdf.pages.each { |page| doc.pages << doc.import(page) }
        end

      images_pdf_result =
        save_signed_pdf(
          pdf: images_pdf,
          submitter:,
          pkcs:,
          uuid: images_pdf_uuid(original_documents.select(&:image?)),
          name: template.name
        )

      results + [images_pdf_result]
    end
    # rubocop:enable Metrics

    def save_signed_pdf(pdf:, submitter:, pkcs:, uuid:, name:)
      io = StringIO.new

      pdf.trailer.info[:Creator] = info_creator

      pdf.sign(io, reason: sign_reason(submitter.email),
                   certificate: pkcs.certificate,
                   key: pkcs.key,
                   certificate_chain: pkcs.ca_certs || [])

      ActiveStorage::Attachment.create!(
        uuid:,
        blob: ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(io.string), filename: "#{name}.pdf"
        ),
        metadata: { sha256: Base64.urlsafe_encode64(Digest::SHA256.digest(io.string)) },
        name: 'documents',
        record: submitter
      )
    end

    def images_pdf_uuid(attachments)
      Digest::UUID.uuid_v5(Digest::UUID::OID_NAMESPACE, attachments.map(&:uuid).sort.join(':'))
    end

    def build_pdfs_index(submitter)
      latest_submitter =
        submitter.submission.submitters
                 .select(&:completed_at?)
                 .select { |e| e.id != submitter.id && e.completed_at <= submitter.completed_at }
                 .max_by(&:completed_at)

      Submissions::EnsureResultGenerated.call(latest_submitter) if latest_submitter

      documents   = latest_submitter&.documents&.preload(:blob).to_a.presence
      documents ||= submitter.submission.template.documents.preload(:blob)

      documents.to_h do |attachment|
        pdf =
          if attachment.image?
            build_pdf_from_image(attachment)
          else
            HexaPDF::Document.new(io: StringIO.new(attachment.download))
          end

        [attachment.uuid, pdf]
      end
    end

    def build_pdf_from_image(attachment)
      pdf = HexaPDF::Document.new
      page = pdf.pages.add

      scale = [A4_SIZE.first / attachment.metadata['width'].to_f,
               A4_SIZE.last / attachment.metadata['height'].to_f].min

      page.box.width = attachment.metadata['width'] * scale
      page.box.height = attachment.metadata['height'] * scale

      page.canvas.image(
        StringIO.new(attachment.preview_secured_images.first.download),
        at: [0, 0],
        width: page.box.width,
        height: page.box.height
      )

      pdf
    end

    def sign_reason(email)
      format(SIGN_REASON, email:)
    end

    def info_creator
      INFO_CREATOR
    end

    def h
      Rails.application.routes.url_helpers
    end
  end
end
