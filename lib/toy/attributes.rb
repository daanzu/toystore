module Toy
  module Attributes
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    included do
      attribute_method_suffix('', '=', '?')
      attribute :id, String
    end

    module ClassMethods
      def attributes
        @attributes ||= {}
      end

      def defaulted_attributes
        attributes.values.select(&:default?)
      end

      def attribute(key, type, options = {})
        Attribute.new(self, key, type, options)
      end

      def attribute?(key)
        attributes.has_key?(key.to_s)
      end
    end

    module InstanceMethods
      def initialize(attrs={})
        @_new_record = true unless defined?(@_new_record)
        @attributes = {}.with_indifferent_access
        self.class.defaulted_attributes.each do |attribute|
          @attributes[attribute.name] = attribute.default
        end
        self.attributes = attrs
        write_attribute :id, self.class.next_key(self) unless id?
      end

      def initialize_from_database(attrs={})
        @_new_record = false
        send(:initialize, attrs)
        self
      end

      def reload
        if attrs = store[store_key]
          instance_variables.each        { |ivar| instance_variable_set(ivar, nil) }
          @attributes = {}.with_indifferent_access
          self.attributes = Toy.decode(attrs)
          self.class.lists.each_key      { |name| send(name).reset }
          self.class.references.each_key { |name| send(name).reset }
        else
          raise NotFound.new(id)
        end
        self
      end

      def id
        read_attribute(:id)
      end

      def attributes
        @attributes.merge(embedded_attributes)
      end

      def persisted_attributes
        attributes.tap do |attrs|
          attrs.each_key do |key|
            if attribute = attribute_definition(key)
              attrs.delete(key) if attribute.virtual?
              attrs[attribute.abbr] = attrs.delete(attribute.name) if attribute.abbr?
            end
          end
        end
      end

      def embedded_attributes
        {}.tap do |attrs|
          self.class.embedded_lists.each_key do |name|
            attrs[name] = send(name).map(&:attributes)
          end
        end
      end

      def attributes=(attrs)
        return if attrs.nil?
        attrs.each do |key, value|
          if attribute_method?(key)
            write_attribute(key, value)
          elsif respond_to?("#{key}=")
            send("#{key}=", value)
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
          attribute_definition(key).try(:read, @attributes[key])
        end

        def write_attribute(key, value)
          @attributes[key] = attribute_definition(key).try(:write, value)
        end

        def attribute_definition(key)
          self.class.attributes[key.to_s]
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
    end
  end
end