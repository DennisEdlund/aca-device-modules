MODULE_NAME='Powersoft K Series rev1mod' (dev device, 
					    dev TP[], 
					    dev vdevice,
					    char IpAddress[],
					    long IpPort,
					    long DiscoveryPort,
					    constant DeviceID,
					    integer nchControl[],
					    integer txtInfo[],
					    integer InCelsius,
					    integer ToggleTempBtn,
					    constant moduleNumber,
					    integer PollEnable,
					    integer PollingStatusBtn,
					    integer ConnectToDSP,
					    
					    constant MaxFaders,
					    integer nchFadersUp[],
					    integer nchFadersDown[],
					    integer lvlFadersLevels[],
					    integer FaderUnmute[],
					    constant DisableButton,
					    integer nchInputRouting[],
					    
					    constant MaxPresets,
					    integer nchPresets[],
					    char PresetName[][],
					    constant HoldValue,
					    integer CurrentPreset,
					    integer MediaPresetsBtn,
					    integer CurrentMediaPresets,
					    char TxtForMsgBox[][],
					    
					    integer MaxPresetPerPage,
					    integer UpBtn,
					    integer		DownBtn,
					    integer		nchVChannel[],
					    integer	 TxtVChannel[],
					    integer enableChanEdit[],
					    integer EnterPageBtn,
					    constant TpMaxPages,
					    constant TxtPages,
					    integer GetPresetNameBtn,
					    integer nchFunctionsPreset[],
					    char DSPtxtEmptyPreset[],
					    integer txtMsgBox[],
					    char MsgBoxPopPages[][],
					    constant LvlProgressBar)

(*


//  _________________________________________________________________________
// |                                                                         |
// | System:                                                                 |
// |                                                                         |
// | Powersoft K-2 Canali Class Amplifier                                    |
// |                                                                         |
// | Rev History: 12/03/12                                                   |
// |                                                                         |
// | Program by:                                                             |
// |             Cristiano Romani                                            |
// |             cristiano@romani-controls.com                               |
// |                                                                         |
// |             tel. +39  335 5437877                                       |
// |             fax. +39 0481  790292                                       |
// |_________________________________________________________________________|




*)

define_type

structure _tp
{
    char name[50]
    char buffer[255]
    char strName[50]
    integer answer
}


structure _ampModule
{
    integer mute
    
    integer PosAuxVoltage
    integer NegAuxVoltage
    float AuxAnalogVoltage
    integer MainVoltage
    integer MainCurrent
    float ExternalVoltage
    
    integer OutputCurrentMeter[2]
    integer OutputVoltageMeter[2]
    
    integer PosBusVoltage[2]
    integer NegBusVoltage[2]
    
    integer Clock
    integer Vaux
    integer IGBT
    integer BOOST
    
    integer Led

    integer OutAttenuations[3]
    integer HWMute[3]
    integer ModTemp
    
    integer Protection[2]
    integer HWProtection[2]
    integer AlarmTriggered[2]
    integer DSPAlarmTriggered[2]
    char ToneINAlarm[2][2]
    char ToneOUTAlarm[2][2]
    char LoadAlarm[2][2]
    
    // Ready
    integer Presence
    integer LastONOFF
    integer Mod1Ready
    integer DeviceON
    integer ChannelIdle[2]
    
    // Flags 
    integer Signal[2]
    
    integer ProtectionCount
    long Impedances[2]
    integer Gains[2]
    integer OutVoltages[2]
    integer MaxMains

    // Limiter
    integer Clip[2]
    integer Gate[2]
    
    integer ModCounter
    integer Boards[5]
    integer InputRouting
    integer IdleTime
    integer DSPModCounter
    long DSPCRC1
    long DSPCRC2
    long DSPCRC0
    long KAESOPModCounter
    long KAESOPCRC
}

structure _dsp
{
    char buffer[500]
    char reply[500]
    char trash[500]
    integer IsOnline
    
    _ampModule ampModule[2]
}


Define_variable


volatile integer InDebug = 1

volatile _tp tps[20]
volatile _dsp dsp

constant tlFeedbacks = 1
volatile long tlFeedbacksArray[] = { 400 }

constant tlDevicePoll = 2
constant waitTime = 3 // 300 mseconds

volatile long tlDevicePollArray[6] = 
{
    1500, // Status Request Of Module #1
    1500, // Mute Status Request Of Module #1
    1500, // Status Request Of Module #2 if Present
    1500, // Mute Status Request Of Module #2 if Present
    1000, // Request Presets Online
    1500  // Status Tone CH1,CH2 if Alarm is Active
}

constant tlGetNamePoll = 3
volatile long tlGetNamePollArray[] = { 300 }

constant tlProgressBar  = 12
volatile long tlProgressArray[240]  
volatile integer tlRepeatTimes

volatile integer UseConnect = 1
volatile integer GetPreset = 0
volatile integer TempPreset = 0

volatile integer TpIsHolding[20]
volatile integer TpPresetsIsHolding[20]
volatile integer TpWasEditing[20]

volatile integer TpCurrentPage[20]
volatile integer TpVIsHolding[20]

volatile integer PendingName = 0
volatile integer Pendingk = 0

volatile integer IndexPresetName = 0    
volatile integer OldIndexPresetName = 0
constant          MaxIndexPresetName = 50

volatile integer StoreRecallPresetFB = 1

volatile char cCrcHigh
volatile char cCrcLow 



constant Head  = $02
constant CmdID = $4A
constant Tail  = $03

constant Read  = $52
constant Write = $57

constant Esc   = $1b //27
constant dCel  = $05


constant DSPMute    = 1
constant DSPStatus  = 2
constant Protection = 3
constant Ready      = 4
constant Flags      = 5
constant Limiter    = 6
constant Board      = 7
constant Routing    = 8
                     
constant sUp        = 1
constant sDown      = 2


constant PowerONFb         = 401
constant OnlineFb          = 402
constant MuteCH1Fb         = 403
constant MuteCH2Fb         = 404

constant ClockFb           = 405
constant VauxFb            = 406
constant IGBTFb            = 407
constant BOOSTFb           = 408

constant PresenceFb        = 409
constant Mod1ReadyFb       = 410
constant DeviceONFb        = 411
constant Channel1IdleFb    = 412
constant Channel2IdleFb    = 413
                              
constant ProtectionCH1Fb   = 414
constant ProtectionCH2Fb   = 415
constant HWProtectionCH1Fb = 416
constant HWProtectionCH2Fb = 417

constant SignalCH1Fb       = 418
constant SignalCH2Fb       = 419
                               
//constant GateCH1Fb  = 420
//constant GateCH2Fb  = 421
//constant ClipCH1Fb  = 422
//constant ClipCH2Fb  = 423

constant Qmax   =   100     
volatile Queue[Qmax][255]                     // Queued commands 
volatile integer Qhead = 1                   // Queue Head Point 
volatile integer Qtail = 1                   // Queue Tail Point 
volatile integer QhasItem                    // 1 if any items are in the Queue
volatile integer Qready                      // 1 if ready to send the next cmd 



volatile integer g_pCRC16CcittTable[] = 
{
    $0000, $1021, $2042, $3063, $4084, $50a5, $60c6, $70e7,
    $8108, $9129, $a14a, $b16b, $c18c, $d1ad, $e1ce, $f1ef,
    $1231, $0210, $3273, $2252, $52b5, $4294, $72f7, $62d6,
    $9339, $8318, $b37b, $a35a, $d3bd, $c39c, $f3ff, $e3de,
    $2462, $3443, $0420, $1401, $64e6, $74c7, $44a4, $5485,
    $a56a, $b54b, $8528, $9509, $e5ee, $f5cf, $c5ac, $d58d,
    $3653, $2672, $1611, $0630, $76d7, $66f6, $5695, $46b4,
    $b75b, $a77a, $9719, $8738, $f7df, $e7fe, $d79d, $c7bc,
    $48c4, $58e5, $6886, $78a7, $0840, $1861, $2802, $3823,
    $c9cc, $d9ed, $e98e, $f9af, $8948, $9969, $a90a, $b92b,
    $5af5, $4ad4, $7ab7, $6a96, $1a71, $0a50, $3a33, $2a12,
    $dbfd, $cbdc, $fbbf, $eb9e, $9b79, $8b58, $bb3b, $ab1a,
    $6ca6, $7c87, $4ce4, $5cc5, $2c22, $3c03, $0c60, $1c41,
    $edae, $fd8f, $cdec, $ddcd, $ad2a, $bd0b, $8d68, $9d49,
    $7e97, $6eb6, $5ed5, $4ef4, $3e13, $2e32, $1e51, $0e70,
    $ff9f, $efbe, $dfdd, $cffc, $bf1b, $af3a, $9f59, $8f78,
    $9188, $81a9, $b1ca, $a1eb, $d10c, $c12d, $f14e, $e16f,
    $1080, $00a1, $30c2, $20e3, $5004, $4025, $7046, $6067,
    $83b9, $9398, $a3fb, $b3da, $c33d, $d31c, $e37f, $f35e,
    $02b1, $1290, $22f3, $32d2, $4235, $5214, $6277, $7256,
    $b5ea, $a5cb, $95a8, $8589, $f56e, $e54f, $d52c, $c50d,
    $34e2, $24c3, $14a0, $0481, $7466, $6447, $5424, $4405,
    $a7db, $b7fa, $8799, $97b8, $e75f, $f77e, $c71d, $d73c,
    $26d3, $36f2, $0691, $16b0, $6657, $7676, $4615, $5634,
    $d94c, $c96d, $f90e, $e92f, $99c8, $89e9, $b98a, $a9ab,
    $5844, $4865, $7806, $6827, $18c0, $08e1, $3882, $28a3,
    $cb7d, $db5c, $eb3f, $fb1e, $8bf9, $9bd8, $abbb, $bb9a,
    $4a75, $5a54, $6a37, $7a16, $0af1, $1ad0, $2ab3, $3a92,
    $fd2e, $ed0f, $dd6c, $cd4d, $bdaa, $ad8b, $9de8, $8dc9,
    $7c26, $6c07, $5c64, $4c45, $3ca2, $2c83, $1ce0, $0cc1,
    $ef1f, $ff3e, $cf5d, $df7c, $af9b, $bfba, $8fd9, $9ff8,
    $6e17, $7e36, $4e55, $5e74, $2e93, $3eb2, $0ed1, $1ef0
}


define_function long crc16c(char crcString16c[255])
{
    stack_var long m_crc16c,a,b,c
    stack_var integer i
    stack_var char tmp[255]
    
    m_crc16c = $0000
    
    for(i = 1; i < length_string(crcString16c) + 1 ; i++) 
    {
	a = m_crc16c >> 8
	b = crcString16c[i]
	c = (m_crc16c << 8)
    
    
    m_crc16c = (g_pCRC16CcittTable[((a) bxor (b)) + 1] bxor (c))
    
    if(m_crc16c >= $FFFF) 
    {
	tmp = itohex(m_crc16c)
	tmp = right_string(tmp,4)
	m_crc16c = hextoi(tmp)
    }
    
    }
    
    send_string 0, "'calculated checksum is  ', ITOhex(m_crc16c)"
    
    return m_crc16c
}



define_function Debug(char cmd[255])
{
    if(InDebug > 0) send_string 0,"cmd,13,10"
}       

define_function integer TpChanValidRange (integer i)
{
    if((i >= 1) && (i <= 4000) && (i <> DisableButton)) return 1
    else                                                return 0
}

define_function char[20] DPStoA(dev dvID)
{
    return "itoa(dvID.Number), ':', itoa(dvID.Port), ':', itoa(dvID.System)"
}

define_function MsgBox(integer k,integer msg1,integer msg2,integer msg3,integer msg4)
{
    if(k > 0)
    {
	if(TpChanValidRange(txtMsgBox[1])) send_command tp[k],"'^TXT-',itoa(txtMsgBox[1]),',0,',TxtForMsgBox[msg1]"
	if(TpChanValidRange(txtMsgBox[2])) send_command tp[k],"'^TXT-',itoa(txtMsgBox[2]),',0,',TxtForMsgBox[msg2]"
	if(TpChanValidRange(txtMsgBox[3])) send_command tp[k],"'^TXT-',itoa(txtMsgBox[3]),',0,',TxtForMsgBox[msg3]"
	if(TpChanValidRange(txtMsgBox[4])) send_command tp[k],"'^TXT-',itoa(txtMsgBox[4]),',0,',TxtForMsgBox[msg4]"
    
	send_command tp[k],"'PPON-',MsgBoxPopPages[1]"
    }
    else
    {
	if(TpChanValidRange(txtMsgBox[1])) send_command tp,"'^TXT-',itoa(txtMsgBox[1]),',0,',TxtForMsgBox[msg1]"
	if(TpChanValidRange(txtMsgBox[2])) send_command tp,"'^TXT-',itoa(txtMsgBox[2]),',0,',TxtForMsgBox[msg2]"
	if(TpChanValidRange(txtMsgBox[3])) send_command tp,"'^TXT-',itoa(txtMsgBox[3]),',0,',TxtForMsgBox[msg3]"
	if(TpChanValidRange(txtMsgBox[4])) send_command tp,"'^TXT-',itoa(txtMsgBox[4]),',0,',TxtForMsgBox[msg4]"
	 
	send_command tp,"'PPON-',MsgBoxPopPages[1]"
    }
}

define_function integer AnswerBox(integer k,integer msg1,integer msg2,integer msg3,integer msg4)
{
    tps[k].answer = 0
    
    if(TpChanValidRange(txtMsgBox[1])) send_command tp[k],"'^TXT-',itoa(txtMsgBox[1]),',0,',TxtForMsgBox[msg1]"
    if(TpChanValidRange(txtMsgBox[2])) send_command tp[k],"'^TXT-',itoa(txtMsgBox[2]),',0,',TxtForMsgBox[msg2]"
    if(TpChanValidRange(txtMsgBox[3])) send_command tp[k],"'^TXT-',itoa(txtMsgBox[3]),',0,',TxtForMsgBox[msg3]"
    if(TpChanValidRange(txtMsgBox[4])) send_command tp[k],"'^TXT-',itoa(txtMsgBox[4]),',0,',TxtForMsgBox[msg4]"
										 
    send_command tp[k],"'PPON-',MsgBoxPopPages[2]"
}


