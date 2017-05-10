# Switching control for systems using 'MyTurn' distributed physical UI.
class Aca::MyTurn
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder

    # Utility class for accessing the meeting_room logic module
    class SystemAccessor
        def initialize(system)
            @sys = system
        end

        def source_available?(name)
            @sys[:inputs].map { |input| @sys[input] }
                         .flatten
                         .include? name
        end

        def triggers
            extract_trigger = lambda do |config|
                trigger = config[:myturn_trigger]
                if trigger
                    # Allow module to be specified as either `DigitalIO_1`, or
                    # as discreet module name and index keys.
                    /(?<mod>[^_]+)(_(?<idx>\d+))?/ =~ trigger[:module]
                    {
                        module: mod.to_sym,
                        index: idx.to_i || trigger[:index] || 1,
                        status: trigger[:status].to_sym,
                        value: trigger[:value] || :__affirmative
                    }
                end
            end

            @sys[:sources].select { |name| source_available? name }
                          .transform_values(&extract_trigger)
                          .compact
        end

        def displays(myturn_role)
            extract_role = lambda do |config|
                role = config[:myturn_role]
                role.to_sym if role
            end

            @sys[:outputs].transform_values(&extract_role)
                          .select { |_name, role| myturn_role == role }
                          .keys
        end

        def present(source, displays)
            Array(displays).each { |display| @sys.present source, display }
        end

        def source(display)
            display_info = @sys[display]
            display_info ? display_info[:source] : :none
        end
    end

    descriptive_name 'ACA MyTurn Switching Logic'
    generic_name :MyTurn
    implements :logic

    def initialize
        @system = nil
        @subscriptions = []
        @preview_targets = []
    end

    def on_load
        system.subscribe(:System, 1, :current_mode) do
            logger.debug 'System mode change detected'
            rebind_module
        end

        on_update
    end

    def on_unload; end

    def on_update
        self[:preview_disabled] = setting(:preview_disabled) || false
        rebind_module
    end

    def disable
        logger.debug 'Disabling MyTurn triggers'
        self[:switching_disabled] = true
    end

    def enable
        logger.debug 'Enabling MyTurn triggers'
        self[:switching_disabled] = false
    end

    def present(source)
        if self[:switching_disabled]
            logger.debug 'MyTurn switching disabled, ignoring present request'
        else
            logger.debug { "Activating #{source} as MyTurn presentation" }
            present_actual source.to_sym
        end
    end

    def preview(source, replace: :none)
        if self[:switching_disabled] || self[:preview_disabled]
            logger.debug 'MyTurn switching and/or preview disabled, ignoring preview request'
        else
            logger.debug { "Adding #{source} to MyTurn previews" }
            preview_actual source.to_sym, replace.to_sym
        end
    end

    protected

    def present_actual(source)
        # Present the new source.
        old_source = self[:presentation_source]
        @system.present source, self[:primary_displays]
        self[:presentation_source] = source

        # Minimise the previous source to a preview display
        if old_source
            preview old_source, replace: source
        end
    end

    def preview_actual(source, replaceable_source)
        # Use either a display with a replaceable source, or the next in the
        # list of available preview displays.
        replaceable_display = @preview_targets.find do |display|
            @system.source(display) == replaceable_source
        end
        display = replaceable_display || @preview_targets.first

        # Move the used preview to the end of our prefences for re-use.
        @preview_targets.delete display
        @preview_targets << display

        @system.present source, display
    end

    def bind(source, trigger)
        target = trigger.values_at(:module, :index, :status)

        logger.debug { "Binding #{source} to #{target.join(' ')}" }

        is_active = case trigger[:value]
                    when :__affirmative
                        ->(state) { is_affirmative? state }
                    when :__negatory
                        ->(state) { is_negatory? state }
                    else
                        ->(state) { state == trigger[:value] }
                    end

        system.subscribe(*target) do |notice|
            if is_active.call notice.value
                logger.debug { "MyTurn trigger for #{source} activated" }
                present source
            end
        end
    end

    def resubscribe_triggers(triggers)
        @subscriptions.each { |reference| unsubscribe(reference) }

        @subscriptions = triggers.map do |source, trigger|
            bind source, trigger
        end
    end

    def rebind_module
        logger.debug 'Rebinding MyTurn to current system state'

        @system = SystemAccessor.new system[:System]
        self[:triggers] = @system.triggers
        self[:primary_displays] = @system.displays :primary
        self[:preview_displays] = @system.displays :preview

        # Maintain an internal array of preview targets that can be re-ordered
        # without raising status updates.
        @preview_targets = self[:preview_displays].dup

        resubscribe_triggers self[:triggers]
    end
end
