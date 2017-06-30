Orchestrator::Testing.mock_device 'Extron::PduPcs4' do
    # Module waits for this text to become ready
    transmit '© Copyright 20nn, Extron Electronics, IPL T PCS4'
    
    # Information request
    should_send 'I'
    responds "IPL T PCS4\r\n"

    # Enable verbose mode
    should_send "\e3CV\r"
    responds "Vrb3\r\n"

    # Perform actions
    exec(:power, 1, true)
        .should_send("\e1*1PC\x0D")
        .responds("Cpn01 Ppc1\r\n")
    expect(status[:power1]).to be(true)

    exec(:power, 2, false)
        .should_send("\e2*0PC\x0D")
        .responds("Cpn02 Ppc0\r\n")
    expect(status[:power2]).to be(false)
end

