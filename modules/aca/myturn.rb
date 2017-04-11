# Switching control for systems using 'MyTurn' distributed physical UI.
class Aca::MyTurn
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder

    descriptive_name 'MyTurn switching logic'
    generic_name :MyTurn
    implements :logic

    def on_load
        # TODO subscribe to mode changes

        on_update
    end

    def on_unload; end

    def on_update
        rebind
    end

    def present(source)
        source = source.to_sym

        # TODO add switching / window layout logic
    end

    protected

    def source_available?(key)
        sources = system[:inputs].map { |input| system[input] }.flatten
        sources.include?(key)
    end

    def triggers
        sources = system[:sources].select do |name, config|
            source_available?(name) && config.key?(:myturn_trigger)
        end

        sources.transform_values do |details|
            trigger = details[:myturn_trigger]
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
    end

    def subscribe(source, trigger)
        status = trigger.values_at(:module, :index, :status)
        system.subscribe(*status) do |notice|
            if notice.value == trigger[:value]
                logger.debug { "MyTurn triggered for #{source}" }
                present source
            end
        end
    end

    def rebind
        @subscriptions.each { |ref| unsubscribe(ref) } if @subscriptions
        @subscriptions = triggers.map do |source, trigger|
            subscribe(source, trigger)
        end
    end
end
