# encoding: utf-8
require 'kramdown/man/version'

require 'kramdown/converter/base'

module Kramdown
  module Converter
    #
    # Converts markdown into a roff man-page.
    #
    class Man < Base

      # Comment header
      HEADER = [
        ".\\\" Generated by kramdown-man #{::Kramdown::Man::VERSION}",
        ".\\\" https://github.com/postmodern/kramdown-roff#readme"
      ].join("\n")

      # Typographic Symbols and their UTF8 chars
      TYPOGRAPHIC_SYMS = {
        :ndash       => "--",
        :mdash       => "—",
        :hellip      => "…",
        :laquo       => "«",
        :raquo       => "»",
        :laquo_space => "«",
        :raquo_space => "»"
      }

      # Smart Quotes and their UTF8 chars
      SMART_QUOTES = {
        :lsquo => "‘",
        :rsquo => "’",
        :ldquo => "“",
        :rdquo => "”"
      }

      #
      # Initializes the converter.
      #
      # @param [Kramdown::Element] root
      #   The root of the markdown document.
      #
      # @param [Hash] options
      #   Markdown options.
      #
      def initialize(root,options)
        super(root,options)

        @ol_index = 0
      end

      #
      # Converts the markdown document into a man-page.
      #
      # @param [Kramdown::Element] root
      #   The root of a markdown document.
      #
      # @return [String]
      #   The roff output.
      #
      def convert(root)
        "#{HEADER}\n#{convert_root(root)}"
      end

      #
      # Converts the root of a markdown document.
      #
      # @param [Kramdown::Element] root
      #   The root of the markdown document.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_root(root)
        root.children.map { |child|
          convert_element(child)
        }.compact.join("\n")
      end

      #
      # Converts an element.
      #
      # @param [Kramdown::Element] element
      #   An arbitrary element within the markdown document.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_element(element)
        method = "convert_#{element.type}"
        send(method,element) if respond_to?(method)
      end

      #
      # Converts a `kd:blank` element.
      #
      # @param [Kramdown::Element] blank
      #   A `kd:blank` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_blank(blank)
        '.LP'
      end

      #
      # Converts a `kd:text` element.
      #
      # @param [Kramdown::Element] text
      #   A `kd:text` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_text(text)
        escape(text.value)
      end

      #
      # Converts a `kd:typographic_sym` element.
      #
      # @param [Kramdown::Element] sym
      #   A `kd:typographic_sym` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_typographic_sym(sym)
        TYPOGRAPHIC_SYMS[sym.value]
      end

      #
      # Converts a `kd:smart_quote` element.
      #
      # @param [Kramdown::Element] quote
      #   A `kd:smart_quote` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_smart_quote(quote)
        SMART_QUOTES[quote.value]
      end

      #
      # Converts a `kd:header` element.
      #
      # @param [Kramdown::Element] header
      #   A `kd:header` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_header(header)
        text = header.options[:raw_text]

        case header.options[:level]
        when 1 then ".TH #{text}"
        when 2 then ".SH #{text}"
        else        ".SS #{text}"
        end
      end

      #
      # Converts a `kd:hr` element.
      #
      # @param [Kramdown::Element] hr
      #   A `kd:hr` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_hr(hr)
        ".ti 0\n\\l'\\n(.lu'"
      end

      #
      # Converts a `kd:ul` element.
      #
      # @param [Kramdown::Element] ul
      #   A `kd:ul` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_ul(ul)
        content = ul.children.map { |li| convert_ul_li(li) }.join("\n")

        return ".RS\n#{content}\n.RE"
      end

      #
      # Converts a `kd:li` element within a `kd:ul` list.
      #
      # @param [Kramdown::Element] li
      #   A `kd:li` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_ul_li(li)
        li.children.each_with_index.map { |child,index|
          if child.type == :p
            content = convert_children(child.children)

            if index == 0 then ".IP \\(bu 2\n#{content}"
            else               ".IP \\( 2\n#{content}"
            end
          end
        }.compact.join("\n")
      end

      #
      # Converts a `kd:ol` element.
      #
      # @param [Kramdown::Element] ol
      #   A `kd:ol` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_ol(ol)
        @ol_index += 1

        header  = ".nr step#{@ol_index} 0 1"
        content = ol.children.map { |li| convert_ol_li(li) }.join("\n")

        return "#{header}\n.RS\n#{content}\n.RE"
      end

      #
      # Converts a `kd:li` element within a `kd:ol` list.
      #
      # @param [Kramdown::Element] li
      #   A `kd:li` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_ol_li(li)
        li.children.each_with_index.map { |child,index|
          if child.type == :p
            content = convert_children(child.children)

            if index == 0 then ".IP \\n+[step#{@ol_index}]\n#{content}"
            else               ".IP \\n\n#{content}"
            end
          end
        }.compact.join("\n")
      end

      #
      # Converts a `kd:abbreviation` element.
      #
      # @param [Kramdown::Element] abbr
      #   A `kd:abbreviation` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_abbreviation(abbr)
        escape(abbr.value)
      end

      #
      # Converts a `kd:blockquote` element.
      #
      # @param [Kramdown::Element] blockquote
      #   A `kd:blockquote` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_blockquote(blockquote)
        content = blockquote.children.map { |child|
          case child.type
          when :p then convert_children(child.children)
          else         convert_element(child)
          end
        }.join("\n")

        return ".PP\n.RS\n#{content}\n.RE"
      end

      #
      # Converts a `kd:codeblock` element.
      #
      # @param [Kramdown::Element] codeblock
      #   A `kd:codeblock` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_codeblock(codeblock)
        ".nf\n#{escape(codeblock.value).rstrip}\n.fi"
      end

      #
      # Converts a `kd:comment` element.
      #
      # @param [Kramdown::Element] comment
      #   A `kd:comment` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_comment(comment)
        comment.value.lines.map { |line|
          ".\\\" #{line}"
        }.join("\n")
      end

      #
      # Converts a `kd:p` element.
      #
      # @param [Kramdown::Element] p
      #   A `kd:p` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_p(p)
        children = p.children

        if (children.length >= 2) &&
           (children[0].type == :em   || children[0].type == :codespan) &&
           (children[1].type == :text && children[1].value =~ /^(  |\t)/)
          [
            '.TP',
            convert_element(children[0]),
            convert_text(children[1]).lstrip,
            convert_children(children[2..-1])
          ].join("\n").rstrip
        else
          ".PP\n#{convert_children(children)}"
        end
      end

      #
      # Converts a `kd:em` element.
      #
      # @param [Kramdown::Element] em
      #   A `kd:em` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_em(em)
        "\\fI#{convert_children(em.children)}\\fP"
      end

      #
      # Converts a `kd:strong` element.
      #
      # @param [Kramdown::Element] strong
      #   A `kd:strong` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_strong(strong)
        "\\fB#{convert_children(strong.children)}\\fP"
      end

      #
      # Converts a `kd:codespan` element.
      #
      # @param [Kramdown::Element] codespan
      #   A `kd:codespan` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_codespan(codespan)
        "\\fB\\fC#{codespan.value}\\fR"
      end

      #
      # Converts a `kd:a` element.
      #
      # @param [Kramdown::Element] a
      #   A `kd:a` element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_a(a)
        href = a.attr['href']
        text = convert_children(a.children)

        case href
        when /^mailto:/
          email = href[7..-1]

          unless text == email then "#{text}\n.MT #{email}\n.ME"
          else                      "\n.MT #{email}\n.ME"
          end
        when /^man:/
          match = href.match(/man:([A-Za-z0-9_-]+)(?:\((\d[a-z]?)\))?/)

          if match[2] then ".BR #{match[1]} (#{match[2]})"
          else             ".BR #{match[1]}"
          end
        else
          "#{text}\n.UR #{href}\n.UE"
        end
      end

      #
      # Converts the children of an element.
      #
      # @param [Array<Kramdown::Element>] children
      #   The children of an element.
      #
      # @return [String]
      #   The roff output.
      #
      def convert_children(children)
        children.map { |child| convert_element(child) }.join.strip
      end

      #
      # Escapes text for roff.
      #
      # @param [String] text
      #   The unescaped text.
      #
      # @return [String]
      #   The escaped text.
      #
      def escape(text)
        text.gsub('\\','\&\&').gsub('-','\\-')
      end

    end
  end
end
