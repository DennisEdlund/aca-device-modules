require 'set'


module Amx; end
module Amx::Svsi; end


class Amx::Svsi::NSeriesEncoder
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder


    # Discovery Information
    tcp_port 50002
    descriptive_name 'AMX SVSI N-Series Encoder'
    generic_name :Encoder

    # Communication settings
    tokenize delimiter: "\x0D"


    def on_load
        on_update
    end

    def on_unload; end

    def on_update; end

    def connected
        do_poll

        schedule.every('50s') do
            do_poll
        end
    end

    def disconnected
        schedule.clear
    end


    def do_poll
        do_send 'getStatus', priority: 0
    end

    Inputs = {
        hdmi: 'hdmionly',
        vga: 'vgaonly',
        hdmivga: 'hdmivga',
        vgahdmi: 'vgahdmi'
    }
    def switch_to(input, **options)
        source = Inputs[input.to_sym] || input.to_s
        do_send 'vidsrc', source, **options
    end

    # Supports: live, 1-8 (local)
    Modes = Set.new(['1', '2', '3', '4', '5', '6', '7', '8'])
    def media_source(mode)
        the_mode = modes.to_s
        if the_mode == 'live'
            do_send 'live'
        elsif Modes.include? the_mode
            do_send 'local', the_mode
        else
            raise "invalid mode #{the_mode}"
        end
    end


    def mute(state = true)
        if is_affirmative?(state)
            do_send 'txdisable'
        else
            do_send 'txenable'
        end
    end
    alias_method :mute_video, :mute

    def unmute
        mute(false)
    end
    alias_method :unmute_video, :unmute


    def mute_audio(state = true)
        if is_affirmative?(state)
            do_send 'mute'
        else
            do_send 'unmute'
        end
    end

    def unmute_audio
        mute_audio(false)
    end



    protected


    # Device responses are `key:value` pairs. To expose any state information
    # of interest, add in the key below along with a optional alternative
    # name and transform to apply.
    RESPONSE_PARSERS = {
        name: {
            status_variable: :device_name
        },
        stream: {
            status_variable: :stream_id,
            transform: -> (x) { x.to_i }
        },
        playmode: {
            status_variable: :mute,
            transform: -> (x) { x == 'off' }
        },
        mute: {
            status_variable: :audio_mute,
            transform: -> (x) { x == '1' }
        }
    }
    def received(data, deferrable, command)
        logger.debug { "received #{data}" }

        property, value = data.split ':'
        property = property.downcase.to_sym
        parser = RESPONSE_PARSERS[property]
        unless parser.nil?
            status = parser[:status_variable] || property
            unless parser[:transform].nil?
                value = parser[:transform].call(value)
            end
            self[status] = value
        end

        :success
    end


    def do_send(*args, **options)
        command = "#{args.join(':')}\r"
        send command, options
    end

end
