load File.expand_path('./base.rb', File.dirname(__FILE__))
module Extron; end


class Extron::Iplt < Extron::Base
    descriptive_name 'Extron IPL T IP to Relay/IO Gateway'
    generic_name :DigitalIO

    def on_load
      on_update
    end

    def on_update
        # setting invert to true will invert the true/false output of the io or relay status 
        self[:inverted_io] = @invert_io = setting(:invert_io) || false
        self[:inverted_relay] = @invert_relay = setting(:invert_relay) || false
    end

    def relay(index, state, options = {})
        if is_affirmative?(state)
            state = 1
        else
            state = 0
        end

        send("#{index}*#{state}O")
    end

    def relay_status?(index, options = {}, &block)
        send("#{index}O")
    end
    
    def io_status?(index, options = {}, &block)
        send("#{index}]")
    end

    def received(data, resolve, command)
        logger.debug { "Device sent: #{data}" }

        if data =~ /Login/i
            device_ready
        else
            case data[0..2].to_sym
            when :Cpn   #Relay or IO status. Example:
                        #Cpn1 Sio0
                        #012345678
                case data[5..7].to_sym
                when :Rly
		    if @invert_relay
                      self["relay#{data[3].to_i}"] = data[8] == '0' 
                    else
		      self["relay#{data[3].to_i}"] = data[8] == '1' 
		    end
                when :Sio
		    if @invert_io
                     self["io#{data[3].to_i}"] = data[8] == '0' 
		    else 
                      self["io#{data[3].to_i}"] = data[8] == '1'
                    end
                else
                    logger.info "Unrecognised response: #{data}"
                end
            else
                if data == 'E22'    # Busy! We should retry this one
                    command[:delay_on_receive] = 1 unless command.nil?
                    return :failed
                end
            end
        end

        return :success
    end
end

