//+------------------------------------------------------------------+
//|                                                  MoneyGrower.mq4 |
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

#define NONE (-1)
double previousPrice = NONE;
int position = NONE;
int ticket = NONE;
double stopLoss = NONE;

//#define POS_SIZING_FACTOR (0.00002) //position = AccountEquity() * POS_SIZING_FACTOR for USD
#define POS_SIZING_FACTOR (0.0000005) //position = AccountEquity() * POS_SIZING_FACTOR for JPY
#define ACCEPTABLE_SPREAD (4) //for OANDA
//#define ACCEPTABLE_SPREAD (3) //for FXTF

extern int STOP_LOSS = 200;

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
  
    if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
      previousPrice = NONE;
      position = NONE;
      return;
    }
    else if(previousPrice == NONE) {
      previousPrice = Ask;
      position = NONE;
      return;
    }

    double posSize = MathFloor(10.0 * AccountEquity() * POS_SIZING_FACTOR) * 0.1;
    /*
    if(10 < posSize) {
      posSize = 10.0; // for OANDA basic course
    }*/
    
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
    }
  }

  else {
    Print("Something Wrong with OrderSelect(Ticket, SELECT_BY_TICKET), ticket=", ticket);
  }
}