define_function integer ProgressBar(integer k,integer seconds,integer msg1,integer msg2,integer msg3,integer msg4)
{
    
    tlRepeatTimes = seconds
    
    if(timeline_active(tlProgressBar)) timeline_kill(tlProgressBar)
    
    timeline_create(tlProgressBar,tlProgressArray,240,timeline_relative,timeline_repeat)
    
    if(TpChanValidRange(txtMsgBox[1])) send_command tp[k],"'^TXT-',itoa(txtMsgBox[1]),',0,',TxtForMsgBox[msg1]"
    if(TpChanValidRange(txtMsgBox[2])) send_command tp[k],"'^TXT-',itoa(txtMsgBox[2]),',0,',TxtForMsgBox[msg2]"
    if(TpChanValidRange(txtMsgBox[3])) send_command tp[k],"'^TXT-',itoa(txtMsgBox[3]),',0,',TxtForMsgBox[msg3]"
    if(TpChanValidRange(txtMsgBox[4])) send_command tp[k],"'^TXT-',itoa(txtMsgBox[4]),',0,',TxtForMsgBox[msg4]"
										 
    send_command tp[k],"'PPON-',MsgBoxPopPages[3]"				
}



define_function PrintHex(char text[30],cmd[255])
local_var  loop txt[200]
{
  txt  = ""
  loop = 1
  WHILE (loop <= LENGTH_STRING(cmd))
  {
    txt  = "txt ,'$',RIGHT_STRING("'00',ITOHEX(cmd[loop])",2),','"     (* HEX *)
    loop = loop + 1
  }
  if(Indebug > 0) send_string 0,"text,txt ,13,10"
}   


define_function char[100] GetIpError (long lERR)
{
  select
  {
    active (lERR = 0):
      return "";
    active (lERR = 2):
      return "'IP ERROR (',itoa(lERR),'): General Failure (IP_CLIENT_OPEN/IP_SERVER_OPEN)'";
    active (lERR = 4):
      return "'IP ERROR (',itoa(lERR),'): unknown host (IP_CLIENT_OPEN)'";
    active (lERR = 6):
      return "'IP ERROR (',itoa(lERR),'): connection refused (IP_CLIENT_OPEN)'";
    active (lERR = 7):
      return "'IP ERROR (',itoa(lERR),'): connection timed out (IP_CLIENT_OPEN)'";
    active (lERR = 8):
      return "'IP ERROR (',itoa(lERR),'): unknown connection error (IP_CLIENT_OPEN)'";
    active (lERR = 14):
      return "'IP ERROR (',itoa(lERR),'): local port already used (IP_CLIENT_OPEN/IP_SERVER_OPEN)'";
    active (lERR = 16):
      return "'IP ERROR (',itoa(lERR),'): too many open sockets (IP_CLIENT_OPEN/IP_SERVER_OPEN)'";
    active (lERR = 10):
      return "'IP ERROR (',itoa(lERR),'): Binding error (IP_SERVER_OPEN)'";
    active (lERR = 11):
      return "'IP ERROR (',itoa(lERR),'): Listening error (IP_SERVER_OPEN)'";
    active (lERR = 15):
      return "'IP ERROR (',itoa(lERR),'): UDP socket already listening (IP_SERVER_OPEN)'";
    active (lERR = 9):
      return "'IP ERROR (',itoa(lERR),'): Already closed (IP_CLIENT_CLOSE/IP_SERVER_CLOSE)'";
    active (1):
      return "'IP ERROR (',itoa(lERR),'): Unknown'";
  }
}

define_function char[255] Excape(char cmd[])
{
    stack_var integer i
    stack_var char result[255]
    
    result = ""
    
    for(i = 1;i <= length_string(cmd);i ++)
    {
	if((cmd[i] == $02) || (cmd[i] == $03) || (cmd[i] == $7B) || (cmd[i] == $7D) || (cmd[i] == $1B))
	{
	    result = "result,Esc,(cmd[i] + $40)" // CONCATENATE ESCAPE CHAR AND SPECIAL CHAR
	}
	else
	{
	    result = "result,cmd[i]" 
	}
    }
    return result
}

define_function char[255] DeExcape(char cmd[])
{
    stack_var integer i
    stack_var char result[255]
    
    result = ""
    
    for(i = 1;i <= length_string(cmd);i ++)
    {
	if((cmd[i] == esc) && (i < length_string(cmd)))
	{
	    if(cmd[i + 1] >= $40) cmd[i + 1] = cmd[i + 1] - $40												
	}
	else
	{
	    result = "result,cmd[i]" 
	}
    }
    return result
}

define_function char checksum(char cmd[])
{
    stack_var integer i
    stack_var char chk
    
    for(i = 1;i <= length_string(cmd);i ++)
    {
	chk = chk bxor cmd[i]
    }
    return chk
}

define_function char[4] getTAG32()
{
    stack_var char TAGc32[4]
    
    TAGc32 = "itoa(1),itoa(random_number(8)+1),itoa(random_number(8)+1),itoa(4)"
    
    return TAGc32

}

define_function CalculateBINValue(integer Type,integer value)
{
    stack_var integer nIntegerValueTemp,i,b
    stack_var integer NBit[8]

    nIntegerValueTemp = value 
    
    for (i = 1; i < 9; i++)
    {
	nBit[i] = nIntegerValueTemp % 2
	nIntegerValueTemp  = nIntegerValueTemp  / 2
    
	select
	{
	    active(Type == DSPMute):
	    {
		switch(i)
		{
		    case 1:
		    {
		    if(nBit[1]==1) dsp.ampModule[1].HWMute[1] = 1
		    else           dsp.ampModule[1].HWMute[1] = 0
		    }
		    case 2:
		    {
			if(nBit[2]==1) dsp.ampModule[1].HWMute[2] = 1
			else           dsp.ampModule[1].HWMute[2] = 0
		    }
		}
	    }
	    active(Type == DSPStatus):
	    {
		switch(i)
		{
		    case 1:
		    {
			if(nBit[1]==1) dsp.ampModule[1].Clock = 1
			else           dsp.ampModule[1].Clock = 0
		    }
		    case 2:
		    {
			if(nBit[2]==1) dsp.ampModule[1].Vaux = 1
			else           dsp.ampModule[1].Vaux = 0
		    }
		    case 3:
		    {
			if(nBit[3]==1) dsp.ampModule[1].IGBT = 1
			else           dsp.ampModule[1].IGBT = 0
		    }
		    case 4:
		    {
			if(nBit[4]==1) dsp.ampModule[1].BOOST = 1
			else           dsp.ampModule[1].BOOST = 0
		    }
		    default:
		    {
		//																								debug("'Out of interesting!'")
		    }
		}
	    }
	    active(Type == Protection):
	    {
		switch(i)
		{
		    case 1:
		    {
			if(nBit[1]==1) dsp.ampModule[1].Protection[1] = 1
			else           dsp.ampModule[1].Protection[1] = 0
		    }
		    case 2:
		    {
			if(nBit[2]==1) dsp.ampModule[1].HWProtection[1] = 1
			else           dsp.ampModule[1].HWProtection[1] = 0
		    }
		    case 3:
		    {
			if(nBit[3]==1) dsp.ampModule[1].AlarmTriggered[1] = 1
			else           dsp.ampModule[1].AlarmTriggered[1] = 0
		    }
		    case 4:
		    {
			if(nBit[4]==1) dsp.ampModule[1].DSPAlarmTriggered[1] = 1
			else           dsp.ampModule[1].DSPAlarmTriggered[1] = 0
		    }
		    case 5:
		    {
			if(nBit[5]==1) dsp.ampModule[1].Protection[2] = 1
			else           dsp.ampModule[1].Protection[2] = 0
		    }
		    case 6:
		    {
			if(nBit[6]==1) dsp.ampModule[1].HWProtection[2] = 1
			else           dsp.ampModule[1].HWProtection[2] = 0
		    }
		    case 7:
		    {
			if(nBit[7]==1) dsp.ampModule[1].AlarmTriggered[2] = 1
			else           dsp.ampModule[1].AlarmTriggered[2] = 0
		    }
		    case 8:
		    {
			if(nBit[8]==1) dsp.ampModule[1].DSPAlarmTriggered[2] = 1
			else           dsp.ampModule[1].DSPAlarmTriggered[2] = 0
		    }
		    default:
		    {
		    //																								debug("'Protection Out of interesting!'")
		    }
		}
	    }
	    active(Type==Ready):
	    {
		switch(i)
		{
		    case 1:
		    {
			if(nBit[1]==1) dsp.ampModule[1].Presence = 1
			else           dsp.ampModule[1].Presence = 0
		    }
		    case 2:
		    {
			if(nBit[2]==1) dsp.ampModule[1].LastONOFF = 1
			else           dsp.ampModule[1].LastONOFF = 0
		    }
		    case 3:
		    {
			if(nBit[3]==1) dsp.ampModule[1].Mod1Ready = 1
			else           dsp.ampModule[1].Mod1Ready = 0
		    }
		    case 4:
		    {
			if(nBit[4]==1) dsp.ampModule[1].DeviceON = 1
			else           dsp.ampModule[1].DeviceON = 0
		    }
		    case 6:
		    {
			if(nBit[6]==1) dsp.ampModule[1].ChannelIdle[1] = 1
			else           dsp.ampModule[1].ChannelIdle[1] = 0
		    }
		    case 7:
		    {
			if(nBit[7]==1) dsp.ampModule[1].ChannelIdle[2] = 1
			else           dsp.ampModule[1].ChannelIdle[2] = 0
		    }
		    default:
		    {
		    //																								debug("'Ready Out of interesting!'")
		    }
		}
	    }
	    active(Type==Flags):
	    {
		switch(i)
		{
		    case 1:
		    {
		    if(nBit[1]==1) dsp.ampModule[1].Signal[1] = 1
		    else           dsp.ampModule[1].Signal[1] = 0
		    }
		    case 2:
		    {
		    if(nBit[2]==1) dsp.ampModule[1].Signal[2] = 1
		    else           dsp.ampModule[1].Signal[2] = 0
		    }
		    default:
		    {
		    //																								debug("'Ready Out of interesting!'")
		    }
		}
	    }
	    active(Type==Limiter):
	    {
		switch(i)
		{
		    case 1:
		    {
		    if(nBit[1]==1) dsp.ampModule[1].Clip[1] = 1 // Ative
		    else           dsp.ampModule[1].Clip[1] = 0 // Not Active
		    }
		    case 2:
		    {
		    if(nBit[2]==1) dsp.ampModule[1].Clip[2] = 1
		    else           dsp.ampModule[1].Clip[2] = 0
		    }
		    case 3:
		    {
		    if(nBit[3]==1) dsp.ampModule[1].Gate[1] = 1 // Active
		    else           dsp.ampModule[1].Gate[1] = 0 // Not Active
		    }
		    case 4:
		    {
		    if(nBit[4]==1) dsp.ampModule[1].Gate[2] = 1
		    else           dsp.ampModule[1].Gate[2] = 0
		    }
		    default:
		    {
		    //																								debug("'Ready Out of interesting!'")
		    }
		}
	    }
	    active(Type==Board):
	    {
		for(b=1;b<=5;b++)
		{
		
		if(nBit[b]==1) dsp.ampModule[1].Boards[b] = 1 // Presente
		else           dsp.ampModule[1].Boards[b] = 0 // Absence
		
		}
	    }
	    active(Type==Routing):
	    {
		for(b=1;b<=6;b++)
		{
		
		if(nBit[b]==1) dsp.ampModule[1].InputRouting = b-1
		}
	    }
	}
    }
}


define_function char[2] GetID(integer id)
{
    return right_string("'00',itoa(id)",2)
} 

define_function CheckQueue()
{
    if (QhasItem && Qready)                  
    {    
        off[Qready]
        if (Qtail = Qmax)                              
            Qtail = 1                      
        else
            Qtail = Qtail + 1               
 
        if (Qtail = Qhead)                    
            off[QhasItem]                   
      
        send_string device,"Queue[Qtail]"   

        //wait waitTime 'Queue'               
        on[Qready]
     }
}       

define_function SendToDSP (char cmd[])
{
    cmd = "Head,Excape("getid(DeviceID),cmd"),checksum("Head,getid(DeviceID),cmd"),Tail"

    if (Qhead = Qmax)                        
    {
        if (Qtail <> 1)                     
        {
            Qhead = 1
            Queue[Qhead] = cmd              
            on[QhasItem]
        } 
    }
    else if (Qtail <> Qhead + 1)           
    {
        Qhead = Qhead + 1
        Queue[Qhead] = cmd                  
        on[QhasItem]
    }
    else    send_string 0,"__file__,' Que Full!',$0D,$0A"
}

define_function float getIntegerValue(integer Num)
{
    stack_var float flonum
    stack_var float Inum
    
    flonum = (Num / 30.00)
    Inum = 100.00 - flonum
    
    return Inum
}

define_function CheckTpLevels(integer i)
{
    
    debug("'CheckTpLevels ==> ',itoa(i)")
    
    if(TpChanValidRange(lvlFadersLevels[i])) send_level tp,lvlFadersLevels[i],dsp.ampModule[1].OutAttenuations[i]
    if(TpChanValidRange(nchFadersUp[i]))   send_command tp,"'^TXT-',itoa(nchFadersUp[i]),',0,',itoa(getIntegerValue(dsp.ampModule[1].OutAttenuations[i])),'%'"
    
}
define_function checkTPLevelAllVol(integer Volume)
{
    debug("'Check ALL TpLevels ==> ',itoa(Volume)")
    
    if(TpChanValidRange(lvlFadersLevels[1])) send_level tp,lvlFadersLevels[1],dsp.ampModule[1].OutAttenuations[1]
    if(TpChanValidRange(lvlFadersLevels[2])) send_level tp,lvlFadersLevels[2],dsp.ampModule[1].OutAttenuations[2]
    if(TpChanValidRange(lvlFadersLevels[3])) send_level tp,lvlFadersLevels[3],dsp.ampModule[1].OutAttenuations[3]
    
    
    if(TpChanValidRange(nchFadersUp[1]))   send_command tp,"'^TXT-',itoa(nchFadersUp[1]),',0,',itoa(getIntegerValue(dsp.ampModule[1].OutAttenuations[1])),'%'"
    if(TpChanValidRange(nchFadersUp[2]))   send_command tp,"'^TXT-',itoa(nchFadersUp[2]),',0,',itoa(getIntegerValue(dsp.ampModule[1].OutAttenuations[2])),'%'"
    if(TpChanValidRange(nchFadersUp[3]))   send_command tp,"'^TXT-',itoa(nchFadersUp[3]),',0,',itoa(getIntegerValue(dsp.ampModule[1].OutAttenuations[3])),'%'"


}



