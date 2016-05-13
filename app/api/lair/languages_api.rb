module Lair
  class LanguagesApi < Grape::API
    namespace :languages do
      get do
        authorize! Language, :index
        serialize Language.full_list
      end
    end
  end
end
