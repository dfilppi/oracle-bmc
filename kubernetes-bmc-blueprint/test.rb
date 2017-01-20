#!/usr/bin/ruby

require 'json'
require 'oraclebmc'

def get_vcn_client()

    config=OracleBMC::Config.new
    config.user="ocid1.user.oc1..aaaaaaaams6ntkm4d4f7fy55uas2u7jtgzf3zwoebmukrovxygpuc3lef3kq"
    config.fingerprint="42:15:9c:16:0e:34:bc:a3:be:83:31:fb:6c:9f:42:93"
    config.key_file="/home/opc/.ssh/bmcs_api_key"
    config.tenancy="ocid1.tenancy.oc1..aaaaaaaahkcwqbdj6em7q33sd4ahxxdwinwnx6pmucuh3n4nnhu3y4zn23ha"
    config.region="us-phoenix-1"

    vcn_client=OracleBMC::Core::VirtualNetworkClient.new(config:config)

  return vcn_client

end
def create_vcn(vcn_client, name, cidr_block, compartment_id)
  puts 'Creating VCN...'
  request = OracleBMC::Core::Models::CreateVcnDetails.new
  request.cidr_block = cidr_block
  request.display_name = name
  request.compartment_id = compartment_id
  response = vcn_client.create_vcn(request)

  vcn = response.data
  vcn_client.get_vcn(vcn.id).wait_until(:lifecycle_state, OracleBMC::Core::Models::Vcn::LIFECYCLE_STATE_AVAILABLE, max_wait_seconds: 180)
  puts "Created VCN '#{vcn.display_name}' [#{vcn.id}]"
  vcn
end


vc=get_vcn_client()

resp=create_vcn(vc,"xxx","10.0.1.1/24","ocid1.tenancy.oc1..aaaaaaaahkcwqbdj6em7q33sd4ahxxdwinwnx6pmucuh3n4nnhu3y4zn23ha")
