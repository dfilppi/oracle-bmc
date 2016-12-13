#!/usr/bin/ruby

# Copyright (c) 2016 Oracle and/or its affiliates. All rights reserved.
#
# Creates all of the resources necessary to launch an instance, launches an instance, and ensures that it reaches
# a running state. This will use credentials and settings from the DEFAULT profile at ~/.oraclebmc/config.
#
# Format: launch_instance.rb <instance name> <compartment OCID> <availability domain ID> <CIDR block> <full path to a public key file>
#
# Example run:
#   ruby examples/launch_instance.rb 'my_instance5' 'ocid1.compartment.oc1..aaaaaaaac4xqx43texeuonfionxsx4okzfsya5evr2goe2t7v5wntztaymab' 'kIdk:PHX-AD-1' '10.0.0.0/16' '~/.ssh/id_rsa.pub'

require 'oraclebmc'

name = ARGV[0] # Example: 'my_instance'
compartment_id = ARGV[1] # Example: 'ocid1.compartment.oc1..aaaaaaaac4xqx43texeuonfionxsx4okzfsya5evr2goe2t7v5wntztaym4q'
availability_domain = ARGV[2] # Example: 'kIdk:PHX-AD-1'
cidr_block = ARGV[3] # Example: '10.0.0.0/16'
ssh_key_file = ARGV[4] # Example: ~/.ssh/id_rsa.pub

ssh_key = File.open(File.expand_path(ssh_key_file), "rb").read
image_id = 'ocid1.image.oc1.phx.aaaaaaaa4wdx32cwjdjdasqyzatmvlxbef4673rs5y7cowvc3g3o7iwhmhfa' # ol7.1-base-0.0.1
shape = 'x5-2.36.256'

compute_client = OracleBMC::Core::ComputeClient.new
vcn_client = OracleBMC::Core::VirtualNetworkClient.new

def create_vcn(vcn_client, name, cidr_block, compartment_id)
  puts 'Creating VCN...'
  request = OracleBMC::Core::Models::CreateVcnDetails.new
  request.cidr_block = cidr_block
  request.display_name = 'vcn_for_' + name
  request.compartment_id = compartment_id
  response = vcn_client.create_vcn(request)

  vcn = response.data
  vcn_client.get_vcn(vcn.id).wait_until(:lifecycle_state, OracleBMC::Core::Models::Vcn::LIFECYCLE_STATE_AVAILABLE, max_wait_seconds: 180)
  puts "Created VCN '#{vcn.display_name}' [#{vcn.id}]"
  vcn
end

def create_internet_gateway(vcn_client, name, compartment_id, vcn)
  puts 'Creating Internet Gateway...'
  request = OracleBMC::Core::Models::CreateInternetGatewayDetails.new
  request.display_name = 'ig_for_' + name
  request.compartment_id = compartment_id
  request.is_enabled = true
  request.vcn_id = vcn.id
  response = vcn_client.create_internet_gateway(request)

  internet_gateway = response.data
  vcn_client.get_internet_gateway(internet_gateway.id).wait_until(:lifecycle_state, OracleBMC::Core::Models::InternetGateway::LIFECYCLE_STATE_AVAILABLE, max_wait_seconds: 180)
  puts "Created Internet Gateway '#{internet_gateway.display_name}' [#{internet_gateway.id}]"
  internet_gateway
end

def update_route_table(vcn_client, internet_gateway, vcn)
  puts 'Updating route table...'
  route_rule = OracleBMC::Core::Models::RouteRule.new
  route_rule.cidr_block = '0.0.0.0/0'
  route_rule.network_entity_id = internet_gateway.id

  request = OracleBMC::Core::Models::UpdateRouteTableDetails.new
  request.route_rules = [route_rule]
  vcn_client.update_route_table(vcn.default_route_table_id, request)

  vcn_client.get_route_table(vcn.default_route_table_id).wait_until(:lifecycle_state, OracleBMC::Core::Models::RouteTable::LIFECYCLE_STATE_AVAILABLE, max_wait_seconds: 180)
  puts "Updated route table '#{vcn.default_route_table_id}'"
end

def create_subnet(vcn_client, name, vcn, cidr_block, availability_domain, compartment_id)
  puts 'Creating subnet...'
  request = OracleBMC::Core::Models::CreateSubnetDetails.new
  request.cidr_block = cidr_block
  request.availability_domain = availability_domain
  request.display_name = 'subnet_for_' + name
  request.compartment_id = compartment_id
  request.route_table_id = vcn.default_route_table_id
  request.vcn_id = vcn.id
  response = vcn_client.create_subnet(request)

  subnet = response.data
  vcn_client.get_subnet(subnet.id).wait_until(:lifecycle_state, OracleBMC::Core::Models::Subnet::LIFECYCLE_STATE_AVAILABLE, max_wait_seconds: 180)
  puts "Created subnet '#{vcn.display_name}' [#{vcn.id}]"
  subnet
end

def launch_instance(compute_client, name, subnet, availability_domain, compartment_id, image_id, shape, ssh_key)
  puts 'Launching instance...'
  request = OracleBMC::Core::Models::LaunchInstanceDetails.new
  request.availability_domain = availability_domain
  request.compartment_id = compartment_id
  request.display_name = name
  request.image_id = image_id
  request.shape = shape
  request.subnet_id = subnet.id
  request.metadata = {'ssh_authorized_keys' => ssh_key}
  response = compute_client.launch_instance(request)
  instance = response.data

  puts "Launched instance '#{instance.display_name}' [#{instance.id}]"
  print "Waiting to reach running state."
  $stdout.flush

  compute_client.get_instance(instance.id).wait_until(:lifecycle_state, OracleBMC::Core::Models::Instance::LIFECYCLE_STATE_RUNNING) { |response|
    if response.data.lifecycle_state == OracleBMC::Core::Models::Instance::LIFECYCLE_STATE_TERMINATED ||
        response.data.lifecycle_state == OracleBMC::Core::Models::Instance::LIFECYCLE_STATE_TERMINATING
      puts "Instance failed to provision."
      throw :stop_succeed # :stop_fail can be used to throw a WaiterFailedError exception. :stop_succeed will stop the waiter silently.
    end

    print '.'
    $stdout.flush
  }

  puts ''
  puts "Instance '#{instance.display_name}' is now running."
end

vcn = create_vcn(vcn_client, name, cidr_block, compartment_id)
internet_gateway = create_internet_gateway(vcn_client, name, compartment_id, vcn)
update_route_table(vcn_client, internet_gateway, vcn)
subnet = create_subnet(vcn_client, name, vcn, cidr_block, availability_domain, compartment_id)
launch_instance(compute_client, name, subnet, availability_domain, compartment_id, image_id, shape, ssh_key)
