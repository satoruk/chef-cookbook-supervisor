#
# Cookbook Name:: supervisor
# Recipe:: default
#
# Copyright 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "python"

python_pip "supervisor" do
  action :upgrade
  version node['supervisor']['version'] if node['supervisor']['version']
end

directory node['supervisor']['dir'] do
  owner "root"
  group "root"
  mode "755"
end

template "/etc/supervisord.conf" do
  source "supervisord.conf.erb"
  owner "root"
  group "root"
  mode "644"
  variables({
    :supervisord_minfds => node['supervisor']['minfds'],
    :supervisord_minprocs => node['supervisor']['minprocs'],
    :supervisor_version => node['supervisor']['version'],
  })
end

directory node['supervisor']['log_dir'] do
  owner "root"
  group "root"
  mode "755"
  recursive true
end


availableUpstart = false
case node['platform']
when "ubuntu"
  availableUpstart = true if node[:platform_version].to_f >= 6.10
when "centos"
  availableUpstart = true if node[:platform_version].to_f >= 6.0
end

if availableUpstart
  template "/etc/init/supervisor.conf" do
    source "supervisor.upstart.conf.erb"
    owner "root"
    group "root"
    mode "755"
  end
  service "supervisor" do
    provider Chef::Provider::Service::Upstart
    action [:enable, :start]
  end
else
  case node['platform']
  when "debian", "ubuntu"
    template "/etc/init.d/supervisor" do
      source "supervisor.init.erb"
      owner "root"
      group "root"
      mode "755"
    end

    template "/etc/default/supervisor" do
      source "supervisor.default.erb"
      owner "root"
      group "root"
      mode "644"
    end

    service "supervisor" do
      action [:enable, :start]
    end
  else
    Chef::Log.warn("The #{node['platform']} is not support")
  end
end

