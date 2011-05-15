class Typisch::Type
  class Boolean < Tagged
    def self.top_tag
      "Boolean"
    end

    Tagged::RESERVED_TAGS << top_tag
  end
end