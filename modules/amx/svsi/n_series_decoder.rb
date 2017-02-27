module Amx; end
module Amx::Svsi; end


class Amx::Svsi::NSeriesDecoder
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder


    # Discovery Information
    tcp_port 50002
    descriptive_name 'AMX SVSI N-Series Decoder'
    generic_name :Decoder

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


    # Status commands

    def do_poll
        do_send 'getStatus', priority: 0
    end


    # Switching

    def switch(stream_id)
        do_send 'set', stream_id
        switch_audio 0  # enable AFV
    end

    def switch_video(stream_id)
        switch_audio self[:audio]  # lock audio to current stream
        do_send 'set', stream_id
    end

    def switch_audio(stream_id)
        do_send 'seta', stream_id
    end

    def switch_kvm(ip_address, video_follow = true)
        host = ip_address
        host << ",#{video_follow ? 1 : 0}"
        do_send 'KVMMasterIP', host
    end


    # Audio

    def mute(state = true)
        if is_affirmative? state
            do_send 'mute', name: :mute
        else
            unmute
        end
    end

    def unmute
        do_send 'unmute', name: :mute
    end


    # Play modes

    def live(state = true)
        if is_affirmative? state
            do_send 'live'
        else
            local self[:playlist]
        end
    end

    def local(playlist = 0)
        do_send 'local', playlist
    end


    # Scaling

    def scaler(state)
        if is_affirmative? state
            do_send 'scalerenable', name: :scaler
        else
            do_send 'scalerdisable', name: :scaler
        end
    end

    OUTPUT_MODES = [
        'auto',
        '1080p59.94',
        '1080p60',
        '720p60',
        '4K30',
        '4K25'
    ]
    def output_resolution(mode)
        unless OUTPUT_MODES.include? mode
            logger.error("\"#{mode}\" is not a valid resolution")
            return
        end
        do_send 'modeset', mode
    end


    # Video wall processing

    def videowall(width, height, x_pos, y_pos, scale = 'auto')
        if width > 1 and height > 1
            videowall_size width, height
            videowall_position x_pos, y_pos
            videowall_scaling scale
            videowall_enable
        else
            videowall_disable
        end
    end

    def videowall_enable(state = true)
        state = is_affirmative?(state) ? 'on' : 'off'
        do_send 'setSettings', 'wallEnable', state
    end

    def videowall_disable
        videowall_enable false
    end

    def videowall_size(width, height)
        do_send 'setSettings', 'wallHorMons', width
        do_send 'setSettings', 'wallVerMons', height
    end

    def videowall_position(x, y)
        do_send 'setSettings', 'wallMonPosH', x
        do_send 'setSettings', 'wallMonPosV', y
    end

    VIDEOWALL_SCALING_MODES = [
        'auto',     # decoder decides best method
        'fit',      # aspect distort
        'stretch'   # fill and crop
    ]
    def videowall_scaling(scaling_mode)
        unless VIDEOWALL_SCALING_MODES.include? scaling_mode
            logger.error "\"#{scaling_mode}\" is not a valid scaling mode"
            return
        end
        do_send 'setSettings', 'wallStretch', scaling_mode
    end


    protected


    # Device responses are `key:value` pairs. To expose any state information
    # of interest, add in the key below along with a optional alternative
    # name and transform to apply.
    RESPONSE_PARSERS = {
        stream: {
            status_variable: :video,
            transform: -> (x) { @stream = x.to_i }
        },
        streamaudio: {
            status_variable: :audio,
            transform: -> (x) do
                stream_id = x.to_i
                # AFV comes from the device as stream 0
                # remap to actual audio stream id for status
                stream_id == 0 ? @stream : stream_id
            end
        },
        name: {
            status_variable: :device_name
        },
        playmode: {
            status_variable: :local_playback,
            transform: -> (x) { x == 'local' }
        },
        playlist: {
            transform: -> (x) { x.to_i }
        },
        mute: {
            transform: -> (x) { x == '1' }
        },
        scalerbypass: {
            status_variable: :scaler_active,
            transform: -> (x) { x != 'no' }
        },
        mode: {
            status_variable: :output_res,
        },
        inputres: {
            status_variable: :input_res
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
