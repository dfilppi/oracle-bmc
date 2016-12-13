#!/usr/bin/ruby

require 'json'
require 'base64'
require 'oraclebmc'
require 'yaml'

path=`ctx download_resource "scripts/util.rb"`

require path

def create_subnet(vcn_client, name, vcn, cidr_block, availability_domain, compartment_id)
  `ctx logger info 'Creating subnet...'`
  request = OracleBMC::Core::Models::CreateSubnetDetails.new
  request.cidr_block = cidr_block
  request.availability_domain = availability_domain
  request.display_name = name
  request.compartment_id = compartment_id
  request.route_table_id = vcn.default_route_table_id
  request.vcn_id = vcn.id
  response = vcn_client.create_subnet(request)

  subnet = response.data
  vcn_client.get_subnet(subnet.id).wait_until(:lifecycle_state, OracleBMC::Core::Models::Subnet::LIFECYCLE_STATE_AVAILABLE, max_wait_seconds: 180)
  `ctx logger info "Created subnet '#{vcn.display_name}' [#{vcn.id}]"`
  subnet
end

bmcconfig=ctx("node properties bmc_config")
name=`ctx node properties resource_id`
cidr_block=`ctx node properties cidr_block`
compartment_id=`ctx node properties compartment_id`
vcn_enc=`ctx instance runtime_properties "vcn"`
vcn=Marshal.load(Base64.decode64(vcn_enc))

vcn_client=get_vcn_client(bmcconfig)

begin

  name=`ctx node properties resource_id`
  cidr=`ctx node properties cidr_block`
  compartment_id=`ctx node properties compartment_id`
  availability_domain=`ctx node properties availability_domain`
  sresp=create_subnet(vcn_client, name, vcn, cidr_block, availability_domain, compartment_id)
  `ctx instance runtime_properties subnet_id #{sresp.id}`

end