define_function float getFahrenheit(integer G)
{
    stack_var float f

    f = ((G + 40) * 1.8) - 40
    
    return f
}


define_function ClearTpInfo()
{
    dsp.ampModule[1].PosAuxVoltage = 0
    dsp.ampModule[1].NegAuxVoltage = 0
    dsp.ampModule[1].AuxAnalogVoltage = 0
    dsp.ampModule[1].MainVoltage = 0
    dsp.ampModule[1].MainCurrent = 0
    dsp.ampModule[1].ExternalVoltage  = 0
    dsp.ampModule[1].PosBusVoltage[1] = 0
    dsp.ampModule[1].NegBusVoltage[1] = 0
    dsp.ampModule[1].PosBusVoltage[2] = 0
    dsp.ampModule[1].NegBusVoltage[2] = 0
    
    dsp.ampModule[1].Clock = 0
    dsp.ampModule[1].Vaux  = 0
    dsp.ampModule[1].IGBT  = 0
    dsp.ampModule[1].BOOST = 0
    dsp.ampModule[1].Led   = 0
    
    dsp.ampModule[1].OutAttenuations[1] = 0
    dsp.ampModule[1].OutAttenuations[2] = 0
    dsp.ampModule[1].OutAttenuations[3] = 0
    
    dsp.ampModule[1].HWMute[1] = 0
    dsp.ampModule[1].HWMute[2] = 0
    
    dsp.ampModule[1].ModTemp   = 0

    dsp.ampModule[1].Protection[1] = 0
    dsp.ampModule[1].Protection[2] = 0
    
    dsp.ampModule[1].HWProtection[1] = 0
    dsp.ampModule[1].HWProtection[2] = 0
    dsp.ampModule[1].AlarmTriggered[1] = 0
    dsp.ampModule[1].AlarmTriggered[2] = 0
    dsp.ampModule[1].DSPAlarmTriggered[1] = 0
    dsp.ampModule[1].DSPAlarmTriggered[2] = 0
    dsp.ampModule[1].Presence = 0
    dsp.ampModule[1].LastONOFF = 0
    dsp.ampModule[1].Mod1Ready = 0
    dsp.ampModule[1].DeviceON  = 0
    dsp.ampModule[1].ChannelIdle[1] = 0
    dsp.ampModule[1].ChannelIdle[2] = 0
    dsp.ampModule[1].Signal[1] = 0
    dsp.ampModule[1].Signal[2] = 0
    dsp.ampModule[1].ProtectionCount = 0
    dsp.ampModule[1].Impedances[1] = 0
    dsp.ampModule[1].Impedances[2] = 0
    dsp.ampModule[1].Gains[1] = 0
    dsp.ampModule[1].Gains[2] = 0
    dsp.ampModule[1].OutVoltages[1] = 0
    dsp.ampModule[1].OutVoltages[2] = 0
    dsp.ampModule[1].MaxMains = 0
    dsp.ampModule[1].Clip[1]  = 0 
    dsp.ampModule[1].Clip[2]  = 0
    dsp.ampModule[1].Gate[1]  = 0
    dsp.ampModule[1].Gate[2]  = 0
    dsp.ampModule[1].ModCounter = 0
    dsp.ampModule[1].Boards[1]  = 0
    dsp.ampModule[1].Boards[2]  = 0
    dsp.ampModule[1].Boards[3]  = 0
    dsp.ampModule[1].Boards[4]  = 0
    dsp.ampModule[1].Boards[5]  = 0
    dsp.ampModule[1].InputRouting = 0
    dsp.ampModule[1].IdleTime     = 0
    dsp.ampModule[1].DSPModCounter = 0
    dsp.ampModule[1].DSPCRC1       = 0
    dsp.ampModule[1].DSPCRC2       = 0
    dsp.ampModule[1].DSPCRC0       = 0
    dsp.ampModule[1].KAESOPModCounter = 0
    dsp.ampModule[1].KAESOPCRC = 0
    
    send_level tp,lvlFadersLevels[1],30
    send_level tp,lvlFadersLevels[2],30
}

