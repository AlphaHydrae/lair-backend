class ApplicationSerializer
  attr_reader :policy

  def initialize policy
    @policy = policy
  end

  def record
    @policy.record
  end

  def serialize *args

    options = args.extract_options!

    if other_record = args.shift
      if other_record.kind_of? Array
        other_record.collect do |r|
          Pundit.policy!(@policy.user_context, r).serializer.serialize options
        end
      else
        Pundit.policy!(@policy.user_context, other_record).serializer.serialize options
      end
    else
      to_builder(options).attributes!
    end
  end

  def to_builder options = {}
    Jbuilder.new do |json|
      build json, options
    end
  end

  def build json, options = {}
    raise NotImplementedError, 'Override #build or #to_builder'
  end
end
