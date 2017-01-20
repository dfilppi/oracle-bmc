require 'json'

def ctx(s)
  cmd="ctx "+s
  return `#{cmd}`.gsub(/u('[^']+')/, "\\1").gsub("'","\"")
end

def get_vcn_client(bmcconfig)
  vcn_client=nil

  if bmcconfig != ''
    parsed=JSON.parse(bmcconfig)
    config=OracleBMC::Config.new
    config.user=parsed['user']
    config.fingerprint=parsed['fingerprint']
    config.key_file=parsed['private_key_file']
    config.tenancy=parsed['tenancy']
    config.region=parsed['region']


    vcn_client=OracleBMC::Core::VirtualNetworkClient.new(config:config)

  else
  
    vcn_client=OracleBMC::Core::VirtualNetworkClient.new

  end

  return vcn_client

end
