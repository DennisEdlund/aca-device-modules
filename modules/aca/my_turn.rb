# Switching control for systems using 'MyTurn' distributed physical UI.
class Aca::MyTurn
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder

    descriptive_name 'ACA MyTurn Switching Logic'
    generic_name :MyTurn
    implements :logic

    def on_load
        # TODO: subscribe to mode changes

        on_update
    end

    def on_unload; end

    def on_update
        rebind
    end

    def present(source)
        logger.debug { "Activating #{source} as MyTurn presentation" }
        source = source.to_sym

        # TODO: add switching / window layout logic
    end

    protected

    def source_available?(sys, key)
        sources = sys[:inputs].map { |input| sys[input] }.flatten
        sources.include? key
    end

    def extract_trigger(source)
        trigger = source[:myturn_trigger]
        # Allow module to be specified as either `DigitalIO_1`, or as
        # discreet module name and index keys.
        /(?<mod>[^_]+)(_(?<idx>\d+))?/ =~ trigger[:module]
        {
            module: mod,
            index: idx || trigger[:index] || 1,
            status: trigger[:status],
            value: trigger[:value]
        }
    end

    def lookup_triggers(sys)
        sources = sys[:sources].select do |name, config|
            source_available?(sys, name) && config.key?(:myturn_trigger)
        end
        sources.transform_values { |config| extract_trigger(config) }
    end

    def bind(source, trigger)
        logger.debug do
            target = "#{trigger[:module]}_#{trigger[:index]}"
            target << "::#{trigger[:status]}"
            "Binding #{source} to #{target} when #{trigger[:value]}"
        end
        status = trigger.values_at(:module, :index, :status)
        system.subscribe(*status) do |notice|
            present source if notice.value == trigger[:value]
        end
    end

    def rebind
        logger.debug 'Rebinding MyTurn triggers'

        sys = system[:System]

        @subscriptions.each { |ref| unsubscribe(ref) } if @subscriptions

        @subscriptions = lookup_triggers(sys).map do |source, trigger|
            bind source, trigger
        end
    end
end
