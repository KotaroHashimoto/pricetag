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

#define OANDA_INTERVAL (1)


// the start time of the last bar that contained data returned by the fxlabs server
int lastts = 0;     

// the time of the last data point that was returned by the fxlabs server
int lastdatapt = 0; 

// the time of the last call out to the fxlabs server
int lastcall = 0; 

bool fatal_error = false;
string symbol;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
  init_fxlabs(); 
  lastts = 0; 
  lastdatapt = 0; 
  lastcall = 0;
  fatal_error = false;
  symbol = Symbol();
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

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   if (fatal_error) {
      Print("fatal error");
      return; 
   }
/*   
//   datetime timemax = MathMin(Time[0] + Period()*60, TimeCurrent());    
   Print("Time[0] = ", Time[0]);
   Print("Bars = ", Bars);
   Print("IndicatorCounted() = ", IndicatorCounted());
   Print("Period() = ", Period());
   Print("TimeCurrent() = ", TimeCurrent());*/
   
   int sz = 0;
   int ref = -1; 
   bool triggerUpdate = true;
   
   datetime timemin = Time[2];
   datetime timemax = MathMin(Time[0] + Period()*60, TimeCurrent());   

   if(triggerUpdate) {
      // get orderbook data
      ref = orderbook(symbol, timemax-timemin); 
      Print("ref = ", ref);
      if (ref >= 0)
      {
         sz = orderbook_sz(ref);
         Print("size = ", sz);
         if (sz < 0) 
         {
            fatal_error = true; 
            Print("Error retrieving size of Orderbook data, sz = ", sz); 
            return; 
         }
      }
   }
     
   if (sz == 0) {
      Print("size = 0");
      return;
   }
   
   int idx = 0;
   int ts = orderbook_timestamp(ref, idx);
   if (ts == -1) {
      Print("orderbook_timestamps error");
      return;   
   }
   Print("ts = ", ts);

   int pp_sz = orderbook_price_points_sz(ref, ts);
   Print("pp_sz = ", pp_sz);
   double pricepoints[];
   double ps[]; 
   double pl[]; 
   double os[]; 
   double ol[];

   // we should verify ArrayResize worked, but for sake
   // of brevity we omit this from the sample code
   ArrayResize(pricepoints, pp_sz);
   ArrayResize(ps, pp_sz); 
   ArrayResize(pl, pp_sz); 
   ArrayResize(os, pp_sz); 
   ArrayResize(ol, pp_sz); 
         
   if (!orderbook_price_points(ref, ts, pricepoints, ps, pl, os, ol)) {
      return; 
   }  
                  
   for(int i = 0; i < 1; i++) 
   {
      Print(pricepoints[i], " ", ps[i], " ", pl[i], " ", os[i], " ", ol[i]);
   }
}
//+------------------------------------------------------------------+
