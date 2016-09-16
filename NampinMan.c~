//+------------------------------------------------------------------+
//|                                              MakibishiGrower.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define ACCEPTABLE_SPREAD (5) //for Rakuten
//#define ACCEPTABLE_SPREAD (4) //for OANDA
//#define ACCEPTABLE_SPREAD (3) //for FXTF1000
//#define ACCEPTABLE_SPREAD (0) //for ICMarket
//#define ACCEPTABLE_SPREAD (16) //for XMTrading

#define MAX_SL (0.100) //for USDJPY
//#define MAX_SL (0.00100) //for GBPUSD
//#define MAX_SL (0.00075) //for EURUSD


#define MAX_POSITIONS (128)
#define NONE (-1)

double MIN_LOT = NONE;
double MIN_SL = NONE;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  //---
  Print("AccountBalance=", AccountBalance());
  Print("AccountEquity=", AccountEquity());
  Print("AccountFreeMargin=", AccountFreeMargin());
  Print("AccountCredit=", AccountCredit());
  Print("AccountName=", AccountName());
  Print("AccountNumber=", AccountNumber());
  Print("AccountProfit=", AccountProfit());
  Print("AccountServer()=", AccountServer());
  Print("AccountLeverage()=", AccountLeverage());
  Print("IsDemo=", IsDemo());
  Print("IsTradeAllowed()=", IsTradeAllowed());
  Print("TerminalCompany()=", TerminalCompany());
  Print("IsConnected()=", IsConnected());
  Print("AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)=", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
   
  Print("Symbol()=", Symbol());

  MIN_SL = Point * MarketInfo(Symbol(), MODE_STOPLEVEL);
  Print("MIN_SL=", MIN_SL);

  Print("SPREAD=", MarketInfo(Symbol(), MODE_SPREAD));
  Print("POINT=", MarketInfo(Symbol(), MODE_POINT));
  
  Print("ASK=", Ask);
  Print("BID=", Bid);
  
  MIN_LOT = MarketInfo(Symbol(), MODE_MINLOT);
  Print("MIN_LOT=", MIN_LOT);
  
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
  double stopLoss = NONE;
  double atr = iATR(Symbol(), PERIOD_M15, 2, 1);  
  if(atr < MIN_SL) {
    stopLoss = MIN_SL;
  }
  else if(MAX_SL < atr) {
    stopLoss = MAX_SL;
  }
  else {
    stopLoss = atr;
  }

  double longProfit = 0;
  double shortProfit = 0;
  
  int sTicket = NONE;
  int lTicket = NONE;
  double sMin = 1000000.0;
  double lMin = 1000000.0;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      double profit = OrderProfit();
      double aProfit = MathAbs(profit);
      
      if(OrderType() == OP_BUY) {
        if(OrderStopLoss() < Bid - stopLoss) {
          bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - stopLoss, 0, 0);
        }
        if(aProfit < lMin) {
          lMin = aProfit;
          lTicket = OrderTicket();
        }
        longProfit += profit;
      }
      else if(OrderType() == OP_SELL) {
        if(Ask + stopLoss < OrderStopLoss()) {
          bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + stopLoss, 0, 0);
     	  }
        if(aProfit < sMin) {
          sMin = aProfit;
          sTicket = OrderTicket();
        }
        shortProfit += profit;
      }
    }
  }
  

  if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
    return;
  }/*
  else if(MAX_POSITIONS < OrdersTotal()) {
    return;
  }
  else if(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) < 100.0) {
    return;
  }
  else if((DayOfWeek() == 5 && 18 < Hour()) || DayOfWeek() == 6) {
//      Print("No entry on Friday night. Hour()=", Hour());
    return;
  }*/
  else if(OrdersTotal() < MAX_POSITIONS){
    if(MathAbs(longProfit) > MathAbs(shortProfit)) {
      int ticket = OrderSend(Symbol(), OP_SELL, MIN_LOT, Bid, 0, Ask + stopLoss, 0);
    }
    else {
      int ticket = OrderSend(Symbol(), OP_BUY, MIN_LOT, Ask, 0, Bid - stopLoss, 0);
    }
  }
  else {
    if(MathAbs(longProfit) > MathAbs(shortProfit)) {
      if(lTicket != NONE) {
        bool closed = OrderClose(lTicket, MIN_LOT, Bid, 0);
      }
    }
    else {
      if(sTicket != NONE) {
        bool closed = OrderClose(sTicket, MIN_LOT, Ask, 0);
      }
    }
  }
}
