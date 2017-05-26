module Aca; end

class Aca::SkypeLogic
    include ::Orchestrator::Constants

    descriptive_name 'ACA Skype Logic'
    generic_name :Skype
    implements :logic


    def on_load
        self[:accept_call] = 0
        self[:hang_up] = 0
        self[:call_uri] = 0
    end


    def set_uri(uri)
        self[:uri] = uri
    end

    def call_uri
        self[:call_uri] += 1
    end

    def incoming_call(state, remote = nil)
        self[:incoming_call] = !!state
        self[:remote] = remote
    end

    def accept_call
        self[:accept_call] += 1

        if not self[:in_call]
            schedule.in('1s') do
                self[:mute] = true
            end
        end
    end

    def hang_up
        self[:hang_up] += 1
    end

    def show_self(state)
        self[:show_self] = !!state
    end

    def mute(state)
        self[:mute] = !!state
    end

    def in_call(state)
        self[:in_call] = !!state
    end

    def room_user(name)
        self[:room_user] = name
    end
end
