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

#define OANDA_REQUEST_DURATION (5)
#define OANDA_REFLESH_SPAN (20)

extern int SDIFF;

bool fatal_error = false;
string symbol;
string common_data_path;

int pp_sz;
double pp[];
double pendingOrders[];
double positionPressure;
double hash;
double previousHash;

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
  common_data_path = "OANDA_";
  positionPressure = 0.0;
  hash = 0.0;
  previousHash = 0.0;
  
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
      if((s + SDIFF) % OANDA_REFLESH_SPAN < OANDA_REFLESH_SPAN) {
         return true;
      }
   }
   
   return false;
}

double askOandaUpdate() {
   if(fatal_error) {
      Print("fatal error");
      return -1; 
   }
   if(!triggerOandaUpdate() && (previousHash != 0.0)) {
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
   
   double ips = 0.0;
   double ipl = 0.0;
   for(int i = 0; i < pp_sz; i++) {
      pendingOrders[i] = ol[i] - os[i];
      ips += ps[i];
      ipl += pl[i];
      hash = ol[i] + os[i] + pl[i] + ps[i];
   }

   return ips - ipl;
}

void writeOrderBookInfo() {
 
   string filepath = common_data_path + Symbol() + ".csv";
 
   if(FileIsExist(filepath)) {
      FileDelete(filepath);
   }

   int fh = FileOpen(filepath, FILE_CSV | FILE_WRITE, ",");
   if(fh!=INVALID_HANDLE) {
      FileWrite(fh, TimeCurrent());
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
   if(previousHash == hash || pressure == -1) {
      return;
   }
   else {
      hasUpdated = true;
      previousHash = hash;
      positionPressure = pressure;
      writeOrderBookInfo();
   }   
}
//+------------------------------------------------------------------+