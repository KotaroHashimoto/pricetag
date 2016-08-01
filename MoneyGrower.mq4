//+------------------------------------------------------------------+
//|                                                  MoneyGrower.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define NONE (-1)
double previousPrice = NONE;
int position = NONE;
int ticket = NONE;
double stopLoss = NONE;
double posSizeFactor = NONE;
double MAX_LOT = NONE;

#define ACCEPTABLE_LOSS (0.01)
#define C (0.01) //for FXTF1000
//#define C (10)
//#define ACCEPTABLE_SPREAD (4) //for OANDA
#define ACCEPTABLE_SPREAD (3) //for FXTF1000

extern int STOP_LOSS = 100;

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
   
  Print("Symbol()=", Symbol());
  Print("STOPLEVEL=", MarketInfo(Symbol(), MODE_STOPLEVEL));
  Print("SPREAD=", MarketInfo(Symbol(), MODE_SPREAD));
  
  stopLoss = STOP_LOSS * Point;
  Print("STOP_LOSS=", STOP_LOSS);
  Print("stopLoss=", stopLoss);
  Print("ASK=", Ask);
  Print("BID=", Bid);
  
  MAX_LOT = MarketInfo(Symbol(), MODE_MAXLOT);
  Print("MAX_LOT=", MAX_LOT);
  
  posSizeFactor = C * ACCEPTABLE_LOSS / STOP_LOSS;
  Print("posSizeFactor=", posSizeFactor);
  Print("Initial Lot=", MathFloor(100.0 * AccountEquity() * posSizeFactor) / 100.0);
  
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

int nextPosition()
{
  if(position == NONE) {
    if(previousPrice < Ask) {
      return OP_BUY;
    }
    else if(Ask < previousPrice) {
      return OP_SELL;
    }
    else {
      return NONE;
    }
  }
  else {
    if(position == OP_BUY) {
      return OP_SELL;
    }
    else if(position == OP_SELL) {
      return OP_BUY;
    }
    else {
      return NONE;
    }
  }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  if(OrdersTotal() == 0) {
    if((DayOfWeek() == 5 && 18 < Hour()) || DayOfWeek() == 6) {
      return;
    }
    else if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
      previousPrice = NONE;
      position = NONE;
      return;
    }
    else if(previousPrice == NONE) {
      previousPrice = Ask;
      position = NONE;
      return;
    }

    double posSize = MathFloor(100.0 * AccountEquity() * posSizeFactor) / 100.0; //for FXTF1000
    if(MAX_LOT < posSize) {
      posSize = MAX_LOT;
    }
    
    if(nextPosition() == OP_BUY) {
      ticket = OrderSend(Symbol(), OP_BUY, posSize, Ask, 3, Bid - stopLoss, 0, NULL, 0, 0, Red);
      position = OP_BUY;
      previousPrice = Bid;
    }
    else if(nextPosition() == OP_SELL) {
      ticket = OrderSend(Symbol(), OP_SELL, posSize, Bid, 3, Ask + stopLoss, 0, NULL, 0, 0, Blue); 
      position = OP_SELL;
      previousPrice = Ask;
    }
    else {
      Print("Something Wrong with nextPositon() !!");
      Print("LastError=", GetLastError());
    }
  }
  
  else if(OrderSelect(ticket, SELECT_BY_TICKET) == True) {      

    if(OrderType() == OP_BUY) {       
      if(OrderStopLoss() < Bid - stopLoss) {
        bool modified = OrderModify(ticket, OrderOpenPrice(), Bid - stopLoss, 0, 0, Red);
      }
      previousPrice = Bid;
    }
    else if(OrderType() == OP_SELL) {
      if(Ask + stopLoss < OrderStopLoss()) {
        bool modified = OrderModify(ticket, OrderOpenPrice(), Ask + stopLoss, 0, 0, Blue);
      }                     
      previousPrice = Ask;
    }
    else {
      Print("Something Wrong with OrderType() !!");
      Print("LastError=", GetLastError());
    }
  }

  else {
    Print("Something Wrong with OrderSelect(ticket, SELECT_BY_TICKET), ticket=", ticket);
    Print("LastError=", GetLastError());
  }
}