define_function ReloadTpInfo(integer k)
{
    if(k > 0)
    {
	if(TpChanValidRange(txtInfo[ 1])) send_command tp[k],"'^TXT-',itoa(txtInfo[ 1]),',0,',itoa(dsp.ampModule[1].PosAuxVoltage),' V'"
	if(TpChanValidRange(txtInfo[ 2])) send_command tp[k],"'^TXT-',itoa(txtInfo[ 2]),',0,-',itoa(dsp.ampModule[1].NegAuxVoltage),' V'"
	if(TpChanValidRange(txtInfo[ 3])) send_command tp[k],"'^TXT-',itoa(txtInfo[ 3]),',0,',ftoa(dsp.ampModule[1].AuxAnalogVoltage),' V'"
	if(TpChanValidRange(txtInfo[ 4])) send_command tp[k],"'^TXT-',itoa(txtInfo[ 4]),',0,',itoa(dsp.ampModule[1].MainVoltage),' V'"
	if(TpChanValidRange(txtInfo[ 5])) send_command tp[k],"'^TXT-',itoa(txtInfo[ 5]),',0,',itoa(dsp.ampModule[1].MainCurrent),' A'"
	if(TpChanValidRange(txtInfo[ 6])) send_command tp[k],"'^TXT-',itoa(txtInfo[ 6]),',0,',ftoa(dsp.ampModule[1].ExternalVoltage),' V'"
	if(TpChanValidRange(txtInfo[ 7])) send_command tp[k],"'^TXT-',itoa(txtInfo[ 7]),',0,',itoa(dsp.ampModule[1].PosBusVoltage[1]),' V'"
	if(TpChanValidRange(txtInfo[ 8])) send_command tp[k],"'^TXT-',itoa(txtInfo[ 8]),',0,-',itoa(dsp.ampModule[1].NegBusVoltage[1]),' V'"
	if(TpChanValidRange(txtInfo[ 9])) send_command tp[k],"'^TXT-',itoa(txtInfo[ 9]),',0,',itoa(dsp.ampModule[1].PosBusVoltage[2]),' V'"
	if(TpChanValidRange(txtInfo[10])) send_command tp[k],"'^TXT-',itoa(txtInfo[10]),',0,-',itoa(dsp.ampModule[1].NegBusVoltage[2]),' V'"
	
	if(TpChanValidRange(txtInfo[11])) send_command tp[k],"'^TXT-',itoa(txtInfo[11]),',0,',itoa(dsp.ampModule[1].Clock)"
	if(TpChanValidRange(txtInfo[12])) send_command tp[k],"'^TXT-',itoa(txtInfo[12]),',0,',itoa(dsp.ampModule[1].Vaux)"
	if(TpChanValidRange(txtInfo[13])) send_command tp[k],"'^TXT-',itoa(txtInfo[13]),',0,',itoa(dsp.ampModule[1].IGBT)"
	if(TpChanValidRange(txtInfo[14])) send_command tp[k],"'^TXT-',itoa(txtInfo[14]),',0,',itoa(dsp.ampModule[1].BOOST)"
	if(TpChanValidRange(txtInfo[15])) send_command tp[k],"'^TXT-',itoa(txtInfo[15]),',0,',itoa(dsp.ampModule[1].Led)"
	
	if(TpChanValidRange(txtInfo[16]))
	{
	    if(dsp.ampModule[1].OutAttenuations[1] > 0) send_command tp[k],"'^TXT-',itoa(txtInfo[16]),',0,-',itoa(dsp.ampModule[1].OutAttenuations[1]),' dB'"
	    else                                        send_command tp[k],"'^TXT-',itoa(txtInfo[16]),',0,',itoa(dsp.ampModule[1].OutAttenuations[1]),' dB'"
	}
	if(TpChanValidRange(txtInfo[17]))
	{
	    if(dsp.ampModule[1].OutAttenuations[1] > 0) send_command tp[k],"'^TXT-',itoa(txtInfo[17]),',0,-',itoa(dsp.ampModule[1].OutAttenuations[2]),' dB'"
	    else                                        send_command tp[k],"'^TXT-',itoa(txtInfo[17]),',0,',itoa(dsp.ampModule[1].OutAttenuations[2]),' dB'"
	}
	
	if(TpChanValidRange(txtInfo[18])) send_command tp[k],"'^TXT-',itoa(txtInfo[18]),',0,',itoa(dsp.ampModule[1].HWMute[1])"
	if(TpChanValidRange(txtInfo[19])) send_command tp[k],"'^TXT-',itoa(txtInfo[19]),',0,',itoa(dsp.ampModule[1].HWMute[2])"
	
	if(TpChanValidRange(txtInfo[20]))
	{
	    if(InCelsius == 1) send_command tp[k],"'^TXT-',itoa(txtInfo[20]),',0,',itoa(dsp.ampModule[1].ModTemp),'° C'"
	    else               send_command tp[k],"'^TXT-',itoa(txtInfo[20]),',0,',itoa(getFahrenheit(dsp.ampModule[1].ModTemp)),'° F'"
	}
	if(TpChanValidRange(txtInfo[21])) send_command tp[k],"'^TXT-',itoa(txtInfo[21]),',0,',itoa(dsp.ampModule[1].Protection[1])"
	if(TpChanValidRange(txtInfo[22])) send_command tp[k],"'^TXT-',itoa(txtInfo[22]),',0,',itoa(dsp.ampModule[1].Protection[2])"
	
	if(TpChanValidRange(txtInfo[23])) send_command tp[k],"'^TXT-',itoa(txtInfo[23]),',0,',itoa(dsp.ampModule[1].HWProtection[1])"
	if(TpChanValidRange(txtInfo[24])) send_command tp[k],"'^TXT-',itoa(txtInfo[24]),',0,',itoa(dsp.ampModule[1].HWProtection[2])"
	if(TpChanValidRange(txtInfo[25])) send_command tp[k],"'^TXT-',itoa(txtInfo[25]),',0,',itoa(dsp.ampModule[1].AlarmTriggered[1])"
	if(TpChanValidRange(txtInfo[26])) send_command tp[k],"'^TXT-',itoa(txtInfo[26]),',0,',itoa(dsp.ampModule[1].AlarmTriggered[2])"
	if(TpChanValidRange(txtInfo[27])) send_command tp[k],"'^TXT-',itoa(txtInfo[27]),',0,',itoa(dsp.ampModule[1].DSPAlarmTriggered[1])"
	if(TpChanValidRange(txtInfo[28])) send_command tp[k],"'^TXT-',itoa(txtInfo[28]),',0,',itoa(dsp.ampModule[1].DSPAlarmTriggered[2])"
	if(TpChanValidRange(txtInfo[29])) send_command tp[k],"'^TXT-',itoa(txtInfo[29]),',0,',itoa(dsp.ampModule[1].Presence)"
	if(TpChanValidRange(txtInfo[30])) send_command tp[k],"'^TXT-',itoa(txtInfo[30]),',0,',itoa(dsp.ampModule[1].LastONOFF)"
	if(TpChanValidRange(txtInfo[31])) send_command tp[k],"'^TXT-',itoa(txtInfo[31]),',0,',itoa(dsp.ampModule[1].Mod1Ready)"
	if(TpChanValidRange(txtInfo[32])) send_command tp[k],"'^TXT-',itoa(txtInfo[32]),',0,',itoa(dsp.ampModule[1].DeviceON)"
	if(TpChanValidRange(txtInfo[33])) send_command tp[k],"'^TXT-',itoa(txtInfo[33]),',0,',itoa(dsp.ampModule[1].ChannelIdle[1])"
	if(TpChanValidRange(txtInfo[34])) send_command tp[k],"'^TXT-',itoa(txtInfo[34]),',0,',itoa(dsp.ampModule[1].ChannelIdle[2])"
	if(TpChanValidRange(txtInfo[35])) send_command tp[k],"'^TXT-',itoa(txtInfo[35]),',0,',itoa(dsp.ampModule[1].Signal[1])"
	if(TpChanValidRange(txtInfo[36])) send_command tp[k],"'^TXT-',itoa(txtInfo[36]),',0,',itoa(dsp.ampModule[1].Signal[2])"
	if(TpChanValidRange(txtInfo[37])) send_command tp[k],"'^TXT-',itoa(txtInfo[37]),',0,',itoa(dsp.ampModule[1].ProtectionCount)"
	if(TpChanValidRange(txtInfo[38])) send_command tp[k],"'^TXT-',itoa(txtInfo[38]),',0,',itoa(dsp.ampModule[1].Impedances[1])"
	if(TpChanValidRange(txtInfo[39])) send_command tp[k],"'^TXT-',itoa(txtInfo[39]),',0,',itoa(dsp.ampModule[1].Impedances[2])"
	if(TpChanValidRange(txtInfo[40])) send_command tp[k],"'^TXT-',itoa(txtInfo[40]),',0,',itoa(dsp.ampModule[1].Gains[1])"
	if(TpChanValidRange(txtInfo[41])) send_command tp[k],"'^TXT-',itoa(txtInfo[41]),',0,',itoa(dsp.ampModule[1].Gains[2])"
	if(TpChanValidRange(txtInfo[42])) send_command tp[k],"'^TXT-',itoa(txtInfo[42]),',0,',itoa(dsp.ampModule[1].OutVoltages[1]),' V'"
	if(TpChanValidRange(txtInfo[43])) send_command tp[k],"'^TXT-',itoa(txtInfo[43]),',0,',itoa(dsp.ampModule[1].OutVoltages[2]),' V'"
	if(TpChanValidRange(txtInfo[44])) send_command tp[k],"'^TXT-',itoa(txtInfo[44]),',0,',itoa(dsp.ampModule[1].MaxMains),' A'"
	if(TpChanValidRange(txtInfo[45])) send_command tp[k],"'^TXT-',itoa(txtInfo[45]),',0,',itoa(dsp.ampModule[1].Clip[1])"
	if(TpChanValidRange(txtInfo[46])) send_command tp[k],"'^TXT-',itoa(txtInfo[46]),',0,',itoa(dsp.ampModule[1].Clip[2])"
	if(TpChanValidRange(txtInfo[47])) send_command tp[k],"'^TXT-',itoa(txtInfo[47]),',0,',itoa(dsp.ampModule[1].Gate[1])"
	if(TpChanValidRange(txtInfo[48])) send_command tp[k],"'^TXT-',itoa(txtInfo[48]),',0,',itoa(dsp.ampModule[1].Gate[2])"
	if(TpChanValidRange(txtInfo[49])) send_command tp[k],"'^TXT-',itoa(txtInfo[49]),',0,',itoa(dsp.ampModule[1].ModCounter)"
	if(TpChanValidRange(txtInfo[50])) send_command tp[k],"'^TXT-',itoa(txtInfo[50]),',0,',itoa(dsp.ampModule[1].Boards[1])"
	if(TpChanValidRange(txtInfo[51])) send_command tp[k],"'^TXT-',itoa(txtInfo[51]),',0,',itoa(dsp.ampModule[1].Boards[2])"
	if(TpChanValidRange(txtInfo[52])) send_command tp[k],"'^TXT-',itoa(txtInfo[52]),',0,',itoa(dsp.ampModule[1].Boards[3])"
	if(TpChanValidRange(txtInfo[53])) send_command tp[k],"'^TXT-',itoa(txtInfo[53]),',0,',itoa(dsp.ampModule[1].Boards[4])"
	if(TpChanValidRange(txtInfo[54])) send_command tp[k],"'^TXT-',itoa(txtInfo[54]),',0,',itoa(dsp.ampModule[1].Boards[5])"
	if(TpChanValidRange(txtInfo[55])) send_command tp[k],"'^TXT-',itoa(txtInfo[55]),',0,',itoa(dsp.ampModule[1].InputRouting)"
	if(TpChanValidRange(txtInfo[56])) send_command tp[k],"'^TXT-',itoa(txtInfo[56]),',0,',itoa(dsp.ampModule[1].IdleTime)"
	if(TpChanValidRange(txtInfo[57])) send_command tp[k],"'^TXT-',itoa(txtInfo[57]),',0,',itoa(dsp.ampModule[1].DSPModCounter)"
	if(TpChanValidRange(txtInfo[58])) send_command tp[k],"'^TXT-',itoa(txtInfo[58]),',0,',itoa(dsp.ampModule[1].DSPCRC1)"
	if(TpChanValidRange(txtInfo[59])) send_command tp[k],"'^TXT-',itoa(txtInfo[59]),',0,',itoa(dsp.ampModule[1].DSPCRC2)"
	if(TpChanValidRange(txtInfo[60])) send_command tp[k],"'^TXT-',itoa(txtInfo[60]),',0,',itoa(dsp.ampModule[1].DSPCRC0)"
	if(TpChanValidRange(txtInfo[61])) send_command tp[k],"'^TXT-',itoa(txtInfo[61]),',0,',itoa(dsp.ampModule[1].KAESOPModCounter)"
	if(TpChanValidRange(txtInfo[62])) send_command tp[k],"'^TXT-',itoa(txtInfo[62]),',0,',itoa(dsp.ampModule[1].KAESOPCRC)"
	
	CheckTpLevels(1)
	CheckTpLevels(2)
	CheckTpLevels(3)
    }
    else				
    {
	if(TpChanValidRange(txtInfo[ 1])) send_command tp,"'^TXT-',itoa(txtInfo[ 1]),',0,',itoa(dsp.ampModule[1].PosAuxVoltage),' V'"
	if(TpChanValidRange(txtInfo[ 2])) send_command tp,"'^TXT-',itoa(txtInfo[ 2]),',0,-',itoa(dsp.ampModule[1].NegAuxVoltage),' V'"
	if(TpChanValidRange(txtInfo[ 3])) send_command tp,"'^TXT-',itoa(txtInfo[ 3]),',0,',ftoa(dsp.ampModule[1].AuxAnalogVoltage),' V'"
	if(TpChanValidRange(txtInfo[ 4])) send_command tp,"'^TXT-',itoa(txtInfo[ 4]),',0,',itoa(dsp.ampModule[1].MainVoltage),' V'"
	if(TpChanValidRange(txtInfo[ 5])) send_command tp,"'^TXT-',itoa(txtInfo[ 5]),',0,',itoa(dsp.ampModule[1].MainCurrent),' A'"
	if(TpChanValidRange(txtInfo[ 6])) send_command tp,"'^TXT-',itoa(txtInfo[ 6]),',0,',ftoa(dsp.ampModule[1].ExternalVoltage),' V'"
	if(TpChanValidRange(txtInfo[ 7])) send_command tp,"'^TXT-',itoa(txtInfo[ 7]),',0,',itoa(dsp.ampModule[1].PosBusVoltage[1]),' V'"
	if(TpChanValidRange(txtInfo[ 8])) send_command tp,"'^TXT-',itoa(txtInfo[ 8]),',0,-',itoa(dsp.ampModule[1].NegBusVoltage[1]),' V'"
	if(TpChanValidRange(txtInfo[ 9])) send_command tp,"'^TXT-',itoa(txtInfo[ 9]),',0,',itoa(dsp.ampModule[1].PosBusVoltage[2]),' V'"
	if(TpChanValidRange(txtInfo[10])) send_command tp,"'^TXT-',itoa(txtInfo[10]),',0,-',itoa(dsp.ampModule[1].NegBusVoltage[2]),' V'"
	
	if(TpChanValidRange(txtInfo[11])) send_command tp,"'^TXT-',itoa(txtInfo[11]),',0,',itoa(dsp.ampModule[1].Clock)"
	if(TpChanValidRange(txtInfo[12])) send_command tp,"'^TXT-',itoa(txtInfo[12]),',0,',itoa(dsp.ampModule[1].Vaux)"
	if(TpChanValidRange(txtInfo[13])) send_command tp,"'^TXT-',itoa(txtInfo[13]),',0,',itoa(dsp.ampModule[1].IGBT)"
	if(TpChanValidRange(txtInfo[14])) send_command tp,"'^TXT-',itoa(txtInfo[14]),',0,',itoa(dsp.ampModule[1].BOOST)"
	if(TpChanValidRange(txtInfo[15])) send_command tp,"'^TXT-',itoa(txtInfo[15]),',0,',itoa(dsp.ampModule[1].Led)"
	
	if(TpChanValidRange(txtInfo[16]))
	{
	    if(dsp.ampModule[1].OutAttenuations[1] > 0) send_command tp,"'^TXT-',itoa(txtInfo[16]),',0,-',itoa(dsp.ampModule[1].OutAttenuations[1]),' dB'"
	    else                                        send_command tp,"'^TXT-',itoa(txtInfo[16]),',0,',itoa(dsp.ampModule[1].OutAttenuations[1]),' dB'"
	}
	if(TpChanValidRange(txtInfo[17]))
	{
	    if(dsp.ampModule[1].OutAttenuations[1] > 0) send_command tp,"'^TXT-',itoa(txtInfo[17]),',0,-',itoa(dsp.ampModule[1].OutAttenuations[2]),' dB'"
	    else                                        send_command tp,"'^TXT-',itoa(txtInfo[17]),',0,',itoa(dsp.ampModule[1].OutAttenuations[2]),' dB'"
	}
	
	if(TpChanValidRange(txtInfo[18])) send_command tp,"'^TXT-',itoa(txtInfo[18]),',0,',itoa(dsp.ampModule[1].HWMute[1])"
	if(TpChanValidRange(txtInfo[19])) send_command tp,"'^TXT-',itoa(txtInfo[19]),',0,',itoa(dsp.ampModule[1].HWMute[2])"
	
	if(TpChanValidRange(txtInfo[20]))
	{
	    if(InCelsius == 1 ) send_command tp,"'^TXT-',itoa(txtInfo[20]),',0,',itoa(dsp.ampModule[1].ModTemp),'° C'"
	    else                send_command tp,"'^TXT-',itoa(txtInfo[20]),',0,',itoa(getFahrenheit(dsp.ampModule[1].ModTemp)),'° F'"
	}
	
	if(TpChanValidRange(txtInfo[21])) send_command tp,"'^TXT-',itoa(txtInfo[21]),',0,',itoa(dsp.ampModule[1].Protection[1])"
	if(TpChanValidRange(txtInfo[22])) send_command tp,"'^TXT-',itoa(txtInfo[22]),',0,',itoa(dsp.ampModule[1].Protection[2])"
	
	if(TpChanValidRange(txtInfo[23])) send_command tp,"'^TXT-',itoa(txtInfo[23]),',0,',itoa(dsp.ampModule[1].HWProtection[1])"
	if(TpChanValidRange(txtInfo[24])) send_command tp,"'^TXT-',itoa(txtInfo[24]),',0,',itoa(dsp.ampModule[1].HWProtection[2])"
	if(TpChanValidRange(txtInfo[25])) send_command tp,"'^TXT-',itoa(txtInfo[25]),',0,',itoa(dsp.ampModule[1].AlarmTriggered[1])"
	if(TpChanValidRange(txtInfo[26])) send_command tp,"'^TXT-',itoa(txtInfo[26]),',0,',itoa(dsp.ampModule[1].AlarmTriggered[2])"
	if(TpChanValidRange(txtInfo[27])) send_command tp,"'^TXT-',itoa(txtInfo[27]),',0,',itoa(dsp.ampModule[1].DSPAlarmTriggered[1])"
	if(TpChanValidRange(txtInfo[28])) send_command tp,"'^TXT-',itoa(txtInfo[28]),',0,',itoa(dsp.ampModule[1].DSPAlarmTriggered[2])"
	if(TpChanValidRange(txtInfo[29])) send_command tp,"'^TXT-',itoa(txtInfo[29]),',0,',itoa(dsp.ampModule[1].Presence)"
	if(TpChanValidRange(txtInfo[30])) send_command tp,"'^TXT-',itoa(txtInfo[30]),',0,',itoa(dsp.ampModule[1].LastONOFF)"
	if(TpChanValidRange(txtInfo[31])) send_command tp,"'^TXT-',itoa(txtInfo[31]),',0,',itoa(dsp.ampModule[1].Mod1Ready)"
	if(TpChanValidRange(txtInfo[32])) send_command tp,"'^TXT-',itoa(txtInfo[32]),',0,',itoa(dsp.ampModule[1].DeviceON)"
	if(TpChanValidRange(txtInfo[33])) send_command tp,"'^TXT-',itoa(txtInfo[33]),',0,',itoa(dsp.ampModule[1].ChannelIdle[1])"
	if(TpChanValidRange(txtInfo[34])) send_command tp,"'^TXT-',itoa(txtInfo[34]),',0,',itoa(dsp.ampModule[1].ChannelIdle[2])"
	if(TpChanValidRange(txtInfo[35])) send_command tp,"'^TXT-',itoa(txtInfo[35]),',0,',itoa(dsp.ampModule[1].Signal[1])"
	if(TpChanValidRange(txtInfo[36])) send_command tp,"'^TXT-',itoa(txtInfo[36]),',0,',itoa(dsp.ampModule[1].Signal[2])"
	if(TpChanValidRange(txtInfo[37])) send_command tp,"'^TXT-',itoa(txtInfo[37]),',0,',itoa(dsp.ampModule[1].ProtectionCount)"
	if(TpChanValidRange(txtInfo[38])) send_command tp,"'^TXT-',itoa(txtInfo[38]),',0,',itoa(dsp.ampModule[1].Impedances[1])"
	if(TpChanValidRange(txtInfo[39])) send_command tp,"'^TXT-',itoa(txtInfo[39]),',0,',itoa(dsp.ampModule[1].Impedances[2])"
	if(TpChanValidRange(txtInfo[40])) send_command tp,"'^TXT-',itoa(txtInfo[40]),',0,',itoa(dsp.ampModule[1].Gains[1])"
	if(TpChanValidRange(txtInfo[41])) send_command tp,"'^TXT-',itoa(txtInfo[41]),',0,',itoa(dsp.ampModule[1].Gains[2])"
	if(TpChanValidRange(txtInfo[42])) send_command tp,"'^TXT-',itoa(txtInfo[42]),',0,',itoa(dsp.ampModule[1].OutVoltages[1]),' V'"
	if(TpChanValidRange(txtInfo[43])) send_command tp,"'^TXT-',itoa(txtInfo[43]),',0,',itoa(dsp.ampModule[1].OutVoltages[2]),' V'"
	if(TpChanValidRange(txtInfo[44])) send_command tp,"'^TXT-',itoa(txtInfo[44]),',0,',itoa(dsp.ampModule[1].MaxMains),' A'"
	if(TpChanValidRange(txtInfo[45])) send_command tp,"'^TXT-',itoa(txtInfo[45]),',0,',itoa(dsp.ampModule[1].Clip[1])"
	if(TpChanValidRange(txtInfo[46])) send_command tp,"'^TXT-',itoa(txtInfo[46]),',0,',itoa(dsp.ampModule[1].Clip[2])"
	if(TpChanValidRange(txtInfo[47])) send_command tp,"'^TXT-',itoa(txtInfo[47]),',0,',itoa(dsp.ampModule[1].Gate[1])"
	if(TpChanValidRange(txtInfo[48])) send_command tp,"'^TXT-',itoa(txtInfo[48]),',0,',itoa(dsp.ampModule[1].Gate[2])"
	if(TpChanValidRange(txtInfo[49])) send_command tp,"'^TXT-',itoa(txtInfo[49]),',0,',itoa(dsp.ampModule[1].ModCounter)"
	if(TpChanValidRange(txtInfo[50])) send_command tp,"'^TXT-',itoa(txtInfo[50]),',0,',itoa(dsp.ampModule[1].Boards[1])"
	if(TpChanValidRange(txtInfo[51])) send_command tp,"'^TXT-',itoa(txtInfo[51]),',0,',itoa(dsp.ampModule[1].Boards[2])"
	if(TpChanValidRange(txtInfo[52])) send_command tp,"'^TXT-',itoa(txtInfo[52]),',0,',itoa(dsp.ampModule[1].Boards[3])"
	if(TpChanValidRange(txtInfo[53])) send_command tp,"'^TXT-',itoa(txtInfo[53]),',0,',itoa(dsp.ampModule[1].Boards[4])"
	if(TpChanValidRange(txtInfo[54])) send_command tp,"'^TXT-',itoa(txtInfo[54]),',0,',itoa(dsp.ampModule[1].Boards[5])"
	if(TpChanValidRange(txtInfo[55])) send_command tp,"'^TXT-',itoa(txtInfo[55]),',0,',itoa(dsp.ampModule[1].InputRouting)"
	if(TpChanValidRange(txtInfo[56])) send_command tp,"'^TXT-',itoa(txtInfo[56]),',0,',itoa(dsp.ampModule[1].IdleTime)"
	if(TpChanValidRange(txtInfo[57])) send_command tp,"'^TXT-',itoa(txtInfo[57]),',0,',itoa(dsp.ampModule[1].DSPModCounter)"
	if(TpChanValidRange(txtInfo[58])) send_command tp,"'^TXT-',itoa(txtInfo[58]),',0,',itoa(dsp.ampModule[1].DSPCRC1)"
	if(TpChanValidRange(txtInfo[59])) send_command tp,"'^TXT-',itoa(txtInfo[59]),',0,',itoa(dsp.ampModule[1].DSPCRC2)"
	if(TpChanValidRange(txtInfo[60])) send_command tp,"'^TXT-',itoa(txtInfo[60]),',0,',itoa(dsp.ampModule[1].DSPCRC0)"
	if(TpChanValidRange(txtInfo[61])) send_command tp,"'^TXT-',itoa(txtInfo[61]),',0,',itoa(dsp.ampModule[1].KAESOPModCounter)"
	if(TpChanValidRange(txtInfo[62])) send_command tp,"'^TXT-',itoa(txtInfo[62]),',0,',itoa(dsp.ampModule[1].KAESOPCRC)"
	
	CheckTpLevels(1)
	CheckTpLevels(2)
	CheckTpLevels(3)
    }
}

