require 'spec_helper'

require 'puppet/network/http'

describe Puppet::Network::HTTP::API::V3 do
  let(:response) { Puppet::Network::HTTP::MemoryResponse.new }

  it "mounts the environments endpoint" do
    request = Puppet::Network::HTTP::Request.from_hash(:path => "/v3/environments")
    Puppet::Network::HTTP::API::V3.routes.process(request, response)

    expect(response.code).to eq(200)
  end

  it "mounts indirected routes" do
    request = Puppet::Network::HTTP::Request.
        from_hash(:path => "/v3/node/foo",
                  :params => {:environment => "production"},
                  :headers => {"accept" => "text/pson"})
    Puppet::Network::HTTP::API::V3.routes.process(request, response)

    expect(response.code).to eq(200)
  end

  it "responds to unknown paths with a 400" do
    request = Puppet::Network::HTTP::Request.from_hash(:path => "/v3/unknown")

    Puppet::Network::HTTP::API::V3.routes.process(request, response)
    expect(response.code).to eq(400)
    expect(response.body).to match('Could not find indirection')
  end
end
