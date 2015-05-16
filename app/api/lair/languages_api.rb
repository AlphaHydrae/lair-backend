module Lair
  class LanguagesApi < Grape::API
    namespace :languages do
      get do
        authorize! Language, :index
        Language.full_list.collect(&:to_builder).collect(&:attributes!)
      end
    end
  end
end
