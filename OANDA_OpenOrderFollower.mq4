//+------------------------------------------------------------------+
//|                                      OANDA_OpenOrderFollower.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   double oanda = iCustom(Symbol(), 0, "OANDA_OpenOrder", 0, 0);
   Print("oanda: ", oanda);

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
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int a, b, c;
   double[100] d0, d1, d2, d3, d4;
   String s;
   
   double oanda = iCustom(Symbol(), 0, "OANDA_OpenOrder", 0, 0);
   Print("oanda: ", oanda);
  }
//+------------------------------------------------------------------+
