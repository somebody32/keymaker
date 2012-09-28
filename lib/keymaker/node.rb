require 'forwardable'

module Keymaker

  module Node

    extend ActiveSupport::Concern

    include Keymaker::Persistence

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

      def property(attribute,type=String)
        property_traits[attribute] = type
        attr_accessor attribute
      end

      def execute_cypher(query, params={}, return_type=:results_only)
        executed_query = neo_service.execute_query(query, params)
        if executed_query.present?
          case return_type
          when :results_only
            executed_query["data"].flatten
          # TODO: Make this less specific
          when :full_user
            {"user" => executed_query["data"].flatten[0]["data"], "neo_id" => executed_query["data"].flatten[1]}
          end
        else
          return []
        end
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

  end

end
