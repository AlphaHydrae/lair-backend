require_dependency 'random'

module ResourceWithIdentifier
  extend ActiveSupport::Concern

  def set_identifier attr = :api_id, size = 12
    self[attr] ||= self.class.generate_unused_identifier attr, size
  end

  module ClassMethods

    def generate_unused_identifier attr, size = 12
      next while exists?(attr => id = generate_random_identifier(size))
      id
    end

    def generate_random_identifier size = 12
      SecureRandom.random_alphanumeric size
    end
  end
end
