#!/usr/bin/ruby

require 'json'
require 'yaml'
require 'base64'
require 'oraclebmc'

path=`ctx download_resource "scripts/util.rb"`

require path

bmcconfig=ctx("node properties bmc_config")

vcn_client=get_vcn_client(bmcconfig)

vcnid=`ctx instance runtime_properties vcn_id`

vcn_client.delete_vcn(vcnid)
