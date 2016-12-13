#!/usr/bin/ruby

subnet_id=`ctx target instance runtime_properties subnet_id`

`ctx source instance runtime_properties "subnet_id" "#{subnet_id}"`
