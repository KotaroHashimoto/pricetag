//+------------------------------------------------------------------+
//|                                              ACB_BreakOut_EA.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input double Stop_Loss_Percentage = 1.0;
input int Open_Time = 0;
input int Close_Time = 24;
input bool EMA_Filter = False;


double stopLoss;
double entryPrice;
double quickProfit;
double firstTarget;
double finalTarget;
int signal;

const string indName = "Market/ACB Breakout Arrows";

void getIndicatorValues() {

  if(iCustom(NULL, 0, indName, 0, 1)) {
    signal = OP_BUY;
    stopLoss = iCustom(NULL, 0, indName, 2, 1);
  }
  else if(iCustom(NULL, 0, indName, 1, 1)) {
    signal = OP_SELL;
    stopLoss = iCustom(NULL, 0, indName, 3, 1);
  }
  else {
    signal = -1;
    stopLoss = 0.0;
  }

  stopLoss = ObjectGetDouble(0, "StopLoss", OBJPROP_PRICE);
  entryPrice = ObjectGetDouble(0, "Entry", OBJPROP_PRICE);
  quickProfit = ObjectGetDouble(0, "FirstTarget", OBJPROP_PRICE);
  firstTarget = ObjectGetDouble(0, "Target1", OBJPROP_PRICE);
  finalTarget = ObjectGetDouble(0, "Target2", OBJPROP_PRICE);
  
  Print("stopLoss: ", stopLoss, " entryPrice: ", entryPrice, " quickProfit: ", quickProfit, " firstTarget:", firstTarget, " finalTarget: ", finalTarget);
}


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

  getIndicatorValues();
}
//+------------------------------------------------------------------+


