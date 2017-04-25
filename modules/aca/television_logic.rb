
module Aca; end

class Aca::TelevisionLogic
    include ::Orchestrator::Constants


    descriptive_name 'ACA Television Logic'
    generic_name :Television
    implements :logic


    def on_load
        on_update

        # Load the previous state
        goto(@start_channel, false) if @start_channel
    end

    def on_update
        @start_channel = setting(:start_channel)
        @tv_input = setting(:tv_input) || :hdmi
        @module = setting(:tv_mod)

        # Update the Schedules if running as a standalone TV system
        unless system.exists? :System
            begin
                # Startup schedule
                schedule.clear
                time = setting(:power_on_time)
                time = setting(:startup_time) if time.nil?
                if time
                    schedule.cron(time) do
                        logger.info "powering ON displays in system #{system.name}"
                        power_on_displays
                        goto(@start_channel, false) if @start_channel
                    end
                end

                # Poweroff schedule
                time = setting(:power_off_time)
                time = setting(:shutdown_time) if time.nil?
                if time
                    schedule.cron(time) do
                        logger.info "powering OFF (hard) displays in system #{system.name}"
                        power_off_displays
                    end
                end
            rescue => e
                logger.print_error(e, 'bad cron schedule configuration')
            end
        end

        @box_id = setting(:box_id)
        @channels = setting(:channels) || {}
        self[:channelNames] = @channels.keys

        self[:name] = setting(:name) || system.name
        self[:input_list] = setting(:input_list)
    end

    def goto(channel, save = true)
        chan_id = [@channels[channel]]
        chan_id << @box_id if @box_id

        if chan_id[0]
            if @module
                system.get_implicit(@module).channel(*chan_id)
            else
                system.all(:IPTV).channel(*chan_id)
            end

            self[:channelName] = channel
            define_setting(:start_channel, channel) if save
        else
            logger.warn "Unknown channel #{channel}"
        end
    end

    def power_on
        power_on_displays
    end

    def power_off
        logger.info "powering off displays in system #{system.name}"
        system.all(:Display).power Off
    end


    protected


    def power_on_displays
        system.all(:Display).each do |display|
            if check display.arity(:power)
                # As this is UDP we send the power on request twice
                display.power On, setting(:broadcast)
                schedule.in(1 + rand(5000)) do
                    display.power On, setting(:broadcast)
                end
            else
                display.power On
            end

            display.switch_to @tv_input
        end
    end

    def power_off_displays
        system.all(:Display).each do |disp|
            if disp.respond_to? :hard_off
                disp.hard_off
            else
                disp.power Off
            end
        end
    end

    # Checks if the display support broadcasting power on
    def check(arity)
        arity >= 2 || arity < 0
    end
end
