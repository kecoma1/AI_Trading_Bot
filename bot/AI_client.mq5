#define MAX_BUFF_LEN 2048
#define TIMEOUT 10000

/* Input parameters */
input int            PORT = 8688;                  // Puerto de conexión
input string         ADDR = "localhost";           // Dirección a la que conectarse
input int            num_data_to_save = 10;        // Número de los datos a guardar

/* To check whether there is an error or not */
bool     error = false;

/* Socket variables */
int      socket;                 // Socket handle

/* RSI variables */
int      rsi_h;                  // RSI handle
double   rsi[];                  // RSI array

/* Std deviation variables */
int      std_h;                  // STD deviation handle
double   std[];                  // std array

/* Velas */
MqlRates candles[];              // Velas

/* To check if a message has been sent */
bool sent = false;


// Function to know if the previous candle is a boom
// Función para saber si la vela anterior es un boom
bool es_anterior_boom() { return candles[1].close > candles[1].open; }


void OnInit() {

   // Inicializando rsi y std
   // Initializing rsi and std
   rsi_h = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   if (rsi_h == INVALID_HANDLE) Print("Error - 3.1: iRSI failure. ", GetLastError());

   std_h = iStdDev(_Symbol, _Period, 20, 0, MODE_SMA, PRICE_CLOSE);
   if (std_h == INVALID_HANDLE) Print("Error - 3.2: iStdDev failure. ", GetLastError());

   if (rsi_h == INVALID_HANDLE || std_h == INVALID_HANDLE) {
      error = true;
      return;
   }

   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(std, true);
   ArraySetAsSeries(candles, true);

   // Initializing the socket
   socket = SocketCreate();
   if (socket == INVALID_HANDLE) {
      Print("Error - 1: SocketCreate failure. ", GetLastError());
      error = true;
   } else {
      if (SocketConnect(socket, ADDR, PORT, TIMEOUT)) Print("[INFO]\tConnection stablished");
      else Print("Error - 2: SocketConnect failure. ", GetLastError());
   }
}


void OnDeinit(const int reason) {

   if (error) return;

   /* Closing the socket */
   // Creating the message
   char req[];
   
   Print("[INFO]\tClosing the socket.");
   
   int len = StringToCharArray("END CONNECTION\0", req)-1;
   SocketSend(socket, req, len);
   SocketClose(socket);
}


void OnTick() {

   if (error) return;

   // Cargando velas, el rsi y los valores del std
   // Loading the candles, rsi and std values
   CopyBuffer(rsi_h, 0, 0, num_data_to_save, rsi);
   CopyBuffer(std_h, 0, 0, num_data_to_save+1, std);
   CopyRates(_Symbol, _Period, 0, num_data_to_save, candles);

   // Si el anterior es boom vamos preparar los datos para enviarlos
   // If the previous one is a boom we are going to save data in the file
   if (es_anterior_boom() && !sent) {

      string data = "";
   
      // Saving the RSI
      // Guardamos el RSI
      string rsi_data = "";
      for(int i = 0; i < num_data_to_save; i++) {
         double rsi_normalized = NormalizeDouble(rsi[i], _Digits);
         rsi_data += DoubleToString(rsi_normalized)+",";
      }
      
      // Saving the std Dev increments
      // Guardamos los incrementos del std Dev
      string increment_data = "";
      for(int i = 0; i < num_data_to_save; i++) {
         double increment_normalized = NormalizeDouble(std[i]-std[i+1], _Digits);
         increment_data += DoubleToString(increment_normalized)+",";
      }
      
      data = rsi_data+increment_data;

      // Sending data
      Print("[INFO]\tSending RSI and STD deviation");
      
      char req[];
      int len = StringToCharArray(data, req)-1;
      SocketSend(socket, req, len);
      
      sent = true;
      
      EventSetTimer(PeriodSeconds());
   }
}

void OnTimer() {
   sent = false;
   EventKillTimer();
}
