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
        dev = devices[device]
        host = system[:USB_Host]

        if dev && host
            perform_join(host, dev)

            # Make sure join information is up to date
            dev.query_joins
            host.query_joins
        elsif dev.nil?
            logger.warn "unable to switch - device #{device} not found! (host: #{host.nil?})"
        elsif host.nil?
            logger.warn "unable to switch - no USB hosts in system"
        end
    end

    def switch(map)
        hosts   = get_hosts
        devices = get_devices

        endpoints = Set.new

                  # input, outputs
        map.each do |host, devs|
            devs = Array(devs)

            if host == 0
                devs.each do |dev|
                    device = devices[dev.to_s]
                    if device
                        # Unjoin performs the join query
                        device.unjoin_all
                    else
                        logger.warn "unable to switch - device #{dev} not found!"
                    end
                end
            else
                host_actual = hosts[host]

                if host_actual
                    endpoints << host_actual

                    devs.each do |dev|
                        device = devices[dev.to_s]
                        if device
                            endpoints << device
                            perform_join(host_actual, device)
                        else
                            logger.warn "unable to switch - device #{dev} not found!"
                        end
                    end
                else
                    logger.warn "unable to switch - host #{host} not found!"
                end
            end
        end

        endpoints.each do |endpoint|
            endpoint.query_join
        end
    end


    protected


    def perform_join(host, device)
        # Check if already joined
        unless host[:joined_to].include?(device[:mac_address])
            host.join(device[:mac_address])
        end

        unless device[:joined_to].include?(host[:mac_address])
            device.join(host[:mac_address])
        end
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
