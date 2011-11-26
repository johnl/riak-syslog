require 'hirb'

module Brightbox
  # Remove most of the ascii art table output
  class SimpleTable < Hirb::Helpers::Table
    def render_table_header
      title_row = ' ' + @fields.map {|f|
        format_cell(@headers[f], @field_lengths[f])
      }.join('  ')
      ["", title_row, render_border]
    end

    def render_footer
      [render_border, ""]
    end

    def render_border
      '-' + @fields.map {|f| '-' * @field_lengths[f] }.join('--') + '-'
    end

    def render_rows
      @rows.map do |row|
        row = ' ' + @fields.map {|f|
          format_cell(row[f], @field_lengths[f])
        }.join('  ')
      end
    end

  end

  # Vertical table for "show" views
  class ShowTable < Hirb::Helpers::Table

    def self.render(rows, options={})
      new(rows, {:escape_special_chars=>false, :resize=>false}.merge(options)).render
    end

    def setup_field_lengths
      @field_lengths = default_field_lengths
    end

    def render_header; []; end
    def render_footer; []; end

    def render_rows
      longest_header = Hirb::String.size @headers.values.sort_by {|e| Hirb::String.size(e) }.last
      @rows.map do |row|
        fields = @fields.map {|f|
          "#{Hirb::String.rjust(@headers[f], longest_header)}: #{row[f]}"
        }
        fields << "" if @rows.size > 1
        fields.compact.join("\n")
      end
    end
  end


  # Print nice ascii tables (or tab separated lists, depending on mode)
  # Has lots of magic.
  def render_table(rows, options = {})
    options = { :description => false }.merge options
    # Figure out the fields from the :model option
    if options[:model] and options[:fields].nil?
      options[:fields] = options[:model].default_field_order
    end
    # Figure out the fields from the first row
    if options[:fields].nil? and rows.first.class.respond_to?(:default_field_order)
      options[:fields] = rows.first.class.default_field_order
    end
    # Call to_row on all the rows
    rows = rows.collect do |row|
      row.respond_to?(:to_row) ? row.to_row : row
    end
    # Call render_cell on all the cells
    rows.each do |row|
      row.keys.each do |k|
        row[k] = row[k].render_cell if row[k].respond_to? :render_cell
      end
    end
    if options[:s]
      # Simple output
      rows.each do |row|
        if options[:vertical]
          data options[:fields].collect { |k| [k, row[k]].join("\t") }.join("\n")
        else
          data options[:fields].collect { |k| row[k].is_a?(Array) ? row[k].join(',') : row[k] }.join("\t")
        end
      end
    else
      # "graphical" table
      if options[:vertical]
        data ShowTable.render(rows, options)
      else
        data SimpleTable.render(rows, options)
      end
    end
  end

  module_function :render_table
end
