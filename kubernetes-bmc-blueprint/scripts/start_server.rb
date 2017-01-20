#!/usr/bin/ruby

require 'json'
require 'yaml'
require 'base64'
require 'oraclebmc'
require 'socket'

path=`ctx download_resource "scripts/util.rb"`

require path

def port_open?(ip, port, seconds=1)
  (1..seconds).each do |i|
    begin
      `ctx logger info "CHECKING #{ip} #{port}"`
      TCPSocket.new(ip, port).close
      `ctx logger info CONNECTED`
      return true
    rescue 
      `ctx logger info ERR`
      puts "err"
    end
    sleep 1
  end
  `ctx logger info TIMEOUT`
  false
end

def launch_instance(compute_client, name, subnet_id, availability_domain, compartment_id, image_id, shape, ssh_key)
  puts 'Launching instance...'
  request = OracleBMC::Core::Models::LaunchInstanceDetails.new
  request.availability_domain = availability_domain
  request.compartment_id = compartment_id
  request.display_name = name
  request.image_id = image_id
  request.shape = shape
  request.subnet_id = subnet_id
  request.metadata = {'ssh_authorized_keys' => ssh_key}
  response = compute_client.launch_instance(request)
  instance = response.data

  `ctx logger info "Launched instance '#{instance.display_name}' [#{instance.id}]"`
  `ctx logger info "Waiting to reach running state."`
  `ctx instance runtime_properties instance_id "#{instance.id}"`

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
  instance
end


bmc_config=ctx("node properties bmc_config")

parsed=JSON.parse(bmc_config)

name=`ctx node properties resource_id`
subnet_id=`ctx instance runtime_properties subnet_id`
adomain=`ctx node properties availability_domain`
compartment_id=`ctx node properties compartment_id`
image_id=`ctx node properties image`
shape_id=`ctx node properties shape`
keyfile=`ctx node properties ssh_keyfile`
key=File.open(File.expand_path(keyfile),"rb").read

compute_client=OracleBMC::Core::ComputeClient.new
instance=launch_instance(compute_client, name, subnet_id, adomain, compartment_id, image_id, shape_id, key)

opts={}
opts[:instance_id]=instance.id
vcn_client=get_vcn_client(bmc_config)
vnas=compute_client.list_vnic_attachments(compartment_id,opts)
vnas.data.each do |vna|
  vnic=vcn_client.get_vnic(vna.vnic_id)
  # This only makes sense in a single NIC scenario (currently all there is)
  `ctx instance runtime_properties public_ip #{vnic.data.public_ip}`
  `ctx instance runtime_properties private_ip #{vnic.data.private_ip}`
  if not port_open?(vnic.data.public_ip,22,180)
    raise "timed out waiting for ssh port to be open"
  end
end

