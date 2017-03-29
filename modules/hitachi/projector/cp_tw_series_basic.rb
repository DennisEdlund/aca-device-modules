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
        self[:stable_power] = true

        # Meta data for inquiring interfaces
        self[:type] = :projector

        on_update
    end

    def on_update
    end

    def connected
        power? priority: 0
        input? priority: 0
        lamp? priority: 0
        filter? priority: 0
        audio_mute? priority: 0
        picture_mute? priority: 0
        freeze? priority: 0
        error? priority: 0

        schedule.every('20s') do
            power?(priority: 0).then do
                if self[:power] == On
                    input? priority: 0
                    audio_mute? priority: 0
                    picture_mute? priority: 0
                end
            end
        end

        schedule.every('10m') do
            lamp? priority: 0
            filter? priority: 0
            error? priority: 0
        end
    end

    def disconnected
        schedule.clear
    end


    def power(state)
        self[:stable_power] = false

        if is_affirmative?(state)
            logger.debug "-- requested to power on"
            self[:power_target] = On
            do_send "BA D2 01 00 00 60 01 00", name: :power
            power?
        else
            logger.debug "-- requested to power off"
            self[:power_target] = Off
            do_send "2A D3 01 00 00 60 00 00", name: :power
            power?
        end
    end

    INPUTS = {
        hdmi: '0E D2 01 00 00 20 03 00',
        hdmi2: '6E D6 01 00 00 20 0D 00'
    }
    def switch_to(input)
        inps = input.to_sym
        self[:stable_input] = false
        self[:input_target] = inps
        do_send INPUTS[inps], name: :input
    end

    def mute(state = true)
        if is_affirmative?(state)
            do_send "6E F1 01 00 A0 20 01 00"
        else
            do_send "FE F0 01 00 A0 20 00 00"
        end
    end

    def unmute
        mute false
    end 

    def mute_audio(state = true)
        if is_affirmative?(state)
            do_send "D6 D2 01 00 02 20 01 00"
        else
            do_send "46 D3 01 00 02 20 00 00"
        end
    end


    QueryRequests = {
        power?: "19 D3 02 00 00 60 00 00",
        input?: "CD D2 02 00 00 20 00 00",
        error?: "D9 D8 02 00 20 60 00 00",
        freeze?: "B0 D2 02 00 02 30 00 00",
        audio_mute?: "75 D3 02 00 02 20 00 00",
        picture_mute?: "CD F0 02 00 A0 20 00 00",
        lamp?: "C2 FF 02 00 90 10 00 00",
        filter?: "C2 F0 02 00 A0 10 00 00"
    }
    QueryRequests.each do |request, cmd|
        define_method request do |opts = {}|
            opts[:query] = request
            do_send(cmd, opts)
        end
    end

    def lamp_hours_reset
        do_send('58 DC 06 00 30 70 00 00')
    end

    def filter_hours_reset
        do_send('98 C6 06 00 40 70 00 00')
    end

    
    protected


    ResponseCodes = {
        0x06 => :ack,
        0x15 => :nak,
        0x1c => :error,
        0x1d => :data,
        0x1f => :busy
    }

    def received(data, resolve, command)
        logger.debug { "received \"0x#{byte_to_hex(data)}\" for #{command ? byte_to_hex(command[:data]) : 'unknown'}" }

        resp = str_to_array(data)
        case ResponseCodes[resp[0]]
        when :ack
            :success
        when :nak
            logger.debug "NAK response"
            :abort
        when :error
            logger.debug "Error response"
            :abort
        when :data
            if command
                case command[:query]
                when :power?
                    self[:power] = resp[1] == 0
                    self[:cooling] = resp[1] == 2

                    if self[:power] == self[:power_target]
                        self[:stable_power] = true
                    elsif not self[:stable_power]
                        logger.debug "recovering power state #{self[:power]} != target #{self[:power_target]}"
                        power(self[:power_target])
                    end
                when :input?

                when :error?
                when :freeze?
                when :audio_mute?
                when :picture_mute?
                when :lamp?
                when :filter?
                else
                    logger.warn "unknown command query: #{command[:query]}"
                end
            else
                logger.warn "data received for unknown command"
            end
        when :busy
            if resp[1] == 0x04 && resp[2] == 0x00
                logger.warn "authentication enabled, please disable"
                :abort
            else
                logger.debug "projector busy, retrying"
                :retry
            end
        end
    end

    def do_send(data, **options)
        cmd = "BEEF030600 #{data}"
        options[:hex_string] = true
        logger.debug { "sent \"0x#{cmd}\" name: #{options[:name]}" }
        send cmd, options
    end
end

