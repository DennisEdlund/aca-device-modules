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
        device_type: '*',
        device_id: '*',
        username: 'clearone',
        password: 'converge'
    })


    def on_load
        on_update
    end
    
    def on_update
        @device_type = setting(:device_type)
        @device_id = setting(:device_id)
    end
    
    
    def connected
        self[:authenticated] = false
    end
    
    def disconnected
        schedule.clear
    end
    
    
    def preset(number, type = :macro)
        do_send "#{type} #{number}", name: type.to_sym
    end
    alias_method :macro, :preset

    def start_audio
        do_send "startAudio"
    end

    def reboot
        do_send "reboot"
    end

    def get_aliases
        do_send "SESSION get aliases"
    end


    # ---------------------
    # Compatibility Methods
    # ---------------------
    def fader(fader_id, level, fader_type = 'F', meter_type = 'A')
        value = in_range(level, 99.99, -99.99)

        faders = Array(fader_id)
        faders.each do |fad|
            do_send 'LVL', fad, fader_type, meter_type, value
        end
    end

    def faders(ids:, level:, index: 'F', type: 'A', **_)
        fader(ids, level, index, type)
    end

    def query_fader(fader_id, fader_type = 'F', meter_type = 'A')
        fad = fader_id.is_a?(Array) ? fader_id[0] : fader_id
        do_send 'LVL', fad, fader_type, meter_type
    end

    def query_faders(ids:, index: 'F', type: 'A', **_)
        query_fader(ids, index, type)
    end


    def mute(mute_id, value = true, fader_type = 'F')
        level = is_affirmative?(value) ? 1 : 0

        mutes = Array(mute_id)
        mutes.each do |mute|
            do_send 'MUTE', mute, fader_type, level
        end
    end

    def unmute(mute_id, fader_type = 'F')
        mute(mute_id, false, fader_type)
    end

    def mutes(ids:, muted: true, index: 'F', **_)
        mute(ids, muted, index)
    end

    def query_mute(mute_id, fader_type = 'F')
        fad = mute_id.is_a?(Array) ? mute_id[0] : mute_id
        do_send 'MUTE', fad, fader_type
    end

    def query_mutes(ids:, index: 'F', **_)
        query_mute(ids, index)
    end



    def received(data, resolve, command)
        logger.debug { "received #{data.inspect}" }

        if data == "\n" && !self[:authenticated]
            schedule.in(300) { send "#{setting(:username)}\r\n", priority: 999 }
        elsif data =~ /user:/i
            schedule.in(300) { send "#{setting(:password)}\r\n", priority: 999 }
        elsif data == 'Authenticated.'
            self[:authenticated] = true
        elsif data == 'Invalid User/Pass.'
            self[:authenticated] = false
            logger.warn data
        end

        return :success
    end


    protected


    def do_send(command, *args, **options)
        logger.debug { "requesting #{command}" }
        send "##{@device_type}#{@device_id} #{command} #{args.join(' ')}\r", options
    end
end

