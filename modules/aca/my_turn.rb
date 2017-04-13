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

            compare = ->(x) { x == trigger[:value] }
            affirmative = ->(x) { is_affirmative? x }

            # Allow module to be specified as either `DigitalIO_1`, or as
            # discreet module name and index keys.
            /(?<mod>[^_]+)(_(?<idx>\d+))?/ =~ trigger[:module]
            {
                module: mod.to_sym,
                index: idx.to_i || trigger[:index] || 1,
                status: trigger[:status].to_sym,
                check: trigger.key?(:value) ? compare : affirmative
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
                          .select { |_name, role| myturn_role.casecmp role }
                          .keys
        end
    end

    descriptive_name 'ACA MyTurn Switching Logic'
    generic_name :MyTurn
    implements :logic

    def on_load
        system.subscribe(:System, 1, :current_mode) do
            logger.debug 'System mode change detected'
            rebind
        end

        on_update
    end

    def on_unload; end

    def on_update
        rebind
    end

    def disable(state = true)
        state = is_affirmative? state
        logger.debug { "#{state ? 'Dis' : 'En'}abling MyTurn triggers" }
        @switching_disabled = state
    end

    def enable
        disable false
    end

    def present(source)
        if @switching_disabled
            logger.debug 'MyTurn switching disabled, ignoring present request'
            return
        end

        logger.debug { "Activating #{source} as MyTurn presentation" }
        source = source.to_sym

        # TODO: add switching / window layout logic
    end

    protected


    def bind(source, trigger)
        target = trigger.values_at(:module, :index, :status)

        logger.debug { "Binding #{source} to #{target.join(' ')}" }

        system.subscribe(*target) do |notice|
            if trigger[:check][notice.value]
                logger.debug { "MyTurn trigger for #{source} activated" }
                present source
            end
        end
    end

    def rebind
        logger.debug 'Rebinding MyTurn to current system state'

        unless @subscriptions.nil?
            @subscriptions.each { |reference| unsubscribe(reference) }
        end

        sys = SystemAccessor.new system[:System]

        @subscriptions = sys.triggers.map do |source, trigger|
            bind source, trigger
        end

        @primary_displays = sys.displays :primary
        @preview_displays = sys.displays :preview
    end
end
