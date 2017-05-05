module Aca; end

class Aca::BlindLogic
    include ::Orchestrator::Constants

    descriptive_name 'ACA Blind Control Logic'
    generic_name :Blinds
    implements :logic

    def on_load
        on_update
    end

    def on_update
        blinds = setting :blinds

        hashable_settings = blinds.each_with_index.map do |blind, idx|
            name = blind[:title] || "Blind #{idx + 1}"
            [name.to_sym, blind.slice(:module, :up, :stop, :down)]
        end

        self[:controls] = Hash[hashable_settings]
    end

    def up(blind = :all)
        logger.debug { "Raising #{blind}" }
        move blind, :up
    end
    alias_method :open, :up

    def down(blind = :all)
        logger.debug { "Lowering #{blind}" }
        move blind, :down
    end
    alias_method :close, :down

    def stop(blind = :all)
        logger.debug { "Stopping #{blind}" }
        move blind, :stop
    end

    protected

    # Allow either index or name based lookups
    def sanitize(blind)
        blind = self[:controls].keys[blind - 1] if blind.is_a? Integer
        blind.to_sym
    end

    def move_all(direction)
        self[:controls].keys.each do |individual_blind|
            move individual_blind, direction
        end
    end

    def move(blind, direction)
        blind = sanitize blind

        return move_all direction if blind == :all

        begin
            config = self[:controls][blind]

            mod = config[:module]
            cmd = config[direction]

            system.get_implicit(mod).method_missing(cmd[:func], *cmd[:args])
        rescue => details
            logger.print_error details, "moving blind #{blind} #{direction}"
        end
    end
end
