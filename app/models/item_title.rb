class ItemTitle < ActiveRecord::Base

  def to_builder
    Jbuilder.new do |title|
      title.text contents
    end
  end
end