define_function CheckMuteOff(integer i)
{				
    stack_var char value[10]
    
    
    if(dsp.ampModule[1].HWMute[i] == 1)
    {
	switch(i)
	{
	    case 1: // CH1
	    {
		value = "$6d,$31,$30"
		SendToDSP(value)
		dsp.ampModule[1].HWMute[1] = 0
	    }
	    case 2: // CH2
	    {
		value = "$6d,$32,$30"
		dsp.ampModule[1].HWMute[2] = 0
		SendToDSP(value)
	    }
	    case 3: // CH1+CH2
	    {
		value = "$6d,$31,$30"
		SendToDSP(value)
		dsp.ampModule[1].HWMute[1] = 0
		
		value = "$6d,$32,$30"
		dsp.ampModule[1].HWMute[2] = 0
		SendToDSP(value)
	    }
	
	}
	debug("'(1) CheckMuteOff !!!!'") 
    }
    else debug("'(1) CheckMuteOff ==> SKIPPED :',itoa(i)") 
    
}

define_function integer GetAttenuationValue(integer CGain)
{
    stack_var integer value
    
    if(CGain <= MaxFaders)
    {
	value = dsp.ampModule[1].OutAttenuations[CGain]
    }
    else
    {
	value = max_value(dsp.ampModule[1].OutAttenuations[1],dsp.ampModule[1].OutAttenuations[2])
    }

    return value
}

define_function CheckVolValue(integer i,integer direction)
{
    stack_var integer tmpval,loop
    stack_var char cmd[10]
    
    tmpval = GetAttenuationValue(i)
    
    if(direction = sUp)
    {
	if(tmpval <= 1) tmpval = 0
	else   tmpval  = tmpval - 1
    }
    else
    {
	if(tmpval >= 29) tmpval = 30
	else   tmpval  = tmpval + 1
    }
    
    if(i <= MaxFaders)
    {
	cmd = "$76,right_string("'0',itohex(i)",1),right_string("'00',itohex(tmpval)",2)"
	sendtodsp(cmd)
	dsp.ampModule[1].OutAttenuations[i] = tmpval
	CheckTpLevels(i)
    }
    else
    {
	cmd = "$76,right_string("'0',itohex(0)",1),right_string("'00',itohex(tmpval)",2)"
	sendtodsp(cmd)
	for(loop=1;loop<=MaxFaders;loop++)
	{
	    dsp.ampModule[1].OutAttenuations[loop] = tmpval
	}
	dsp.ampModule[1].OutAttenuations[3] = tmpval
	checkTPLevelAllVol(tmpval)
    }
}


// Update Preset Name Buttons
define_function tpUpdatePresetNames(integer ID)
{
    stack_var integer i
    
    if(ID == 0) // Reload ALL
    {
	for(i = 1; i <= MaxPresets;i ++)
	{
	    if(TpChanValidRange(nchPresets[i])) 
	    {
		if(PresetName[i] <> '')	send_command tp,"'^TXT-',itoa(nchPresets[i]),',0,',PresetName[i]"
		else 																			send_command tp,"'^TXT-',itoa(nchPresets[i]),',0,',DSPtxtEmptyPreset"
	    }
	}
    }
    else // Reload Located Preset
    {
	if(TpChanValidRange(nchPresets[ID]))	send_command tp,"'^TXT-',itoa(nchPresets[ID]),',0,',PresetName[ID]"
    }
}

// Update Vertical Preset Name
define_function tpUpdateVPresetNames(integer k, integer PageNum)
{
    stack_var integer i
    stack_var integer base
    
    base = MaxPresetPerPage * (PageNum - 1)
    
    TpCurrentPage[k] = PageNum
    
    For(i = 1; i <= MaxPresetPerPage; i ++)
    {
	if(base + i)
	{
	    if(PresetName[i] <> '') send_command Tp[k],"'^TXT-',itoa(TxtVChannel[i]),',0,',right_string("'00',itoa(base+i)",2),') ',PresetName[base + i]"
	    else                    send_command Tp[k],"'^TXT-',itoa(TxtVChannel[i]),',0,',right_string("'00',itoa(base+i)",2),') ',DSPtxtEmptyPreset"
	}
    }
    
    send_command Tp[k],"'^TXT-',itoa(TxtPages),',0,',itoa(PageNum),' - ',itoa(TpMaxPages)"
}

define_function RecallPresets(integer k,integer num)
{				
    stack_var integer Media
    stack_var char cmd[20]
    
    cmd = "$78,$30,$30,$61,$72,itoa(CurrentMediaPresets),right_string("'00',itohex(num - 1)",2)"
    sendtodsp(cmd)
    
    if(TpChanValidRange(txtInfo[64])) send_command tp,"'^TXT-',itoa(txtInfo[64]),',0,',PresetName[num]"
    
    ProgressBar(k,25,9,10,11,12)
    
    debug("'Recall Preset --> ',itoa(num)")
}

define_function SavePresets(integer k,integer num,char Name[40])
{				
    stack_var integer Media
    stack_var char cmd[100],cmd2[50]
    
    cmd = "$78,$30,$30,$61,$77,itoa(CurrentMediaPresets),right_string("'00',itohex(num - 1)",2),name"
    sendtodsp(cmd)
    
    debug("'Preset[',itoa(num),'] Saved with name: ',name")
}

define_function DeletePresets(integer k,integer num)
{				
    stack_var integer Media
    stack_var char cmd[100]
    
    cmd = "$78,$30,$30,$61,$64,itoa(CurrentMediaPresets),right_string("'00',itohex(num - 1)",2)"
    sendtodsp(cmd)
    
    PendingName = num
    PendingK = k
    
    debug("'Preset[',itoa(num),'] has been Deleted'")
}


define_function GetIndexPreset(char Name[40])
{
    stack_var integer loop,Value
    stack_var sinteger result
    
    Value = 0
    
    for(loop=1;loop<=50;loop++)
    {
	result = (compare_string(PresetName[loop],Name)) 
	
	if(result == 1)
	{
	    value = loop
	    break;
	}
    }
    
    if(Value > 0)
    {
	debug("'Presets Name[',itoa(Value),'] = ',Name")
	if(TpChanValidRange(txtInfo[64])) send_command tp,"'^TXT-',itoa(txtInfo[64]),',0,',Name"
	CurrentPreset = Value
    }
    else
    {
	debug("'Presets Name Index 0'")
	if(TpChanValidRange(txtInfo[64])) send_command tp,"'^TXT-',itoa(txtInfo[64]),',0,',Name"
	msgbox(1,33,34,35,36)
    }
}

