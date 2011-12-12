# This file is part of the NetflowFu library for Ruby.
# Copyright (C) 2011 Davide Guerri
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require "rubygems"
require "packetfu"
require "logger"

cwd = File.expand_path(File.dirname(__FILE__))
$: << cwd
#noinspection RubyResolve
require File.join(cwd, "netflowfu", "netflow5")
#noinspection RubyResolve
require File.join(cwd, "netflowfu", "netflow9")
#noinspection RubyResolve
require File.join(cwd, "netflowfu", "version")

module PacketFu

  class NetflowHeader < Struct.new(:netflow_version)
    #noinspection RubyResolve
    include StructFu

    def initialize(args={})
      super(Int16.new(args[:netflow_version]))
    end

    # Returns the object in string form.
    def to_s
      self.to_a.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      PacketFu.force_binary(str)

      return self if str.nil?
      self[:netflow_version].read(str[0, 2])

      self
    end

    def self.version(str)
      str[0, 2].unpack("n")[0]
    end

  end
end

class NetflowCollector

  # Flow Data records that correspond to a Template Record MAY appear in
  # the same and/or subsequent Export Packets.  The Template Record is
  # not necessarily carried in every Export Packet.  As such, the NetFlow
  # Collector MUST store the Template Record to interpret the
  # corresponding Flow Data Records that are received in subsequent data
  # packets.
  #            -- RFC 3954 - Template Management
  MAX_TEMPLATES = 255

  def initialize(args={})
    @netflow_callbacks = args[:netflow_callbacks]

    if args[:logger].nil?
      @logger = Logger.new(STDERR)
      @logger.level= Logger::WARN
    else
      @logger = args[:logger]
    end

    @templates = Hash.new

  end

  # TODO: delete templates if they aren't used for a given period of time/a given number of netflow packet
  # TODO: sequence number management
  # TODO: Source ID management (e.g. separate templates, ...)
  def receive(data)
    begin
      version = PacketFu::NetflowHeader.version(data)
      if version == 9
        netflow9 = PacketFu::Netflow9.new.read(data)
        # Adds templates that are found in packet
        netflow9.template_flowsets.each do |flowset|
          flowset.flows.each do |flow|
            if @templates.size < MAX_TEMPLATES
              @templates.merge!(flow.template_id => flow.template_fields)
            else
              @logger.warn "Max templates reached. Discarding template with id '#{flow.template_id}'..."
            end
          end
        end
        # Decode data flowsets
        netflow9.decode_data(@templates)
        @netflow_callbacks.method(:netflow9_callback).call(netflow9)
      elsif version == 5
        if @netflow_callbacks.respond_to?(:netflow5_callback)
          netflow5 = PacketFu::Netflow5.new.read(data)
          @netflow_callbacks.method(:netflow5_callback).call(netflow5)
        end
      else
        @logger.warn "Unsupported netflow version (#{version}) or not a netflow packet. Skipping packet..."
      end
    rescue Exception => e
      @logger.error "'#{e.to_s}'. Skipping packet..."
    end
  end

end
