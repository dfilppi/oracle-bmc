from fabric.api import run, sudo
from cloudify import ctx
import time

def start_manager():
  sudo("service firewalld stop")
  sudo("sh -c 'echo DOCKER_NETWORK_OPTIONS=\"-H tcp://0.0.0.0:2375\" >>  /etc/sysconfig/docker-network'")
  sudo("service docker restart")
  time.sleep(2)
  ip=ctx.instance.runtime_properties['private_ip']  # set by relationship
  sudo("docker -H localhost:2375 swarm init --advertise-addr {}".format(ip))
  output=sudo("docker -H localhost:2375 swarm join-token -q manager")
  ctx.instance.runtime_properties["manager_token"]=str(output)
  output=sudo("docker -H localhost:2375 swarm join-token -q worker")
  ctx.instance.runtime_properties["worker_token"]= str(output)
  # Install compose
  unames=run("uname -s")
  unamem=run("uname -m")
  sudo("curl -L https://github.com/docker/compose/releases/download/1.9.0/docker-compose-{}-{} -o /usr/local/bin/docker-compose".format(str(unames),str(unamem)))
  sudo("chmod +x /usr/local/bin/docker-compose")

def start_worker(ip,manager_ip,token):
  sudo("service firewalld stop")
  sudo("service docker restart")
  sudo("docker swarm join --advertise-addr {} --token {} {}".format(ip,token,manager_ip))
  hostname=str(run("hostname"))
  node_id=sudo("docker -H {}:2375 node ls -q -f name={}".format(manager_ip,hostname))
  sudo("docker -H {}:2375 node update --label-add role=worker {}".format(manager_ip,node_id))
