module SpecLanguagesHelper
  def create_languages *iso_codes
    iso_codes.collect{ |iso_code| create :language, tag: iso_code.to_s }
  end
end
