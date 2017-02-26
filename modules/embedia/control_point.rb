module Embedia; end

class Embedia::ControlPoint
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder


    descriptive_name 'Embedia Control Point Blinds'
    generic_name :Blinds
    implements   :device

    
    delay between_sends: 200
    tokenize indicator: ':', delimiter: "\r\n"



    def on_load
        on_update
    end

    def on_update
    end

    def connected
        @polling_timer = schedule.every('50s') do
            logger.debug "Maintaining connection"
            query_sensor 0
        end
    end
    
    def disconnected
        @polling_timer.cancel unless @polling_timer.nil?
        @polling_timer = nil
    end

    Commands = {
        stop: 0x28,
        extend: 0x4e,
        retract: 0x4b,
        next_extent_preset: 0x4f,
        previous_extent_preset: 0x50,

        close: 0x16,
        open: 0x1a,
        next_tilt_preset: 0x07,
        previous_tilt_preset: 0x04,

        clear_override: 0x4c
    }
    Commands.each do |command, value|
        define_method command do |address, **options|
            do_send [address.to_i, 0x06, 0, 1, 0, value], **options
        end
    end

    def extent_preset(address, number)
        num = 0x1D + in_range(number.to_i, 10, 1)
        do_send [address.to_i, 0x06, 0, 1, 0, num], name: :extent_preset
    end

    def tilt_preset(address, number)
        num = 0x39 + in_range(number.to_i, 10, 1)
        do_send [address.to_i, 0x06, 0, 1, 0, num], name: :tilt_preset
    end

    def query_sensor(address)
        do_send [address.to_i, 0x03, 0, 1, 0, 1]
    end

    def received(data_raw, resolve, command)
        logger.debug { "Embedia sent #{data_raw}" }

        data = hex_to_byte(data_raw[1..-1])
        address = data[0]
        func = data[1]

        case func
        when 3 # Sensor level
            logger.info "Sensor response #{data_raw} on address 0x#{address.to_s(16)}"
        else
            logger.info "Unknown response #{data_raw} on address 0x#{address.to_s(16)}"
        end

        return :success
    end


    protected


    def do_send(data, **options)
        sending = byte_to_hex(data + [lrc_checksum(data)])
        logger.debug "sending :#{sending}"
        send ":#{sending)}\r\n", **options
    end

    def lrc_checksum(data)
        lrc = 58 # === ':'
        data.each do |byte|
            lrc = lrc ^ byte
        end
        (lrc & 0xFF)
    end
end
