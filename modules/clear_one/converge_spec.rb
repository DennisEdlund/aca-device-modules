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
end
