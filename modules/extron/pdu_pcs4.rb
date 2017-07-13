load File.expand_path('./base.rb', File.dirname(__FILE__))
module Extron; end


class Extron::PduPcs4 < Extron::Base
    descriptive_name 'Extron IPL T PCS4 PDU'
    generic_name :PDU

    def on_load
        on_update
    end

    def on_update
        self[:inverted_relay] = @invert_relay = setting(:invert_relay) || false
    end

    def power(point, state, **opts)
        val = is_affirmative?(state) ? 1 : 0
        do_send("\e#{point.to_i}*#{val}PC", opts)
    end

    def power?(point, **opts)
        do_send("\e#{point.to_i}PC", opts)
    end

    def power_cycle(point)
        power(point, Off).then do
            defer = thread.defer
            schedule.in('4s') { defer.resolve(power(point, On)) }
            defer.promise
        end
    end

    def alarm_relay(state, options = {})
        state = is_affirmative?(state) ? 1 : 0
        send("1*#{state}O\x0D")
    end

    def alarm_status?(options = {})
        send("1O\x0D")
    end

    def device_ready
        super # Call device ready in Extron::Base
        (1..4).each { |point| power?(point) }
    end


    ERRORS = {
        12 => 'Invalid port number',
        13 => 'Invalid parameter (number is out of range)',
        14 => 'Not valid for this configuration',
        17 => 'System timed out',
        22 => 'System is busy',
        23 => 'Checksum error (for file uploads)',
        24 => 'Privilege violation',
        25 => 'Device is not present',
        26 => 'Maximum connections exceeded',
        27 => 'Invalid event number',
        28 => 'Bad filename or file not found'
    }


    def received(data, resolve, command)
        logger.debug { "Device sent: #{data}" }

        if data =~ /Login/i
            device_ready
        else
            result = data.split(' ')
            case data[0..2].to_sym
            when :Cpn # Relay or power point status
                index = result[0][3..-1].to_i

                case result[1][0..2].to_sym
                when :Rly
                    if @invert_relay
                        self["relay#{index}"] = result[1][-1] == '0' 
                    else
                        self["relay#{index}"] = result[1][-1] == '1' 
                    end
                when :Ppc
                    self["power#{index}"] = result[1][-1] == '1'
                else
                    logger.info "Unrecognised response: #{data}"
                end
            else
                if data == 'E22'    # Busy! We should retry this one
                    command[:delay_on_receive] = 1000 unless command.nil?
                    return :failed
                elsif data[0] == 'E'
                    logger.info "Extron Error #{ERRORS[data[1..2].to_i]}"
                    logger.info "- for command #{command[:data]}" unless command.nil?
                end
            end
        end

        return :success
    end
end
