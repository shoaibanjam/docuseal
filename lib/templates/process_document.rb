# frozen_string_literal: true

module Templates
  module ProcessDocument
    DPI = 200
    FORMAT = '.jpg'
    ATTACHMENT_NAME = 'preview_images'
    SECURED_ATTACHMENT_NAME = 'preview_secured_images'

    PDF_CONTENT_TYPE = 'application/pdf'
    Q = 35
    MAX_WIDTH = 1400
    MAX_NUMBER_OF_PAGES_PROCESSED = 15

    module_function

    def call(attachment, data)
      if attachment.content_type == PDF_CONTENT_TYPE
        generate_pdf_preview_images(attachment, data)
      elsif attachment.image?
        generate_preview_image(attachment, data)
      end

      attachment
    end

    def generate_preview_image(attachment, data)
      ActiveStorage::Attachment.where(name: ATTACHMENT_NAME, record: attachment).destroy_all

      image = Vips::Image.new_from_buffer(data, '')
      image = image.autorot.resize(MAX_WIDTH / image.width.to_f)

      io = StringIO.new(image.write_to_buffer(FORMAT, Q: Q, interlace: true))

      ActiveStorage::Attachment.create!(
        blob: ActiveStorage::Blob.create_and_upload!(
          io:, filename: "0#{FORMAT}",
          metadata: { analyzed: true, identified: true, width: image.width, height: image.height }
        ),
        name: ATTACHMENT_NAME,
        record: attachment
      )
    end

    def generate_pdf_preview_images(attachment, data)
      ActiveStorage::Attachment.where(name: ATTACHMENT_NAME, record: attachment).destroy_all
      number_of_pages = HexaPDF::Document.new(io: StringIO.new(data)).pages.size

      (attachment.metadata['pdf'] ||= {})[:number_of_pages] = number_of_pages

      attachment.save!

      (0..[number_of_pages - 1, MAX_NUMBER_OF_PAGES_PROCESSED].min).each do |page_number|
        page = Vips::Image.new_from_buffer(data, '', dpi: DPI, page: page_number)
        page = page.resize(MAX_WIDTH / page.width.to_f)

        io = StringIO.new(page.write_to_buffer(FORMAT, Q: Q, interlace: true))

        ApplicationRecord.no_touching do
          ActiveStorage::Attachment.create!(
            blob: ActiveStorage::Blob.create_and_upload!(
              io:, filename: "#{page_number}#{FORMAT}",
              metadata: { analyzed: true, identified: true, width: page.width, height: page.height }
            ),
            name: ATTACHMENT_NAME,
            record: attachment
          )
        end
      end
    end

    def generate_pdf_preview_from_file(attachment, file_path, page_number)
      io = StringIO.new

      command = [
        'pdftocairo', '-jpeg', '-jpegopt', "progressive=y,quality=#{Q},optimize=y",
        '-scale-to-x', MAX_WIDTH, '-scale-to-y', '-1',
        '-r', DPI, '-f', page_number + 1, '-l', page_number + 1,
        '-singlefile', Shellwords.escape(file_path), '-'
      ].join(' ')

      Open3.popen3(command) do |_, stdout, _, _|
        io.write(stdout.read)

        io.rewind
      end

      page = Vips::Image.new_from_buffer(io.read, '')

      io.rewind

      ApplicationRecord.no_touching do
        ActiveStorage::Attachment.create!(
          blob: ActiveStorage::Blob.create_and_upload!(
            io:, filename: "#{page_number}#{FORMAT}",
            metadata: { analyzed: true, identified: true, width: page.width, height: page.height }
          ),
          name: ATTACHMENT_NAME,
          record: attachment
        )
      end

      io
    end

    def generate_pdf_secured_preview_images(template, attachment, data)
      ActiveStorage::Attachment.where(name: SECURED_ATTACHMENT_NAME, record: attachment).destroy_all
      number_of_pages = PDF::Reader.new(StringIO.new(data)).pages.size - 1
      (0..number_of_pages).each do |page_number|
        pdf = Vips::Image.new_from_buffer(data, '', dpi: DPI, page: page_number)
        pdf = pdf.resize(MAX_WIDTH / pdf.width.to_f)
        redacted_boxes = template.fields.select { |field| field['type'] == 'redact' && field['areas'][0]['page'] == page_number }
        if !redacted_boxes.empty?
          redacted_boxes.each do |box|
            x = (box['areas'][0]['x'] * pdf.width).to_i
            y = (box['areas'][0]['y'] * pdf.height).to_i
            w = (box['areas'][0]['w'] * pdf.width).to_i
            h = (box['areas'][0]['h'] * pdf.height).to_i
            black_rect = Vips::Image.black(w, h)
            pdf = pdf.insert(black_rect, x, y)
          end
        end
        
        io = StringIO.new(pdf.write_to_buffer(FORMAT, Q: Q))
  
        ActiveStorage::Attachment.create!(
          blob: ActiveStorage::Blob.create_and_upload!(
            io: io, filename: "#{page_number}#{FORMAT}",
            metadata: { analyzed: true, identified: true, width: pdf.width, height: pdf.height }
          ),
          name: SECURED_ATTACHMENT_NAME,
          record: attachment
        )
      end
    end

  end
end
