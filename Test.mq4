//+------------------------------------------------------------------+
//|                                                     Kohamama.mq4 |
//|                           Copyright 2017, Palawan Software, Ltd. |
//|                             https://coconala.com/services/204383 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Palawan Software, Ltd."
#property link      "https://coconala.com/services/204383"
#property description "Author: Kotaro Hashimoto <hasimoto.kotaro@gmail.com>"
#property version   "1.00"
#property strict

const string indName = "SupportResistance";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
    
  //--- create timer
   EventSetTimer(1);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
  
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  Print(getSignal());
  
  }

int getSignal() {

  if(0 < iCustom(NULL, PERIOD_CURRENT, indName, 0, 10)) {
    return OP_BUY;
  }
  else if(0 < iCustom(NULL, PERIOD_CURRENT, indName, 1, 10)) {
    return OP_SELL;
  }
  else {
    return -1;
  }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {

  for(int i = 0; i < 20; i++) {
    Print(iCustom(NULL, PERIOD_CURRENT, "DragonArrows", 2, i));
  }
  Print("");
//    Print(iCustom(NULL, PERIOD_CURRENT, indName, 3, 0));
  
//  Print(nextLot());
//  Print(int(TimeLocal() - tm));
//---
//  Print(TimeToString(TimeGMT()), ", ", TimeToString(TimeLocal()));
//  Print((TimeGMT()), ", ", (TimeLocal()), ", ", TimeCurrent(), ", ", TimeGMTOffset() / 3600.0, ", ", TimeDay());
//  Print(TimeDayOfWeek(TimeLocal()), ", ", TimeLocal());
//  Print(TradeStopTime(1234, "0:00", "2:00"));
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
