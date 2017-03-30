//+------------------------------------------------------------------+
//|                                                      HumTaro.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

int handle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

  handle = FileOpen("PalawanLog.csv", FILE_CSV|FILE_WRITE, ',');
  if(handle < 0) {
    Print("File write error. " + string(GetLastError()));
    return 0;
  }
  else {
    FileWrite(handle, "Time", "CurrencyPair", "Buy Signal", "Buy Stop", "Sell Signal", "Sell Stop");
  }
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  FileClose(handle);
  Print("file write succeeded.");   
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

//  FileWrite(handle, TimeCurrent(), Symbol(), Buy_Signal, Buy_Stoploss, Sell_Signal, Sell_Stoploss);
}
//+------------------------------------------------------------------+


