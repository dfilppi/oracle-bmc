#!/usr/bin/ruby

require 'json'
require 'yaml'
require 'base64'
require 'oraclebmc'

path=`ctx download_resource "scripts/util.rb"`

require path


def create_internet_gateway(vcn_client, name, compartment_id, vcn_id)

  puts 'Creating Internet Gateway...'
  request = OracleBMC::Core::Models::CreateInternetGatewayDetails.new
  request.display_name = name
  request.compartment_id = compartment_id
  request.is_enabled = true
  request.vcn_id = vcn_id
  response = vcn_client.create_internet_gateway(request)

  internet_gateway = response.data
  vcn_client.get_internet_gateway(internet_gateway.id).wait_until(:lifecycle_state, OracleBMC::Core::Models::InternetGateway::LIFECYCLE_STATE_AVAILABLE, max_wait_seconds: 180)
  puts "Created Internet Gateway '#{internet_gateway.display_name}' [#{internet_gateway.id}]"
  internet_gateway
end

def update_route_table(vcn_client, internet_gateway, vcn, cidrs)
  `ctx logger info 'Updating route table...'`

  rules=[]
  cidrs.each do |cidr|
    route_rule = OracleBMC::Core::Models::RouteRule.new
    route_rule.network_entity_id = internet_gateway.id
    route_rule.cidr_block = cidr
    rules << route_rule
  end
  request = OracleBMC::Core::Models::UpdateRouteTableDetails.new
  request.route_rules = rules
  resp=vcn_client.update_route_table(vcn.default_route_table_id, request)
  `ctx instance runtime_properties route_table_id "#{resp.data.id}"`

  vcn_client.get_route_table(vcn.default_route_table_id).wait_until(:lifecycle_state, OracleBMC::Core::Models::RouteTable::LIFECYCLE_STATE_AVAILABLE, max_wait_seconds: 180)
end

bmcconfig=ctx("node properties bmc_config")
name=`ctx node properties resource_id`
compartment_id=`ctx node properties compartment_id`
route_cidrs_str=ctx("node properties route_cidrs")
route_cidrs=YAML.load(route_cidrs_str)
`ctx logger info "#{route_cidrs}"`
vcn_enc=`ctx instance runtime_properties "vcn"`
vcn=Marshal.load(Base64.decode64(vcn_enc))

vcn_client=get_vcn_client(bmcconfig)

begin

  resp=create_internet_gateway(vcn_client, name, compartment_id, vcn.id)
  # TODO add error handling

  `ctx instance runtime_properties "gateway_id" "#{resp.id}"`

  # Add routes
  update_route_table(vcn_client,resp,vcn,route_cidrs)

end
