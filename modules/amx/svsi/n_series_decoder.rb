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


    def do_poll
        do_send 'getStatus', priority: 0
    end


    def switch(stream_id, options = {})
        do_send 'set', stream_id, options
        switch_audio 0, options  # enable AFV
    end

    def switch_video(stream_id, options = {})
        switch_audio self[:audio]  # lock audio to current stream
        do_send 'set', stream_id, options
    end

    def switch_audio(stream_id, options = {})
        do_send 'seta', stream_id, options
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
