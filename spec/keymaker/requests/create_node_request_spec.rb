require 'spec_helper'
require 'keymaker'

describe Keymaker::CreateNodeRequest, vcr: true do

  let(:create_node_request) { Keymaker::CreateNodeRequest.new(Keymaker.service, options).submit }
  let(:options) {{}}

  before(:each) { make_request_and_get_neo_id :create_node_request }

  context "with properties" do
    let(:options) {{name: "John Connor"}}
    it "creates a node with the given properties" do
      @response.body.should include(
        {"self"=>"#{neo4j_host}/db/data/node/#{@node_id}", "data"=>{"name"=>"John Connor"}}
      )
    end
  end

  context "without properties" do
    it "creates an empty node" do
      @response.body.should include(
        {"self"=>"#{neo4j_host}/db/data/node/#{@node_id}", "data"=>{}}
      )
    end
  end

  it "returns a 201 status code" do
    @response.status.should == 201
  end

  it "returns application/json" do
    @response.faraday_response.headers["content-type"].should include("application/json")
  end

end
