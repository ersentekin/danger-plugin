module Danger
  # This plugin looks for code style violations for
  # added lines on the current MR / PR,
  # and offers inline patches.
  #
  # It uses 'clang-format' and only checks ".h", ".m" and ".mm" files
  #
  # @example Ensure that added lines does not violate code style
  #
  #          code-style-validation.check
  #
  # @see  Ersen Tekin/danger-code_style_validation
  # @tags code, style, violation, validation
  #

  VIOLATION_ERROR_MESSAGE = 'Code style violations detected.'.freeze

  # Code style validation check plugin
  class DangerCodeStyleValidation < Plugin
    def check
      diff = ''
      case danger.scm_provider
      when :github
        diff = github.pr_diff
      when :gitlab
        diff = gitlab.mr_diff
      when :bitbucket_server
        diff = bitbucket_server.pr_diff
      else
        raise 'Unknown SCM Provider'
      end

      changes = get_changes(diff)
      message = resolve_changes(changes)

      return if message.empty?
      fail VIOLATION_ERROR_MESSAGE
      markdown '### Code Style Check (`.h`, `.m` and `.mm`)'
      markdown '---'
      markdown message
    end

    private

    def get_changes(diff_str)
      changes = {}
      line_cursor = 0

      patches = parse_diff(diff_str)

      patches.each do |patch|
        second_line = patch.lines.at(1)

        if second_line.start_with?("+++ b/")
          file_name = second_line.split('+++ b/').last.chomp

          unless file_name.end_with?('.m', '.h', '.mm')
            next
          end
        end

        line_cursor = -1

        changed_line_numbers = []
        starting_line_no = 0

        patch.each_line do |line|
          # get hunk lines
          if line.start_with?('@@ ')
            line_numbers_str = line.split('@@ ')[1].split(' @@')[0]

            starting_line_no = line_numbers_str.split('+')[1].split(',')[0]

            # set cursor to 0 to be aware of the real diff file content lines has started
            line_cursor = 0
            next
          end

          unless line_cursor == -1
            if line.start_with?('+')
              changed_line_no = starting_line_no.to_i + line_cursor.to_i
              changed_line_numbers.push(changed_line_no)
            end
            unless line.start_with?('-')
              line_cursor += 1
            end
          end
        end

        changes[file_name] = changed_line_numbers
      end

      changes
    end

    def parse_diff(diff)
      patches = if danger.scm_provider == :gitlab
                  diff.split("\n---")
                else
                  diff.split("\ndiff --git")
                end
      patches
    end

    def generate_markdown(title, content)
      markup_message = '#### ' + title + "\n"
      markup_message += "```patch \n" + content + "\n``` \n"
      markup_message
    end

    def resolve_changes(changes)
      # Parse all patches from diff string

      markup_message = ''

      # patches.each do |patch|
      changes.each do |file_name, changed_lines|
        changed_lines_command_array = []

        changed_lines.each do |line_number|
          changed_lines_command_array.push('-lines=' + line_number.to_s + ':' + line_number.to_s)
        end

        changed_lines_command = changed_lines_command_array.join(' ')
        format_command_array = ['clang-format', changed_lines_command, file_name]

        # clang-format command for formatting JUST changed lines
        formatted = `#{format_command_array.join(' ')}`

        formatted_temp_file = Tempfile.new('temp-formatted')
        formatted_temp_file.write(formatted)
        formatted_temp_file.rewind

        diff_command_array = ['diff ', file_name, formatted_temp_file.path]

        # Generate diff string between formatted and original strings
        diff = `#{diff_command_array.join(' ')}`
        formatted_temp_file.close
        formatted_temp_file.unlink

        # generate Markup message of patch suggestions
        # to prevent code-style violations
        unless diff.empty?
          markup_message += generate_markdown(file_name, diff)
        end
      end

      markup_message
    end
  end
end
