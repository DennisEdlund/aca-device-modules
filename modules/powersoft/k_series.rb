module Powersoft; end


# Channel Range: 1 -> 4000


class Powersoft::KSeries
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder

    # Discovery Information
    tcp_port 8002
    descriptive_name 'Powersoft K-Series Amplifier'
    generic_name :Amplifier

    tokenize indicator: "\x02", delimiter: "\x03"


    def on_load
        on_update
    end

    def on_update
        id = (setting(:device_id) || 65).to_s.rjust(2, '0')
        @device_id = str_to_array(id)
    end

    def connected
        schedule.every('50s') do
            logger.debug "polling"
            get_meters
        end
    end

    def disconnected
        schedule.clear
    end

    #
    # Power commands
    #
    def power(state)
        target = is_affirmative?(state)
        promise = if target
            do_send(0x70, 0x31)
        else
            do_send(0x70, 0x30)
        end
        promise.then do
            self[:power] = target
        end
    end

    def mute(index, value = true)
        val = is_affirmative?(value) ? 0x31 : 0x30
        do_send(0x6d, 0x30 + index.to_i, val)
    end

    def get_firmware_ver
        do_send(0x49, priority: 0)
    end

    def get_meters
        do_send(0x4c, priority: 0)
    end

    def get_status
        do_send(0x53, priority: 0)
    end

    def get_voltages
        do_send(0x54, priority: 0)
    end


    protected


    ResponseCode = {
        0x04 => :inv,
        0x06 => :ack,
        0x15 => :nack,
        0x49 => :firmware,
        0x4C => :meters,
        0x53 => :status,
        0x54 => :voltages,
        0x78 => :relays,
        0x4A => :alarm_and_load
    }

    def received(data, resolve, command)
        resp = unescape(data)

        logger.debug { "received 0x#{byte_to_hex(resp)}" }

        device_id = resp[0..1]
        resp_code = resp[2]
        resp      = resp[3..-1]

        # resp == device id, code, data
        case ResponseCode[resp_code]
        when :inv, :nack
            logger.debug { "aborted due to #{ResponseCode[resp_code]}" }
            return :abort
        when :ack
            logger.debug "acknowledgment received"
        when :firmware
            logger.debug "firmware received"
        when :meters
            resp.shift(2)

            self[:current1] = get_short(resp)
            self[:current2] = get_short(resp)
            self[:voltage1] = get_short(resp)
            self[:voltage2] = get_short(resp)
        when :status
            self[:dsp_model] = array_to_str(bytes.shift(2))
            self[:out_attenuation1] = get_short(resp)
            self[:out_attenuation2] = get_short(resp)

            # DSP Mute
            bits = get_short(resp)
            self[:dsp_mute1] = (bits & 0b1) > 0
            self[:dsp_mute2] = (bits & 0b10) > 0

            self[:mod_temp] = get_short(resp)

            # Protection
            bits = get_short(resp)
            self[:protection1]          = (bits & 0b1) > 0
            self[:hw_protection1]       = (bits & 0b10) > 0
            self[:alarm_triggered1]     = (bits & 0b100) > 0
            self[:dsp_alarm_triggered1] = (bits & 0b1000) > 0
            self[:protection2]          = (bits & 0b10000) > 0
            self[:hw_protection2]       = (bits & 0b100000) > 0
            self[:alarm_triggered2]     = (bits & 0b1000000) > 0
            self[:dsp_alarm_triggered2] = (bits & 0b10000000) > 0

            # Ready
            bits = get_short(resp)
            self[:presence]      = (bits & 0b1) > 0
            self[:last_on_off]   = (bits & 0b10) > 0
            self[:mod1_ready]    = (bits & 0b100) > 0
            self[:device_on]     = (bits & 0b1000) > 0
            self[:channel1_idle] = (bits & 0b100000) > 0 # note skipped bit 5
            self[:channel2_idle] = (bits & 0b1000000) > 0

            # Flags
            bits = get_short(resp)
            self[:signal1] = (bits & 0b1) > 0
            self[:signal2] = (bits & 0b10) > 0

            self[:protection_count] = get_short(resp)
            self[:impedances1] = get_uint(resp)
            self[:impedances2] = get_uint(resp)
            self[:gains1] = get_short(resp)
            self[:gains2] = get_short(resp)
            self[:out_voltages1] = get_short(resp)
            self[:out_voltages2] = get_short(resp)
            self[:max_mains] = get_short(resp)

            # Limiter
            bits = get_short(resp)
            self[:clip1] = (bits & 0b1) > 0
            self[:clip2] = (bits & 0b10) > 0
            self[:gate1] = (bits & 0b100) > 0
            self[:gate2] = (bits & 0b1000) > 0

            self[:mod_counter] = get_uint(resp)

            # Board
            bits = get_short(resp)
            self[:board1] = (bits & 0b1) > 0
            self[:board2] = (bits & 0b10) > 0
            self[:board3] = (bits & 0b100) > 0
            self[:board4] = (bits & 0b1000) > 0
            self[:board5] = (bits & 0b10000) > 0

            self[:input_routing] = get_short(resp)
            self[:idle_time] = get_uint(resp)
            self[:dsp_mod_counter] = get_uint(resp)
            self[:dsp_crc1] = get_uint(resp)
            self[:dsp_crc2] = get_uint(resp)
            self[:dsp_crc0] = get_uint(resp)
            self[:kaesop_mod_counter] = get_uint(resp)
            self[:kaesop_crc] = get_uint(resp)
        when :voltages
            resp.shift(2)

            self[:pos_aux_voltage] = get_short(resp)
            self[:neg_aux_voltage] = get_short(resp)
            self[:aux_analog_voltage] = get_short(resp) * 0.1
            self[:main_voltage] = get_short(resp)
            self[:main_current] = get_short(resp)
            self[:external_voltage] = get_short(resp) * 0.1
            self[:pos_bus_voltage1] = get_short(resp)
            self[:neg_bus_voltage1] = get_short(resp)
            self[:pos_bus_voltage2] = get_short(resp)
            self[:neg_bus_voltage2] = get_short(resp)

            bits = get_short(resp)
            self[:dsp_clock] = (bits & 0b1) > 0
            self[:dsp_vaux]  = (bits & 0b10) > 0
            self[:dsp_igbt]  = (bits & 0b100) > 0
            self[:dsp_boost] = (bits & 0b1000) > 0

            self[:led] = get_short(resp)

        when :relays
            logger.debug "relays board message received"
        when :alarm_and_load
            logger.debug "alarm tone and load received"
        end

        :success
    end

    def get_short(bytes)
        array_to_str(bytes.shift(2)).unpack('n')[0]
    end

    def get_uint(bytes)
        array_to_str(bytes.shift(4)).unpack('N')[0]
    end


    EscapeChar = 0x1B
    ReservedBytes = [0x02, 0x03, 0x7B, 0x7D, EscapeChar]


    def escape(bytes)
        escaped = []
        bytes.each do |byte|
            if ReservedBytes.include?(byte)
                escaped << EscapeChar
                escaped << (byte + 0x40)
            else
                escaped << byte
            end
        end
        escaped
    end

    def unescape(str)
        bytes = str_to_array(str)
        unescaped = []
        bytes.each_with_index do |byte, index|
            if EscapeChar == byte && bytes[index + 1] && bytes[index + 1] > 0x40
                bytes[index + 1] = bytes[index + 1] + 0x40
            else
                unescaped << byte
            end
        end
        unescaped
    end

    def checksum(bytes)
        check = 0
        bytes.each { |byte| check = check ^ byte }
        check
    end

    def do_send(*cmd, **options)
        encoded = [0x02] + escape(@device_id + cmd)
        check = checksum(encoded)
        send(encoded + [check, 0x03], options)
    end
end
