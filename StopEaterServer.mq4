//+------------------------------------------------------------------+
//|                                              StopEaterServer.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#include <fxlabsnet.mqh>

#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define REFLASH_DELAY_S (5)
int delay;

#define MASK (0)
#define UPDATE (1)
#define READY (2)
char watchOanda;

bool fatal_error = false;
string symbol;

int pp_sz;
double pp[];
double pendingOrders[];
double positionPressure;
double hash;
double previousHash;

#define DERR (-100000.00)

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
  init_fxlabs(); 
  fatal_error = false;
  symbol = Symbol();
  watchOanda = UPDATE;

  if(!StringCompare(symbol, "USDJPY"))
    delay = 0;
  else if(!StringCompare(symbol, "EURUSD"))
    delay = 1 * REFLASH_DELAY_S;
  else if(!StringCompare(symbol, "GBPUSD"))
    delay = 2 * REFLASH_DELAY_S;
  else if(!StringCompare(symbol, "GBPJPY"))
    delay = 3 * REFLASH_DELAY_S;
  else if(!StringCompare(symbol, "AUDJPY"))
    delay = 4 * REFLASH_DELAY_S;
  else if(!StringCompare(symbol, "EURJPY"))
    delay = 5 * REFLASH_DELAY_S;
  else
    return -1;

  positionPressure = 0.0;
  hash = 0.0;
  previousHash = 0.0;
  
  int pos = StringLen(symbol) - 3;
  symbol = StringConcatenate(StringSubstr(symbol, 0, pos), "_", StringSubstr(symbol, pos));
  
  while(!EventSetTimer(1));
  
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
    EventKillTimer();
}
  
bool triggerOandaUpdate() {

   int m = Minute();

   if(watchOanda == READY && !(m % 20)) {
      watchOanda = UPDATE;
   }
   else if(watchOanda == MASK && (m == 19 || m == 39 || m == 59)) {
      watchOanda = READY;
   }

   if(watchOanda == UPDATE) {
     int t = (Seconds() % 30) - delay;     
     if(-1 < t && t < REFLASH_DELAY_S) {
       return true;
     }
   }

   return false;
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

double askOandaUpdate() {
   if(fatal_error) {
      Print("fatal error");
      return DERR; 
   }
   if(!triggerOandaUpdate() && (previousHash != 0.0)) {
      return DERR;
   }

   int sz = 0;
   int ref = -1;

   Print("OANDA updating... previousHash = ", previousHash);

// ref = orderbook(symbol, Time[1] - TimeCurrent());
   ref = orderbook(symbol, 0);
   if(ref >= 0) {
      sz = orderbook_sz(ref);
      if(sz < 0) {
         fatal_error = true; 
         Print("Error retrieving size of Orderbook data, sz = ", sz); 
         return DERR; 
      }
   }
     
   if (sz == 0) {
      Print("size = 0, returning.");
      return DERR;
   }
   
   int idx = 0;
   int ts = orderbook_timestamp(ref, idx);
   if (ts == -1) {
      Print("orderbook_timestamps error");
      return DERR;   
   }

   pp_sz = orderbook_price_points_sz(ref, ts);
   if(pp_sz < 1) {
     Print("pp_sz = ", pp_sz);
      return DERR;   
   }
   
   double ps[]; 
   double pl[]; 
   double os[]; 
   double ol[];

   if(!checkArrayResize(ArrayResize(pp, pp_sz), pp_sz)) 
      return DERR;
   else if(!checkArrayResize(ArrayResize(ps, pp_sz), pp_sz)) 
      return DERR;
   else if(!checkArrayResize(ArrayResize(pl, pp_sz), pp_sz)) 
      return DERR;
   else if(!checkArrayResize(ArrayResize(os, pp_sz), pp_sz)) 
      return DERR;
   else if(!checkArrayResize(ArrayResize(ol, pp_sz), pp_sz)) 
      return DERR;
   else if(!checkArrayResize(ArrayResize(pendingOrders, pp_sz), pp_sz)) 
      return DERR;


   if(!orderbook_price_points(ref, ts, pp, ps, pl, os, ol)) {
      Print("orderbook_price_points() failed.");
      return DERR; 
   }  
   
   double ips = 0.0;
   double ipl = 0.0;
   for(int i = 0; i < pp_sz; i++) {
      pendingOrders[i] = ol[i] - os[i];
      ips += ps[i];
      ipl += pl[i];
      hash = ol[i] + os[i] + pl[i] + ps[i];
   }

   Print("pp_sz = ", pp_sz, ", ipl = ", ipl, " ips = ", ips);
   return ips - ipl;
}

void writeOrderBookInfo() {

   string filepath = "OANDA_" + Symbol() + ".csv";
 
   if(FileIsExist(filepath)) {
      FileDelete(filepath);
   }

   int fh;
   do {
     fh = FileOpen(filepath, FILE_CSV | FILE_WRITE, ",");
   } while(fh == INVALID_HANDLE);

   FileWrite(fh, TimeCurrent());
   FileWrite(fh, positionPressure, pp_sz);

   for(int i = 0; i < pp_sz; i++) {
     FileWrite(fh, pp[i], pendingOrders[i]);
   }

   FileClose(fh);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
  return;
}

void OnTimer() {
//---
   double pressure = askOandaUpdate();
   
   if(previousHash == hash || pressure == DERR) {
      return;
   }
   else {
      Print("OANDA updated. hsame hash? = ", hash == previousHash, ", pressure = ", pressure);

      watchOanda = MASK;
      previousHash = hash;
      positionPressure = pressure;
      writeOrderBookInfo();
   }   
}
//+------------------------------------------------------------------+
