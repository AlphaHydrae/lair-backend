class VideoSerializer < ItemSerializer
  def build json, options = {}
    super json, options
    json.audioLanguages record.audio_languages.collect(&:tag)
    json.subtitleLanguages record.subtitle_languages.collect(&:tag)
  end
end
