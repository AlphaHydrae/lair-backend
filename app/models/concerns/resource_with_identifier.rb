require_dependency 'random'

module ResourceWithIdentifier
  extend ActiveSupport::Concern

  def set_identifier options = {}, &block
    attr = options.fetch :attr, :api_id
    self[attr] ||= self.class.generate_unused_identifier options, &block
  end

  module ClassMethods

    def generate_unused_identifier options = {}, &block
      attr = options.fetch :attr, :api_id
      size = options.fetch :size, 12
      next while identifier_exists?(attr, id = (block.try(:call) || generate_random_identifier(size)))
      id
    end

    def generate_random_identifier size = 12
      SecureRandom.random_alphanumeric size
    end

    def identifier_exists? attr, identifier
      if attr == :api_id && Event::TRACKED_MODELS.include?(self)
        return true if Event.where(trackable_type: self.name, trackable_api_id: identifier).exists?
      end

      exists? attr => identifier
    end
  end
end
