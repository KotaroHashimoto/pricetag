//+------------------------------------------------------------------+
//|                                              MakibishiGrower.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define ACCEPTABLE_SPREAD (5)
#define LOTS_RATIO (1.22)
#define MAX_MARGIN (300)
#define NAMPIN_SPAN (0.01)
#define TP (0.1)
#define NONE (-1)

double MIN_LOT = NONE;
double MIN_SL = NONE;
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

  MIN_SL = Point * MarketInfo(Symbol(), MODE_STOPLEVEL);
  Print("MIN_SL=", MIN_SL);

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


void countPosAmount(double& sells, double& buys) {

  buys = 0;
  sells = 0;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderType() == OP_SELL) {
        sells += OrderLots();
      }
      else if(OrderType() == OP_BUY) {
        buys += OrderLots();
      }
    }
  }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{  
  if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
    previousBid = Bid;
    previousAsk = Ask;
    return;
  }
  
  double buys = 0.0;
  double sells = 0.0;
  countPosAmount(sells, buys);

  double highestLong = 0;
  double lowestLong = 10000;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderType() == OP_BUY) {
        if(OrderOpenPrice() < lowestLong) {
          lowestLong = OrderOpenPrice();
        }
        if(highestLong < OrderOpenPrice()) {
          highestLong = OrderOpenPrice();
	     }
      }
    }
  }

  
  if(23 == Hour()) { // pos time

    for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS)) {
        if(OrderTakeProfit() != 0) {
          bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), 0, 0, 0);
        }
      }
    }

    if(buys < LOTS_RATIO * sells) {
      int ticket = OrderSend(Symbol(), OP_BUY, MIN_LOT, Ask, 0, 0, 0);
      Sleep(10 * 1000);
    }
  }

  else { // day time

    for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS)) {

        if(OrderType() == OP_BUY) {
          if(OrderTakeProfit() == 0) {

            if(0 < OrderProfit()) {            
              bool closed = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
              if(closed) {
                i = 0;
              }
            }
            else {
              bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), 0, Ask + TP, 0);
	         }
          }
        }
      }
    }


    if(buys < LOTS_RATIO * sells) {
      if(Ask + NAMPIN_SPAN < lowestLong || highestLong + NAMPIN_SPAN < Ask) {
        int ticket = OrderSend(Symbol(), OP_BUY, MIN_LOT, Ask, 0, 0, Ask + TP);
      }
    }    
  }
  
  previousBid = Bid;
  previousAsk = Ask;
}
