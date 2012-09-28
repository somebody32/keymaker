require 'spec_helper'
require 'keymaker'

describe Keymaker::BatchRequest, :vcr => true do

  let(:batch_request) { Keymaker::BatchRequest.new(Keymaker.service, options).submit }

  context "when :to and :method are not set" do
    let(:options) do
      [ { foo: "WET", ot: "/node/1" } ]
    end
    it "raises BatchRequestError" do
      expect { batch_request }.to raise_error(Keymaker::BatchRequestError)
    end
  end

  context "when a resource is not found" do
    let(:options) do
      [ { method: "GET", to: "/node/999999999" } ]
    end
    it "raises BatchRequestError" do
      expect { batch_request }.to raise_error(Keymaker::BatchRequestError)
    end
  end

  context "with valid options" do
    let(:options) do
      [ {
        method: "POST",
        to: "/node",
        id: 0,
        body: {
          name: "John Connor"
        }
      }, {
        method: "POST",
        to: "/node",
        id: 1,
        body: {
          name: "Sarah Connor"
        }
      }, {
        method: "POST",
        to: "{0}/relationships",
        id: 3,
        body: {
          to: "{1}",
          data: {
            since: "1985"
          },
          type: "knows"
        }
      } ]
    end

    def node_results(id, node_id, name)
      {
        "id" => id,
        "location" => "#{neo4j_host}/db/data/node/#{node_id}",
        "body" => {
          "outgoing_relationships" => "#{neo4j_host}/db/data/node/#{node_id}/relationships/out",
          "data" => { "name" => name },
          "traverse" => "#{neo4j_host}/db/data/node/#{node_id}/traverse/{returnType}",
          "all_typed_relationships" => "#{neo4j_host}/db/data/node/#{node_id}/relationships/all/{-list|&|types}",
          "property" => "#{neo4j_host}/db/data/node/#{node_id}/properties/{key}",
          "self" => "#{neo4j_host}/db/data/node/#{node_id}",
          "properties" => "#{neo4j_host}/db/data/node/#{node_id}/properties",
          "outgoing_typed_relationships" => "#{neo4j_host}/db/data/node/#{node_id}/relationships/out/{-list|&|types}",
          "incoming_relationships" => "#{neo4j_host}/db/data/node/#{node_id}/relationships/in",
          "extensions" => {},
          "create_relationship" => "#{neo4j_host}/db/data/node/#{node_id}/relationships",
          "paged_traverse" => "#{neo4j_host}/db/data/node/#{node_id}/paged/traverse/{returnType}{?pageSize,leaseTime}",
          "all_relationships" => "#{neo4j_host}/db/data/node/#{node_id}/relationships/all",
          "incoming_typed_relationships" => "#{neo4j_host}/db/data/node/#{node_id}/relationships/in/{-list|&|types}",
        },
        "from" => "/node"
      }
    end

    def relation_results(id, node_id, type, start_id, end_id)
      {
        "id" => id,
        "location" => "#{neo4j_host}/db/data/relationship/#{node_id}",
        "body" => {
          "start" => "#{neo4j_host}/db/data/node/#{start_id}",
          "data" => { "since"=>"1985" },
          "self" => "#{neo4j_host}/db/data/relationship/#{node_id}",
          "property" => "#{neo4j_host}/db/data/relationship/#{node_id}/properties/{key}",
          "properties" => "#{neo4j_host}/db/data/relationship/#{node_id}/properties",
          "type" => type,
          "extensions" => {},
          "end" => "#{neo4j_host}/db/data/node/#{end_id}"
        },
        "from" => "#{neo4j_host}/db/data/node/#{start_id}/relationships"
      }
    end

    it "runs the commands and returns their respective results" do
      response = batch_request.body

      response.size.should == 3

      results = []

      start_node_id = get_neo_id response[0], :location
      results << node_results(0, start_node_id, "John Connor")

      end_node_id = get_neo_id response[1], :location
      results << node_results(1, end_node_id, "Sarah Connor")

      relation_node_id = get_neo_id response[2], :location
      results << relation_results(3, relation_node_id, "knows", start_node_id, end_node_id)

      response.should == results
    end

    it "returns a 200 status code" do
      batch_request.status.should == 200
    end

  end

end
