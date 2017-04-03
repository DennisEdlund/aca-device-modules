
Orchestrator::Testing.mock_device 'Extron::Switcher::Dxp' do

    # Module waits for this text to become ready
    transmit '© Copyright 2009, Extron Electronics, Device Name, etc etc'

    # Information request
    should_send 'I'
    responds "model name\r\n"

    # Enable verbose mode
    should_send "\e3CV\r"
    responds "Vrb3\r\n"

    # Perform actions
    exec(:switch, {1 => 3, 4 => 2})
        .should_send("1*3!")
        .responds("Out3 In1 All\r\n")
        .should_send("4*2!")
        .responds("Out4 In2 All\r\n")

    # Confirm result
    expect(result).to eq({1 => 3, 4 => 2})

    # Check status
    expect(status[:audio3]).to be(1)
    expect(status[:audio3]).to be(1)

    expect(status[:audio4]).to be(2)
    expect(status[:audio4]).to be(2)

end
