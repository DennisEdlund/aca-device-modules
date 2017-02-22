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

        @polling_timer = schedule.every('50s') do
            do_poll
        end
    end

    def disconnected
        @polling_timer.cancel unless @polling_timer.nil?
        @polling_timer = nil
    end


    def do_poll
        do_send 'getStatus', priority: 0
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
