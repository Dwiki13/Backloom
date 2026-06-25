//+------------------------------------------------------------------+
//| Signal-Based EA Template                                          |
//| Reads trading signals from JSON file and executes on MT5          |
//+------------------------------------------------------------------+
#property copyright "Auto Trading System"
#property link      ""
#property version   "1.00"
#property strict

input string SignalFilePath = "C:\\xauusd-signal\\signal.json";
input double LotSize = 0.05;
input int Slippage = 30;
input int MagicNumber = 20250101;

string lastSignalTime = "";

//+------------------------------------------------------------------+
int OnInit()
{
   Print("Signal EA initialized. Monitoring: ", SignalFilePath);
   EventSetTimer(5); // Check every 5 seconds
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
}

//+------------------------------------------------------------------+
void OnTimer()
{
   CheckSignal();
}

//+------------------------------------------------------------------+
void CheckSignal()
{
   int file = FileOpen(SignalFilePath, FILE_READ|FILE_TXT, ',');
   if(file == INVALID_HANDLE)
   {
      Print("Cannot open signal file");
      return;
   }

   string direction = FileReadString(file);
   StringReplace(direction, "\"", "");
   StringReplace(direction, "direction:", "");
   StringReplace(direction, " ", "");

   string entryStr = FileReadString(file);
   StringReplace(entryStr, "\"", "");
   StringReplace(entryStr, "entry:", "");

   string slStr = FileReadString(file);
   StringReplace(slStr, "\"", "");
   StringReplace(slStr, "sl:", "");

   string tp1Str = FileReadString(file);
   StringReplace(tp1Str, "\"", "");
   StringReplace(tp1Str, "tp1:", "");

   string lotStr = FileReadString(file);
   StringReplace(lotStr, "\"", "");
   StringReplace(lotStr, "lot_size:", "");

   string timeStr = FileReadString(file);
   StringReplace(timeStr, "\"", "");
   StringReplace(timeStr, "timestamp:", "");

   FileClose(file);

   // Skip if same signal already processed
   if(timeStr == lastSignalTime) return;

   if(direction == "NONE" || direction == "") return;

   double entry = StringToDouble(entryStr);
   double sl = StringToDouble(slStr);
   double tp1 = StringToDouble(tp1Str);
   double lot = StringToDouble(lotStr);

   if(lot <= 0) lot = LotSize;

   ExecuteTrade(direction, entry, sl, tp1, lot);
   lastSignalTime = timeStr;
}

//+------------------------------------------------------------------+
void ExecuteTrade(string direction, double entry, double sl, double tp, double lot)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = "XAUUSD";
   request.volume = lot;
   request.deviation = Slippage;
   request.magic = MagicNumber;

   if(direction == "BUY")
   {
      request.type = ORDER_TYPE_BUY;
      request.price = SymbolInfoDouble("XAUUSD", SYMBOL_ASK);
      request.sl = sl;
      request.tp = tp;
   }
   else if(direction == "SELL")
   {
      request.type = ORDER_TYPE_SELL;
      request.price = SymbolInfoDouble("XAUUSD", SYMBOL_BID);
      request.sl = sl;
      request.tp = tp;
   }
   else
   {
      Print("Unknown direction: ", direction);
      return;
   }

   if(!OrderSend(request, result))
   {
      Print("OrderSend failed: ", GetLastError());
   }
   else
   {
      Print(direction, " order placed. Ticket: ", result.order, " Price: ", result.price);
   }
}

//+------------------------------------------------------------------+
void OnTick()
{
   // Timer handles signal checking
}
