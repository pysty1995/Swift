
import Cocoa


class SerialPortDemoController: NSObject, NSApplicationDelegate, ORSSerialPortDelegate, NSUserNotificationCenterDelegate {
	
    @IBOutlet weak var open_close_port: NSButton!
    @IBOutlet var incoming_data: NSTextView!

    @IBOutlet weak var U1_data: NSTextField!
    @IBOutlet weak var U5_length_data: NSTextField!
    @IBOutlet weak var U5_OTP_CODE: NSTextField!
    @IBOutlet weak var U1_data_length: NSTextField!
    @IBOutlet weak var U1_otp_code: NSTextField!
    @IBOutlet weak var status: NSTextField!
    @IBOutlet weak var result_text: NSTextFieldCell!
    @IBOutlet weak var time_start: NSTextField!
    @IBOutlet weak var time_end: NSTextField!
    @IBOutlet weak var duration: NSTextField!
    @IBOutlet weak var pass_count: NSTextField!
    @IBOutlet weak var fail_count: NSTextField!
    @IBOutlet weak var total_count: NSTextField!
    @IBOutlet weak var rate: NSTextField!
    
    
    var U5_otp_code: String = ""
    var timer0 = Timer()
    
    var allow: Bool = false
    var error_time: Bool = false
    var run_time = 0
    

    let format_date = DateFormatter()
    let format_time = DateFormatter()
    var start: Double = 0
    var end: Double = 0
    var i = 0
    var pass: Int = 0
    var fail: Int = 0
    var total: Int = 0
    var rate_success: Float = 0.0
    
    @IBAction func U1_input(_ sender: NSTextField) {
        
        let currentTime = Date()
        format_time.dateFormat = "HH:mm:ss"
        
        time_start.stringValue = ""
        time_end.stringValue = ""
        U1_data_length.stringValue = ""
        U1_otp_code.stringValue = ""
        U5_length_data.stringValue = ""
        U5_OTP_CODE.stringValue = ""
        result_text.stringValue = ""
        duration.stringValue = ""
        
        result_text.placeholderString = "Waiting"
    
        time_start.stringValue = format_time.string(from: currentTime)
        start = currentTime.timeIntervalSinceReferenceDate
        
        if allow == true{
        let u1_data: String = U1_data.stringValue
        print(u1_data)
        if u1_data == ""{
                status.stringValue = "No U1 input"
            }else{
            
                if u1_data.prefix(9) == "Accessory"{
                U1_data_length.stringValue = String(u1_data.count)
                        if u1_data.count == 42{
                            let index1 = u1_data.index(u1_data.startIndex, offsetBy: 25)
                            let index2 = u1_data.index(u1_data.startIndex, offsetBy: 41)
                            U1_otp_code.stringValue = String(u1_data[index1...index2])
                            }
                        else
                        {
                            U1_otp_code.stringValue = "Wrong U1 data"
                                    }
                    process()
                    
            }
            
            
            }
        }
    }
    
    
    @IBAction func Start(_ sender: NSButton) {
        process()
    }
    
