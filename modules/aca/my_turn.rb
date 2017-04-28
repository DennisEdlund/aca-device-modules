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

        def extract_trigger(config)
            trigger = config[:myturn_trigger]

            return nil if trigger.nil?

            # Allow module to be specified as either `DigitalIO_1`, or as
            # discreet module name and index keys.
            /(?<mod>[^_]+)(_(?<idx>\d+))?/ =~ trigger[:module]
            {
                module: mod.to_sym,
                index: idx.to_i || trigger[:index] || 1,
                status: trigger[:status].to_sym,
                value: trigger[:value] || :__affirmative
            }
        end

        def triggers
            @sys[:sources].select { |name| source_available? name }
                          .transform_values { |config| extract_trigger(config) }
                          .compact
        end

        def extract_role(output)
            role = output[:myturn_role]
            role.nil? ? nil : role.to_sym
        end

        def displays(myturn_role)
            @sys[:outputs].transform_values { |config| extract_role(config) }
                          .select { |_name, role| myturn_role == role }
                          .keys
        end

        def present(source, displays)
            Array(displays).each { |display| @sys.present source, display }
        end

        def source(display)
            @sys[display][:source] unless @sys[display].nil?
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
        if self[:switching_disabled]
            logger.debug 'MyTurn switching disabled, ignoring preview request'
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
        preview old_source, replace: source unless old_source.nil?
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
                        ->(x) { is_affirmative? x }
                    when :__negatory
                        ->(x) { is_negatory? x }
                    else
                        ->(x) { x == trigger[:value] }
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
