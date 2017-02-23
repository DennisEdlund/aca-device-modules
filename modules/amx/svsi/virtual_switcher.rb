module Amx; end
module Amx::Svsi; end


=begin

This driver provides an abstraction layer for systems using SVSI based signal
distribution. In place of referencing specific decoders and stream id's,
this may be used to enable all endpoints associated with a system to be
grouped as a virtual matrix switcher and a familiar switcher API used.

=end


class Amx::Svsi::VirtualSwitcher
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder


    descriptive_name 'AMX SVSI Virtual Switcher'
    generic_name :Switcher
    implements :logic


    def switch(signal_map)
        connect(signal_map, &:switch)
    end

    def switch_video(signal_map)
        connect(signal_map, &:switch_video)
    end

    def switch_audio(signal_map)
        connect(signal_map, &:switch_audio)
    end


    protected


    # Apply a signal map to encoders and decoders in the current system. The
    # signal map is a hash map in the following form
    #
    #   {
    #       <input>: <outputs>
    #   }
    #
    # Where <input> can be the encoder name that's been set on the device, or
    # the encoder index within the current system. Similarly, outputs can be
    # referred to via the device name or index and can be a single item or an
    # array.
    def connect(signal_map, &connect_method)
        encoders = get_system_modules(:Encoder)
        decoders = get_system_modules(:Decoder)

        signal_map.each do |input, outputs|
            encoder = encoders[input]
            stream = encoder.nil? ? 0 : encoder[:stream_id]
            [*outputs].each do |output|
                decoder = decoders[output]
                unless decode.nil?
                    connect_method.call(decoder, stream)
                else
                    logger.warn \
                        "unable to switch - decoder #{output} not found"
                end
            end
        end
    end


    # Get a lookup table of all modules in the system of a specific type. A
    # lookup table will be returned providing the ability to retreive them
    # via index, name or the name configured on the device itself.
    def get_system_modules(name)
        devices = {}
        system.all(name).each_with_index do |mod, idx|
            devices[idx.to_s] = mod
            devices["#{name}_#{idx}"] = mod
            devices[mod[:name]] = mod unless mod[:name].nil?
        end
        devices
    end

end
