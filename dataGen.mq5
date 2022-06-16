// Input parameters for the file
// Parametros de entrada para un archivo
input string         nombre_archivo = "data.csv";  // Nombre del archivo a generar
input int            num_data_to_save = 10;        // Número de los datos a guardar
input int            candles_to_close_op = 2;      // Número de velas desde un boom hasta cerrar operación 

// Manejador del archivo
// File handler
int fp = 0;

// String to write
// String a escribir
string data = "";

// Array velas
// Candle array
MqlRates candles[];

// RSI handler and array
int rsi_h;
double rsi[];

// Std. Deviation handler and array
int std_h;
double std[];

// Para ver si la operación es exitosa
// To check if the operation is successfully
bool op_abierta = false;
int velas = 0;
double price_open = 0;

// Function to know if the previous candle is a boom
// Función para saber si la vela anterior es un boom
bool es_anterior_boom() { return candles[1].close > candles[1].open; }

void OnInit() {
   // Abrimos el archivo
   // Openning the file
   fp = FileOpen(nombre_archivo, FILE_WRITE, 0, CP_ACP);
   
   string file_header = "";
   for(int i = 0; i < num_data_to_save; i++) 
      file_header += "RSI_"+IntegerToString(i)+",";
      
   for(int i = 0; i < num_data_to_save; i++) 
      file_header += "std_incr_"+IntegerToString(i)+",";
      
   file_header += "class";
   FileWrite(fp, file_header);

   // Handlers
   rsi_h = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   std_h = iStdDev(_Symbol, _Period, 20, 0, MODE_SMA, PRICE_CLOSE);
   
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(std, true);
   ArraySetAsSeries(candles, true);
}


void OnTick() {
   // Loading information
   // Cargando información
   CopyBuffer(rsi_h, 0, 0, num_data_to_save, rsi);
   CopyBuffer(std_h, 0, 0, num_data_to_save+1, std);
   CopyRates(_Symbol, _Period, 0, num_data_to_save, candles);
   
   // Si el anterior es boom vamos a guardar datos en el archivo
   // If the previous one is a boom we are going to save data in the file
   if (es_anterior_boom() && !op_abierta) {
   
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
      
      op_abierta = true;
      velas = Bars(_Symbol, _Period);
      
      price_open = candles[0].close;
   } else if (op_abierta) {
      if (velas+candles_to_close_op <= Bars(_Symbol, _Period)) {
         if (price_open > candles[0].close) FileWrite(fp, data+"1");
         else FileWrite(fp, data+"0");
      
         data = "";
         op_abierta = false;
      }   
   }
}

void OnDeinit(const int reason) {
   FileClose(fp);
}