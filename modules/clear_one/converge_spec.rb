Orchestrator::Testing.mock_device 'ClearOne::Converge' do
    transmit "\r\n************\r\n* Converge *\r\n************\r\nVersion 4.4.0.2\r\n\r\n"
    transmit "\r\nuser: "
    wait(350)
    should_send "clearone\r\n"

    transmit "\r\npass"
    wait(350)
    should_send "converge\r\n"

    transmit "\r\n\r\nAuthenticated.\r\nText Mode Engaged\r\n"
    transmit "\r\nLevel: Administrator\r\n"

    expect(status[:authenticated]).to be(true)

    exec(:preset, 1)
        .should_send("#H* macro 1\r\n")
        .responds("OK> #H0 MACRO 1\r\n")

    expect(status[:last_macro]).to be(1)

    exec(:fader, 1, -90, 'mic')
        .should_send("#H* GAIN 1 M -65.0 A\r\n")
        .responds("OK> #H0 GAIN 1 M -65.00 A\r\n")

    expect(status[:fader1_mic]).to be(-65.0)

    exec(:mute, 1)
        .should_send("#H* MUTE 1 F 1\r\n")
        .responds("OK> #H0 MUTE 1 F 1\r\n")

    expect(status[:fader1_fader_mute]).to be(true)
end
