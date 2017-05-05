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

        extract_config = ->(blind) { blind.slice :module, :up, :stop, :down }
        extract_title = ->(blind, fallback) { blind[:title] || fallback }

        blinds.each_with_index(1).map! do |blind, num|
            [extract_config[blind], extract_title[blind, "Blind #{num}"]]
        end

        self[:blinds] = Hash[blinds]
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
        if key.is_a? Integer
            self[:blinds].values[key - 1]
        else
            self[:blinds][key]
        end
    end

    def move(blind, direction)
        if blind.to_sym == :all
            self[:blinds].keys.each { |key| move key, direction }
            return
        end

        config = conifg_for blind

        mod = config[:module]
        cmd = config[direction]

        begin
            system.get_implicit(mod).method_missing(cmd[:func], *cmd[:args])
        rescue => details
            logger.print_error details, "moving blind #{blind} #{direction}"
        end
    end
end
