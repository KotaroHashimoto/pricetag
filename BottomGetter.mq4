//+------------------------------------------------------------------+
//|                                              MakibishiGrower.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//#define ACCEPTABLE_SPREAD (20) //for Rakuten
//#define ACCEPTABLE_SPREAD (4) //for OANDA
#define ACCEPTABLE_SPREAD (3) //for FXTF1000, Gaitame
//#define ACCEPTABLE_SPREAD (0) //for ICMarket
//#define ACCEPTABLE_SPREAD (16) //for XMTrading

#define MAX_NAMPIN (50)
#define NAMPIN_MARGIN (0.005)
#define NONE (-1)

double MIN_LOT = NONE;

double previousAsk = NONE;
double previousBid = NONE;

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
  
  Print("AccountMargin() = ", AccountMargin());

//  MIN_SL = Point * MarketInfo(Symbol(), MODE_STOPLEVEL);
//  Print("MIN_SL=", MIN_SL);

  Print("SPREAD=", MarketInfo(Symbol(), MODE_SPREAD));
  Print("POINT=", MarketInfo(Symbol(), MODE_POINT));
  
  Print("ASK=", Ask);
  Print("BID=", Bid);

  previousAsk = Ask;
  previousBid = Bid;
  
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
/*
  double longProfit = 0;
  double shortProfit = 0;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderType() == OP_BUY) {
        longProfit += OrderProfit();
      }
      else if(OrderType() == OP_SELL) {
        shortProfit += OrderProfit();
      }
    }
  }
*/
  double highest = 0;
  double lowest = 10000;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderType() == OP_BUY) {
        if(OrderOpenPrice() < lowest) {
          lowest = OrderOpenPrice();
        }
        if(highest < OrderOpenPrice()) {
          highest = OrderOpenPrice();
        }
      }
    }
  }

  if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
    previousBid = Bid;
    previousAsk = Ask;
    return;
  }

  if(MAX_NAMPIN < OrdersTotal()) {
    return;
  }

  if(Ask < lowest - NAMPIN_MARGIN/* && Ask < previousAsk*/) {
    int ticket = OrderSend(Symbol(), OP_BUY, MIN_LOT, Ask, 0, 0, 0);
  }
  if(highest + NAMPIN_MARGIN < Ask/* && Ask < previousAsk*/) {
    int ticket = OrderSend(Symbol(), OP_BUY, MIN_LOT, Ask, 0, 0, 0);
  }
  
  previousBid = Bid;
  previousAsk = Ask;
}