    func process(){
        
        timer0.invalidate()
        timer0 = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(Send1), userInfo: nil, repeats: false)
        timer0 = Timer.scheduledTimer(timeInterval: 0.55, target: self, selector: #selector(Send2), userInfo: nil, repeats: false)
        timer0 = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(U5_data_process), userInfo: nil, repeats: false)
        timer0 = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(createCSV), userInfo: nil, repeats: false)

    }
    ///// Func to get the OTP code from U5, output is U5_otp_code
    @objc func U5_data_process(){
        let U5_data: String = incoming_data.string
        let U5_length = U5_data.count
        if U5_length > 200{
            U5_length_data.stringValue = String(U5_length)
            let index1 = U5_data.index(U5_data.startIndex, offsetBy: 160)
            let index2 = U5_data.index(U5_data.startIndex, offsetBy: 176)
            U5_otp_code = String(U5_data[index1...index2])
            U5_OTP_CODE.stringValue = String(U5_otp_code)
             check_code()
            
        }else
            {
                error_time = true
                let currentTime = Date()
                format_time.dateFormat = "HH:mm:ss"
                status.stringValue = "Can not read U5 otp!"
                U5_length_data.stringValue = ""
                U5_OTP_CODE.stringValue = ""
                result_text.stringValue = "NG"
                result_text.textColor = NSColor.red
                time_end.stringValue = format_time.string(from: currentTime)
                end = currentTime.timeIntervalSinceReferenceDate
                let result: Float = Float(end - start)
                if result > 0.7 && error_time == true{
                    fail += 1
                    duration.stringValue = "\(result)s"
                    
                }
        }
   
    pass_count.stringValue = String(pass)
    fail_count.stringValue = String(fail)
    total = fail + pass
    rate_success = Float(pass) / Float(total) * 100
    print(rate_success)
    total_count.stringValue = String(total)
    let display_rate = NSString(format: "%.2f", rate_success)
    rate.stringValue = "\(display_rate)%"
        
    }
    
    ////// check result between U1 and U5 code
    @objc func check_code(){
       
        print("U5 is: \(U5_OTP_CODE.stringValue)")
        print("U1 is: \(U1_otp_code.stringValue)")
        let currentTime = Date()
        format_time.dateFormat = "HH:mm:ss"
        if U5_OTP_CODE.stringValue == U1_otp_code.stringValue{
            status.stringValue = "OTP is matched!"
            result_text.stringValue = "OK"
            result_text.textColor = NSColor.green
            time_end.stringValue = format_time.string(from: currentTime)
            end = currentTime.timeIntervalSinceReferenceDate
            let result: Float = Float(end - start)
            
            if result > 0.5{
            pass += 1
            duration.stringValue = "\(result)s"
            }
        }else{
            status.stringValue = "OTP is not matched!"
            result_text.stringValue = "NG"
            result_text.textColor = NSColor.red
            time_end.stringValue = format_time.string(from: currentTime)
            end = currentTime.timeIntervalSinceReferenceDate
            let result: Float = Float(end - start)
            
            if result > 0.5{
                fail += 1
                duration.stringValue = "\(result)s"
                
            }
            
        }

    }
    
    // MARK: -------> Send command:
    
      @objc func Send1() {
        incoming_data.string = ""
        let string1 = "quick_config" + "\r\n"
        let data1 = string1.data(using: String.Encoding.utf8)
        self.serialPort?.send(data1!)
    }
     @objc func Send2() {
        let string2 = "otp asnread 124" + "\r\n"
        let data2 = string2.data(using: String.Encoding.utf8)
        self.serialPort?.send(data2!)
    }
    // Clear the screen
    @IBAction func clear_func(_ sender: NSButton) {
        incoming_data.string = ""
        U1_data.stringValue = ""
        U1_otp_code.stringValue = ""
        U1_data_length.stringValue = ""
        U5_otp_code = ""
        U5_length_data.stringValue = ""
        U5_OTP_CODE.stringValue = ""
        result_text.stringValue = ""
        status.stringValue = ""
        pass_count.stringValue = ""
        fail_count.stringValue = ""
        total_count.stringValue = ""
        time_start.stringValue = ""
        time_end.stringValue = ""
        duration.stringValue = ""
        rate.stringValue = ""
    }
    @objc func clear(){
        incoming_data.string = ""
        U5_otp_code = ""
        U5_length_data.stringValue = ""
        U5_OTP_CODE.stringValue = ""
        
    }
    // Func to create .csv file
    
    @objc func createCSV() -> Void
    {
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yy"
        let date = dateFormatter.string(from: currentDate)
        let fileName = "Test." + "\(date)"
        let DocumentDirURL = try! FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = DocumentDirURL.appendingPathComponent("/Data/\(fileName)").appendingPathExtension("csv")
        var writeString = ""
        
        if let filehandle = try?FileHandle(forUpdating: fileURL)
        {
            
            filehandle.seekToEndOfFile()
            let newLine = "\(i),\(U5_OTP_CODE.stringValue),\(U1_otp_code.stringValue),\(result_text.stringValue),\(time_start.stringValue),\(duration.stringValue)\r\n"
            writeString.append(newLine)
            filehandle.write(writeString.data(using: .utf8)!)
            i = i + 1
        } else {
            do {
                
                writeString = "STT,U5 OTP Code,U1 OTP Code,Test result,Time test,Duration\r\n"
                let newLine = "\r\n"
                writeString.append(newLine)
                try "\(writeString)".write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
  
            } catch let error as NSError {
                print("Fail to write to URL")
                print(error)
               
            }

        }
       
    }
    
   
    //MARK:-------------------------------------------------------->SerialPort
    
    
    @objc let serialPortManager = ORSSerialPortManager.shared()
    
    @objc let availableBaudRates = [300, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200, 230400]
    
    
    @objc dynamic var serialPort: ORSSerialPort? {
        didSet {
            oldValue?.close()
            oldValue?.delegate = nil
            serialPort?.delegate = self
        }
    }

    @IBAction func action_close_open_port(_ sender: NSButton) {
        if let port = self.serialPort{
            if(port.isOpen){
                port.close()
            }else{
                port.open()
            }
        }
    }
	// MARK: - ORSSerialPortDelegate
   @objc func listPort() {
        let availablePorts = ORSSerialPortManager.shared().availablePorts
        var i = 0
        for port in availablePorts {
            print("\(i). \(port.name)")
            i += 1
            
        }
    }
    @IBAction func stop_bit1(_ sender: NSMenuItem) {
        serialPort?.numberOfStopBits = 1
    }
    @IBAction func stop_bit_2(_ sender: NSMenuItem) {
        serialPort?.numberOfStopBits = 2
    }
    

    
    
       func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        self.open_close_port.title = "Close"
        //serialPort.numberOfDataBits = 8
        //serialPort.dtr = true
        //serialPort.rts = true
        //serialPort.baudRate = 115200
        //serialPort.numberOfStopBits = 1
        //serialPort.parity = .none
        status.stringValue = "Serial port was opened!"
        allow = true
        print(serialPort.baudRate)
        print(serialPort.numberOfDataBits)
        print(serialPort.numberOfStopBits)
        print(serialPort.dtr)
        print(serialPort.rts)
        print(self.serialPort as Any)
        
	}
	
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        self.open_close_port.title = "Open"
        status.stringValue = "Serial port was closed!"
        allow = false
    }
	
	func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
		if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            
            self.incoming_data.textStorage?.mutableString.append(string as String)
            self.incoming_data.needsDisplay = true
		}
	}
	
	func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
		self.serialPort = nil
        self.open_close_port.title = "Open"
        status.stringValue = "Serial port was removed!"
	}
	
	func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
		print("SerialPort \(serialPort) encountered an error: \(error)")
	}
	
	// MARK: - NSUserNotifcationCenterDelegate
	
	func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
		let popTime = DispatchTime.now() + Double(Int64(3.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: popTime) { () -> Void in
			center.removeDeliveredNotification(notification)
		}
	}
	
	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}
	
    override init() {
        super.init()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(serialPortsWereConnected(_:)), name: NSNotification.Name.ORSSerialPortsWereConnected, object: nil)
        nc.addObserver(self, selector: #selector(serialPortsWereDisconnected(_:)), name: NSNotification.Name.ORSSerialPortsWereDisconnected, object: nil)
        NSUserNotificationCenter.default.delegate = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
   //  MARK: - Notifications at System
    
    @objc func serialPortsWereConnected(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let connectedPorts = userInfo[ORSConnectedSerialPortsKey] as! [ORSSerialPort]
            status.stringValue = "Ports were connected: \(connectedPorts)"
        }
    }

    @objc func serialPortsWereDisconnected(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let disconnectedPorts: [ORSSerialPort] = userInfo[ORSDisconnectedSerialPortsKey] as! [ORSSerialPort]
            status.stringValue = "Ports were disconn: \(disconnectedPorts)"
        }
    }
    
    
    
}
