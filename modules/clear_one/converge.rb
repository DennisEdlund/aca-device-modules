# encoding: US-ASCII

module ClearOne; end

class ClearOne::Converge
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder


    # Discovery Information
    tcp_port 23 # Telnet
    descriptive_name 'ClearOne Converge'
    generic_name :Mixer

    # Starts with: "Version 4.4.0.2\r\n\r\n" then requests authenitcation
    tokenize delimiter: "\r\n", wait_ready: /Version.+\r\n\r/i
    clear_queue_on_disconnect!


    default_settings({
        # Specifying '*' for device type works however it returns
        # failures with the success for other devices
        device_type: 'H',
        device_id: '*',
        username: 'clearone',
        password: 'converge'
    })


    DeviceTypes = {
        converge_880t: 'D',
        converge_880: '1',
        converge_th20: '2',
        converge_840t: '3',
        converge_8i: 'A',
        converge_1212: 'G',
        converge_1212a: 'I',
        converge_880ta: 'H',
        converge_vh20: 'E'
    }
    DeviceTypes.merge!(DeviceTypes.invert)

    Groups = {
        input: 'I',
        output: 'O',
        mic: 'M',
        beamforming_mic: 'V',
        amp: 'J',
        gating: 'G',
        processing: 'P',
        expansion: 'E',
        line_in: 'L',
        expansion_ref: 'A',
        gpio: 'Y',
        matrix: 'X',
        fader: 'F',
        presets: 'S',
        macros: 'C',
        transmit: 'T',
        receive: 'R',
        virtual_ref: 'B',
        time_event: 'Q',
        web: 'W',
        pa_virtual_ref: 'H',
        voip_transmit: 'K',
        voip_receive: 'Z',
        usb_transmit: 'D',
        usb_receive: 'U'
    }
    Groups.merge!(Groups.invert)

    MeterTypes = {
        input_level: 'I',
        post_gain_level: 'A',
        post_filter_level: 'N',
        post_gate_level: 'G'
    }
    MeterTypes.merge!(MeterTypes.invert)


    def on_load
        on_update
    end

    def on_update
        @device_type = setting(:device_type)
        @device_id = setting(:device_id)

        self[:model] = DeviceTypes[@device_type] || 'any'
    end


    def connected
        self[:authenticated] = false

        schedule.every('50s') do
            query_meter 1
        end
    end

    def disconnected
        schedule.clear
    end


    def preset(number, type = :macro)
        do_send type, number, name: type.to_sym
    end
    alias_method :macro, :preset

    def start_audio
        do_send "startAudio"
    end

    def reboot
        do_send "reboot"
    end


    # ---------------------
    # Compatibility Methods
    # ---------------------
    def fader(fader_id, level, fader_type = :fader)
        value = in_range(level, 20.0, -65.0)

        faders = Array(fader_id)
        faders.each do |fad|
            do_send 'GAIN', fad, Groups[fader_type.to_sym], value, 'A'
        end
    end

    def faders(ids:, level:, index: :fader, **_)
        fader(ids, level, index, type)
    end

    def query_fader(fader_id, fader_type = :fader)
        fad = fader_id.is_a?(Array) ? fader_id[0] : fader_id
        do_send 'GAIN', fad, Groups[fader_type.to_sym]
    end

    def query_faders(ids:, index: :fader, **_)
        query_fader(ids, index)
    end


    def mute(mute_id, value = true, fader_type = :fader)
        level = is_affirmative?(value) ? 1 : 0
        fad_type = Groups[fader_type.to_sym]

        mutes = Array(mute_id)
        mutes.each do |mute|
            do_send 'MUTE', mute, fad_type, level
        end
    end

    def unmute(mute_id, fader_type = :fader)
        mute(mute_id, false, fader_type)
    end

    def mutes(ids:, muted: true, index: :fader, **_)
        mute(ids, muted, index)
    end

    def query_mute(mute_id, fader_type = :fader)
        fad = mute_id.is_a?(Array) ? mute_id[0] : mute_id
        do_send 'MUTE', fad, Groups[fader_type.to_sym]
    end

    def query_mutes(ids:, index: :fader, **_)
        query_mute(ids, index)
    end


    def enable_level_reporting(value)
        level = is_affirmative?(value) ? 1 : 0
        do_send 'LVLREPORTEN', level
    end

    def query_meter(fader_id, fader_type = :input, meter_type = :input_level)
        fad = fader_id.is_a?(Array) ? fader_id[0] : fader_id
        do_send 'LVL', fad, Groups[fader_type.to_sym], MeterTypes[meter_type.to_sym]
    end


    def received(data, resolve, command)
        logger.debug { "received #{data.inspect}" }

        if !self[:authenticated]
            if data == "\n"
                schedule.in(300) { send "#{setting(:username)}\r\n", priority: 999 }
            elsif data =~ /user/i
                schedule.in(300) { send "#{setting(:password)}\r\n", priority: 999 }
            elsif data =~ /Authenticated/i
                self[:authenticated] = true
            elsif data =~ /Invalid/i
                self[:authenticated] = false
                logger.warn data
            end

            return :success
        end

        result = data.split('> ')[-1].split(' ')

        case result[1].downcase.to_sym
        when :mute
            id = result[2]
            type = Groups[result[3]]
            self["fader#{id}_#{type}_mute"] = result[4] == '1'
        when :lvl
            id = result[2]
            type = Groups[result[3]]
            meter = MeterTypes[result[4]] || 'unknown_meter'
            self["#{type}#{id}_#{meter}"] = result[5].to_f
        when :gain
            id = result[2]
            type = Groups[result[3]]
            self["fader#{id}_#{type}"] = result[4].to_f
        when :macro
            self[:last_macro] = result[2].to_i
        else
            # Example response: OK> #H0 ERROR ARGUMENT ERROR.
            logger.error(result.join(' ')) if data =~ /error/i
        end

        return :success
    end


    protected


    def do_send(command, *args, **options)
        cmd = "##{@device_type}#{@device_id} #{command} #{args.join(' ')}\r\n"
        logger.debug { "requesting #{cmd.inspect}" }
        send cmd, options
    end
end
