# encoding: ASCII-8BIT

load File.expand_path('../base.rb', File.dirname(__FILE__))
module Extron::Switcher; end


# :title:Extron USB Switcher
#
# Status information avaliable:
# -----------------------------
#
# (built in)
# connected
#
# (module defined)
# input



class Extron::Switcher::UsbExtenderPlus < Extron::Base
    # Discovery Information
    udp_port 6137
    descriptive_name 'Extron USB Extender Plus'
    generic_name :Switcher
    delay between_sends: 100


    def on_load
        on_update
    end

    def on_update
        @disable_polling = @__config__.settings.udp

        # The transmitter is the computer / host
        @mac_address = setting(:mac_address).downcase
        @host_ip = remote_address
        @port = setting(:pair_port) || 6137
        @unpair = Array(setting(:unpair))

        # Receivers are the devices, like keyboards and mice
        # { "location name": ["ip", "mac_address", port] } # port is optional
        self[:receivers] = setting(:receivers) || {}
        @lookup = self[:receivers].values

        @lookup.each do |dev|
            dev[1] = dev[1].downcase
        end
        @unpair.map! { |mac| mac.downcase }
    end


    def switch_to(input)
        device = input.is_a?(Integer) ? @lookup[input] : self[:receivers][input.to_sym]

        if device
            rec_mac = device[1]
            query_join.then do
                if self[:joined_to].include? rec_mac
                    logger.debug { "device #{device[0]} already joined" }
                else
                    unpair(device)
                    logger.debug { "pairing #{device[0]} to #{@host_ip}" }
                    
                    # pair just this device to this host
                    to_host = hex_to_byte("2f03f4a2020000000302#{device[1]}")
                    thread.udp_service.send(@host_ip, @port, to_host)
                    logger.debug { "pair desk: \"#{@host_ip}\", \"#{byte_to_hex(to_host)}\"" }

                    to_device = hex_to_byte("2f03f4a2020000000302#{@mac_address}")
                    thread.udp_service.send(device[0], device[2] || @port, to_device)
                    logger.debug { "pair disp: \"#{receiver[0]}\", \"#{byte_to_hex(to_device)}\"" }
                end
            end
        else
            logger.warn("#{input} receiver not found")
        end
    end


    def query_join
        send('2f03f4a2000000000300', hex_string: true, name: :join_query)
    end


    def ping_device
        send('2f03f4a2010000000002', hex_string: true)
    end


    def send_hex(ip, hex_string)
        thread.udp_service.send(ip, @port, hex_to_byte(hex_string))
    end


    def received(data, resolve, command)
        resp = byte_to_hex(data)

        logger.debug { "Extron USB sent #{resp}" }

        if resp[0..21] == '2f03f4a200000000030100'
            macs = resp[22..-1].scan(/.{12}/)
            logger.debug { "Extron USB joined with: #{macs}" }
            self[:joined_to] = macs
        elsif resp == '2f03f4a2010000000003'
            logger.debug 'Extron USB responded to UDP ping'
        else
            logger.debug 'Unknown response'
        end

        :success
    end

=begin

    # These methods are for RS232 comms only...

    def keyboard_emulation(enable)
        val = is_affirmative?(enable) ? 1 : 0
        do_send("\eE#{val}USBC", name: :emulation)
    end

    def is_keyboard_emulated?
        do_send("\eEUSBC", name: :emulation_query)
    end

    def network_pairing(enable)
        val = is_affirmative?(enable) ? 1 : 0
        do_send("\eN#{val}USBC", name: :pair)
    end

    def can_network_pair?
        do_send("\eNUSBC", name: :pair_query)
    end


    ERRORS = {
        10 => 'Invalid command',
        12 => 'Invalid port number',
        13 => 'Invalid parameter (number is out of range)',
        14 => 'Not valid for this configuration',
        22 => 'Busy',
        24 => 'Privilege violation',
        25 => 'Device is not present'
    }


    def received(data, resolve, command)
        logger.debug { "Extron USB sent #{data}" }

        if data =~ /Login/i
            device_ready
        elsif data[0] == 'E'
            logger.info "Extron Error #{ERRORS[data[1..2].to_i]}"
            logger.info "- for command #{command[:data]}" unless command.nil?
        elsif command && command[:name]
            case command[:name]
            when :emulation
                # UsbcE1
                self[:emulating] = data[5] == '1'
            when :emulation_query
                self[:emulating] = data[0] == '1'
            when :pair
                # UsbcN1
                self[:pairing_enabled] = data[5] == '1'
            when :pair_query
                self[:pairing_enabled] = data[0] == '1'
            end
        end

        return :success
    end

    def device_ready
        do_send("\e3CV", :wait => true)    # Verbose mode and tagged responses
        network_pairing(true)
    end

=end


    protected



    def unpair(device)
        @unpair.each do |host|
            to_host = hex_to_byte("2f03f4a2020000000303#{device[1]}")
            thread.udp_service.send(host[0], host[2] || @port, to_host)
            logger.debug { "unpair host #{host[0]} from #{device[0]}" }

            to_device = hex_to_byte("2f03f4a2020000000303#{host[1]}")
            thread.udp_service.send(device[0], device[2] || @port, to_device)
            logger.debug { "unpair device #{device[0]} from #{host[0]}" }
        end
    end
end
