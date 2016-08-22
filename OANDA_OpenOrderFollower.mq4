//+------------------------------------------------------------------+
//|                                      OANDA_OpenOrderFollower.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#import "fxlabsnet.dll"
   void Orderbook_Price_Points(int, int, double&[], double&[], double&[], double&[], double&[], int, string&);
#import

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
   int a = 1, b = 1, c = 1;
   double d0[100], d1[100], d2[100], d3[100], d4[100];
   string s;
   
   Orderbook_Price_Points(a, b, d0, d1, d2, d3, d4, c, s);
   Print("d0: ", d0[0]);
   Print("d1: ", d1[0]);
   Print("d2: ", d2[0]);
   Print("d3: ", d3[0]);
   Print("d4: ", d4[0]);
   Print("s: ", s);
}
//+------------------------------------------------------------------+
