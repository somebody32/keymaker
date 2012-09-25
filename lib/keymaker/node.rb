require 'forwardable'

module Keymaker

  module Node

    def self.included(base)
      base.extend ActiveModel::Callbacks
      base.extend ClassMethods

      base.class_eval do
        attr_writer :new_node
        include ActiveModel::MassAssignmentSecurity

        include Keymaker::Indexing
        include Keymaker::Serialization

        attr_protected :created_at, :updated_at
      end

      base.after_save :update_indices

      base.class_attribute :property_traits
      base.class_attribute :indices_traits

      base.property_traits = {}
      base.indices_traits = {}

      base.property :active_record_id, Integer
      base.property :node_id, Integer
      base.property :created_at, DateTime
      base.property :updated_at, DateTime
    end

    module ClassMethods

      extend Forwardable

      def_delegator :Keymaker, :service, :neo_service

      def properties
        property_traits.keys
      end

      def property(attribute, type = String)
        property_traits[attribute] = type
        attr_accessor attribute
      end

    end

    def initialize(attrs)
      @new_node = true
      process_attrs(attrs) if attrs.present?
    end

    def neo_service
      self.class.neo_service
    end

    def new?
      @new_node
    end

    def sanitize(attrs)
      serializable_hash(except: :node_id).merge(attrs.except('node_id')).reject {|k,v| v.blank?}
    end

    def save
      create_or_update
    end

    def create_or_update
      run_callbacks :save do
        new? ? create : update(attributes)
      end
    end

    def create
      run_callbacks :create do
        neo_service.create_node(sanitize(attributes)).on_success do |response|
          self.node_id = response.neo4j_id
          self.new_node = false
        end
        self
      end
    end

    def update(attrs)
      process_attrs(sanitize(attrs.merge(updated_at: Time.now.utc.to_i)))
      neo_service.update_node_properties(node_id, sanitize(attributes))
    end

  end

end
