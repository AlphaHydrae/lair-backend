module Lair
  class LanguagesApi < Grape::API
    namespace :languages do
      get do
        Language.full_list.collect(&:to_builder).collect(&:attributes!)
      end
    end
  end
end
