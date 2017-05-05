module Aca; end

class Aca::BlindLogic
    include ::Orchestrator::Constants

    descriptive_name 'ACA Blind Control Logic'
    generic_name :Blinds
    implements :logic

    def initialize
        @all_blinds = []
    end

    def on_load
        on_update
    end

    def on_update
        blind_definitions = setting :blinds

        @all_blinds = []

        blind_definitions.each_with_index do |blind, idx|
            name = blind[:title] || "Blind #{idx + 1}"
            self[name.to_sym] = blind.slice :module, :up, :stop, :down
            @all_blinds << name
        end
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

    # Lookup blind either via it's title or index (1 based, for humans)
    def config_for(key)
        key = @all_blinds[key - 1] if key.is_a? Integer
        self[key.to_sym]
    end

    def move(blind, direction)
        if blind.to_sym == :all
            @all_blinds.each do |individual_blind|
                move individual_blind, direction
            end
            return
        end

        begin
            config = conifg_for blind

            mod = config[:module]
            cmd = config[direction]

            system.get_implicit(mod).method_missing(cmd[:func], *cmd[:args])
        rescue => details
            logger.print_error details, "moving blind #{blind} #{direction}"
        end
    end
end
