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

vc=get_vcn_client()
compute_client=OracleBMC::Core::ComputeClient.new
resp=compute_client.get_instance("ocid1.instance.oc1.phx.abyhqljsfkyx75pbw7iflcy5tfpxhdzlnxqyvp57wxxodm5ccojduea6jpvq")

compartment_id=resp.data.compartment_id
opts={}
opts[:instance_id]=resp.data.id

vnas=compute_client.list_vnic_attachments(compartment_id,opts)

vnas.data.each do |vna|
  vnic=vc.get_vnic(vna.vnic_id)
  puts vnic.data.public_ip
end
