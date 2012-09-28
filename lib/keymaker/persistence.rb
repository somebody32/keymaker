module Keymaker

  module Persistence

    extend ActiveSupport::Concern

    included do
      class_eval do

        def self.create(attrs)
          new(attrs).create
        end

      end
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