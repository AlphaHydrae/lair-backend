require_dependency 'random'

module ResourceWithIdentifier
  extend ActiveSupport::Concern

  def set_identifier attr = :api_id, size = 12, &block
    self[attr] ||= self.class.generate_unused_identifier attr, size, &block
  end

  module ClassMethods

    def generate_unused_identifier attr, size = 12, &block
      next while exists?(attr => id = (block.try(:call) || generate_random_identifier(size)))
      id
    end

    def generate_random_identifier size = 12
      SecureRandom.random_alphanumeric size
    end
  end
end
