require 'spec_helper'
require 'keymaker'
require 'active_support/core_ext'

describe Keymaker::Node do

  class Morpheus
    include Keymaker::Node
  end

  it "should create new node" do
    nd = Morpheus.create says: "Choose the pill"
    nd.create.should be_a_kind_of Keymaker::Node
    puts nd.inspect
  end

end