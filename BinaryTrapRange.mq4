//+------------------------------------------------------------------+
//|                                                       2sf1sb.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define ACCEPTABLE_SPREAD (3) //for FXTF1000
//#define ACCEPTABLE_SPREAD (4) //for OANDA, Gaitame, ICMarket
//#define ACCEPTABLE_SPREAD (5) //for Rakuten
//#define ACCEPTABLE_SPREAD (16) //for XMTrading

#define TP (0.05)
#define MARGIN (0.01)

double LOT;
double previousAsk;
double previousBid;

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
  Print("MIN_SL=", Point * MarketInfo(Symbol(), MODE_STOPLEVEL));

  Print("SPREAD=", MarketInfo(Symbol(), MODE_SPREAD));
  Print("POINT=", MarketInfo(Symbol(), MODE_POINT));
  
  previousAsk = Ask;
  previousBid = Bid;
  Print("ASK=", Ask);
  Print("BID=", Bid);
  
  LOT = MarketInfo(Symbol(), MODE_MINLOT);
  Print("LOT=", LOT);

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
    previousBid = Bid;
    previousAsk = Ask;
    return;
  }

  double upper = High[iHighest(Symbol(), PERIOD_M1, MODE_HIGH, 1440, 60)];
  double bottom = Low[iLowest(Symbol(), PERIOD_M1, MODE_LOW, 1440, 60)];

  double highestShort = 0;
  double lowestShort = 10000;
  double highestLong = 0;
  double lowestLong = 10000;

  for(int i = 0; i < OrdersTotal(); i++) {  
    if(OrderSelect(i, SELECT_BY_POS)) {    
    
      if(OrderType() == OP_BUY) {
        if(OrderTakeProfit() == 0 || OrderStopLoss() == 0 || OrderLots() != LOT) {
          bool closed = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
        }
	else if(OrderOpenPrice() < bottom || upper < OrderOpenPrice()) {
          bool closed = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
	}
        else {
          if(OrderOpenPrice() < lowestLong) {
            lowestLong = OrderOpenPrice();
          }
          if(highestLong < OrderOpenPrice()) {
            highestLong = OrderOpenPrice();
          }
        }
      }
      else if(OrderType() == OP_SELL) {
        if(OrderTakeProfit() == 0 || OrderStopLoss() == 0 || OrderLots() != LOT) {
          bool closed = OrderClose(OrderTicket(), OrderLots(), Ask, 0);
        }
	else if(OrderOpenPrice() < bottom || upper < OrderOpenPrice()) {
          bool closed = OrderClose(OrderTicket(), OrderLots(), Ask, 0);
	}
        else {
          if(highestShort < OrderOpenPrice()) {
            highestShort = OrderOpenPrice();
          }
          if(OrderOpenPrice() < lowestShort) {
            lowestShort = OrderOpenPrice();
          }
        }
      }
    }
  }

  if(previousBid < Bid && bottom < Bid && Bid < upper) {
    if(Bid < lowestShort - MARGIN || highestShort + MARGIN < Bid) {
      int ticket = OrderSend(Symbol(), OP_SELL, LOT, Bid, 0, 0, Ask - TP);
    }
  }
  
  if(Ask < previousAsk && bottom < Ask && Ask < upper) {
    if(Ask < lowestLong - MARGIN || highestLong + MARGIN < Ask ) {
      int ticket = OrderSend(Symbol(), OP_BUY, LOT, Ask, 0, 0, Bid + TP);
    }
  }

  previousBid = Bid;
  previousAsk = Ask;
}
