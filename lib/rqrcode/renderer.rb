module RQRCode
  LEVELS = %w(l m q h).freeze

  SIZES = (1..40).to_a.freeze

  # CAPACITY = Hash[LEVELS.map { |level| [level, [nil] * SIZES.length] }]
  # SIZES.each { |size| LEVELS.each { |level| next if CAPACITY[level][size - 1]; string = "a" * (CAPACITY[level][size - 2] || 0); begin; loop { QRCode.new(string << "a", size: size, level: level) }; rescue QRCodeRunTimeError; CAPACITY[level][size - 1] = string.length; puts "#{size}#{level}: #{CAPACITY[level][size - 1]}"; end } }

  CAPACITY = {"l"=>[18, 33, 54, 79, 107, 135, 155, 193, 231, 272, 322, 368, 426, 459, 521, 587, 645, 719, 793, 859, 930, 1004, 1092, 1172, 1274, 1368, 1466, 1529, 1629, 1733, 1841, 1953, 2069, 2189, 2304, 2432, 2564, 2700, 2810, 2954], "m"=>[15, 27, 43, 63, 85, 107, 123, 153, 181, 214, 252, 288, 332, 363, 413, 451, 505, 561, 625, 667, 712, 780, 858, 912, 998, 1060, 1126, 1191, 1265, 1371, 1453, 1539, 1629, 1723, 1810, 1912, 1990, 2100, 2214, 2332], "q"=>[12, 21, 33, 47, 61, 75, 87, 109, 131, 152, 178, 204, 242, 259, 293, 323, 365, 395, 443, 483, 510, 566, 612, 662, 716, 752, 806, 869, 909, 983, 1031, 1113, 1169, 1229, 1284, 1352, 1424, 1500, 1580, 1664], "h"=>[8, 15, 25, 35, 45, 59, 65, 85, 99, 120, 138, 156, 178, 195, 196, 251, 281, 311, 339, 383, 404, 440, 462, 512, 536, 594, 626, 659, 699, 743, 791, 843, 899, 959, 984, 1052, 1094, 1140, 1220, 1274]}.with_indifferent_access.freeze

  def self.size_for string, level=:h
    length = string.length
    SIZES.find { |size| CAPACITY[level][size - 1] > length }
  end

  module Renderer
    ActiveSupport.on_load(:action_controller) do
      ActionController::Renderers.add :qrcode do |string, options|
        level = options.delete :level
        level ||= :h

        size = options.delete :size
        size ||= RQRCode.size_for string

        qrcode = RQRCode::QRCode.new string, :size => size, :level => level

        type = options.delete(:type) || request.negotiate_mime(ImageBody::TYPES).try(:to_s) || "image/png"

        self.content_type = type
        self.response_body = Body.new qrcode.modules, type, options
      end
    end

    class Body
      attr_accessor :modules, :type, :options

      def self.new modules, type, options={}
        return super unless self == Body
        if type == "image/svg+xml"
          SvgBody
        else
          ImageBody
        end.new modules, type, options
      end

      def initialize modules, type, options={}
        self.modules = modules
        self.type = type
        self.options = options
      end

      def width
        modules.first.length
      end

      def height
        modules.length
      end

      def scale
        @scale ||= [options[:scale].to_i, 1].max
      end
    end

    class ImageBody < Body
      FORMATS = Hash[*Magick.formats.select { |key, value| value.include? 'w' }.map do |key, value|
        extension = key.downcase
        MIME::Types.of(extension).select { |type| type.media_type == "image" }.map do |type|
          Mime::Type.register type.to_s, extension unless Mime::Type.lookup_by_extension extension
          [type.to_s, key]
        end
      end.flatten.compact].freeze

      TYPES = FORMATS.keys.freeze

      COLORS = {true => 0, false => Magick::QuantumRange}.freeze

      def pixels
        modules.flatten.map { |dark| COLORS[dark] }
      end

      def image
        # "I" = greyscale integers
        Magick::Image.constitute(width, height, "I", pixels).tap do |image|
          image.format = FORMATS[type]
          image.scale! scale unless scale == 1
        end
      end

      def each
        yield image.to_blob
      end
    end

    # ImageMagick doesn't generate well-formed SVG, and it uses circles (wtf), so we special-case it
    class SvgBody < Body
      COLORS = {true => "black", false => "white"}.freeze

      def each
        yield %{<?xml version="1.0" standalone="yes"?>}
        yield %{<svg xmlns="http://www.w3.org/2000/svg" width="#{width * scale}" height="#{height * scale}">}
        modules.each.with_index do |row, y|
          row.each.with_index do |dark, x|
            yield %{<rect width="#{scale}" height="#{scale}" x="#{x * scale}" y="#{y * scale}" style="fill:#{COLORS[dark]}"/>}
          end
        end
        yield %{</svg>}
      end
    end
  end
end
