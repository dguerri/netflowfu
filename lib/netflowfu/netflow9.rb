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

  # Templates Classes

  class Netflow9TemplateField < Struct.new(
      :field_type,
      :field_length
  )
    #noinspection RubyResolve
    include StructFu

    def initialize(args={})
      raise(ArgumentError, "Invalid field_length") if (!args[:field_length].nil? and args[:field_length] <= 0)
      super(
          Int16.new(args[:field_type]),
          Int16.new(args[:field_length])
      )
    end

    def to_s(args={})
      self.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      PacketFu.force_binary(str)

      return self if (!str.respond_to? :to_s or str.nil?)
      self[:field_type].read(str[0, 2])
      self[:field_length].read(str[2, 2])
      raise(ArgumentError, "Invalid field_length") if (self[:field_length].to_i <= 0)
      self
    end

    # Accessor methods
    def field_type=(i); self[:field_type] = typecast i end
    def field_type; self[:field_type].to_i end

    def field_length=(i)
      self[:field_length] = typecast i
      raise(ArgumentError, "Invalid field_length") if (self[:field_length].to_i <= 0)
    end
    def field_length; self[:field_length].to_i end

  end

  class Netflow9TemplateFields < Array
    #noinspection RubyResolve
    include StructFu

    def to_s(args={})
      self.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      self.clear
      PacketFu.force_binary(str)

      return self if (!str.respond_to? :to_s or str.nil?)
      i = 0
      while i < str.to_s.size
        this_record = Netflow9TemplateField.new.read(str[i, str.size])
        self << this_record
        #noinspection RubyResolve
        i += this_record.sz
      end
      self
    end

    # Return the size of any flow instantiated from this template
    def flow_size
      size = 0
      self.each { |x| size += x.field_length }

      size
    end

  end

  class Netflow9Template < Struct.new(
      :template_id,
      :template_fields_count,
      :template_fields
  )
    #noinspection RubyResolve
    include StructFu

    def initialize(args={})
      super(
          Int16.new(args[:template_id]),
          Int16.new(args[:template_fields_count]),
          Netflow9TemplateFields.new.read(args[:template_fields])
      )
    end

    def to_s(args={})
      self.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      PacketFu.force_binary(str)

      return self if (!str.respond_to? :to_s or str.nil?)
      self[:template_id].read(str[0, 2])
      self[:template_fields_count].read(str[2, 2])
      self[:template_fields].read(str[4, [str.size, 4 * self[:template_fields_count].to_i].min])

      self
    end

    # Accessor methods
    def template_id=(i); self[:template_id] = typecast i end
    def template_id; self[:template_id].to_i end

    def template_fields_count=(i); self[:template_fields_count] = typecast i end # Usually recalc()'ed
    def template_fields_count; self[:template_fields_count].to_i end

    # Recalculates calculated fields for Netflow 9.
    def recalc(args=:all)
      case args
        when :template_fields_count
          self.template_fields_count = self[:template_fields].count
        when :all
          self.template_fields_count = self[:template_fields].count
        else
          raise(ArgumentError, "No such field '#{args}'")
      end
    end

  end

  class Netflow9Templates < Array
    #noinspection RubyResolve
    include StructFu

    def to_s(args={})
      self.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      self.clear
      PacketFu.force_binary(str)

      return self if (!str.respond_to? :to_s or str.nil?)
      i = 0
      while i < str.to_s.size
        this_record = Netflow9Template.new.read(str[i, str.size])
        self << this_record
        #noinspection RubyResolve
        i += this_record.sz
      end
      self
    end

    def count_flows
      self.size
    end

  end


  # Data Flows Classes

  class Netflow9FlowField < Struct.new(:value)
    #noinspection RubyResolve
    include StructFu

    def initialize(args={})
      @field_type = args.delete(:field_type) || raise(ArgumentError, "Missing argument field_type")
      @field_length = args.delete(:field_length) || raise(ArgumentError, "Missing argument field_length")
      raise(ArgumentError, "Invalid field_length") if (@field_length <= 0)

      super

      self[:value] = case @field_length
                       when 1
                         Int8.new(args[:value])
                       when 2
                         Int16.new(args[:value])
                       when 4
                         Int32.new(args[:value])
                       else
                         #noinspection RubyArgCount
                         StructFu::String.new.read(args[:value])
                     end
    end

    def to_s(args={})
      self.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      force_binary(str)
      return self if str.nil?
      self[:value].read(str[0, @field_length])

      self
    end

    def generate_template_field
      Netflow9TemplateField.new(:field_type => @field_type, :field_length => @field_length)
    end

    # Accessor methods
    def value=(i); self[:value] = typecast i end
    def value
      if self[:value].kind_of? StructFu::Int
        self[:value].to_i
      else
        self[:value].to_s
      end

    end

    # Class methods
    def self.field_type_to_class(field_type)
      case field_type
        when 1
          Netflow9FlowField::InBytes
        when 2
          Netflow9FlowField::InPkts
        when 3
          Netflow9FlowField::Flows
        when 4
          Netflow9FlowField::Protocol
        when 5
          Netflow9FlowField::Tos
        when 6
          Netflow9FlowField::TcpFlags
        when 7
          Netflow9FlowField::L4SrcPort
        when 8
          Netflow9FlowField::Ipv4SrcAddress
        when 9
          Netflow9FlowField::SrcMask
        when 10
          Netflow9FlowField::InputSnmp
        when 11
          Netflow9FlowField::L4DstPort
        when 12
          Netflow9FlowField::Ipv4DstAddress
        when 13
          Netflow9FlowField::DstMask
        when 14
          Netflow9FlowField::OutputSnmp
        when 15
          Netflow9FlowField::Ipv4NextHop
        when 16
          Netflow9FlowField::SrcAs
        when 17
          Netflow9FlowField::DstAs
        when 18
          Netflow9FlowField::BgpIpv4NextHop
        when 19
          Netflow9FlowField::MulDstPkts
        when 20
          Netflow9FlowField::MulDstBytes
        when 21
          Netflow9FlowField::LastSwitched
        when 22
          Netflow9FlowField::FirstSwitched
        when 23
          Netflow9FlowField::OutBytes
        when 24
          Netflow9FlowField::OutPkts
        when 25
          Netflow9FlowField::MinPktLngth
        when 26
          Netflow9FlowField::MaxPktLngth
        when 27
          Netflow9FlowField::Ipv6SrcAddr
        when 28
          Netflow9FlowField::Ipv6DstAddr
        when 29
          Netflow9FlowField::Ipv6SrcMask
        when 30
          Netflow9FlowField::Ipv6DstMask
        when 31
          Netflow9FlowField::Ipv6FlowLabel
        when 32
          Netflow9FlowField::IcmpType
        when 33
          Netflow9FlowField::MulIgmpType
        when 34
          Netflow9FlowField::SamplingInterval
        when 35
          Netflow9FlowField::SamplingAlgorithm
        when 36
          Netflow9FlowField::FlowActiveTimeout
        when 37
          Netflow9FlowField::FlowInactiveTimeout
        when 38
          Netflow9FlowField::EngineType
        when 39
          Netflow9FlowField::EngineId
        when 40
          Netflow9FlowField::TotalBytesExp
        when 41
          Netflow9FlowField::TotalPktsExp
        when 42
          Netflow9FlowField::TotalFlowsExp
        when 44
          Netflow9FlowField::Ipv4SrcPrefix
        when 45
          Netflow9FlowField::Ipv4DstPrefix
        when 46
          Netflow9FlowField::MplsTopLabelType
        when 47
          Netflow9FlowField::MplsTopLabelIpAddr
        when 48
          Netflow9FlowField::FlowSamplerId
        when 49
          Netflow9FlowField::FlowSamplerMode
        when 50
          Netflow9FlowField::FlowSamplerRandomInterval
        when 52
          Netflow9FlowField::MinTtl
        when 53
          Netflow9FlowField::MaxTtl
        when 54
          Netflow9FlowField::Ipv4Ident
        when 55
          Netflow9FlowField::DstTos
        when 56
          Netflow9FlowField::InSrcMac
        when 57
          Netflow9FlowField::OutDstMac
        when 58
          Netflow9FlowField::SrcVlan
        when 59
          Netflow9FlowField::DstVlan
        when 60
          Netflow9FlowField::IpProtocolVersion
        when 61
          Netflow9FlowField::Direction
        when 62
          Netflow9FlowField::Ipv6NextHop
        when 63
          Netflow9FlowField::BgpIpv6NextHop
        when 64
          Netflow9FlowField::Ipv6OptionHeaders
        when 70
          Netflow9FlowField::MplsLabel1
        when 71
          Netflow9FlowField::MplsLabel2
        when 72
          Netflow9FlowField::MplsLabel3
        when 73
          Netflow9FlowField::MplsLabel4
        when 74
          Netflow9FlowField::MplsLabel5
        when 75
          Netflow9FlowField::MplsLabel6
        when 76
          Netflow9FlowField::MplsLabel7
        when 77
          Netflow9FlowField::MplsLabel8
        when 78
          Netflow9FlowField::MplsLabel9
        when 79
          Netflow9FlowField::MplsLabel10
        else
          nil
      end
    end

    class InBytes < Netflow9FlowField
      # Incoming counter with length N x 8 bits for number of bytes associated with an IP Flow.

      def initialize(args={})
        args[:field_type] = 1
        args[:field_length] ||= 4 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Input Bytes = #{self.value}"
      end

    end

    class InPkts < Netflow9FlowField
      # Incoming counter with length N x 8 bits for the number of packets associated with an IP Flow.
      def initialize(args={})
        args[:field_type] = 2
        args[:field_length] ||= 4 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Input Packets = #{self.value}"
      end

    end

    class Flows < Netflow9FlowField
      # Number of flows that were aggregated; default for N is 4.

      def initialize(args={})
        args[:field_type] = 3
        args[:field_length] ||= 4 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Flows = #{self.value}"
      end

    end

    class Protocol < Netflow9FlowField
      # IP protocol byte.

      def initialize(args={})
        args[:field_type] = 4
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        proto = case self.value
                  when  1; "ICMP"
                  when  2; "IGMP"
                  when  6; "TCP"
                  when 17; "UDP"
                  else   ; "#{self.value}"
                end
        "Protocol = #{proto}"
      end

    end

    class Tos < Netflow9FlowField
      # Type of Service byte setting when entering incoming interface.

      def initialize(args={})
        args[:field_type] = 5
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "TOS = #{self.value}"
      end

    end

    class TcpFlags < Netflow9FlowField
      # Cumulative of all the TCP flags seen for this flow.

      def initialize(args={})
        args[:field_type] = 6
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        flags = self.value
        flags_s = ""
        flags_s += flags & 0b00100000 == 0b00100000 ? "U" : "."
        flags_s += flags & 0b00010000 == 0b00010000 ? "A" : "."
        flags_s += flags & 0b00001000 == 0b00001000 ? "P" : "."
        flags_s += flags & 0b00000100 == 0b00000100 ? "R" : "."
        flags_s += flags & 0b00000010 == 0b00000010 ? "S" : "."
        flags_s += flags & 0b00000001 == 0b00000001 ? "F" : "."

        "TCP Flags = #{flags_s}"
      end

    end

    class L4SrcPort < Netflow9FlowField
      # TCP/UDP source port number e.g. FTP, Telnet, or equivalent.

      def initialize(args={})
        args[:field_type] = 7
        args[:field_length] = 2 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "L4 Source port = #{self.value}"
      end

    end

    class Ipv4Address < Netflow9FlowField
      # "Virtual" class for IPv4 address field

      def initialize(args={})
        args[:field_length] = 4 # Fixed Length
        super(args)
      end

      def to_ipaddr
        #noinspection RubyResolve
        IPAddr.new(self.value, Socket::AF_INET)
      end


    end

    class Ipv4SrcAddress < Ipv4Address
      # IPv4 source address.

      def initialize(args={})
        args[:field_type] = 8
        super(args)

      end

      # Return a human readable description and value for this field
      def humanize
        "IPv4 Source Address = #{self.to_ipaddr.to_s}"
      end

    end

    class SrcMask < Netflow9FlowField
      # The number of contiguous bits in the source address subnet mask i.e. the mask in slash notation.

      def initialize(args={})
        args[:field_type] = 9
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Source Netmask = #{self.value}"
      end

    end

    class InputSnmp < Netflow9FlowField
      # Input interface index; default for N is 2 but higher values could be used.

      def initialize(args={})
        args[:field_type] = 10
        args[:field_length] ||= 2 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Input SNMP interface = #{self.value}"
      end

    end

    class L4DstPort < Netflow9FlowField
      # TCP/UDP destination port number e.g. FTP, Telnet, or equivalent.

      def initialize(args={})
        args[:field_type] = 11
        args[:field_length] = 2 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "L4 Destination Port = #{self.value}"
      end

    end

    class Ipv4DstAddress < Ipv4Address
      # IPv4 destination address.

      def initialize(args={})
        args[:field_type] = 12
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "IPv4 Destination Address = #{to_ipaddr.to_s}"
      end

    end

    class DstMask < Netflow9FlowField
      # The number of contiguous bits in the destination address subnet mask.

      def initialize(args={})
        args[:field_type] = 13
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Destination Netmask = #{self.value}"
      end

    end

    class OutputSnmp < Netflow9FlowField
      # Output interface index; default for N is 2 but higher values could be used.

      def initialize(args={})
        args[:field_type] = 14
        args[:field_length] ||= 2 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Output SNMP Interface = #{self.value}"
      end

    end

    class Ipv4NextHop < Ipv4Address
      # IPv4 address of next-hop router.

      def initialize(args={})
        args[:field_type] = 15
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "IPv4 Next-Hop Address = #{self.to_ipaddr.to_s}"
      end

    end

    class SrcAs < Netflow9FlowField
      # Source BGP autonomous system number where N could be 2 or 4.

      def initialize(args={})
        args[:field_type] = 16
        args[:field_length] ||= 2 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Source AS number = #{self.value}"
      end

    end

    class DstAs < Netflow9FlowField
      # Destination BGP autonomous system number where N could be 2 or 4.

      def initialize(args={})
        args[:field_type] = 17
        args[:field_length] ||= 2 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Destination AS number = #{self.value}"
      end

    end

    class BgpIpv4NextHop < Ipv4Address
      # Next-hop router's IP in the BGP domain.

      def initialize(args={})
        args[:field_type] = 18
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "BGP IPv4 Next-Hop Address = #{self.to_ipaddr.to_s}"
      end

    end


    class MulDstPkts < Netflow9FlowField
      # IP multicast outgoing packet counter with length N x 8 bits for packets associated with the IP Flow.

      def initialize(args={})
        args[:field_type] = 19
        args[:field_length] ||= 4 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Multicast Destination Packets = #{self.value}"
      end

    end

    class MulDstBytes < Netflow9FlowField
      # IP multicast outgoing byte counter with length N x 8 bits for bytes associated with the IP Flow.

      def initialize(args={})
        args[:field_type] = 20
        args[:field_length] ||= 4 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Multicast Destination Bytes = #{self.value}"
      end

    end

    class LastSwitched < Netflow9FlowField
      # System uptime at which the last packet of this flow was switched.

      def initialize(args={})
        args[:field_type] = 21
        args[:field_length] = 4 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Last Switched Time = #{self.value} milliseconds"
      end

    end

    class FirstSwitched < Netflow9FlowField
      # System uptime at which the first packet of this flow was switched.

      def initialize(args={})
        args[:field_type] = 22
        args[:field_length] = 4 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "First Switched Time = #{self.value} milliseconds"
      end

    end

    class OutBytes < Netflow9FlowField
      # Outgoing counter with length N x 8 bits for the number of bytes associated with an IP Flow.

      def initialize(args={})
        args[:field_type] = 23
        args[:field_length] ||= 4 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Output Bytes = #{self.value}"
      end

    end

    class OutPkts < Netflow9FlowField
      # Outgoing counter with length N x 8 bits for the number of packets associated with an IP Flow.

      def initialize(args={})
        args[:field_type] = 24
        args[:field_length] ||= 4 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Output Packets = #{self.value}"
      end

    end

    class MinPktLngth < Netflow9FlowField
      # Minimum IP packet length on incoming packets of the flow.

      def initialize(args={})
        args[:field_type] = 25
        args[:field_length] = 2 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Minimum IP Packet Length = #{self.value}"
      end

    end

    class MaxPktLngth < Netflow9FlowField
      # Maximum IP packet length on incoming packets of the flow.

      def initialize(args={})
        args[:field_type] = 26
        args[:field_length] = 2 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Maximum IP Packet Length = #{self.value}"
      end

    end

    class Ipv6Address < Netflow9FlowField
      # "Virtual" class for IPv6 Address fields

      def initialize(args={})
        args[:field_length] = 16 # Fixed Length
        super(args)
      end

      def to_ipaddr
        IPAddr.new(self.value, Socket::AF_INET6)
      end

    end

    class Ipv6SrcAddr < Ipv6Address
      # IPv6 Source Address.

      def initialize(args={})
        args[:field_type] = 27
        super(args)
      end

      def humanize
        "IPv6 Source Address = #{self.value}"
      end

    end

    class Ipv6DstAddr < Ipv6Address
      # IPv6 Destination Address.

      def initialize(args={})
        args[:field_type] = 28
        super(args)
      end

      def humanize
        "IPv6 Destination Address = #{self.value}"
      end

    end

    class Ipv6SrcMask < Netflow9FlowField
      # Length of the IPv6 source mask in contiguous bits

      def initialize(args={})
        args[:field_type] = 29
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "IPv6 Source Mask = #{self.value}"
      end

    end

    class Ipv6DstMask < Netflow9FlowField
      # Length of the IPv6 destination mask in contiguous bits.

      def initialize(args={})
        args[:field_type] = 30
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "IPv6 Destination Mask = #{self.value}"
      end

    end

    class Ipv6FlowLabel < Netflow9FlowField
      # IPv6 flow label as per RFC 2460 definition.

      def initialize(args={})
        args[:field_type] = 31
        args[:field_length] = 3 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "IPv6 Flow Label = #{self.value}"
      end

    end

    class IcmpType < Netflow9FlowField
      # Internet Control Message Protocol (ICMP) packet type; reported as ((ICMP Type * 256) + ICMP code).

      def initialize(args={})
        args[:field_type] = 32
        args[:field_length] = 2 # Fixed Length
        super(args)
      end

      def icmp_code
        self.value & 0x0011
      end

      def icmp_type
        self.value & 0x1100 >> 2
      end

      # Return a human readable description and value for this field
      def humanize
        "ICMP packet type = #{self.icmp_type} code = #{self.icmp_code}"
      end

    end

    class MulIgmpType < Netflow9FlowField
      # Internet Group Management Protocol (IGMP) packet type.

      def initialize(args={})
        args[:field_type] = 33
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "IGMP Packet Type = #{self.value}"
      end

    end

    class SamplingInterval < Netflow9FlowField
      # When using sampled NetFlow, the rate at which packets are sampled.
      # e.g. a value of 100 indicates that one of every 100 packets is sampled.

      def initialize(args={})
        args[:field_type] = 34
        args[:field_length] = 4 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Sampling Interval = #{self.value}"
      end

    end

    class SamplingAlgorithm < Netflow9FlowField
      # The type of algorithm used for sampled NetFlow:
      # 0x01 Deterministic Sampling ,0x02 Random Sampling.

      def initialize(args={})
        args[:field_type] = 35
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        sampling = case self.value
                     when 0x01
                       "Deterministic"
                     when 0x02
                       "Random"
                     else
                       "Unknown"
                   end
        "Sampling Algorithm = #{sampling}"
      end

    end

    class FlowActiveTimeout < Netflow9FlowField
      # Timeout value (in seconds) for active flow entries in the NetFlow cache.

      def initialize(args={})
        args[:field_type] = 36
        args[:field_length] = 2 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Flow Active Timeout = #{self.value}"
      end

    end

    class FlowInactiveTimeout < Netflow9FlowField
      # Timeout value (in seconds) for inactive flow entries in the NetFlow cache.

      def initialize(args={})
        args[:field_type] = 37
        args[:field_length] = 2 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Flow Inactive Timeout = #{self.value}"
      end

    end

    class EngineType < Netflow9FlowField
      # Type of flow switching engine: RP = 0, VIP/Linecard = 1.

      def initialize(args={})
        args[:field_type] = 38
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        engine_type = case self.value
                        when 0
                          "RP"
                        when 1
                          "Linecard"
                        else
                          "Unknown"
                      end
        "Engine Type = #{engine_type}"
      end

    end

    class EngineId < Netflow9FlowField
      # ID number of the flow switching engine.

      def initialize(args={})
        args[:field_type] = 39
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Flow Id = #{self.value}"
      end

    end

    class TotalBytesExp < Netflow9FlowField
      # Counter with length N x 8 bits for bytes for the number of bytes exported by the Observation Domain.

      def initialize(args={})
        args[:field_type] = 40
        args[:field_length] ||= 4 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Total Exported Bytes = #{self.value}"
      end

    end

    class TotalPktsExp < Netflow9FlowField
      # Counter with length N x 8 bits for bytes for the number of packets exported by the Observation Domain.

      def initialize(args={})
        args[:field_type] = 41
        args[:field_length] ||= 4 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Total Exported Packets = #{self.value}"
      end

    end

    class TotalFlowsExp < Netflow9FlowField
      # Counter with length N x 8 bits for bytes for the number of flows exported by the Observation Domain.

      def initialize(args={})
        args[:field_type] = 42
        args[:field_length] ||= 4 # Variable Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Total Exported Flows = #{self.value}"
      end

    end

    class Ipv4SrcPrefix < Ipv4Address
      # IPv4 source address prefix (specific for Catalyst architecture).

      def initialize(args={})
        args[:field_type] = 44
        super(args)
      end

      def humanize
        "Catalyst IPv4 Source Address Prefix = #{self.to_ipaddr.to_s}"
      end
    end

    class Ipv4DstPrefix < Ipv4Address
      # IPv4 destination address prefix (specific for Catalyst architecture).

      def initialize(args={})
        args[:field_type] = 45
        super(args)
      end

      def humanize
        "Catalyst IPv4 Destination Address Prefix = #{self.to_ipaddr.to_s}"
      end
    end

    class MplsTopLabelType < Netflow9FlowField
      # MPLS Top Label Type:
      #  0x00 UNKNOWN
      #  0x01 TE-MIDPT
      #  0x02 ATOM
      #  0x03 VPN
      #  0x04 BGP
      #  0x05 LDP.

      def initialize(args={})
        args[:field_type] = 46
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      def humanize
        mpls_top_label_type = case self.value.to_i
                                when 0x00
                                  "UNKNOWN"
                                when 0x01
                                  "TE-MIDPT"
                                when 0x02
                                  "ATOM"
                                when 0x03
                                  "VPN"
                                when 0x04
                                  "BGP"
                                when 0x05
                                  "LDP"
                                else
                                  "Undefined"
                              end
        "MPLS Top Label = #{mpls_top_label_type}"
      end
    end

    class MplsTopLabelIpAddr < Netflow9FlowField
      # Forwarding Equivalent Class corresponding to the MPLS Top Label.

      def initialize(args={})
        args[:field_type] = 47
        args[:field_length] = 4 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "MPLS FEC Class = #{self.value}"
      end

    end

    class FlowSamplerId < Netflow9FlowField
      # Identifier shown in "show flow-sampler".

      def initialize(args={})
        args[:field_type] = 48
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Flow Sampler Id = #{self.value}"
      end

    end

    class FlowSamplerMode < Netflow9FlowField
      # The type of algorithm used for sampling data: 0x02 random sampling.
      # Use in connection with FLOW_SAMPLER_MODE.

      def initialize(args={})
        args[:field_type] = 49
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Flow Sampler Mode = #{self.value}"
      end

    end

    class FlowSamplerRandomInterval < Netflow9FlowField
      # Packet interval at which to sample. Use in connection with FLOW_SAMPLER_MODE.

      def initialize(args={})
        args[:field_type] = 50
        args[:field_length] = 4 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Flow Sampler Random Interval = #{self.value}"
      end

    end

    class MinTtl < Netflow9FlowField
      # Minimum TTL on incoming packets of the flow.

      def initialize(args={})
        args[:field_type] = 52
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Minimum TTL = #{self.value}"
      end

    end

    class MaxTtl < Netflow9FlowField
      # Maximum TTL on incoming packets of the flow.

      def initialize(args={})
        args[:field_type] = 53
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Maximum TTL = #{self.value}"
      end

    end

    class Ipv4Ident < Netflow9FlowField
      # The IPv4 identification field.

      def initialize(args={})
        args[:field_type] = 54
        args[:field_length] = 2 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "IPv4 Identification Field = #{self.value}"
      end

    end

    class DstTos < Netflow9FlowField
      # Type of Service byte setting when exiting outgoing interface.

      def initialize(args={})
        args[:field_type] = 55
        args[:field_length] = 1 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Outgoing interface assigned TOS = #{self.value}"
      end

    end

    class MacAddress < Netflow9FlowField
      # "Virtual" class for mac addresses

      def initialize(args={})
        args[:field_length] = 6 # Fixed Length
        super(args)
      end

      def to_mac_address_s
        "%02x:%02x:%02x:%02x:%02x:%02x" % self.value.to_s.unpack("CCCCCC")
      end

    end

    class InSrcMac < MacAddress
      # Incoming source MAC address.

      def initialize(args={})
        args[:field_type] = 56
        super(args)
      end

      def humanize
        "Incoming Source MAC Address = #{self.to_mac_address_s}"
      end
    end

    class OutDstMac < MacAddress
      # Outgoing destination MAC address.

      def initialize(args={})
        args[:field_type] = 57
        super(args)
      end

      def humanize
        "Outgoing Destination MAC Address = #{self.to_mac_address_s}"
      end
    end

    class SrcVlan < Netflow9FlowField
      # Virtual LAN identifier associated with ingress interface.

      def initialize(args={})
        args[:field_type] = 58
        args[:field_length] = 2 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Ingress Interface VLAN ID = #{self.value}"
      end

    end

    class DstVlan < Netflow9FlowField
      # Virtual LAN identifier associated with egress interface.

      def initialize(args={})
        args[:field_type] = 59
        args[:field_length] = 2 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Egress Interface VLAN ID = #{self.value}"
      end

    end

    class IpProtocolVersion < Netflow9FlowField
      # Internet Protocol Version Set to 4 for IPv4, set to 6 for IPv6.

      def initialize(args={})
        args[:field_type] = 60
        args[:field_length] = 1 # Fixed Length
        args[:value] = (args[:value] == 6) ? 6 : 4
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "IP Version = #{self.value}"
      end

    end

    class Direction < Netflow9FlowField
      # Flow direction: 0 - ingress flow, 1 - egress flow.

      def initialize(args={})
        args[:field_type] = 61
        args[:field_length] = 1 # Fixed Length
        args[:value] = (args[:value] == 1) ? 1 : 0
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        direction = case self.value
                      when 1
                        "Egress"
                      else
                        "Ingress"
                    end
        "Direction = #{direction}"
      end

    end

    class Ipv6NextHop < Ipv6Address
      # IPv6 address of the next-hop router.

      def initialize(args={})
        args[:field_type] = 62
        super(args)
      end

      def humanize
        "IPv6 address of the next-hop router = #{self.to_ipaddr.to_s}"
      end
    end

    class BgpIpv6NextHop < Ipv6Address
      # IPv6 Next-hop router in the BGP domain.

      def initialize(args={})
        args[:field_type] = 63
        super(args)
      end

      def humanize
        "IPv6 BGP Next-Hop Router = #{self.to_ipaddr.to_s}"
      end
    end

    class Ipv6OptionHeaders < Netflow9FlowField
      # Bit-encoded field identifying IPv6 option headers found in the flow.

      def initialize(args={})
        args[:field_type] = 64
        args[:field_length] = 4 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "IPv6 Option Headers = #{self.value}"
      end

    end

    class MplsLabel1 < Netflow9FlowField
      # MPLS label at position 1 in the stack.

      def initialize(args={})
        args[:field_type] = 70
        args[:field_length] = 3 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Position 1 MPLS Label = #{self.value.inspect}"
      end

    end

    class MplsLabel2 < Netflow9FlowField
      # MPLS label at position 2 in the stack.

      def initialize(args={})
        args[:field_type] = 71
        args[:field_length] = 3 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Position 2 MPLS Label = #{self.value.inspect}"
      end

    end

    class MplsLabel3 < Netflow9FlowField
      # MPLS label at position 3 in the stack.

      def initialize(args={})
        args[:field_type] = 72
        args[:field_length] = 3 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Position 3 MPLS Label = #{self.value.inspect}"
      end


    end

    class MplsLabel4 < Netflow9FlowField
      # MPLS label at position 4 in the stack.

      def initialize(args={})
        args[:field_type] = 73
        args[:field_length] = 3 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Position 4 MPLS Label = #{self.value.inspect}"
      end


    end

    class MplsLabel5 < Netflow9FlowField
      # MPLS label at position 5 in the stack.

      def initialize(args={})
        args[:field_type] = 74
        args[:field_length] = 3 # Fixed Length
        super(args)
      end

      def decode
        self.value.to_s
      end

      # Return a human readable description and value for this field
      def humanize
        "Position 5 MPLS Label = #{self.value.inspect}"
      end

    end

    class MplsLabel6 < Netflow9FlowField
      # MPLS label at position 6 in the stack.

      def initialize(args={})
        args[:field_type] = 75
        args[:field_length] = 3 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Position 6 MPLS Label = #{self.value.inspect}"
      end


    end

    class MplsLabel7 < Netflow9FlowField
      # MPLS label at position 7 in the stack.

      def initialize(args={})
        args[:field_type] = 76
        args[:field_length] = 3 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Position 7 MPLS Label = #{self.value.inspect}"
      end


    end

    class MplsLabel8 < Netflow9FlowField
      # MPLS label at position 8 in the stack.

      def initialize(args={})
        args[:field_type] = 77
        args[:field_length] = 3 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Position 8 MPLS Label = #{self.value.inspect}"
      end


    end

    class MplsLabel9 < Netflow9FlowField
      # MPLS label at position 9 in the stack.

      def initialize(args={})
        args[:field_type] = 78
        args[:field_length] = 3 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Position 9 MPLS Label = #{self.value.inspect}"
      end

    end

    class MplsLabel10 < Netflow9FlowField
      # MPLS label at position 10 in the stack.

      def initialize(args={})
        args[:field_type] = 79
        args[:field_length] = 3 # Fixed Length
        super(args)
      end

      # Return a human readable description and value for this field
      def humanize
        "Position 10 MPLS Label = #{self.value.inspect}"
      end

    end

  end

  class Netflow9DecodedDataFlowFields < Array
    # Decoded (from a template) flow fields
    def initialize(args={})
      @template_fields = args.delete(:template_fields) || raise(ArgumentError, "Missing template definition")
    end

    def to_s(args={})
      self.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      self.clear
      PacketFu.force_binary(str)
      return self if (!str.respond_to? :to_s or str.nil?)

      i = 0
      @template_fields.each do |template_field|
        if i >= str.size
          raise("Invalid packet")
        end
        # Instantiate the right class for this flow field
        this_flow_field_class = Netflow9FlowField.field_type_to_class(template_field.field_type.to_i)
        this_flow_field = if this_flow_field_class.nil?
                            Netflow9FlowField.new(:field_type => template_field.field_type.to_i,
                                                  :field_length => template_field.field_length.to_i)
                          else
                            this_flow_field_class.new(:field_length => template_field.field_length.to_i)
                          end

        this_flow_field.read(str[i, template_field.field_length])
        self << this_flow_field
        i += template_field.field_length
      end

      self
    end

    def generate_template_fields
      Netflow9TemplateFields.new.read(self.map { |x| x.generate_template_field.to_s }.join)
    end

    def humanize
      self.map { |x| x.humanize }.join("\n") + "\n"
    end

  end

  class Netflow9DecodedDataFlow < Struct.new(
      :decoded_data_flow_fields
  )
    #noinspection RubyResolve
    include StructFu

    def initialize(args={})
      @template_fields = args.delete(:template_fields) || raise(ArgumentError, "Missing template definition")
      raise(ArgumentError, "Wrong template definition") if @template_fields.class != Netflow9TemplateFields

      super(
          Netflow9DecodedDataFlowFields.new(
              { :template_fields => @template_fields }
          ).read(args[:decoded_data_flow_fields])
      )
    end

    def to_s(args={})
      str = self.map { |x| x.to_s }.join
      # Add the padding
      str + ("\x00" * (4 - (str.size % 4)))
    end

    # Reads a string to populate the object.
    def read(str)
      PacketFu.force_binary(str)

      return self if (!str.respond_to? :to_s or str.nil?)
      self[:decoded_data_flow_fields] = Netflow9DecodedDataFlowFields.new(:template_fields => @template_fields)
      self[:decoded_data_flow_fields].read(str)

      self
    end

    def humanize
      self[:decoded_data_flow_fields].humanize
    end

  end

  class Netflow9RawDataFlows < Struct.new(:flows_data)

    #noinspection RubyResolve
    include StructFu

    def initialize(args={})
      super(args[:flows_data].nil? ? nil : args[:flows_data].clone)
    end

    def to_s(args={})
      str = self.map { |x| x.to_s }.join
      # Add the padding
      str + ("\x00" * (4 - (str.size % 4)))
    end

    # Reads a string to populate the object.
    def read(str)
      PacketFu.force_binary(str)

      return self if str.nil?
      self[:flows_data] = str.clone

      self
    end

    # Accessor methods
    def flows_data=(i); self[:flows_data] = typecast i end
    def flows_data; self[:flows_data].to_s end

    def count_flows
      raise("Can't count flows in a #{self.class} instance...")
    end

    def humanize
      "Netflow9RawDataFlows"
      #flows_data.inspect
    end

  end

  class Netflow9DataFlows < Array
    #noinspection RubyResolve
    include StructFu

    def initialize(args={})
      @template_fields = args.delete(:template_fields)
    end

    def to_s(args={})
      self.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      self.clear
      PacketFu.force_binary(str)
      return self if (!str.respond_to? :to_s or str.nil?)

      if @template_fields.nil?
        # We don't have a template... let's read the raw data
        self << Netflow9RawDataFlows.new.read(str)
      else
        flow_size = @template_fields.flow_size
        i = 0
        while (i + flow_size) <= str.size
          this_flow = Netflow9DecodedDataFlow.new(:template_fields => @template_fields)
          this_flow.read(str[i, flow_size])
          self << this_flow
          i += flow_size
        end
      end

      self
    end

    def decode(template_fields)
      @template_fields = template_fields
      self.read(self.to_s)
    end

    def generate_template_fields
      Netflow9TemplateFields.new.read(self.map { |x| x.generate_template_field.to_s }.join)
    end

    def humanize
      self.map { |x| x.humanize }.join("\n") + "\n"
    end

  end

  # Flowsets classes

  class Netflow9UnknownFlows < Struct.new(
      :flows_data
  )
    #noinspection RubyResolve
    include StructFu

    def initialize(args={})
      super(args[:flows_data].nil? ? nil : args[:flows_data].clone)
    end

    def to_s(args={})
      self.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      PacketFu.force_binary(str)

      return self if str.nil?
      self[:flows_data] = str.clone

      self
    end

    def count_flows
      # TODO ...
      raise("Can't count #{self.class} instance...")
    end

    # Accessor methods
    def flows_data=(i); self[:flows_data] = typecast i end
    def flows_data; self[:flows_data].to_s end

    def humanize
      "Netflow9UnknownFlows"
      #flows_data.inspect
    end

  end

  class Netflow9Flowset < Struct.new(
      :flowset_id,
      :flowset_length,
      :flows
  )
    #noinspection RubyResolve
    include StructFu

    def initialize(args={})
      raise(ArgumentError, "Invalid flowset_length") if (!args[:flowset_length].nil? and args[:flowset_length] <= 0)
      super(
          Int16.new(args[:flowset_id]),
          Int16.new(args[:flowset_length]),
          # Select the right flowset type
          if args[:flowset_id].nil?
            nil
          else
            if args[:flowset_id].to_i == 0
              Netflow9Templates.new.read(args[:flows])
            elsif args[:flowset_id].to_i == 1
              #Netflow9FOptions.new.read(args[:flows])
              Netflow9UnknownFlows.new.read(args[:flows])
            elsif args[:flowset_id].to_i > 255
              Netflow9DataFlows.new.read(args[:flows])
            else
              raise(ArgumentError, "Unknown flowset `#{args[:flowset_id].to_i}'")
            end
          end
      )
      @decoded = false
    end

    def to_s(args={})
      self.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      @decoded = false
      PacketFu.force_binary(str)

      return self if str.nil?
      self[:flowset_id].read(str[0, 2])
      self[:flowset_length].read(str[2, 2])
      raise("Invalid flowset_length") if self[:flowset_length].to_i <= 4

      if self[:flowset_id].to_i == 0
        self[:flows]=Netflow9Templates.new
      elsif self[:flowset_id].to_i == 1
        # TODO Options Template Flows
        self[:flows]=Netflow9UnknownFlows.new
      elsif self[:flowset_id].to_i > 255
        self[:flows]=Netflow9DataFlows.new
      else
        self[:flows]=Netflow9UnknownFlows.new
      end
      # flowset_length is the len of the whole flowset, id and len included
      self[:flows].read(str[4, [str.size, self[:flowset_length].to_i - 4].min])

      self
    end

    def is_a_template_flowset?
      self[:flowset_id].to_i == 0
    end

    def is_a_data_flowset?
      self[:flowset_id].to_i > 255
    end

    def count_flows
      self[:flows].count_flows
    end

    def decode(template)
      self[:flows].decode(template) if self.is_a_data_flowset?
      @decoded = true
    end

    # Accessor methods
    def flowset_id=(i); self[:flowset_id] = typecast i end
    def flowset_id; self[:flowset_id].to_i end

    def flowset_length=(i)
      self[:flowset_length] = typecast i
      raise(ArgumentError,"Invalid flowset_length") if self[:flowset_length].to_i <= 4
    end # Usually calc()'ed
    def flowset_length; self[:flowset_length].to_i end

    # Recalculates calculated fields.
    def recalc(args=:all)
      case args
        when :flowset_length
          self.flowset_length = self.to_s.size
        when :all
          self.flowset_length = self.to_s.size
        else
          raise(ArgumentError, "No such field '#{args}'")
      end
    end

    def humanize
      self.flows.humanize
    end

  end

  class Netflow9Flowsets < Array
    #noinspection RubyResolve
    include StructFu

    def to_s(args={})
      self.map { |x| x.to_s }.join
    end

    # Reads a string to populate the object.
    def read(str)
      self.clear
      PacketFu.force_binary(str)

      return self if (!str.respond_to? :to_s or str.nil?)

      i = 0
      while i < str.to_s.size
        this_record = Netflow9Flowset.new.read(str[i, str.size])
        self << this_record
        #noinspection RubyResolve
        i += this_record.sz
      end
      self
    end

    def count_flows
      cnt = 0
      self.each { |x| cnt += x.count_flows }
      cnt
    end

    def template_flowsets
      self.select { |x| x.is_a_template_flowset? }
    end

    def data_flowsets
      self.select { |x| x.is_a_data_flowset? }
    end

    # Decode data flowsets against the right template template
    def decode_data(templates)
      self.each do |flowset|
        if flowset.is_a_data_flowset?
          template = templates[flowset.flowset_id]
          # Decode the data flowset
          flowset.decode(template) unless template.nil?
          # else => Unknown template
        end
      end
    end
  end

