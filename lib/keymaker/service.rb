require "addressable/uri"

module Keymaker

  class Service

    extend MatchMethodMacros

    attr_accessor :config

    def initialize(config)
      self.config = config
    end

    def connection=(connection)
      @connection = connection
    end

    def connection
      @connection ||= Faraday.new(url: config.connection_service_root_url) do |conn|
        conn.use FaradayMiddleware::Mashify
        conn.request :json
        conn.response :json, :content_type => /\bjson$/
        conn.adapter :net_http
      end
    end

    # Raw requests to Neo4j REST API which live in lib/requests/*
    match_method(/_request$/) do |name, *args|
      "Keymaker::#{name.to_s.classify}".constantize.new(self, args.first).submit
    end

    def method_missing(name, *args)
      # match_method uses modules, so we can use super to delegate to
      # the generated #method_missing definitions.
      super
    end

    def create_node(attrs)
      # TODO: parse response into manageable Ruby objects
      create_node_request(attrs)
    end

    def get_node(node_id)
      response = get_node_request({node_id: node_id})
      data = response.body.data
      data.merge!("neo4j_id" => response.neo4j_id, "__raw_response__" => response)
    end

    def update_node_properties(node_id, attrs)
      update_node_properties_request({node_id: node_id}.merge(attrs))
    end

    def delete_node(node_id)
      delete_node_request(node_id: node_id)
    end

    def create_relationship(rel_type, start_node_id, end_node_id, data={})
      create_relationship_request({node_id: start_node_id, rel_type: rel_type, end_node_id: end_node_id, data: data})
    end

    def delete_relationship(relationship_id)
      delete_relationship_request(relationship_id: relationship_id)
    end

    def add_node_to_index(index_name, key, value, node_id)
      add_node_to_index_request(index_name: index_name, key: key, value: value, node_id: node_id)
    end

    def remove_node_from_index(index_name, key, value, node_id)
      remove_node_from_index_request(index_name: index_name, key: key, value: value, node_id: node_id)
    end

    def path_traverse(start_node_id, data={})
      traverse_path_request({node_id: start_node_id}.merge(data))
    end

    def batch_get_nodes(node_ids)
      batch_get_nodes_request(node_ids)
    end

    def execute_cypher(query, params)
      # TODO: factor this out into proper parser objects or its
      # own middleware
      body = execute_cypher_request({query: query, params: params}).body
      body.data.map do |result|
        if body.columns.count > 1
          Hashie::Mash.new(Hash[body.columns.zip(result)])
        else
          if result[0].kind_of?(Hashie::Mash)
            result[0].merge!(result[0].data)
            result[0].delete(:data)
            result[0]
          else
            Hashie::Mash.new(body.columns[0] => result[0])
          end
        end
      end
    end

    def execute_script(script, params={})
      execute_gremlin_request({script: script, params: params})
    end

    def get(url, body)
      faraday_response = connection.get(parse_url(url), body)
      Keymaker::Response.new(self, faraday_response)
    end

    def delete(url, body={})
      faraday_response = connection.delete(parse_url(url), body)
      Keymaker::Response.new(self, faraday_response)
    end

    def post(url, body)
      faraday_response = connection.post(parse_url(url), body)
      Keymaker::Response.new(self, faraday_response)
    end

    def put(url, body)
      faraday_response = connection.put(parse_url(url), body)
      Keymaker::Response.new(self, faraday_response)
    end

    def parse_url(url)
      connection.build_url(url).tap do |uri|
        if uri.port != Integer(config.port)
          raise RuntimeError, "bad port"
        end
      end
    end

  end
end
