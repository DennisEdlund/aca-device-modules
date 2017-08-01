module Aca; end

class Aca::LocateUser
    include ::Orchestrator::Constants


    descriptive_name 'IP and Username to MAC lookup'
    generic_name :LocateUser
    implements :logic


    def on_load
        @looking_up = {}
        @udp = reactor.udp
    end

    def lookup(ip, username, domain = '.')
        login = "#{domain}\\#{username}"

        # prevents concurrent and repeat lookups for the one IP and user
        return if @looking_up[ip] || self[ip] == login
        @looking_up[ip] = true

        logger.debug { "Looking up #{ip} for #{login}" }
        mac = perform_arp_request(ip).value
        if mac
            # store the mac address in the database
            bucket = ::User.bucket
            expire = 1.year.from_now
            mac_key = "macuser-#{mac}"

            # Associate user with the MAC address
            old_login = ::User.bucket.get(mac_key, quiet: true)
            bucket.set(mac_key, login, expire_at: expire)

            # Remove the MAC address from any previous user
            if old_user
                user_key = "usermacs-#{old_login}"
                user_macs = bucket.get(user_key, quiet: true)
                if user_macs
                    user_macs[:macs].delete(mac)
                    bucket.set(user_key, user_macs, expire_at: expire)
                end
            end

            # Update the users list of MAC addresses
            user_key = "usermacs-#{login}"
            user_macs = bucket.get(user_key, quiet: true) || {macs: []}
            if not user_macs[:macs].include?(mac)
                user_macs[:macs].unshift(mac)
                bucket.set(user_key, user_macs, expire_at: expire)
            end

            self[ip] = login
        else
            logger.debug { "unable to locate MAC for #{ip}" }
        end
    rescue => e
        logger.print_error(e, "looking up #{ip}")
    ensure
        @looking_up.delete(ip)
    end


    protected


    def perform_arp_request(ip)
        reactor = thread
        defer = reactor.defer

        # This send will force the ARP cache to be updated
        @udp.send(ip, 9, '@', wait: true)
        reactor.sleep 100
        extract_arp_from_cache(reactor, ip, defer)

        defer.promise
    end

    def extract_arp_from_cache(reactor, ip, defer)
        out = String.new

        # ARP looks up the cached MAC address for the IP
        io = reactor.spawn('arp', args: [ip])
        io.stdout.progress do |data|
            out << data
        end
        io.stdout.start_read
        io.finally do
            logger.debug { "output of arp was:\n#{out}" }
            begin
                # This grabs the first MAC address on all platforms
                resps = out.split(/\s+/)
                resps.each do |resp|
                    if resp =~ /^(?:[[:xdigit:]]{1,2}([-:]))(?:[[:xdigit:]]{1,2}\1){4}[[:xdigit:]]{1,2}$/
                        defer.resolve(resp)
                        break
                    end
                end

                # NOTE:: nil will be ignored if defer is already resolved
                defer.resolve(nil)
            rescue => e
                defer.reject(e)
            end
        end
    end
end
