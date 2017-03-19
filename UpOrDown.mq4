//+------------------------------------------------------------------+
//|                                                     UpOrDown.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

  string CurrencyPairs[] = {"EURUSD", "EURJPY", "USDJPY", "GBPUSD", "GBPJPY", 
                            "AUDUSD", "AUDJPY", "EURGBP", "EURAUD", "GBPAUD"};

  string date = string(Year()) + "_" + string(Month()) + "_" + string((Day() - 1));
  int handle=FileOpen(date + ".csv", FILE_CSV|FILE_WRITE, ',');
  if(handle < 0) {
    return -1;
  }
   
  for(int i = 0; i < 10; i++) {
  
    double ma5 = iMA(CurrencyPairs[i], PERIOD_D1, 5, 0, MODE_SMA, PRICE_CLOSE, 1);
    double ma25 = iMA(CurrencyPairs[i], PERIOD_D1, 25, 0, MODE_SMA, PRICE_CLOSE, 1);
    double price = iClose(CurrencyPairs[i], PERIOD_D1, 1);
    
    FileWrite(handle, CurrencyPairs[i], determine(ma5, price), determine(ma25, price));
    Print(CurrencyPairs[i], " = ", price, ", ma5 = ", ma5, " ma25 = ", ma25);
  }

  FileClose(handle);
  
//---
   return(INIT_SUCCEEDED);
}

string determine(double ma, double price) {

  if(ma == 0 || price == 0) {
    return "err";
  }
  else if(price < ma) {
    return "Down";
  }
  else {
    return "Up";
  }
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
   
  }
//+------------------------------------------------------------------+
