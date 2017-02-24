# encoding: ASCII-8BIT


module Extron; end
module Extron::UsbExtenderPlus; end


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



class Extron::UsbExtenderPlus::Endpoint
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder

    # Discovery Information
    udp_port 6137
    descriptive_name 'Extron USB Extender Plus Endpoint'
    generic_name :USB_Device
    delay between_sends: 300


    def on_load
        on_update
    end

    def on_update
        # Ensure the MAC address is in a consistent format
        self[:mac_address] = byte_to_hex(hex_to_byte(setting(:mac_address)))
        self[:ip] = remote_address
        self[:port] = remote_port

        self[:location] = setting(:location)

        @polling_timer.cancel unless @polling_timer.nil?
        @polling_timer = schedule.every('120s') do
            logger.debug "-- polling extron USB device"
            promise = query_joins

            # Manually set the connection state (UDP device)
            promise.then do
                set_connected_state(true) unless self[:connected]
            end
            promise.catch do
                set_connected_state(false) if self[:connected]
                logger.warn "Extron USB Device Probably Offline: #{remote_address}\nUDP Ping failed."
            end
        end

        query_joins
    end


    def query_joins
        promise = send('2f03f4a2000000000300', hex_string: true)
        promise.catch do
            set_connected_state(false) if self[:connected]
            logger.warn "Extron USB Device Probably Offline: #{remote_address}\nJoin query failed."
        end
        promise
    end


    def ping
        send('2f03f4a2010000000002', hex_string: true)
    end


    def unjoin_all
        if self[:joined_to].empty?
            logger.debug 'nothing to unjoin from'
        end

        self[:joined_to].each do |mac|
            send_unjoin(mac)
        end

        query_joins
    end

    def unjoin(from)
        mac = if from.is_a? Integer
            self[:joined_to][from]
        else
            formatted = byte_to_hex(hex_to_byte(from))
            if self[:joined_to].include? formatted
                formatted
            else
                nil
            end
        end

        if mac
            send_unjoin(mac)
            query_joins
        else
            logger.debug { "not currently joined to #{from}" }
        end
    end

    def join(mac)
        logger.debug { "joining with #{mac}" }
        send "2f03f4a2020000000302#{mac}", hex_string: true, wait: false, delay: 600
    end


    def received(data, resolve, command)
        resp = byte_to_hex(data)

        logger.debug { "Extron USB sent #{resp}" }

        check = resp[0..21]
        if check == '2f03f4a200000000030100' || check == '2f03f4a200000000030101'
            self[:is_host] = check[-1] == '0'

            macs = resp[22..-1].scan(/.{12}/)
            logger.debug { "Extron USB joined with: #{macs}" }
            self[:joined_to] = macs
        elsif resp == '2f03f4a2010000000003'
            logger.debug 'Extron USB responded to UDP ping'
        elsif resp == '2f03f4a2020000000003'
            # I think this is a busy response...
            return :retry
        else
            logger.info "Unknown response from extron: #{resp}"
        end

        :success
    end


    protected


    def send_unjoin(mac)
        logger.debug { "unjoining from #{mac}" }
        send "2f03f4a2020000000303#{mac}", hex_string: true, wait: false, delay: 600
    end
end
