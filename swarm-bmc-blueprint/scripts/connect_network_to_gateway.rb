#!/usr/bin/ruby

require 'json'

vcn=`ctx target instance runtime_properties vcn`

`ctx logger info "SETTING VCN INTO GATEWAY:{}".format(str(vcn))`

`ctx source instance runtime_properties "vcn" "#{vcn}"`
