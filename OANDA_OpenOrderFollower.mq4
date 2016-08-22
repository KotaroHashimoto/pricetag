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
   
   OrderBook_Price_Points(a, b, d0, d1, d2, d3, d4, c, s);   

   Print("a: ", a);
   Print("b: ", b);
   Print("c: ", c);
   Print("s: ", s);
   Print("d0: ", d0);
   Print("d1: ", d1);
   Print("d2: ", d2);
   Print("d3: ", d3);
   Print("d4: ", d4);
  }
//+------------------------------------------------------------------+
