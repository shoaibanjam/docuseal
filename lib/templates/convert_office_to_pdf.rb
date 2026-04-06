# frozen_string_literal: true

require 'fileutils'
require 'logger'
require 'open3'
require 'tmpdir'
require 'timeout'

module Templates
  module ConvertOfficeToPdf
    CONVERT_TIMEOUT = ENV.fetch('OFFICE_CONVERT_TIMEOUT', '600').to_i

    ConversionError = Class.new(StandardError)

    class << self
      MAX_ERROR_CHARS = 300

      def logger
        return Rails.logger if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

        @logger ||= Logger.new($stderr)
      end

      def soffice_executables
        candidates = [
          ENV['SOFFICE_PATH'],
          '/usr/local/bin/soffice-for-docuseal',
          '/usr/lib/libreoffice/program/soffice',
          '/usr/lib/libreoffice/program/soffice.bin',
          '/usr/bin/soffice',
          'soffice'
        ].compact.uniq

        selected = candidates.select do |p|
          next false if p.to_s.empty?

          p.include?('/') ? File.executable?(p) : true
        end

        selected.empty? ? ['soffice'] : selected
      end

      def call(file_data, original_filename)
        raise ConversionError, 'empty file' if !file_data || file_data.bytesize.zero?

        Timeout.timeout(CONVERT_TIMEOUT) do
          Dir.mktmpdir('office_to_pdf') do |dir|
            ext = File.extname(original_filename.to_s)
            ext = '.bin' if ext.empty? || ext.length > 10
            input_path = File.join(dir, "source#{ext}")
            File.binwrite(input_path, file_data)

            profile_dir = File.join(dir, 'lo_profile')
            runtime_dir = File.join(dir, 'xdg_runtime')
            FileUtils.mkdir_p([profile_dir, runtime_dir])

            user_install = "file://#{profile_dir}"

            attempts = []

            soffice_executables.each do |executable|
              cmd = [
                executable,
                "-env:UserInstallation=#{user_install}",
                '--headless',
                '--invisible',
                '--norestore',
                '--nolockcheck',
                '--nodefault',
                '--nofirststartwizard',
                '--convert-to', 'pdf',
                '--outdir', dir,
                input_path
              ]

              env_cmd = [
                'env', '-i',
                "HOME=#{dir}",
                "XDG_RUNTIME_DIR=#{runtime_dir}",
                'PATH=/usr/lib/libreoffice/program:/usr/bin:/bin',
                'LANG=C.UTF-8',
                'LC_ALL=C.UTF-8',
                'LD_LIBRARY_PATH=/usr/lib/libreoffice/program:/usr/lib/libreoffice/lib'
              ]

              stdout, stderr, status = Open3.capture3(*(env_cmd + cmd))
              stderr_msg = stderr.to_s.strip
              stdout_msg = stdout.to_s.strip

              if status.success?
                attempts.clear
                break
              end

              attempts << {
                executable:,
                status: status.exitstatus,
                stderr: compact_message(stderr_msg),
                stdout: compact_message(stdout_msg)
              }
            end

            base = File.basename(input_path, File.extname(input_path))
            pdf_path = File.join(dir, "#{base}.pdf")

            unless File.file?(pdf_path)
              message =
                if attempts.any?
                  attempts.map do |a|
                    "exec=#{a[:executable]} status=#{a[:status]} stderr=#{a[:stderr].empty? ? '(empty)' : a[:stderr]} stdout=#{a[:stdout].empty? ? '(empty)' : a[:stdout]}"
                  end.join(' | ')
                else
                  'pdf_missing'
                end

              logger.error("LibreOffice failed: #{message}")
              raise ConversionError, message
            end

            pdf_data = File.binread(pdf_path)
            raise ConversionError, 'pdf_empty' if pdf_data.bytesize < 32

            pdf_data
          end
        end
      rescue Timeout::Error
        logger.error('LibreOffice conversion timed out')
        raise ConversionError, 'timeout'
      end

      private

      def compact_message(message)
        value = message.to_s.strip
        return '' if value.empty?

        value = value.lines.first.to_s.strip if value.length > MAX_ERROR_CHARS
        return value if value.length <= MAX_ERROR_CHARS

        "#{value[0, MAX_ERROR_CHARS]}..."
      end
    end
  end
end
