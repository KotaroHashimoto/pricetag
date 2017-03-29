//+------------------------------------------------------------------+
//|                                                      HumTaro.mq4 |
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
  bool Buy_Signal = iCustom(NULL, 0, "Market/ACB Breakout Arrows", 0, 1);
  bool Sell_Signal = iCustom(NULL, 0, "Market/ACB Breakout Arrows", 1, 1); 
  
  double Buy_Stoploss = 0.0;
  if(iCustom(NULL, 0, "Market/ACB Breakout Arrows",2,1) != 0)
    Buy_Stoploss = iCustom(NULL, 0, "Market/ACB Breakout Arrows", 2, 1);

  double Sell_Stoploss = 0.0;
  if(iCustom(NULL, 0, "Market/ACB Breakout Arrows", 3, 1) != 0)
    Sell_Stoploss = iCustom(NULL, 0, "Market/ACB Breakout Arrows", 3, 1);

  Print("Sell Signal:" + DoubleToStr(Sell_Signal) + "(" + DoubleToStr(Sell_Stoploss) + ") Buy Signal:" + DoubleToStr(Buy_Signal) + "(" + DoubleToStr(Buy_Stoploss) + ")");

}
//+------------------------------------------------------------------+
