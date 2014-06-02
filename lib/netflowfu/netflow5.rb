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

module PacketFu

  class Netflow5Flow < Struct.new(
      :source_ip,
      :destination_ip,
      :nexthop,
      :input_interface,
      :output_interface,
      :packets,
      :octets,
      :first_uptime,
      :last_uptime,
      :source_port,
      :destination_port,
      :pad_1,
      :tcp_flags,
      :proto,
      :tos,
      :source_as,
      :destination_as,
      :source_netmask,
      :destination_netmask,
      :pad_2
  )
    #noinspection RubyResolve
    include StructFu

    def to_s(args={})
      self.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      PacketFu.force_binary(str)

      return self if (!str.respond_to? :to_s || str.nil?)
      self[:source_ip].read(str[0, 4])
      self[:destination_ip].read(str[4, 4])
      self[:nexthop].read(str[8, 4])
      self[:input_interface,].read(str[12, 2])
      self[:output_interface].read(str[14, 2])
      self[:packets].read(str[16, 4])
      self[:octets].read(str[20, 4])
      self[:first_uptime].read(str[24, 4])
      self[:last_uptime].read(str[28, 4])
      self[:source_port].read(str[32, 2])
      self[:destination_port].read(str[34, 2])
      self[:pad_1].read(str[36, 1])
      self[:tcp_flags].read(str[37, 1])
      self[:proto].read(str[38, 1])
      self[:tos].read(str[39, 1])
      self[:source_as].read(str[40, 2])
      self[:destination_as].read(str[42, 2])
      self[:source_netmask].read(str[44, 1])
      self[:destination_netmask].read(str[45, 1])
      self[:pad_2].read(str[46, 2])

      self
    end

    def initialize(args={})
      super(
          Int32.new(args[:source_ip]),
          Int32.new(args[:destination_ip]),
          Int32.new(args[:nexthop]),
          Int16.new(args[:input_interface]),
          Int16.new(args[:output_interface]),
          Int32.new(args[:packets]),
          Int32.new(args[:octets]),
          Int32.new(args[:first_uptime]),
          Int32.new(args[:last_uptime]),
          Int16.new(args[:source_port]),
          Int16.new(args[:destination_port]),
          Int8.new(0x00), # Pad_1
          Int8.new(args[:tcp_flags]),
          Int8.new(args[:proto]),
          Int8.new(args[:tos]),
          Int16.new(args[:source_as]),
          Int16.new(args[:destination_as]),
          Int8.new(args[:source_netmask]),
          Int8.new(args[:destination_netmask]),
          Int16.new(0x0000) # Pad_2
      )
    end

    def source_ip=(i); self[:source_ip] = typecast i end
    def source_ip; self[:source_ip].to_i end

    def destination_ip=(i); self[:destination_ip=] = typecast i end
    def destination_ip; self[:destination_ip].to_i end

    def nexthop=(i); self[:nexthop] = typecast i end
    def nexthop; self[:nexthop].to_i end

    def input_interface=(i); self[:input_interface] = typecast i end
    def input_interface; self[:input_interface].to_i end

    def output_interface=(i); self[:output_interface] = typecast i end
    def output_interface; self[:output_interface].to_i end

    def packets=(i); self[:packets] = typecast i end
    def packets; self[:packets].to_i end

    def octets=(i); self[:octets] = typecast i end
    def octets; self[:octets].to_i end

    def first_uptime=(i); self[:first_uptime] = typecast i end
    def first_uptime; self[:first_uptime].to_i end

    def last_uptime=(i); self[:last_uptime] = typecast i end
    def last_uptime; self[:last_uptime].to_i end

    def source_port=(i); self[:source_port] = typecast i end
    def source_port; self[:source_port].to_i end

    def destination_port=(i); self[:destination_port] = typecast i end
    def destination_port; self[:destination_port].to_i end

    def tcp_flags=(i); self[:tcp_flags] = typecast i end
    def tcp_flags; self[:tcp_flags].to_i end

    def proto=(i); self[:proto] = typecast i end
    def proto; self[:proto].to_i end

    def tos=(i); self[:tos] = typecast i end
    def tos; self[:tos].to_i end

    def source_as=(i); self[:source_as] = typecast i end
    def source_as; self[:source_as].to_i end

    def destination_as=(i); self[:destination_as] = typecast i end
    def destination_as; self[:destination_as].to_i end

    def source_netmask=(i); self[:source_netmask] = typecast i end
    def source_netmask; self[:source_netmask].to_i end

    def destination_netmask=(i); self[:destination_netmask] = typecast i end
    def destination_netmask; self[:destination_netmask].to_i end

    def tcp_flags_s
      flags_s = ""
      flags_s += self.tcp_flags & 0b00100000 == 0b00100000 ? "U" : "."
      flags_s += self.tcp_flags & 0b00010000 == 0b00010000 ? "A" : "."
      flags_s += self.tcp_flags & 0b00001000 == 0b00001000 ? "P" : "."
      flags_s += self.tcp_flags & 0b00000100 == 0b00000100 ? "R" : "."
      flags_s += self.tcp_flags & 0b00000010 == 0b00000010 ? "S" : "."
      flags_s += self.tcp_flags & 0b00000001 == 0b00000001 ? "F" : "."

      flags_s
    end

    def proto_s
      case self.proto
        when  1; "ICMP"
        when  2; "IGMP"
        when  6; "TCP"
        when 17; "UDP"
        else   ; "#{self.proto}"
      end
    end

    # Return a human readable description and value for this field
    #noinspection RubyResolve
    def humanize
      <<EOS
