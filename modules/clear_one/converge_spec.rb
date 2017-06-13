Orchestrator::Testing.mock_device 'ClearOne::Converge' do
    transmit "************\r\n"
    transmit "* Converge *\r\n"
    transmit "************\r\n"
    transmit "Version 4.2.3\r\n"
    transmit "\r\n"
    transmit "\r\n"

    transmit "user: "
    wait(350)
    should_send "clearone\r\n"
    transmit "clearone\r\n"
    
    transmit "password: "
    wait(350)
    should_send "converge\r\n"
    transmit "\r\n"
    transmit "Authenticated.\r\n"

    expect(status[:authenticated]).to be(true)
end
