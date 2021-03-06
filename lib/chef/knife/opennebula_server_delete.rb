#
# Author:: Matt Ray (<matt@getchef.com>)
# Copyright:: Copyright (c) 2012-2014 Chef Software, Inc.
# License:: Apache License, Version 2.0
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

require 'chef/node'
require 'chef/api_client'
require 'chef/knife/opennebula_base'

class Chef
  class Knife
     class OpennebulaServerDelete < Knife

      deps do
        require 'highline'
        Chef::Knife.load_deps
      end

      include Knife::OpennebulaBase
  
      banner "knife opennebula server delete VM_NAME (OPTIONS)"

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the opennebula vm itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."


      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end

      def h
        @highline ||= HighLine.new
      end


      def run

        validate!

        @name_args.each do |instance_id|
          begin

        #Fetch instance_id by name of the server =====> MEGAM SYSTEMS CODE START
        connection.servers.all.each do |ser|
        	if ser.name.to_s == "#{instance_id}"
        		instance_id = ser.id
		end
	end
	#=====> MEGAM SYSTEMS CODE END

            server = connection.servers.get(instance_id)

            msg_pair("VM ID", server.id)
            msg_pair("VM Name", server.name)
            msg_pair("IP Address", server.ip)

            puts "\n"
            confirm("Do you really want to delete this server")

            server.destroy

            ui.warn("Deleted server #{server.id}")

            if config[:purge]
              thing_to_delete = config[:chef_node_name] || instance_id
              destroy_item(Chef::Node, thing_to_delete, "node")
              destroy_item(Chef::ApiClient, thing_to_delete, "client")
            else
              ui.warn("Corresponding node and client for the #{instance_id} server were not deleted and remain registered with the Chef Server")
            end

          rescue NoMethodError
            ui.error("Could not locate server '#{instance_id}'.")
          end
        end
      end

    end
  end
end
