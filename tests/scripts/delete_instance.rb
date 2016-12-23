#!/usr/bin/ruby

require 'json'
require 'yaml'
require 'base64'
require 'oraclebmc'

compute_client=OracleBMC::Core::ComputeClient.new

instance_id=`ctx instance runtime_properties instance_id`

compute_client.terminate_instance(instance_id)

compute_client.get_instance(instance_id).wait_until(:lifecycle_state, OracleBMC::Core::Models::Instance::LIFECYCLE_STATE_TERMINATED, max_wait_seconds: 360)

