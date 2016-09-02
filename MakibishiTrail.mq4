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
int longPositios = NONE;
int shortPosition = NONE;
int ticket = NONE;
double MIN_LOT = NONE;
double MIN_POINT = NONE;

double previousAsk = NONE;
double previousBid = NONE;

//#define ACCEPTABLE_SPREAD (4) //for OANDA
//#define ACCEPTABLE_SPREAD (3) //for FXTF1000
#define ACCEPTABLE_SPREAD (0) //for ICMarket

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
  
  MIN_POINT = MarketInfo(Symbol(), MODE_POINT);
  Print("POINT=", MIN_POINT);
  
  previousAsk = Ask;
  previousBid = Bid;
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
  if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
    return;
  }
    
  longPositios = 0;
  shortPosition = 0;
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderType() == OP_BUY) {
        bool closed = False;
        if(0 < OrderProfit() + OrderCommission() + OrderSwap() && Bid < previousBid) {
          closed = OrderClose(OrderTicket(), MIN_LOT, Bid, 0);
        }
        if(!closed) {
          longPositios ++;
        }
      }
      else if(OrderType() == OP_SELL) {
        bool closed = False;
        if(0 < OrderProfit() + OrderCommission() + OrderSwap() && previousAsk < Ask) {
          closed = OrderClose(OrderTicket(), MIN_LOT, Ask, 0);
        }
        if(!closed) {
          shortPosition ++;
        }
      }
    }
  }
    
  if(shortPosition < longPositios) {
    ticket = OrderSend(Symbol(), OP_SELL, MIN_LOT, Bid, 0, 0, 0);
  }
  else {
    ticket = OrderSend(Symbol(), OP_BUY, MIN_LOT, Ask, 0, 0, 0);
  }
  
  previousAsk = Ask;
  previousBid = Bid;
}