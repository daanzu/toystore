module Toy
  module Attributes
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    included do
      # blank suffix is no longer needed in 3.2+
      # open to suggestions on how to do this better
      if defined?(ActiveSupport::VERSION) && ActiveSupport::VERSION::MAJOR == 3 && ActiveSupport::VERSION::MINOR < 2
        attribute_method_suffix('')
      end

      attribute_method_suffix('=')
      attribute_method_suffix('?')
    end

    module ClassMethods
      def attributes
        @attributes ||= {}
      end

      def defaulted_attributes
        @defaulted_attributes ||= attributes.values.select(&:default?)
      end

      def attribute(key, type, options = {})
        @defaulted_attributes = nil
        attribute = Attribute.new(self, key, type, options)
        define_attribute_methods [attribute.name]
        attribute
      end

      def attribute?(key)
        attributes.has_key?(key.to_s)
      end
    end

    def initialize(attrs={})
      initialize_attributes
      self.attributes = attrs
    end

    def attributes
      @attributes
    end

    def attributes=(attrs, *)
      return if attrs.nil?
      attrs.each do |key, value|
        if respond_to?("#{key}=")
          send("#{key}=", value)
        elsif attribute_method?(key)
          write_attribute(key, value)
        end
      end
    end

    def [](key)
      read_attribute(key)
    end

    def []=(key, value)
      write_attribute(key, value)
    end

    private

    def read_attribute(key)
      @attributes[key.to_s]
    end

    def write_attribute(key, value)
      key = key.to_s
      attribute = attribute_instance(key)
      @attributes[key] = attribute.from_store(value)
    end

    def attribute_method?(key)
      self.class.attribute?(key)
    end

    def attribute(key)
      read_attribute(key)
    end

    def attribute=(key, value)
      write_attribute(key, value)
    end

    def attribute?(key)
      read_attribute(key).present?
    end

    def attribute_instance(key)
      self.class.attributes.fetch(key) {
        raise AttributeNotDefined, "#{self.class} does not have attribute #{key}"
      }
    end

    def initialize_attributes
      @attributes ||= {}
      self.class.defaulted_attributes.each do |attribute|
        @attributes[attribute.name.to_s] = attribute.default
      end
    end
  end
end
