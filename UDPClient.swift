import Foundation

@_silgen_name("tellosocket_server") func tello_socket_server(_ host:UnsafePointer<Int8>,port:Int32) -> Int32
@_silgen_name("tellosocket_recive") func tello_socket_recive(_ fd:Int32,buff:UnsafePointer<Byte>,len:Int32,ip:UnsafePointer<Int8>,port:UnsafePointer<Int32>) -> Int32
@_silgen_name("tellosocket_close") func tello_socket_close(_ fd:Int32) -> Int32
@_silgen_name("tellosocket_client") func tello_socket_client() -> Int32
@_silgen_name("tellosocket_get_server_ip") func tello_socket_get_server_ip(_ host:UnsafePointer<Int8>,ip:UnsafePointer<Int8>) -> Int32
@_silgen_name("tellosocket_sendto") func tello_socket_sentto(_ fd:Int32,buff:UnsafePointer<Byte>,len:Int32,ip:UnsafePointer<Int8>,port:Int32) -> Int32

open class UDPClient: Socket {
    public override init(address: String, port: Int32) {
        let remoteipbuff: [Int8] = [Int8](repeating: 0x0,count: 16)
        let ret = tello_socket_get_server_ip(address, ip: remoteipbuff)
        guard let ip = String(cString: remoteipbuff, encoding: String.Encoding.utf8), ret == 0 else {
            super.init(address: "", port: 0)
            return
        }

        super.init(address: ip, port: port)
        let fd: Int32 = tello_socket_client()

        if fd > 0 {
            self.fd = fd
        }
    }
    //指定client IP & Port
    public convenience init(address: String, port: Int32, myAddresss: String, myPort: Int32) {
        self.init(address: address, port: port)
        
        let fd: Int32 = tello_socket_server(myAddresss, port: myPort)
        if fd > 0 {
            self.fd = fd
        }
    }
    
    open func send(data: [Byte]) -> Result {
        guard let fd = self.fd else { return .failure(SocketError.connectionClosed) }
        
        let sendsize: Int32 = tello_socket_sentto(fd, buff: data, len: Int32(data.count), ip: self.address, port: Int32(self.port))
        if Int(sendsize) == data.count {
            return .success
        } else {
            return .failure(SocketError.unknownError)
        }
    }
    
    open func send(string: String)-> Result {
        guard let fd = self.fd else { return .failure(SocketError.connectionClosed) }
        
        let sendsize = tello_socket_sentto(fd, buff: string, len: Int32(strlen(string)), ip: address, port: port)
        if sendsize == Int32(strlen(string)) {
            return .success
        } else {
            return .failure(SocketError.unknownError)
        }
    }
    
    open func send(data: Data) -> Result {
        guard let fd = self.fd else { return .failure(SocketError.connectionClosed) }
        
        var buff = [Byte](repeating: 0x0,count: data.count)
        (data as NSData).getBytes(&buff, length: data.count)
        let sendsize = tello_socket_sentto(fd, buff: buff, len: Int32(data.count), ip: address, port: port)
        if sendsize == Int32(data.count) {
            return .success
        } else {
            return .failure(SocketError.unknownError)
        }
    }
    
    open func recv(_ expectlen: Int) -> ([Byte]?, String, Int) {
        guard let fd = self.fd else {
            return (nil, "no ip", 0)
        }
        var buff: [Byte] = [Byte](repeating: 0x0, count: expectlen)
        var remoteipbuff: [Int8] = [Int8](repeating: 0x0, count: 16)
        var remoteport: Int32 = 0
        let readLen: Int32 = tello_socket_recive(fd, buff: buff, len: Int32(expectlen), ip: &remoteipbuff, port: &remoteport)
        let port: Int = Int(remoteport)
        let address = String(cString: remoteipbuff, encoding: String.Encoding.utf8) ?? ""
        
        if readLen <= 0 {
            return (nil, address, port)
        }

        let data: [Byte] = Array(buff[0..<Int(readLen)])
        return (data, address, port)
    }
    
    open func close() {
        guard let fd = self.fd else { return }
        
        _ = tello_socket_close(fd)
        self.fd = nil
    }
}

open class UDPServer: Socket {
    
    public override init(address: String, port: Int32) {
        super.init(address: address, port: port)
      
        let fd = tello_socket_server(address, port: port)
        if fd > 0 { 
            self.fd = fd
        }
    }
  
    open func recv(_ expectlen: Int) -> ([Byte]?, String, Int) {
        if let fd = self.fd {
            var buff: [Byte] = [Byte](repeating: 0x0,count: expectlen)
            var remoteipbuff: [Int8] = [Int8](repeating: 0x0,count: 16)
            var remoteport: Int32 = 0
            let readLen: Int32 = tello_socket_recive(fd, buff: buff, len: Int32(expectlen), ip: &remoteipbuff, port: &remoteport)
            let port: Int = Int(remoteport)
            var address = ""
            if let ip = String(cString: remoteipbuff, encoding: String.Encoding.utf8) {
                address = ip
            }
          
            if readLen <= 0 {
                return (nil, address, port)
            }
          
            let rs = buff[0...Int(readLen-1)]
            let data: [Byte] = Array(rs)
            return (data, address, port)
        }
      
        return (nil, "no ip", 0)
    }
  
    open func close() {
        
        guard let fd = self.fd else { return }
        _ = tello_socket_close(fd)
        self.fd = nil
        
    }
}
