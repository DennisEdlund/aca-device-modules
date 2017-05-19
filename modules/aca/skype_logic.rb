module Aca; end

class Aca::SkypeLogic
    include ::Orchestrator::Constants

    descriptive_name 'ACA Skype Logic'
    generic_name :Skype
    implements :logic

    def incomming_call(state)
        self[:incomming_call] = !!state
    end

    def accept_call
        self[:accept_call] = !self[:accept_call]
        self[:incomming_call] = false
    end

    def hang_up
        self[:hang_up] = !self[:hang_up]
        self[:incomming_call] = false
    end

    def show_self(state)
        self[:show_self] = !!state
    end

    def mute(state)
        self[:mute] = !!state
    end
end
