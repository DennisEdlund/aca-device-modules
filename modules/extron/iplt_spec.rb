Orchestrator::Testing.mock_device 'Extron::Iplt' do
    # Module waits for this text to become ready
    transmit '(c) Copyright 2013, Extron Electronics, IPL T'
    
    # Information request
    should_send 'I'
    responds "IPL T CR48\r\n"

    # Enable verbose mode
    should_send "\e3CV\r"
    responds "Vrb3\r\n"

    # Perform actions
    exec(:relay, 1, true)
        .should_send("1*1O")
        .responds("Cpn1 Rly1\r\n")
    expect(status[:relay1]).to be(true)

    exec(:relay, 2, false)
        .should_send("1*0O")
        .responds("Cpn2 Rly0\r\n")
    expect(status[:relay2]).to be(false)
  
    transmit "Cpn1 Sio0\r\n"
    expect(status[:io1]).to be(false)

    transmit "Cpn3 Sio1\r\n"
    expect(status[:io3]).to be(true)
end

