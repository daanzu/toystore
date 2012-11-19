module Toy
  module Identity
    extend ActiveSupport::Concern

    included do
      key Toy.key_factory
    end

    module ClassMethods
      def key(name_or_factory = :uuid, options = {})
        @key_factory = if name_or_factory == :uuid
          UUIDKeyFactory.new
        elsif name_or_factory == :native_uuid
          NativeUUIDKeyFactory.new
        elsif name_or_factory == :hash
          HashKeyFactory.new(options.merge(:model => self))
        else
          if name_or_factory.respond_to?(:next_key) && name_or_factory.respond_to?(:key_type)
            name_or_factory
          else
            raise InvalidKeyFactory.new(name_or_factory)
          end
        end

        attribute :id, @key_factory.key_type
        @key_factory
      end

      def key_factory
        @key_factory || raise('Set your key_factory using key(...)')
      end

      def key_type
        @key_factory.key_type
      end

      def next_key(object = nil)
        @key_factory.next_key(object).tap do |key|
          raise InvalidKey.new if key.nil?
        end
      end
    end

    def key_factory
      self.class.key_factory
    end
  end
end
