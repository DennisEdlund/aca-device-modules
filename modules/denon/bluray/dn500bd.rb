# encoding: US-ASCII

module Denon; end
module Denon::Bluray; end


# returns: "nack" on invalid command
# returns: "ack" on valid request
# returns: "ack+@0PCAP00"


class Denon::Bluray::Dn500bd
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder


    # Discovery Information
    tcp_port 9030
    descriptive_name 'Denon Bluray DN-500BD'
    generic_name :Bluray

    # Communication settings
    delay between_sends: 50
    default_settings({
        device_id: 0
    })


    def on_load
        on_update
    end

    def on_update
        @device_id = setting(:device_id) || 0
        self[:power] = true
    end


    def connected
        model_information
        do_poll
        schedule.every('1m') do
            do_poll
        end
    end

    def disconnected
        schedule.clear
    end


    COMMANDS = {
        tray_open: 'PCDTRYOP',
        tray_close: 'PCDTRYCL',

        # Playback
        play:     '2353',
        stop:     '2354',
        pause:    '2348',
        skip:     '2332',
        previous: '2332',

        # Menu navigation
        setup:      'PCSU',
        top_menu:   'DVTP',
        menu:       'DVOP',
        popup_menu: 'DVOP',
        return:     'PCRTN',
        subtitle:   'DVSBTL1',
        home:       'PCHM',
        enter:      'PCENTR'
    }

    STATUS = {
        play_status:'ST',
        tray_status: 'CD',
        num_tracks: 'Tt',
        cur_track: 'Tr',
        cur_track_time: 'tl',
        track_artist: 'at',
        track_title: 'ti',
        track_album: 'al',
        elapsed_time: 'ET',
        remaining_time: 'RM',
        media_type: 'PCTYP',
        audio_format: 'PCAFMT',
        audio_channels: 'PCACH',
        model_information: 'VN'
    }

    PlayStatus = {
        PL: 'playing',
        PP: 'paused',
        DVSR: 'slow reverse',
        DVSF: 'slow play',
        DVFR: 'fast reverse',
        DVFF: 'fast forward',
        DVSP: 'step play',
        DVFS: 'FS play',
        ED: 'menu',
        DVSU: 'setup',
        DVTR: 'track menu'
    }

    MediaStatus = {
        NC: 'no disc',
        CI: 'disc ready',
        UF: 'unformatted media',
        TO: 'tray open',
        TC: 'tray closing',
        TE: 'tray error'
    }




    #
    # Automatically creates a callable function for each command
    #   http://blog.jayfields.com/2007/10/ruby-defining-class-methods.html
    #   http://blog.jayfields.com/2008/02/ruby-dynamically-define-method.html
    #
    COMMANDS.each do |command, value|
        define_method command do |**options|
            options[:name] ||= command
            send_cmd(value, options)
        end
    end

    STATUS.each do |command, value|
        define_method command do |**options|
            options[:status_req] = command
            options[:priority] ||= 0
            send_query(value, options)
        end
    end

    def do_poll
        wait = [tray_status, play_status]
        thread.all(wait).then do
            if self[:playing] || self[:paused]
                num_tracks
                cur_track
                media_type
            end
        end
    end


    DIRECTIONS = {
        left: '1',
        right: '2',
        up: '3',
        down: '4'
    }
    def cursor(direction, options = {})
        val = DIRECTIONS[direction.to_sym]
        send_cmd("PCCUSR#{val}", options)
    end


    protected


    def send_cmd(cmd, options = {})
        str = "@#{@device_id}#{cmd}\r"
        logger.debug { "sending #{str}" }
        send(str, options)
    end

    def send_query(cmd, options = {})
        str = "@#{@device_id}?#{cmd}\r"
        logger.debug { "sending #{str}" }
        send(str, options)
    end

    def received(data, resolve, command)
        logger.debug { "received #{data}" }

        success, resp = data.split('+')
        return :abort if success == 'nack'
        return :success unless resp

        # Remove the @0
        resp_value = resp[2..-1]

        # Work out the status coming in
        resp_type = nil
        STATUS.each do |key, value|
            resp_type = key if resp_value.start_with?(value)
        end

        # Notify if the status coming in is unknown
        if resp_type.nil?
            logger.debug { "unknown status value for #{resp}" }
            return :success
        end

        # Extract the data from the response
        case resp_type
        when :play_status
            state = resp[4..-1].to_sym
            self[:play_status] = PlayStatus[state]
            if self[:disc_ready]
                if state == :PP
                    self[:playing] = false
                    self[:paused] = true
                else
                    self[:playing] = true
                    self[:paused] = false
                end
            else
                self[:playing] = false
                self[:paused] = false
            end
        when :tray_status
            state = resp[4..-1].to_sym
            self[:tray_status] = MediaStatus[state]
            self[:disc_ready] = state == :CI
            self[:ejected] = state == :TO
            self[:loading] = state == :TC
        when :num_tracks
            state = resp[4..-1]
            self[:num_tracks] = state == 'UNKN' ? nil : state.to_i
        when :cur_track
            state = resp[4..-1]
            self[:cur_track] = state == 'UNKN' ? nil : state.to_i
        when :cur_track_time
            self[:cur_track_min] = resp[4..6].to_i
            self[:cur_track_sec] = resp[7..8].to_i
        when :track_artist
            self[:track_artist] = resp[4..-1]
        when :track_title
            self[:track_title] = resp[4..-1]
        when :track_album
            self[:track_album] = resp[4..-1]
        when :elapsed_time
            state = resp[4..-1]
            self[:elapsed_hour] = resp[0..2].to_i
            self[:elapsed_min] = resp[3..4].to_i
            self[:elapsed_second] = resp[5..-1].to_i
        when :remaining_time
            state = resp[4..-1]
            self[:remaining_hour] = resp[0..2].to_i
            self[:remaining_min] = resp[3..4].to_i
            self[:remaining_second] = resp[5..-1].to_i
        when :media_type
            self[:media_type] = resp[7..-1]
        when :audio_format
            self[:audio_format] = resp[8..-1]
        when :audio_channels
            self[:audio_channels] = resp[7..-1]
        when :model_information
            self[:model_version] = resp[4..11]
            self[:model_name] = resp[12..-1]
        else
            logger.debug { "unknown response #{data}" }
        end

        :success
    end
end