IPv4 Source Address = #{IPAddr.new(self.source_ip, Socket::AF_INET)}
IPv4 Destination Address = #{IPAddr.new(self.destination_ip, Socket::AF_INET)}
IPv4 Next-Hop Address = #{IPAddr.new(self.nexthop, Socket::AF_INET)}
Input SNMP Interface = #{self.input_interface}
Output SNMP Interface = #{self.output_interface}
Packets = #{self.packets}
Bytes = #{self.octets}
First Uptime = #{self.first_uptime}
Last Uptime = #{self.last_uptime}
L4 Source port = #{self.source_port}
L4 Destination port = #{self.destination_port}
TCP flags = #{self.tcp_flags_s}
Protocol = #{self.proto_s}
TOS = #{self.tos}
Source AS = #{self.source_as}
Destination AS = #{self.destination_as}
Source Netmask = #{self.source_netmask}
Destination Netmask = #{self.destination_netmask}
EOS
    end

    #noinspection RubyResolve
    def to_hash
      {
          :ip_protocol_version => 4,
          :ip_source_address => IPAddr.new(self.source_ip, Socket::AF_INET),
          :ip_destination_address => IPAddr.new(self.destination_ip, Socket::AF_INET),
          :input_snmp_ifindex => self.input_interface,
          :output_snmp_ifindex => self.output_interface,
          :packets => self.packets,
          :bytes => self.octets,
          :duration => self.last_uptime - self.first_uptime,
          :first_seen => self.first_uptime,
          :last_seen => self.last_uptime,
          :l4_source_port => self.source_port,
          :l4_destination_port => self.destination_port,
          :tcp_flags => self.tcp_flags,
          :l4_protocol => self.proto,
          :tos => self.tos,
          :source_as => self.source_as,
          :destination_as => self.destination_as,


      }
    end

  end

  class Netflow5Flows < Array
    #noinspection RubyResolve
    include StructFu

    def to_s
      self.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      self.clear
      PacketFu.force_binary(str)

      return self if (!str.respond_to? :to_s || str.nil?)
      i = 0
      while i < str.to_s.size
        this_flow = Netflow5Flow.new.read(str[i, str.size])
        self << this_flow
        #noinspection RubyResolve
        i += this_flow.sz
      end
      self
    end

    def humanize
      self.map { |x| x.humanize }.join("\n")
    end

  end

  class Netflow5 < Struct.new(
      :version,
      :flows_count,
      :uptime,
      :unix_seconds,
      :unix_nanoseconds,
      :flow_sequence_number,
      :engine_type,
      :engine_id,
      :sampling_info,
      :flows
  )
    #noinspection RubyResolve
    include StructFu

    def initialize(args={})
      super(
          Int16.new(args[:version]),
          Int16.new(args[:flows_count]),
          Int32.new(args[:uptime]),
          Int32.new(args[:unix_seconds]),
          Int32.new(args[:unix_nanoseconds]),
          Int32.new(args[:flow_sequence_number]),
          Int8.new(args[:engine_type]),
          Int8.new(args[:engine_id]),
          Int16.new(args[:sampling_info]),
          Netflow5Flows.new.read(args[:flows])
      )
    end

    # Returns the object in string form.
    def to_s
      self.to_a.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      PacketFu.force_binary(str)

      return self if str.nil?
      self[:version].read(str[0, 2])
      self[:flows_count].read(str[2, 2])
      self[:uptime].read(str[4, 4])
      self[:unix_seconds].read(str[8, 4])
      self[:unix_nanoseconds].read(str[12, 4])
      self[:flow_sequence_number].read(str[16, 4])
      self[:engine_type].read(str[20, 1])
      self[:engine_id].read(str[21, 1])
      self[:sampling_info].read(str[22, 2])
      self[:flows].read(str[24, str.size])

      self
    end

    # Accessor methods
    def version=(i); self[:version] = typecast i end
    def version; self[:version].to_i end

    def flows_count=(i); self[:flows_count] = typecast i end # Usually calc()'ed
    def flows_count; self[:flows_count].to_i end

    def uptime=(i); self[:uptime] = typecast i end
    def uptime; self[:uptime].to_i
    end

    def unix_seconds=(i); self[:unix_seconds] = typecast i end # Usually calc()'ed
    def unix_seconds; self[:unix_seconds].to_i end

    def unix_nanoseconds=(i); self[:unix_nanoseconds] = typecast i end # Usually calc()'ed
    def unix_nanoseconds; self[:unix_nanoseconds].to_i end

    def flow_sequence_number=(i); self[:netflow9_flow_sequence_number] = typecast i end
    def flow_sequence_number; self[:netflow9_flow_sequence_number].to_i end

    def engine_type=(i); self[:engine_type] = typecast i end
    def engine_type; self[:engine_type].to_i end

    def engine_id=(i) self[:engine_id] = typecast i end
    def engine_id; self[:engine_id].to_i end

    def sampling_info=(i); self[:sampling_info] = typecast i end
    def sampling_info; self[:sampling_info].to_i end

    # Recalculates calculated fields for Netflow 5.
    def recalc(args=:all)
      case args
        when :flows_count
          self.flows_count = self[:flows].count
        when :unix_seconds
          self.unix_seconds = Time.now.to_i
        when :unix_nanoseconds
          self.unix_nanoseconds = Time.now.usec * 1000
        when :all
          self.flows_count = self[:flows].count
          self.unix_seconds = Time.now.to_i
          self.unix_nanoseconds = Time.now.usec * 1000
        else
          raise ArgumentError, "No such field #{args}'"
      end
    end

  end

end
