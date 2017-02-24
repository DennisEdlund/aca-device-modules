# encoding: ASCII-8BIT


module Extron; end
module Extron::UsbExtenderPlus; end


=begin

This driver works by enumerating devices in a system.
Let's say a systems has the following devices:
 * USB_Device
 * USB_Device
 * USB_Host
 * USB_Host

A USB Device can only connect to a single Host at a time.
 --> the USB Hosts are the inputs of this switcher
 --> the devices are the outputs.

=end


class Extron::UsbExtenderPlus::VirtualSwitcher
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder


    descriptive_name 'Extron USB Extender Plus Switcher'
    generic_name :USB_Switcher
    implements :logic


    # Here for compatibility with previous USB switchers
    # Selects the first host and switches the selected device to it.
    def switch_to(device)
        devices = get_devices
        dev = devices[device.to_s]
        host = system[:USB_Host]

        if dev && host
            promise = perform_join(host, dev)

            # Make sure join information is up to date
            promise.finally do
                dev.query_joins
                host.query_joins
            end
        elsif dev.nil?
            logger.warn "unable to switch - device #{device} not found! (host: #{!host.nil?})"
        elsif host.nil?
            logger.warn "unable to switch - no USB hosts in system"
        end
    end

    def switch(map)
        hosts   = get_hosts
        devices = get_devices

        wait = []

                  # input, outputs
        map.each do |host, devs|
            devs = Array(devs)

            if host == 0 || host == '0'
                devs.each do |dev|
                    device = devices[dev.to_s]
                    if device
                        # Unjoin performs the join query
                        host_mac = device[:joined_to][0]
                        if host_mac
                            device.unjoin_all
                            wait << schedule.in(100) do
                                unjoin_previous_host(host_mac, device[:mac_address])
                            end
                        end
                    else
                        logger.warn "unable to switch - device #{dev} not found!"
                    end
                end
            else
                host_actual = hosts[host.to_s]

                if host_actual
                    devs.each do |dev|
                        device = devices[dev.to_s]
                        if device
                            wait << perform_join(host_actual, device)
                        else
                            logger.warn "unable to switch - device #{dev} not found!"
                        end
                    end
                else
                    logger.warn "unable to switch - host #{host} not found!"
                end
            end
        end

        thread.all(wait)
    end


    def unjoin_all
        system.all(:USB_Device).unjoin_all
        schedule.in(200) do
            system.all(:USB_Host).unjoin_all
        end
    end


    protected


    def perform_join(host, device)
        defer = thread.defer

        # Check if these devices are already joined
        host_joined = host[:joined_to].include?(device[:mac_address])
        device_joined = device[:joined_to].include?(host[:mac_address])

        unless host_joined && device_joined
            host_mac = device[:joined_to][0]
            device.unjoin_all

            # Wait a second to give the poor things some time
            schedule.in('1s') do
                unjoin_previous_host(host_mac, device[:mac_address]) if host_mac
                device.join(host[:mac_address])

                # Check if already joined on this host
                # This is possible
                unless host_joined
                    schedule.in(100) do
                        defer.resolve(true)
                        host.join(device[:mac_address])
                    end
                end
            end
        end

        defer.promise
    end

    def unjoin_previous_host(host_mac, device_mac)
        system.all(:USB_Host).each do |host|
            if host[:mac_address] == host_mac
                if host[:joined_to].include?(device_mac)
                    logger.debug 'unjoining previous host from device'
                    host.unjoin(device_mac)
                else
                    logger.debug 'previous host was not joined'
                end
                return
            end
        end
        logger.debug 'no previous host found'
    end

    # Enumerate the devices that make up this virtual switcher
    def get_hosts
        index = 1
        hosts = {}

        system.all(:USB_Host).each do |mod|
            hosts["USB_Host_#{index}"] = mod
            hosts[mod[:location]] = mod if mod[:location]
            hosts[index.to_s] = mod
            index += 1
        end

        hosts
    end

    def get_devices
        index = 1
        devices = {}
        system.all(:USB_Device).each do |mod|
            devices["USB_Device_#{index}"] = mod
            devices[mod[:location]] = mod if mod[:location]
            devices[index.to_s] = mod
            index += 1
        end

        devices
    end
end
