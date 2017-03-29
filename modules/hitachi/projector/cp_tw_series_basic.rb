# encoding: ASCII-8BIT

module Hitachi; end
module Hitachi::Projector; end

# NOTE:: For implementing auth for this device.
# See the manual and the Panasonic Projector implementation (similar)

class Hitachi::Projector::CpTwSeriesBasic
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder


    # Discovery Information
    tcp_port 23
    descriptive_name 'Hitachi CP-TW Projector (no auth)'
    generic_name :Display

    # Communication settings
    tokenize indicator: "\xBE\xEF", msg_length: 11

    # Response time is slow
    # and as a make break device it may take time
    # to acctually setup the connection with the projector
    delay on_receive: 100
    wait_response timeout: 5000, retries: 3


    def on_load
        self[:power] = false

        # Stable by default (allows manual on and off)
        self[:stable_state] = true

        # Meta data for inquiring interfaces
        self[:type] = :projector

        on_update
    end

    def on_update
    end

    def connected
        power?(priority: 0)
        lamp_hours?(priority: 0)

        schedule.every('20s') do
            power?(priority: 0)
            #lamp_hours?(priority: 0)
        end
    end

    def disconnected
        schedule.clear
    end


    def power(state)
        self[:stable_state] = false

        if is_affirmative?(state)
            logger.debug "-- requested to power on"
            self[:power_target] = On
            do_send "BA D2 01 00 00 60 01 00", name: :power
            power? priority: 0
        else
            logger.debug "-- requested to power off"
            self[:power_target] = Off
            do_send "2A D3 01 00 00 60 00 00", name: :power
            power? priority: 0
        end
    end

    def power?(**options)
        do_send "19 D3 02 00 00 60 00 00", options
    end

    
    protected


    def received(data, resolve, command)
        logger.debug { "received \"0x#{byte_to_hex(data)}\"" }

        :success
    end

    def do_send(data, **options)
        cmd = "BEEF030600 #{data}"
        options[:hex_string] = true
        logger.debug { "sent \"0x#{cmd}\" name: #{options[:name]}" }
        send cmd, options
    end
end