# Main

  class Netflow9 < Struct.new(
      :version,
      :flow_records,
      :uptime,
      :unix_seconds,
      :flow_sequence_number,
      :source_id,
      :flowsets
  )
    #noinspection RubyResolve
    include StructFu

    def initialize(args={})
      super(
          Int16.new(args[:version]),
          Int16.new(args[:flow_records]),
          Int32.new(args[:uptime]),
          Int32.new(args[:unix_seconds]),
          Int32.new(args[:flow_sequence_number]),
          Int32.new(args[:source_id]),
          Netflow9Flowsets.new.read(args[:flowsets])
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
      self[:flow_records].read(str[2, 2])
      self[:uptime].read(str[4, 4])
      self[:unix_seconds].read(str[8, 4])
      self[:flow_sequence_number].read(str[12, 4])
      self[:source_id].read(str[16, 4])
      self[:flowsets].read(str[20, str.size])

      self
    end

    def template_flowsets
      self.flowsets.template_flowsets
    end

    def data_flowsets
      self.flowsets.data_flowsets
    end

    # Decode netflow data against passed NetflowTemplates
    # It takes an hash of { template_id => NetflowTemplate } elements
    def decode_data(templates)
      return if templates.nil? or templates.empty?

      self[:flowsets].decode_data(templates)
    end

    # Accessor methods
    def version=(i); self[:version] = typecast i end
    def version; self[:version].to_i end

    def flow_records=(i); self[:flow_records] = typecast i end # Usually calc()'ed
    def flow_records; self[:flow_records].to_i end

    def uptime=(i); self[:uptime] = typecast i end
    def uptime; self[:uptime].to_i end

    def unix_seconds=(i); self[:unix_seconds] = typecast i end # Usually calc()'ed
    def unix_seconds; self[:unix_seconds].to_i end

    def flow_sequence_number=(i); self[:flow_sequence_number] = typecast i end
    def flow_sequence_number; self[:flow_sequence_number].to_i end

    def source_id=(i); self[:source_id] = typecast i end
    def source_id; self[:source_id].to_i end

    # Recalculates calculated fields.
    def recalc(args=:all)
      case args
        when :flow_records
          self.flow_records = self.flowsets.count_flows
        when :unix_seconds
          self.unix_seconds = Time.now.to_i
        when :all
          self.flow_records = self.flowsets.count_flows
          self.unix_seconds = Time.now.to_i
        else
          raise(ArgumentError, "No such field '#{args}'")
      end
    end

  end

end
