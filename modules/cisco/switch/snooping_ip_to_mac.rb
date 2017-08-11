module Cisco; end
module Cisco::Switch; end


require 'set'


class Cisco::Switch::SnoopingIpToMac
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder
    include ::Orchestrator::Security

    descriptive_name 'Cisco Switch Snooping'
    generic_name :Snooping

    # Discovery Information
    tcp_port 22
    implements :ssh

    # Communication settings
    tokenize delimiter: /\n|<space>/,
             wait_ready: ':'
    clear_queue_on_disconnect!

    def on_load
        @check_interface = ::Set.new
        on_update
    end

    def on_update
        @switch_name = setting(:switch_name)
    end

    def connected
        logger.debug "Connected to switch"
        @username = setting(:username) || 'cisco'
        do_send(@username, priority: 99)

        schedule.every('1m') { update_mappings }
    end

    # Don't want the every day user using this method
    protect_method :run
    def run(command, options = {})
        do_send command, **options
    end

    def update_mappings
        do_send 'show ip dhcp snooping binding'
    end

    def received(data, resolve, command)
        logger.debug { "Switch sent #{data}" }

        # Authentication occurs after the connection is established
        if data =~ /#{@username}/
            logger.debug { "Authenticating" }
            # Don't want to log the password ;)
            send("#{setting(:password)}\n", priority: 99)
            return :success
        end

        # determine the hostname
        if @hostname.nil?
            parts = data.split('#')
            if parts.length == 2
                self[:hostname] = @hostname = parts[0]
                return :success # Exit early as this line is not a response
            end
        end

        # Detect more data available
        # ==> More: <space>,  Quit: q or CTRL+Z, One line: <return>
        if data =~ /More:/
            send(' ', priority: 99)
            return :success
        end

        # Interface change detection
        # 07-Aug-2014 17:28:26 %LINK-I-Up:  gi2
        # 07-Aug-2014 17:28:31 %STP-W-PORTSTATUS: gi2: STP status Forwarding
        # 07-Aug-2014 17:44:43 %LINK-I-Up:  gi2, aggregated (1)
        # 07-Aug-2014 17:44:47 %STP-W-PORTSTATUS: gi2: STP status Forwarding, aggregated (1)
        # 07-Aug-2014 17:45:24 %LINK-W-Down:  gi2, aggregated (2)
        if data =~ /%LINK/
            interface = data.split(',')[0].split(/\s/)[-1].downcase

            if data =~ /Up:/
                logger.debug { "Interface Up: #{interface}" }
                @check_interface << interface
                schedule.in(3000) { update_mappings }
            elsif data =~ /Down:/
                logger.debug { "Interface Down: #{interface}" }
                @check_interface.delete(interface)
            end
            return :success
        end

        # Grab the parts of the response
        entries = data.split(/\s/)

        # show interfaces status
        # gi1      1G-Copper    Full    1000  Enabled  Off  Up          Disabled On
        # gi2      1G-Copper      --      --     --     --  Down           --     --
        if entries.include?('Up')
            logger.debug { "Interface Up: #{entries[0]}" }
            @check_interface << entries[0]
            return :success
        elsif entries.include?('Down')
            interface = entries[0]
            logger.debug { "Interface Down: #{interface}" }
            @check_interface.delete(interface)

            # TODO:: Create an actual couchbase model
            # We need to be able to delete these records if the control server restarts
            ip, mac = self[interface]
            self[interface] = nil
            ::User.bucket.delete("inmac-#{mac}")
            return :success
        end

        # We are looking for MAC to IP address mappings
        # =============================================
        # Total number of binding: 1
        #
        #    MAC Address       IP Address    Lease (sec)     Type    VLAN Interface
        # ------------------ --------------- ------------ ---------- ---- ----------
        # 38:c9:86:17:a2:07  192.168.1.15    166764       learned    1    gi3
        if @check_interface.present? && !entries.empty?
            interface = entries[-1].downcase

            # We only want entries that are currently active
            if @check_interface.include? interface

                # Ensure the data is valid
                mac = entries[0]
                if mac =~ /^(?:[[:xdigit:]]{1,2}([-:]))(?:[[:xdigit:]]{1,2}\1){4}[[:xdigit:]]{1,2}$/
                    ip = entries[1]
                    if ::IPAddress.valid? ip
                        logger.debug { "Recording mapping #{ip} => #{mac}" }

                        if self[ip] != mac
                            self[ip] = mac
                            ::User.bucket.set("ipmac-#{ip}", mac.downcase, expire_in: 1.week)
                        end

                        if self[interface] != [ip, mac]
                            self[interface] = [ip, mac]

                            # TODO:: Create an actual couchbase model
                            ::User.bucket.set("inmac-#{mac}", {
                                switch: remote_address,
                                hostname: @hostname,
                                interface: interface,
                                switch_name: @switch_name
                            }, expire_in: 1.week)
                        end
                    end
                end

            end
        end

        :success
    end


    protected


    def do_send(cmd, **options)
        logger.debug { "requesting #{cmd}" }
        send("#{cmd}\n", options)
    end
end
