class Typisch::Type
  class Null < Tagged
    def self.top_tag
      "Null"
    end

    Tagged::RESERVED_TAGS << top_tag
  end
end