define_function DecodeAmpResponce(char cmd[])
{				
    stack_var float f_value
    stack_var long l_value
    stack_var integer loop
    
    debug("'CMD: ',cmd")												
    
    cmd = DeExcape(cmd)

    select
    {
	active(left_string(cmd,1) == "$02"):
	{
	    select
	    {
		active(find_string(cmd,"GetID(DeviceID),$06",1) && (length_string(cmd) <= 7)):
		{
		    debug("'ACK'")
		}
		active(find_string(cmd,"GetID(DeviceID),$15",1) && (length_string(cmd) <= 7)):
		{
		    debug("'NACK'")
		}
		active(find_string(cmd,"GetID(DeviceID),$04",1) && (length_string(cmd) <= 7)):
		{
		    debug("'INV'")
		}
		active(find_string(cmd,"GetID(DeviceID),$04",1) && (length_string(cmd) <= 7)):
		{
		    debug("'OOR'")
		}
		active(find_string(cmd,"GetID(DeviceID),$49",1)):  // Firmware INFO
		{
		    dsp.trash = remove_string(cmd,"$49",1)
		    send_command tp,"'^TXT-',itoa(txtInfo[63]),',0,',cmd"
		}
		active(find_string(cmd,"GetID(DeviceID),$4c",1)):  // Voltage and Current Meter
		{
		    dsp.trash = remove_string(cmd,"$4c",1)
		    dsp.trash = get_buffer_string(cmd,2)
		    
		    dsp.ampModule[1].OutputCurrentMeter[1] = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].OutputCurrentMeter[2] = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].OutputVoltageMeter[1] = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].OutputVoltageMeter[2] = hextoi(get_buffer_string(cmd,2))
		    
		}
		active(find_string(cmd,"GetID(DeviceID),$54",1)): // Responce to Status query of Module #1
		{
		    stack_var long ltmp
		    stack_var char ctmp[20]
		    stack_var integer load1,load2,load3
    
		    dsp.trash = remove_string(cmd,"$54",1)
		    dsp.trash = get_buffer_string(cmd,2)
		    
		    dsp.ampModule[1].PosAuxVoltage     = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].NegAuxVoltage     = hextoi(get_buffer_string(cmd,2))
		    load1 = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].AuxAnalogVoltage  = load1 * 0.1
		    dsp.ampModule[1].MainVoltage       = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].MainCurrent       = hextoi(get_buffer_string(cmd,2))
		    load2 = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].ExternalVoltage   = load2 * 0.1
		    dsp.ampModule[1].PosBusVoltage[1]     = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].NegBusVoltage[1]     = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].PosBusVoltage[2]     = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].NegBusVoltage[2]     = hextoi(get_buffer_string(cmd,2))
    
		    CalculateBINValue(DSPStatus,hextoi(get_buffer_string(cmd,2))) // Status																				
    
		    dsp.ampModule[1].Led                = hextoi(get_buffer_string(cmd,2))
    
		}
    
		// Device Status
		active(find_string(cmd,"GetID(DeviceID),$53",1)):
		{
		    stack_var long ltmp
		    stack_var char ctmp[4]
		    
		    
		    dsp.trash = remove_string(cmd,"$53",1)
		    dsp.trash = get_buffer_string(cmd,2) // Remove DSP Model X6
		    
		    dsp.ampModule[1].OutAttenuations[1]     = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].OutAttenuations[2]     = hextoi(get_buffer_string(cmd,2))
		    
		    CalculateBINValue(DSPMute,hextoi(get_buffer_string(cmd,2))) // Status
		    dsp.ampModule[1].ModTemp        = hextoi(get_buffer_string(cmd,2))
		    CalculateBINValue(Protection,hextoi(get_buffer_string(cmd,2))) // Status
		    CalculateBINValue(Ready,hextoi(get_buffer_string(cmd,2))) // Status
		    
		    CalculateBINValue(Flags,hextoi(get_buffer_string(cmd,2))) // Status
    
		    dsp.ampModule[1].ProtectionCount = hextoi(get_buffer_string(cmd,2))
		    
		    dsp.ampModule[1].Impedances[1] = hextoi(get_buffer_string(cmd,4))
		    dsp.ampModule[1].Impedances[2] = hextoi(get_buffer_string(cmd,4))
		    
		    dsp.ampModule[1].Gains[1] = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].Gains[2] = hextoi(get_buffer_string(cmd,2))
		    
		    dsp.ampModule[1].OutVoltages[1] = hextoi(get_buffer_string(cmd,2))
		    dsp.ampModule[1].OutVoltages[2] = hextoi(get_buffer_string(cmd,2))
		    
		    dsp.ampModule[1].MaxMains = hextoi(get_buffer_string(cmd,2))
		    
		    CalculateBINValue(Limiter,hextoi(get_buffer_string(cmd,2))) // Status
		    
		    dsp.ampModule[1].ModCounter = hextoi(get_buffer_string(cmd,4))
		    
		    CalculateBINValue(Board,hextoi(get_buffer_string(cmd,2))) // Status
		    //																				CalculateBINValue(Routing,hextoi(get_buffer_string(cmd,2))) // Status
		    dsp.ampModule[1].InputRouting = hextoi(get_buffer_string(cmd,2)) // Status
		    
		    dsp.ampModule[1].IdleTime = hextoi(get_buffer_string(cmd,4))
		    
		    dsp.ampModule[1].DSPModCounter = hextoi(get_buffer_string(cmd,4))
		    dsp.ampModule[1].DSPCRC1 = hextoi(get_buffer_string(cmd,4))
		    dsp.ampModule[1].DSPCRC2 = hextoi(get_buffer_string(cmd,4))
		    dsp.ampModule[1].DSPCRC0 = hextoi(get_buffer_string(cmd,4))
		    dsp.ampModule[1].KAESOPModCounter = hextoi(get_buffer_string(cmd,4))
		    dsp.ampModule[1].KAESOPCRC = hextoi(get_buffer_string(cmd,4))
    
		}																                                                    
		active(find_string(cmd,"GetID(DeviceID),$78",1)): // Relays Board
		{
		    select
		    {
			active(find_string(cmd,"$30,$30,$61,$67",1)): // Presets Name from 
			{
			    dsp.trash = remove_string(cmd,"$61,$67",1) // Remove String
			    
			    set_length_string(cmd,length_string(cmd) - 1)
			    
			    if(GetPreset<>1)
			    {
				if(length_string(cmd) == 40)
				{
				    debug("'Presets Name[',itoa(IndexPresetName),'] = ',cmd")
				    PresetName[IndexPresetName] = cmd
				}
				else
				{
				    debug("'Presets Name[',itoa(IndexPresetName),'] = Empty'")
				    PresetName[IndexPresetName] = ''
				}
	
				if(IndexPresetName < MaxIndexPresetName)
				{
				    IndexPresetName = IndexPresetName + 1
				}
				else
				{
				    for(loop=1;loop<=length_array(TP);loop++)
				    {
					TpCurrentPage[loop] = 1
					tpUpdateVPresetNames(loop,TpCurrentPage[loop])
					
				    }
				    tpUpdatePresetNames(0)
				    
				    if(timeline_active(tlGetNamePoll)) timeline_kill(tlGetNamePoll)
				    if(timeline_active(tlDevicePoll)) timeline_kill(tlDevicePoll)
				    timeline_create (tlDevicePoll,tlDevicePollArray,6,timeline_relative,timeline_repeat)
				    
				    if(timeline_active(tlProgressBar)) timeline_kill(tlProgressBar)
				    send_command tp,"'PPOF-',MsgBoxPopPages[3]"				
				}
			    }
			    else
			    {
				if(length_string(cmd) == 40)
				{
				    GetPreset = 0
				    
				    GetIndexPreset(cmd)
				    
				}
			    }
			}
			active(find_string(cmd,"$30,$30,$61,$72",1)): // Load Presets 
			{
			    dsp.trash = remove_string(cmd,"$61,$72",1) // Remove String
			    
			    if(find_string(cmd,"$06",1)) Debug("'ACK - Load Presets'")
			    else if(find_string(cmd,"$15",1)) Debug("'NACK - Load Presets'")
			    else Debug("'UNKNOWN - Load Presets'")
			}
			active(find_string(cmd,"$30,$30,$61,$77",1)): // Store Presets 
			{
			    dsp.trash = remove_string(cmd,"$61,$77",1) // Remove String
			
			    if(find_string(cmd,"$06",1))
			    {
				Debug("'ACK - Store Presets'")
				
				msgbox(0,17,18,19,20)
			    }
			    else if(find_string(cmd,"$15",1))
			    {
				Debug("'NACK - Store Presets'")
				msgbox(0,21,22,23,24)
			    }
			    else Debug("'UNKNOWN - Store Presets'")
			}
			active(find_string(cmd,"$30,$30,$61,$64",1)): // Deleted Presets 
			{
			    dsp.trash = remove_string(cmd,"$61,$64",1) // Remove String
			
			    if(find_string(cmd,"$06",1))
			    {
				Debug("'ACK - Deleted Presets ',itoa(PendingName), 'K --> ',itoa(Pendingk)")
				
				PresetName[PendingName] = ''
			    
				for(loop=1;loop<=length_array(TP);loop++)
				{
				    TpCurrentPage[loop] = 1
				    tpUpdateVPresetNames(loop,TpCurrentPage[loop])
				}
				tpUpdatePresetNames(0)
				
				msgbox(0,25,26,27,28)
			    }
			    else if(find_string(cmd,"$15",1))
			    {
				Debug("'NACK - Deleted Presets'")
				msgbox(0,29,30,31,32)
			    }
			    else Debug("'UNKNOWN - Store Presets'")
			    }
			active(1):
			{
			Debug("'NOT DEFINED COMMAND SET !'")
			}
		    }
		}
		active(find_string(cmd,"GetID(DeviceID),$4a",1)): // Alarm Tone and Load
		{
		    dsp.trash = remove_string(cmd,"$4a",1)  // Remove String
		
		    if(find_string(cmd,"$52",1)) // R
		    {
			dsp.trash = remove_string(cmd,"$52",1)  // Remove String
    
			select
			{
			    active(find_string(cmd,"$18,$01,$70,$03",1)):
			    {
				debug("'DECODE STATUS TONE CH1'")
				
				dsp.trash = get_buffer_string(cmd,10) // Remove 10 Strings
				dsp.ampModule[1].ToneINAlarm[1] = get_buffer_string(cmd,1)
				
				dsp.trash = get_buffer_string(cmd,7) // Remove 7 Strings
				dsp.ampModule[1].ToneOUTAlarm[1] = get_buffer_string(cmd,1)
				dsp.trash = get_buffer_string(cmd,15) // Remove 15 Strings
				dsp.ampModule[1].LoadAlarm[1] = get_buffer_string(cmd,1)
			    }
			    active(find_string(cmd,"$38,$01,$70,$03",1)):
			    {
				debug("'DECODE STATUS TONE CH2'")
				
				dsp.trash = get_buffer_string(cmd,10) // Remove 10 Strings
				dsp.ampModule[1].ToneINAlarm[2] = get_buffer_string(cmd,1)
				
				dsp.trash = get_buffer_string(cmd,7) // Remove 7 Strings
				dsp.ampModule[1].ToneOUTAlarm[2] = get_buffer_string(cmd,1)
				dsp.trash = get_buffer_string(cmd,15) // Remove 15 Strings
				dsp.ampModule[1].LoadAlarm[2] = get_buffer_string(cmd,1)
			    }
			}
		    }
		}
		active(1): // ????
		{																				
		    debug("'Unknown Value '")
		}
	    }
	}
    }
    ReloadTpInfo(0)
}






define_start

set_length_string(Tps,length_string(Tp))
set_length_string(TpIsHolding,length_string(Tp))
set_length_string(TpPresetsIsHolding,length_string(Tp))
set_length_string(TpWasEditing,length_string(Tp))

set_length_string(TpCurrentPage,length_string(Tp))
set_length_string(TpVIsHolding,length_string(Tp))

rebuild_event()

dsp.ampModule[1].OutAttenuations[3] = 20

timeline_create(tlFeedbacks,tlFeedbacksArray,1,timeline_absolute,timeline_repeat)

if(ipaddress <> '')
{
    ip_client_open(device.port,IpAddress,IpPort,3)
    timeline_create (tlDevicePoll,tlDevicePollArray,6,timeline_relative,timeline_repeat)
}

on[Qready]
off[QhasItem]

{
    stack_var integer i
    
    for(i = 1; i <= 240; i ++)
    {
	tlProgressArray[i] = 1000
    }
}



define_event

data_event[tp]
{
    online:
    {
	local_var integer k
	
	k = get_last(tp)
	
	TpWasEditing[k] = 0
	TpPresetsIsHolding[k] = 0
	TpVIsHolding[k] = 0
	
	wait 20
	{
	    ReloadTpInfo(0)
	}				
	wait 40
	{
	    tpUpdatePresetNames(0)
	    
	}
    }
    string:
    {
	stack_var integer k
	stack_var char Trash[100]
	
	k = get_last(tp)
	
	tps[k].Buffer = "tps[k].Buffer,data.text"
    
	select
	{
	    active(find_string(tps[k].buffer,'ABORT',1)):
	    {
	
	    }
	    active(find_string(tps[k].buffer,'KEYB-',1)):
	    {
		Trash = remove_string(tps[k].buffer,'-',1)
		
		debug("'Touch Keyboard Buffer ==> ',tps[k].buffer")
	    
		select
		{
		    active(TpPresetsIsHolding[k] > 0):
		    {
		    debug("'From Preset BTN New Preset name is ==> ',tps[k].buffer")
		    
		    PresetName[TpPresetsIsHolding[k]] = tps[k].Buffer
		    
		    if(TpChanValidRange(nchPresets[TpPresetsIsHolding[k]])) 
		    {
		    if(PresetName[TpPresetsIsHolding[k]] <> '')	send_command tp,"'^TXT-',itoa(nchPresets[TpPresetsIsHolding[k]]),',0,',right_string("'00',itoa(TpPresetsIsHolding[k])",2),') ',PresetName[TpPresetsIsHolding[k]]"
		    else send_command tp,"'^TXT-',itoa(nchPresets[TpPresetsIsHolding[k]]),',0,',right_string("'00',itoa(TpPresetsIsHolding[k])",2),') ',DSPtxtEmptyPreset"
		    }
	
		    SavePresets(k,TpPresetsIsHolding[k],PresetName[TpPresetsIsHolding[k]])
		    tpUpdateVPresetNames(k,TpCurrentPage[k])
		    tpUpdatePresetNames(TpPresetsIsHolding[k])
	
		}
		active(TpVIsHolding[k] > 0):
		{
		    debug("'From Vertical New Preset name is ==> ',tps[k].buffer")
		    
		    PresetName[TpVIsHolding[k]] = tps[k].Buffer
		    
		    SavePresets(k,TpVIsHolding[k],PresetName[TpVIsHolding[k]])
		    tpUpdateVPresetNames(k,TpCurrentPage[k])
		    tpUpdatePresetNames(TpVIsHolding[k])
		}
	    }
	}
    }
    clear_buffer tps[k].Buffer
    TpPresetsIsHolding[k] = 0
    TpVIsHolding[k] = 0
    }
}


data_event[vdevice]
{
    online:
    {
    
    }
    command:
    {
	local_var char Buffer[100]
	stack_var char Reply[100]
	stack_var char Trash[100],cmd[100]	
	stack_var integer Mode,k,Input
	
	while (find_string (data.text,'.',1))
	{
	    Reply = "Buffer,remove_string(data.text,'.',1)"
	    clear_buffer Buffer
	    set_length_string(Reply,length_string(Reply) - 1)
	    
	    select
	    {
		active(find_string(Reply,'<POWER>',1)):
		{
		    trash = remove_string(Reply,'<POWER>',1)
		    
		    Input = atoi(Reply)
		    
		    switch(Input)
		    {
			case 1: // Power ON
			{
			    if(dsp.ampModule[1].ExternalVoltage > 11)
			    {
				SendToDSP("$70,$31")
				dsp.ampModule[1].DeviceON = 1
			    }
			    else
			    {
				msgbox(0,13,14,15,16)
			    }
			}
			default: // Power Off
			{
			    if(dsp.ampModule[1].ExternalVoltage > 11)
			    {
				SendToDSP("$70,$30")
				dsp.ampModule[1].DeviceON = 0
			    }
			    else
			    {
				msgbox(0,13,14,15,16)
			    }
			}
		    }
		}
		active(find_string(Reply,'<PRESET>',1)):
		{
		    trash = remove_string(Reply,'<PRESET>',1)
		    
		    RecallPresets(1,atoi(Reply))
		    
		    if( InDebug > 0) debug("DPStoA(vdevice),' - Virtual Recall Preset: ',Reply")
		}
		active(find_string(Reply,'<ROUTING>',1)):
		{
		    trash = remove_string(Reply,'<ROUTING>',1)
		    
		    Input = atoi(Reply)
		    
		    SendToDSP("$5a,right_string("'00',itohex(Input-1)",2)")
		    
		    dsp.ampModule[1].InputRouting = Input-1
		    
		    if( InDebug > 0) debug("DPStoA(vdevice),' - Virtual Recall Routing: ',Reply")
		}
		active(find_string(Reply,'<DEBUG>',1)):
		{
		    trash = remove_string(Reply,'<DEBUG>',1)
		    
		    InDebug = atoi(Reply)

		    if( InDebug > 0) debug("DPStoA(vdevice),' - Change Debug Information: ',itoa(InDebug)")
		}
	    }
	}
	Buffer = "Buffer,data.text"
    }
}


data_event[device]
{
    online:
    {
	dsp.isonline = 1
	if(Indebug > 0) debug("DPStoA(device),' comes Online !'")
	GetPreset = 1
	
    }
    offline:
    {
	if(ipaddress <> '') 
	{
	    dsp.isonline = 0
	    dsp.ampModule[1].DeviceON = 0
	    dsp.ampModule[1].Mod1Ready = 0
	    if(Indebug > 0) debug("DPStoA(device),' goes Offline !'")
	    
	    ClearTpInfo()
	    ReloadTpInfo(0)
	}
    }
    onerror:
    {
	if(Indebug > 0) debug("DPStoA(device),' ==> comm error ==> ',GetIpError(data.number)")
    }
    string:
    {
	while(find_string(data.text,"$03",1))
	{
	    dsp.Reply = "dsp.buffer,remove_string(data.text,"$03",1)"
	    set_length_string(dsp.Reply,length_string(dsp.Reply) - 2) // remove Checksum & ETX
	    DecodeAmpResponce(dsp.reply)
	    clear_buffer dsp.buffer
	}
	dsp.buffer = "dsp.buffer,data.text"
    }
}

