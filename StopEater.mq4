//+------------------------------------------------------------------+
//|                                                    StopEater.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#include <fxlabsnet.mqh>

#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define OANDA_REQUEST_DURATION (2)
#define OANDA_REFLESH_SPAN (20)

string common_data_path;
bool fatal_error = false;
string symbol;

int pp_sz;
double pp[];
double pendingOrders[];
double positionPressure = 0;

bool hasUpdated;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
  init_fxlabs(); 
  fatal_error = false;
  symbol = Symbol();
  hasUpdated = false;
//  common_data_path = TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "¥¥Experts¥¥Files¥¥";
  common_data_path = "OANDA_";
  
  int pos = StringLen(symbol) - 3;
  symbol = StringConcatenate(StringSubstr(symbol, 0, pos), "_", StringSubstr(symbol, pos));
//  Print(symbol);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
  
bool checkArrayResize(int newsz, int sz)
{
   if (newsz != sz) 
   {
      Alert("ArrayResize failed"); 
      return(false); 
   }
   return(true); 
}

bool triggerOandaUpdate() {

   int m = Minute();
   int s = Seconds();
   
   if(hasUpdated) {
     if(m % 10 == 9) {
        hasUpdated = false;
     }
     return false;
   }

   if((0 <= m && m < OANDA_REQUEST_DURATION) || (20 <= m && m < 20 + OANDA_REQUEST_DURATION) || (40 <= m && m < 40 + OANDA_REQUEST_DURATION)) {
      if(!(m % OANDA_REFLESH_SPAN)) {
         return true;
      }
   }
   
   return false;
}

int askOandaUpdate() {
   if(fatal_error) {
      Print("fatal error");
      return -1; 
   }
   if(!triggerOandaUpdate()) {
      return -1;
   }

   int sz = 0;
   int ref = -1; 

// ref = orderbook(symbol, Time[1] - TimeCurrent());
   ref = orderbook(symbol, 0);
   if(ref >= 0) {
      sz = orderbook_sz(ref);
      if(sz < 0) {
         fatal_error = true; 
         Print("Error retrieving size of Orderbook data, sz = ", sz); 
         return -1; 
      }
   }
     
   if (sz == 0) {
      Print("size = 0, returning.");
      return -1;
   }
   
   int idx = 0;
   int ts = orderbook_timestamp(ref, idx);
   if (ts == -1) {
      Print("orderbook_timestamps error");
      return -1;   
   }

   pp_sz = orderbook_price_points_sz(ref, ts);
   double ps[]; 
   double pl[]; 
   double os[]; 
   double ol[];

   double pressure = 0;

   // we should verify ArrayResize worked, but for sake
   // of brevity we omit this from the sample code
   ArrayResize(pp, pp_sz);
   ArrayResize(ps, pp_sz); 
   ArrayResize(pl, pp_sz); 
   ArrayResize(os, pp_sz); 
   ArrayResize(ol, pp_sz); 

   ArrayResize(pendingOrders, pp_sz); 

   if(!orderbook_price_points(ref, ts, pp, ps, pl, os, ol)) {
      return -1; 
   }  
                  
   for(int i = 0; i < pp_sz; i++) {
      pendingOrders[i] = ol[i] - os[i];
      pressure -= pl[i] - ps[i];
//      if(MathAbs(pp[i] - Bid) < 1.0) {
//         Print(pp[i], ", ", ps[i], ", ", pl[i], ", ", os[i], ", ", ol[i]);
//      }
   }

   return pressure;
}

void writeOrderBookInfo() {
 
   string filepath = common_data_path + Symbol() + ".csv";
 
   if(FileIsExist(filepath)) {
      FileDelete(filepath);
   }

   int fh = FileOpen(filepath, FILE_CSV | FILE_WRITE);
   if(fh!=INVALID_HANDLE) {
      FileWrite(fh, positionPressure, pp_sz);

      for(int i = 0; i < pp_sz; i++) {
        FileWrite(fh, pp[i], pendingOrders[i]);
      }
   }

   FileClose(fh);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---

   double pressure = askOandaUpdate();
   if(positionPressure == pressure || pressure == -1) {
      return;
   }
   else {
      hasUpdated = true;
      positionPressure = pressure;
      writeOrderBookInfo();
   }   
}
//+------------------------------------------------------------------+