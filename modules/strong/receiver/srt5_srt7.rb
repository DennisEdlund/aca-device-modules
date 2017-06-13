# encoding: US-ASCII

module Strong; end
module Strong::Receiver; end


class Strong::Receiver::Srt5Srt7
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder


    # Discovery Information
    descriptive_name 'Strong STB Receiver SRT54XX or SRT70XX'
    generic_name :Receiver
    makebreak!


    def power(state, **options)
        options[:name] = :power

        pwr_on = is_affirmative?(state)
        promise = if pwr_on
            do_send(0x00, options)
        else
            do_send(0x60, options)
        end

        # Set status on success
        promise.then { self[:power] = pwr_on }
    end

    DIRECTIONS = {
        left: 0x0F,
        right: 0x0E,
        up: 0x4B,
        down: 0x0C
    }
    def cursor(direction, **options)
        val = DIRECTIONS[direction.to_sym]
        raise "invalid direction #{direction}" unless val
        options[:name] = :direction
        do_send(val, options)
    end

    def num(number, **options)
        val = case number.to_i
        when 0; 0x1B
        when 1; 0x15
        when 2; 0x16
        when 3; 0x17
        when 4; 0x54
        when 5; 0x55
        when 6; 0x56
        when 7; 0x57
        when 8; 0x18
        when 9; 0x19
        end
        do_send(val, options)
    end

    # Make compatible with IPTV systems
    def channel(number)
        number.to_s.each_char do |char|
            num(char)
        end
    end


    COMMANDS = {
        toogle_tv_radio: 0x41,
        toggle_mute:     0x40,
        toggle_text:     0x03,
        select_subtiles: 0x42,
        select_audio:    0x04,
        mosaic:          0x05,
        sleep:           0x06,
        toggle_freeze:   0x07,
        zoom:            0x44,
        guide:           0x45,
        info:            0x46,
        recall:          0x47,
        group:           0x08,
        menu:            0x09,
        exit:            0x0A,
        enter:           0x0D,  # OK
        channel_up:      0x49,
        channel_down:    0x4A,
        volume_up:       0x0B,
        volume_down:     0x48,
        red:             0x51,
        green:           0x52,
        yellow:          0x53,
        blue:            0x14,
        v_format:        0x1A,
        wide:            0x58,
        file_list:       0x4C,
        play:            0x4D,
        record:          0x13,
        pause:           0x10,
        slow:            0x50,
        stop:            0x4E,
        rewind:          0x4F,
        forward:         0x11,
        advanced:        0x12
    }

    #
    # Automatically creates a callable function for each command
    #   http://blog.jayfields.com/2007/10/ruby-defining-class-methods.html
    #   http://blog.jayfields.com/2008/02/ruby-dynamically-define-method.html
    #
    COMMANDS.each do |command, value|
        define_method command do |**options|
            options[:name] ||= command
            do_send(value, options)
        end
    end


    protected


    def do_send(cmd, options)
        logger.debug { "sending #{options[:name]}: 0x#{cmd.to_s(16)}" }
        checksum = cmd - 0x09
        # Emulate an unsigned byte underflow
        # Source: https://stackoverflow.com/questions/34145891/unsigned-equivalent-of-a-negative-fixnum
        checksum = (~checksum) ^ (2**8 - 1) if checksum < 0
        checksum &= 0xFF
        send([
            0xA5, 0x07, 0x00, 0x30, 0x08,
            0x7F, 0x02, cmd, 0, checksum
        ], options)
    end

    def received(data, resolve, command)
        # Should respond with: A5 04 00 CF 49 7F D5
        logger.debug { "received 0x#{byte_to_hex(data)}" }
        :success
    end
end