button_event[Tp,nchControl]
{
    push:
    {
	stack_var integer k,i
	stack_var char cmd[255]
	
	k = get_last (Tp)
	i = get_last (nchControl)
	
	if(dsp.isonline == 1)
	{
	    cancel_wait 'Pause Status Request'
	    cancel_wait 'Pause Status Request2'
	    cancel_wait 'Pause Status Request3'
	    cancel_wait 'Pause Status Request4'
	    
	    timeline_set(tlDevicePoll,0)
	    timeline_pause(tlDevicePoll)
	    
	    switch(i)
	    {
		case 1: // Power On
		{
		    if(dsp.ampModule[1].ExternalVoltage > 11)
		    {
			cmd = "$70,$31"
			SendToDSP(cmd)
		    }
		    else
		    {
			msgbox(k,13,14,15,16)
		    }
		}
		case 2: // Power Off
		{
		    if(dsp.ampModule[1].ExternalVoltage > 11)
		    {
			cmd = "$70,$30"
			SendToDSP(cmd)
		    }
		    else
		    {
			msgbox(k,13,14,15,16)
		    }
		}
		case 3: // Power Toggle
		{
		    if(dsp.ampModule[1].ExternalVoltage > 11)
		    {
			if(dsp.ampModule[1].DeviceON == 1) 
			{
			    cmd = "$70,$30"
			    SendToDSP(cmd) // Power OFF
			    dsp.ampModule[1].DeviceON = 0
			}
			else
			{
			    cmd = "$70,$31"
			    SendToDSP(cmd) // Power ON
			    dsp.ampModule[1].DeviceON = 1
			}
		    }
		    else
		    {
			msgbox(k,13,14,15,16)
		    }
		}
		case 4: // Mute On CH1
		{
		    cmd = "$6d,$31,$31"
		    dsp.ampModule[1].HWMute[1] = 1
		    SendToDSP(cmd)
		}
		case 5: // Mute Off CH1
		{
		    cmd = "$6d,$31,$30"
		    dsp.ampModule[1].HWMute[1] = 0
		    SendToDSP(cmd)
		}
		case 6: // Mute On CH2
		{
		    cmd = "$6d,$32,$31"
		    dsp.ampModule[1].HWMute[2] = 1
		    SendToDSP(cmd)
		}
		case 7: // Mute Off CH2
		{
		    cmd = "$6d,$32,$30"
		    dsp.ampModule[1].HWMute[2] = 1
		    SendToDSP(cmd)
		}
		case 8: // Toggle Mute CH1
		{
		    if(dsp.ampModule[1].HWMute[1] == 1)
		    {
			cmd = "$6d,$31,$30" // Unmute
			dsp.ampModule[1].HWMute[1] = 0
		    }
		    else
		    {
			cmd = "$6d,$31,$31" // Mute
			dsp.ampModule[1].HWMute[1] = 1
		    }

		    SendToDSP(cmd)
		}
		case 9: // Toggle Mute CH2
		{
		    if(dsp.ampModule[1].HWMute[2] == 1)
		    {
			cmd = "$6d,$32,$30" // Unmute
			dsp.ampModule[1].HWMute[2] = 0
		    }
		    else
		    {
			cmd = "$6d,$32,$31" // Mute
			dsp.ampModule[1].HWMute[2] = 1
		    }
		    SendToDSP(cmd)
		}
		case 10: // Toggle Main Mute
		{
		    if((dsp.ampModule[1].HWMute[2] == 1) && (dsp.ampModule[1].HWMute[1] == 1))
		    {
			cmd = "$6d,$31,$30" // Unmute
			dsp.ampModule[1].HWMute[1] = 0
			SendToDSP(cmd)
			
			cmd = "$6d,$32,$30" // Unmute
			dsp.ampModule[1].HWMute[2] = 0
			SendToDSP(cmd)
		    }
		    else
		    {
			cmd = "$6d,$31,$31" // Mute
			dsp.ampModule[1].HWMute[1] = 1
			SendToDSP(cmd)
			
			cmd = "$6d,$32,$31" // Mute
			dsp.ampModule[1].HWMute[2] = 1
			SendToDSP(cmd)
		    }
		}
	    }
	}
    }
    release:
    {
	stack_var integer k,i
	
	k = get_last (Tp)
	i = get_last (nchControl)
	
	if(dsp.isonline == 1)
	{
	    wait 5 'Pause Status Request'
	    {
		timeline_restart(tlDevicePoll)
	    }
	}
    }
}


button_event[tp,nchFadersUp]
{
    push:
    {
	stack_var integer k,i

	k = get_last (tp)
	i = get_last (nchFadersUp)

	if(dsp.isonline == 1)
	{
	    cancel_wait 'Pause Status Request'
	    cancel_wait 'Pause Status Request2'
	    cancel_wait 'Pause Status Request3'
	    cancel_wait 'Pause Status Request4'
	    
	    timeline_set(tlDevicePoll,0)
	    timeline_pause(tlDevicePoll)
	    
	    to[tp[k],nchFadersUp[i]]

	    if((length_array(FaderUnmute)) >= i)
	    {
		if(FaderUnmute[i] <> 0) 
		{
		    CheckMuteOff(FaderUnmute[i])
		}
	    }
	    CheckVolValue(i,sup)
	}
    }
    hold[3,repeat]:
    {
	stack_var integer k,i

	k = get_last (tp)
	i = get_last (nchFadersUp)

	if(dsp.isonline == 1)
	{
	    CheckVolValue(i,sup)
	}
    }
    release:
    {
	stack_var integer k,i
	
	k = get_last (Tp)
	i = get_last (nchFadersUp)
	
	if(dsp.isonline == 1)
	{
	    wait 5 'Pause Status Request2'
	    {
		timeline_restart(tlDevicePoll)
	    }
	}
    }
}

button_event[tp,nchFadersDown]
{
    push:
    {
	stack_var integer k,i
    
	k = get_last (tp)
	i = get_last (nchFadersDown)
	
	if(dsp.isonline == 1)
	{
	    cancel_wait 'Pause Status Request'
	    cancel_wait 'Pause Status Request2'
	    cancel_wait 'Pause Status Request3'
	    cancel_wait 'Pause Status Request4'
    
	    timeline_set(tlDevicePoll,0)
	    timeline_pause(tlDevicePoll)
	    
	    to[tp[k],nchFadersDown[i]]

	    if((length_array(FaderUnmute)) >= i)
	    {
		if(FaderUnmute[i] <> 0) 
		{
		    CheckMuteOff(FaderUnmute[i])
		}
	    }
	    CheckVolValue(i,sdown)								
	}
    }
    hold[3,repeat]:
    {
	stack_var integer k,i

	k = get_last (tp)
	i = get_last (nchFadersDown)

	if(dsp.isonline == 1)
	{
	    CheckVolValue(i,sdown)		
	}
    }
    release:
    {
	stack_var integer k,i
	
	k = get_last (Tp)
	i = get_last (nchFadersDown)
	
	if(dsp.isonline == 1)
	{
	    wait 5 'Pause Status Request3'
	    {
		timeline_restart(tlDevicePoll)
	    }
	}
    }
}

button_event[Tp,nchInputRouting]
{
    push:
    {
	stack_var integer k,i
	local_var char cmd[255]
	
	k = get_last (Tp)
	i = get_last (nchInputRouting)
	
	if(dsp.isonline == 1)
	{
	    cancel_wait 'Pause Status Request'
	    cancel_wait 'Pause Status Request2'
	    cancel_wait 'Pause Status Request3'
	    cancel_wait 'Pause Status Request4'
	    
	    timeline_set(tlDevicePoll,0)
	    timeline_pause(tlDevicePoll)
	    
	    cmd = "$5a,right_string("'00',itohex(i-1)",2)"
	    SendToDSP(cmd)
	    
	    dsp.ampModule[1].InputRouting = i-1
	    debug(" DPStoA(device),'Sets input signal routing --> ',itoa(i)")
	}
    }
    release:
    {
	stack_var integer k,i
	
	k = get_last (Tp)
	i = get_last (nchInputRouting)
	
	if(dsp.isonline == 1)
	{
	    wait 10 'Pause Status Request4'
	    {
		timeline_restart(tlDevicePoll)
	    }
	}
    }
}

Button_event[Tp,GetPresetNameBtn]
{
    push:
    {
	stack_var integer k
	k = get_last(Tp)
	
	to[Tp[k],GetPresetNameBtn]
	
	IndexPresetName = 1    
	OldIndexPresetName = 0
	
	ProgressBar(k,25,5,6,7,8)
	
	if(timeline_active(tlDevicePoll)) timeline_kill(tlDevicePoll)
	if(timeline_active(tlGetNamePoll)) timeline_kill(tlGetNamePoll)
	timeline_create (tlGetNamePoll,tlGetNamePollArray,1,timeline_relative,timeline_repeat)
    }
}

// Select Current Media Stored Presets
// 0:EEPROM,1:SmartCard

button_event[tp,MediaPresetsBtn]
{
    push:
    {
	stack_var integer k,i

	k = get_last (tp)
	
	if(CurrentMediaPresets == 0) CurrentMediaPresets = 1
	else                         CurrentMediaPresets = 0
	
	debug("'Current Media Presets Updated: ',itoa(CurrentMediaPresets)")
    }
}

button_event[tp,nchPresets]
{
    push:
    {
	stack_var integer k,i

	k = get_last (tp)
	i = get_last (nchPresets)
	
	if(dsp.isonline == 1)
	{
	    TpPresetsIsHolding[k] = 0
	    
	    switch(StoreRecallPresetFB)
	    {
		case 1: // Recall
		{
		    RecallPresets(k,i)
		    CurrentPreset = i
		}
		case 2: // Store
		{
		    TpPresetsIsHolding[k] = i
		    send_command tp[k],"'AKEYB-',PresetName[TpPresetsIsHolding[k]]"
		}
		case 3: // Delete
		{
		    TpPresetsIsHolding[k] = i
		    
		    AnswerBox(k,1,2,3,4)
		}
	    }
	}
    }
}


// Vertical Presets

Button_event[Tp,nchVChannel] 
{
    push:
    {
	stack_var integer k
	stack_var integer i
	stack_var integer PresNum
				    
	k = get_last(Tp)
	i = get_last(nchVChannel)
	
	if(dsp.isonline == 1)
	{
	    
	    to[Tp[k],nchVChannel[i]] 
	    
	    TpVIsHolding[k] = 0 
	    
	    PresNum = i + MaxPresetPerPage * (TpCurrentPage[k] - 1) 

	    switch(StoreRecallPresetFB)
	    {
		case 1: // Recall
		{
		    RecallPresets(k,PresNum)
		    CurrentPreset = PresNum
		    debug("'Recall Preset'")
		}
		case 2: // Store
		{
		    if(enableChanEdit[k] == 1)
		    {
			TpVIsHolding[k] = PresNum
			send_command tp[k],"'AKEYB-',PresetName[TpVIsHolding[k]]"
			debug("'Store Preset'")
		    }
		}
		case 3: // Delete
		{
		    if(enableChanEdit[k] == 1)
		    {
			TpVIsHolding[k] = PresNum
			
			AnswerBox(k,1,2,3,4)
			debug("'Delete Preset'")
		    }
		}
	    }
	}
    }
}
    
Button_event[Tp,UpBtn]
Button_event[Tp,DownBtn]
{
    push:
    {
	stack_var integer k
	stack_var integer NewPage
    
	k = get_last(Tp)								
	
	min_to[tp[k],button.input.channel]
	
	if(TpCurrentPage[k] == 0) TpCurrentPage[k] = 1
	
	NewPage = TpCurrentPage[K]
	
	If(button.input.channel == UpBtn)
	{
	    if(	NewPage >= TpMaxPages) NewPage = 1
	    else NewPage ++
	}
	else //Down
	{
	    if(	NewPage <= 1) NewPage = TpMaxPages
	    else NewPage --
    
	}
    tpUpdateVPresetNames(k,NewPage)
    }
}

button_event[tp,nchFunctionsPreset]
{
    push:
    {
	stack_var integer k,i
	k = get_last(tp)
	i = get_last(nchFunctionsPreset)
	
	StoreRecallPresetFB = i
    }
}

Button_event[Tp,EnterPageBtn]
{
    push:
    {
	stack_var integer k
	k = get_last(Tp)
	
	TpCurrentPage[k] = 1
	
	tpUpdateVPresetNames(k,TpCurrentPage[k])
    }
}

button_event[TP,ConnectToDSP]
{
    push:
    {
	stack_var integer k
	
	k = get_last(TP)
	
	if(UseConnect == 1)
	{
	    UseConnect = 0
	    ip_client_close(device.port)
	    ClearTpInfo()
	    ReloadTpInfo(0)
	}
	else UseConnect = 1
    }
}

button_event[TP,PollingStatusBtn]
{
    push:
    {
	stack_var integer k
	k = get_last(TP)
	
	if(PollEnable == 1) PollEnable = 0
	else                PollEnable = 1
    }
}

button_event[TP,ToggleTempBtn]
{
    push:
    {
	stack_var integer k
	k = get_last(TP)
	
	if(InCelsius == 1) InCelsius = 0
	else               InCelsius = 1
    }
    release:
    {
	stack_var integer k
	k = get_last(TP)
	
	if(TpChanValidRange(txtInfo[20]))
	{
	    if(InCelsius == 1) send_command tp[k],"'^TXT-',itoa(txtInfo[20]),',0,',itoa(dsp.ampModule[1].ModTemp),'° C'"
	    else               send_command tp[k],"'^TXT-',itoa(txtInfo[20]),',0,',itoa(getFahrenheit(dsp.ampModule[1].ModTemp)),'° F'"
	}

    }
}


