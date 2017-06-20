Orchestrator::Testing.mock_device 'Panasonic::Projector::Tcp' do
    transmit "NTCONTROL 1 09b075be\r"
    password = "d4a58eaea919558fb54a33a2effa8b94"

    exec(:power?)
        .should_send("#{password}00Q$S\r")
        .responds("00PON\r")

    expect(status[:power]).to be(true)
end
