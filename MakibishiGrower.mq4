//+------------------------------------------------------------------+
//|                                              MakibishiGrower.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//#define ACCEPTABLE_SPREAD (5) //for Rakuten
//#define ACCEPTABLE_SPREAD (4) //for OANDA
#define ACCEPTABLE_SPREAD (3) //for FXTF1000
//#define ACCEPTABLE_SPREAD (0) //for ICMarket
//#define ACCEPTABLE_SPREAD (16) //for XMTrading

#define NAMPIN_MARGIN (0.01)
#define NONE (-1)
#define MAX_SL (0.100)

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

  double highestShort = 0;
  double lowestShort = 10000;
  double highestLong = 0;
  double lowestLong = 10000;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderType() == OP_BUY) {
        if(OrderStopLoss() < Bid - stopLoss) {
          bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - stopLoss, 0, 0);
        }
        if(OrderTakeProfit() == 0 || OrderStopLoss() == 0 || OrderLots() != MIN_LOT) {
          bool closed = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
        }
        if(OrderOpenPrice() < lowestLong) {
          lowestLong = OrderOpenPrice();
        }
        if(highestLong < OrderOpenPrice()) {
          highestLong = OrderOpenPrice();
        }
      }
      else if(OrderType() == OP_SELL) {
        if(Ask + stopLoss < OrderStopLoss()) {
          bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + stopLoss, 0, 0);
     	  }
        if(OrderTakeProfit() == 0 || OrderStopLoss() == 0 || OrderLots() != MIN_LOT) {
          bool closed = OrderClose(OrderTicket(), OrderLots(), Ask, 0);
        }
        if(highestShort < OrderOpenPrice()) {
          highestShort = OrderOpenPrice();
        }
        if(OrderOpenPrice() < lowestShort) {
          lowestShort = OrderOpenPrice();
        }
      }
    }
  }
  

  if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
    previousBid = Bid;
    previousAsk = Ask;
    return;
  }

  if(previousBid < Bid) {
    if(Bid < lowestShort - NAMPIN_MARGIN || highestShort + NAMPIN_MARGIN < Bid) {
      int ticket = OrderSend(Symbol(), OP_SELL, MIN_LOT, Bid, 0, Ask + stopLoss, 0);
    }
  }
  
  if(Ask < previousAsk) {
    if(Ask < lowestLong - NAMPIN_MARGIN || highestLong + NAMPIN_MARGIN < Ask ) {
      int ticket = OrderSend(Symbol(), OP_BUY, MIN_LOT, Ask, 0, Bid - stopLoss, 0);
    }
  }

  previousBid = Bid;
  previousAsk = Ask;
}