timeline_event[tlDevicePoll]
{
    stack_var char cmd[255]
    
    if(dsp.IsOnline == 1) 
    {
	if(PollEnable == 1) 
	{
	    switch(timeline.sequence)
	    {
		case 1: // Get Device Info
		{
		    cmd = "$49" 
		    SendToDSP(cmd)
		}
		case 2: // Get Status Device Meters
		{
		    cmd = "$4c" 
		    SendToDSP(cmd)
		}
		case 3: // Get Status Device
		{
		    cmd = "$53" 
		    SendToDSP(cmd)
		}
		case 4: // Read device Voltage,clock, temperatures and led status
		{
		    cmd = "$54" 
		    SendToDSP(cmd)
		}
		case 5: // Startup Preset Request 
		{
		    if(GetPreset == 1)
		    {
		    cmd = "$78,$30,$30,$61,$67,itoa(CurrentMediaPresets),$46,$46" 
		    SendToDSP(cmd)
		    }
		}
		case 6: // TONE IN & OUT Request
		{
		    if((dsp.ampModule[1].AlarmTriggered[1] == 1) || (dsp.ampModule[1].DSPAlarmTriggered[1] == 1))
		    {
			// Status Tone CH #1
			cmd = "$4A,getTAG32(),$52, $18,$01,$70,$03, $20,$00"
			SendToDSP(cmd)
		    }
		    if((dsp.ampModule[1].AlarmTriggered[2] == 1) || (dsp.ampModule[1].DSPAlarmTriggered[2] == 1))
		    {
			// Status Tone CH #2
			cmd = "$4A,getTAG32(),$52, $38,$01,$70,$03, $20,$00"
			SendToDSP(cmd)
		    }
		}
	    }
	}
    }
    else 
    {
	if((ipaddress <> '') && (UseConnect == 1))
	{
	    ip_client_open(device.port,IpAddress,IpPort,3)
	    debug("'DSP - try to reconnect'")
	}
    }
}

Button_event[tp,3981] // Aswer Yes
{
    push:
    {
	stack_var integer k
	stack_var char cmd[50]
	
	k = get_last(tp)
	tps[k].answer = 1
	
	select
	{
	    active(TpPresetsIsHolding[k] > 0):
	    {
		DeletePresets(k,TpPresetsIsHolding[k])
	    }
	    active(TpVIsHolding[k] > 0):
	    {
		DeletePresets(k,TpVIsHolding[k])
	    }
	}
	TpPresetsIsHolding[k] = 0
	TpVIsHolding[k] = 0
    }
}

Button_event[tp,3982] // Aswer No
{
    push:
    {
	stack_var integer k
	k = get_last(tp)
	tps[k].answer = 2
	
	send_command tp[k],"'PPOF-',MsgBoxPopPages[2]"		
	
	TpPresetsIsHolding[k] = 0
	TpVIsHolding[k] = 0
    }
}

timeline_event[tlProgressBar]
{				
    send_level tp,LvlProgressBar,timeline.sequence * 100 / tlRepeatTimes
				    
    debug("'tlProgressBar ==> ',itoa(timeline.sequence * 100 / tlRepeatTimes),'% (',itoa(timeline.sequence),' secs)'")
    if(timeline.sequence == tlRepeatTimes) 	

    wait 6 
    {
	send_command tp,"'PPOF-',MsgBoxPopPages[3]"				
	if(TpChanValidRange(LvlProgressBar))send_level tp,LvlProgressBar,0
	timeline_kill(tlProgressBar)
	debug("'tlProgressBar - Timeline killed'")
    }
}

timeline_event[tlGetNamePoll]
{
    if(IndexPresetName > MaxIndexPresetName)
    {
	if(timeline_active(tlGetNamePoll)) timeline_kill(tlGetNamePoll)
	debug("'ATTENTION! KILL tlGetNamePoll !'")
    
    }
    else
    {
	if(OldIndexPresetName <> IndexPresetName) // Is both value is not equal
	{
	    OldIndexPresetName = IndexPresetName
	    
	    sendtodsp("$78,$30,$30,$61,$67,itoa(CurrentMediaPresets),right_string("'00',itohex(IndexPresetName - 1)",2)")
	    debug("'Request Preset Name Index[',itoa(IndexPresetName),'] from MEDIA ',itoa(CurrentMediaPresets)")
	}
	else
	{
	    debug("'Request Preset Name WAITING new Command'")
	}
    }
}


timeline_event[tlFeedbacks]
{
    stack_var integer loop
    
    for(loop=1;loop<=MaxPresets;loop++)
    {
	if(TpChanValidRange(nchPresets[loop])) [Tp,nchPresets[loop]] = CurrentPreset = loop
    }
    
    CheckQueue()
    
    if(TpChanValidRange(nchControl[1])) [Tp,nchControl[1]] = ((dsp.ampModule[1].DeviceON = 1) && (dsp.ampModule[1].Mod1Ready = 1))
    if(TpChanValidRange(nchControl[2])) [Tp,nchControl[2]] = ((dsp.ampModule[1].DeviceON = 0) || (dsp.ampModule[1].Mod1Ready = 0))
    if(TpChanValidRange(nchControl[3])) [Tp,nchControl[3]] = ((dsp.ampModule[1].DeviceON = 1) && (dsp.ampModule[1].Mod1Ready = 1))
    if(TpChanValidRange(nchControl[4])) [Tp,nchControl[4]] = (dsp.ampModule[1].HWMute[1] = 1)
    if(TpChanValidRange(nchControl[5])) [Tp,nchControl[5]] = (dsp.ampModule[1].HWMute[1] = 0)
    if(TpChanValidRange(nchControl[6])) [Tp,nchControl[6]] = (dsp.ampModule[1].HWMute[2] = 1)
    if(TpChanValidRange(nchControl[7])) [Tp,nchControl[7]] = (dsp.ampModule[1].HWMute[2] = 0)
    if(TpChanValidRange(nchControl[8])) [Tp,nchControl[8]] = (dsp.ampModule[1].HWMute[1] = 1)
    if(TpChanValidRange(nchControl[9])) [Tp,nchControl[9]] = (dsp.ampModule[1].HWMute[2] = 1)
    if(TpChanValidRange(nchControl[10])) [Tp,nchControl[10]] = ((dsp.ampModule[1].HWMute[1] = 1) && (dsp.ampModule[1].HWMute[2] = 1))

    if(TpChanValidRange(txtInfo[11])) [tp,txtInfo[11]] = dsp.ampModule[1].Clock = 1
    if(TpChanValidRange(txtInfo[12])) [tp,txtInfo[12]] = dsp.ampModule[1].Vaux  = 1
    if(TpChanValidRange(txtInfo[13])) [tp,txtInfo[13]] = dsp.ampModule[1].IGBT  = 1
    if(TpChanValidRange(txtInfo[14])) [tp,txtInfo[14]] = dsp.ampModule[1].BOOST = 1
    if(TpChanValidRange(txtInfo[15])) [tp,txtInfo[15]] = dsp.ampModule[1].Led   = 1
    if(TpChanValidRange(txtInfo[21])) [tp,txtInfo[21]] = dsp.ampModule[1].Protection[1]   = 1
    if(TpChanValidRange(txtInfo[22])) [tp,txtInfo[22]] = dsp.ampModule[1].Protection[2]   = 1
    if(TpChanValidRange(txtInfo[23])) [tp,txtInfo[23]] = dsp.ampModule[1].HWProtection[1] = 1
    if(TpChanValidRange(txtInfo[24])) [tp,txtInfo[24]] = dsp.ampModule[1].HWProtection[2] = 1
    if(TpChanValidRange(txtInfo[25])) [tp,txtInfo[25]] = dsp.ampModule[1].AlarmTriggered[1] = 1
    if(TpChanValidRange(txtInfo[26])) [tp,txtInfo[26]] = dsp.ampModule[1].AlarmTriggered[2] = 1
    if(TpChanValidRange(txtInfo[27])) [tp,txtInfo[27]] = dsp.ampModule[1].DSPAlarmTriggered[1] = 1
    if(TpChanValidRange(txtInfo[28])) [tp,txtInfo[28]] = dsp.ampModule[1].DSPAlarmTriggered[2] = 1
    if(TpChanValidRange(txtInfo[29])) [tp,txtInfo[29]] = dsp.ampModule[1].Presence  = 1
    if(TpChanValidRange(txtInfo[30])) [tp,txtInfo[30]] = dsp.ampModule[1].LastONOFF = 1
    if(TpChanValidRange(txtInfo[31])) [tp,txtInfo[31]] = dsp.ampModule[1].Mod1Ready = 1
    if(TpChanValidRange(txtInfo[32])) [tp,txtInfo[32]] = dsp.ampModule[1].DeviceON  = 1
    if(TpChanValidRange(txtInfo[33])) [tp,txtInfo[33]] = dsp.ampModule[1].ChannelIdle[1] = 1
    if(TpChanValidRange(txtInfo[34])) [tp,txtInfo[34]] = dsp.ampModule[1].ChannelIdle[2] = 1
    if(TpChanValidRange(txtInfo[35])) [tp,txtInfo[35]] = dsp.ampModule[1].Signal[1] = 1
    if(TpChanValidRange(txtInfo[36])) [tp,txtInfo[36]] = dsp.ampModule[1].Signal[2] = 1
    
    if(TpChanValidRange(txtInfo[45])) [tp,txtInfo[45]] = dsp.ampModule[1].Clip[1] = 1
    if(TpChanValidRange(txtInfo[46])) [tp,txtInfo[46]] = dsp.ampModule[1].Clip[2] = 1
    if(TpChanValidRange(txtInfo[47])) [tp,txtInfo[47]] = dsp.ampModule[1].Gate[1] = 1
    if(TpChanValidRange(txtInfo[48])) [tp,txtInfo[48]] = dsp.ampModule[1].Gate[2] = 1
				    
    if(TpChanValidRange(txtInfo[65])) [tp,txtInfo[65]] = ((itoa(dsp.ampModule[1].ToneINAlarm[1])  = '1') && 
						      ((dsp.ampModule[1].AlarmTriggered[1] = 1) || (dsp.ampModule[1].DSPAlarmTriggered[1] = 1)))
    if(TpChanValidRange(txtInfo[66])) [tp,txtInfo[66]] = ((itoa(dsp.ampModule[1].ToneINAlarm[2])  = '1') && 
						      ((dsp.ampModule[1].AlarmTriggered[2] = 1) || (dsp.ampModule[1].DSPAlarmTriggered[2] = 1)))
    if(TpChanValidRange(txtInfo[67])) [tp,txtInfo[67]] = ((itoa(dsp.ampModule[1].ToneOUTAlarm[1]) = '1') && 
						      ((dsp.ampModule[1].AlarmTriggered[1] = 1) || (dsp.ampModule[1].DSPAlarmTriggered[1] = 1)))
    if(TpChanValidRange(txtInfo[68])) [tp,txtInfo[68]] = ((itoa(dsp.ampModule[1].ToneOUTAlarm[2]) = '1') && 
						      ((dsp.ampModule[1].AlarmTriggered[2] = 1) || (dsp.ampModule[1].DSPAlarmTriggered[2] = 1)))
    if(TpChanValidRange(txtInfo[69])) [tp,txtInfo[69]] = ((itoa(dsp.ampModule[1].LoadAlarm[1]) = '1') && 
						      ((dsp.ampModule[1].AlarmTriggered[1] = 1) || (dsp.ampModule[1].DSPAlarmTriggered[1] = 1)))
    if(TpChanValidRange(txtInfo[70])) [tp,txtInfo[70]] = ((itoa(dsp.ampModule[1].LoadAlarm[2]) = '1') && 
						     ((dsp.ampModule[1].AlarmTriggered[2] = 1) || (dsp.ampModule[1].DSPAlarmTriggered[2] = 1)))

    if(TpChanValidRange(nchInputRouting[1])) [Tp,nchInputRouting[1]] = ((dsp.ampModule[1].InputRouting = 0) && (dsp.ampModule[1].DeviceON = 1) && (dsp.ampModule[1].Mod1Ready = 1))
    if(TpChanValidRange(nchInputRouting[2])) [Tp,nchInputRouting[2]] = ((dsp.ampModule[1].InputRouting = 1) && (dsp.ampModule[1].DeviceON = 1) && (dsp.ampModule[1].Mod1Ready = 1))
    if(TpChanValidRange(nchInputRouting[3])) [Tp,nchInputRouting[3]] = ((dsp.ampModule[1].InputRouting = 2) && (dsp.ampModule[1].DeviceON = 1) && (dsp.ampModule[1].Mod1Ready = 1))
    if(TpChanValidRange(nchInputRouting[4])) [Tp,nchInputRouting[4]] = ((dsp.ampModule[1].InputRouting = 3) && (dsp.ampModule[1].DeviceON = 1) && (dsp.ampModule[1].Mod1Ready = 1))
    if(TpChanValidRange(nchInputRouting[5])) [Tp,nchInputRouting[5]] = ((dsp.ampModule[1].InputRouting = 4) && (dsp.ampModule[1].DeviceON = 1) && (dsp.ampModule[1].Mod1Ready = 1))
    if(TpChanValidRange(nchInputRouting[6])) [Tp,nchInputRouting[6]] = ((dsp.ampModule[1].InputRouting = 5) && (dsp.ampModule[1].DeviceON = 1) && (dsp.ampModule[1].Mod1Ready = 1))
    if(TpChanValidRange(nchInputRouting[7])) [Tp,nchInputRouting[7]] = ((dsp.ampModule[1].InputRouting = 6) && (dsp.ampModule[1].DeviceON = 1) && (dsp.ampModule[1].Mod1Ready = 1))
    if(TpChanValidRange(nchInputRouting[8])) [Tp,nchInputRouting[8]] = ((dsp.ampModule[1].InputRouting = 7) && (dsp.ampModule[1].DeviceON = 1) && (dsp.ampModule[1].Mod1Ready = 1))
    
    if(TpChanValidRange(ConnectToDSP))[TP,ConnectToDSP] = UseConnect = 1
    if(TpChanValidRange(MediaPresetsBtn))[tp,MediaPresetsBtn] = CurrentMediaPresets = 1
    if(TpChanValidRange(PollingStatusBtn))[TP,PollingStatusBtn] = PollEnable = 1
    
    if(TpChanValidRange(nchFunctionsPreset[1]))[tp,nchFunctionsPreset[1]] = StoreRecallPresetFB = 1 // Recall
    if(TpChanValidRange(nchFunctionsPreset[2]))[tp,nchFunctionsPreset[2]] = StoreRecallPresetFB = 2 // Store
    if(TpChanValidRange(nchFunctionsPreset[3]))[tp,nchFunctionsPreset[3]] = StoreRecallPresetFB = 3 // Delete
}

