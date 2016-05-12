module TitleHelpers
  def update_titles_from_params record
    return unless params[:titles].kind_of?(Array)

    titles_to_delete = []
    titles_to_add = params[:titles].dup

    record.titles.each do |existing_title|
      title_data = params[:titles].find{ |h| h[:id] == existing_title.api_id }

      if title_data
        existing_title.contents = title_data[:text] if title_data.key? :text
        existing_title.language = Language.language title_data[:language] if title_data.key? :language
        existing_title.display_position = params[:titles].index title_data
        titles_to_add.delete title_data
      else
        existing_title.mark_for_destruction
      end
    end

    titles_to_add.each do |title|
      record.titles.build(contents: title[:text], language: Language.language(title[:language]), display_position: params[:titles].index(title))
    end
  end
end
