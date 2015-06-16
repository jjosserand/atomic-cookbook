# atomic-cookbook

The "atomic" cookbook provides Chef resources to create nodes based in Red Hat's Project Atomic.  See the [project's website](http://www.projectatomic.io/) for more information on Project Atomic.

This cookbook has been tested in CentOS 7 and uses KVM/libvirt to create the Atomic hosts.


## Supported Platforms

 * CentOS (tested on CentOS 7)

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['atomic']['work_dir']</tt></td>
    <td>String</td>
    <td>Location on host to store VM data, including disk images, cloud-init ISOs, etc.</td>
    <td><tt>/var/lib/atomic</tt></td>
  </tr>
  <tr>
    <td><tt>['atomic']['image_base_uri']</tt></td>
    <td>String</td>
    <td>Base URI from where to download the Atomic host images.</td>
    <td><tt>http://buildlogs.centos.org/rolling/7/isos/x86_64</tt></td>
  </tr>
  <tr>
    <td><tt>['atomic']['image_version']</tt></td>
    <td>String</td>
    <td>Name of the Atomic Host image to use.</td>
    <td><tt>CentOS-7-x86_64-AtomicHost-20150228_01.qcow2.xz</tt></td>
  </tr>
</table>

## Usage

This is a library cookbook which provides the `atomic_host` resource for you to use in your own recipes.  In addition, the `atomic::default` recipe should be included in your own recipe or your host's `run_list` which will baseline your host as a KVM hypervisor.

To create an Atomic "master" host:

```ruby
atomic_host 'my_master' do
  ip_address '192.168.122.50'
  node_ips [ '192.168.122.51', '192.168.122.52', '192.168.122.53' ]
  role :master
  action :create
end
```

To create an Atomic "node" host:

```ruby
atomic_host 'node_1' do
  ip_address '192.168.122.51'
  master_ip '192.168.122.50'
  role :node
  action :create
end
```

The following attributes are accepted in the `atomic_host` resource:

 * `ip_address`: **required** - IP address to assign to the Atomic host.  You should ensure this is an IP in an available subnet in your virtualization setup (i.e. libvirt's default of 192.168.122.0/24)
 * `role`: **required** - should be either `:master` or `:node`
 * `master_ip`: **required if role == :node** - the IP address of the master.  The node will not be able to function without knowing which master to join.
 * `node_ips`: **required if role == :master** - an array of IP address of atomic nodes that this master should manage.
 * `password`: optional - password to assign to the `centos` user during cloud-init.  If not provided, a random password will be generated for you and placed in the `user-data` file.
 * `ssh_keys`: optional - an array of SSH public keys to add to the new Atomic host.  This cookbook will create a hypervisor-specific key to be used during the provisioning process, as well.
 * `ram`: optional - amount of RAM, in MB, to allocate to this Atomic host.  Defaults to 2048.
 * `cpus`: optional - number of vCPUs to allocate to this Atomic host.  Defaults to 2.
 * `flannel_network`: optional - the supernet to be used by the flannel network overlay service. Defaults to `172.16.0.0/12`
 * `flannel_subnet_length`: optional - the size of the subnet to be reserved by the flannel network overlay service from within the `flannel_network` supernet, stated in CIDR bits as an integer.  Defaults to `24` (i.e. a '/24' network)
 * `flannel_backend_type`: optional - backend network device. Defaults to `vxlan`.


## License and Authors

Author:: Chef Partner Engineering (<partnereng@chef.io>)

Copyright:: Copyright (c) 2015 Chef Software, Inc.

License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the License at

```
http://www.apache.org/licenses/LICENSE-2.0
```

Unless required by applicable law or agreed to in writing, software distributed under the
License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. See the License for the specific language governing permissions
and limitations under the License.
