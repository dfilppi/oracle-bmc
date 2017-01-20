#!/usr/bin/ruby


vcn=`ctx target instance runtime_properties vcn`

`ctx source instance runtime_properties vcn "#{vcn}"`
