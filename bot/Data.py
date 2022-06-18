import socket

PORT = 8688
ADDR = "localhost"

def socket_ini():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    
    server_socket.bind((ADDR, PORT))
    server_socket.listen(10)
    
    connection, addr = server_socket.accept()
    print("[INFO]\t", addr, "connected")
    
    return connection, server_socket
    

def thread_data(stop_event, data):
    msg = ""
    
    connection, server_socket = socket_ini()
    
    while not stop_event.is_set():
        msg = connection.recv(1024).decode()
        
        if "END CONNECTION" in msg:
            break
        
        rsi_std = msg.split(',')
        del rsi_std[-1]
        
        rsi_std = [ float(elem) for elem in rsi_std ]
        
        try:
            data["rsi_std"] = rsi_std
        except:
            print("[INFO]\tError trying to convert to float, ignored");
        
    connection.close()
    server_socket.close()
        
     