//+------------------------------------------------------------------+
//|                                                   BinaryTrap.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//#define ACCEPTABLE_SPREAD (5) //for Rakuten
//#define ACCEPTABLE_SPREAD (4) //for OANDA
#define ACCEPTABLE_SPREAD (3) //for FXTF1000, Gaitame
//#define ACCEPTABLE_SPREAD (0) //for ICMarket
//#define ACCEPTABLE_SPREAD (16) //for XMTrading

#define MAX_POSITIONS (1000000)
#define NAMPIN_MARGIN (0.01)
#define SL (1.00)
#define TP (0.05)

#define NONE (-1)

double MIN_LOT = NONE;

double previousAsk = NONE;
double previousBid = NONE;

#define HEDGE_LOT (0.80)
#define HEDGE_SL (0.50)

#define HEDGE_OFF (0)
#define SHORT_HEDGE_ON (1)
#define LONG_HEDGE_ON (2)
#define HEDGE_ON_TH (-950)
#define HEDGE_OFF_TH (-850)


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

void hedgeControl(int longMinProfit, int shortMinProfit, int hedgeStatus)
{
  if(hedgeStatus == NONE) {
    if(longMinProfit < HEDGE_ON_TH) {
      return LONG_HEDGE_ON;
    }
    else if (shortMinProfit < HEDGE_ON_TH) {
      return SHORT_HEDGE_ON;
    }
  }
  else if(hedgeStatus == LONG_HEDGE_ON && HEDGE_OFF_TH < longMinProfit) {
    return HEDGE_OFF;
  }
  else if(hedgeStatus == SHORT_HEDGE_ON && HEDGE_OFF_TH < shortMinProfit) {
    return HEDGE_OFF;
  }

  return NONE;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

  double highestShort = 0;
  double lowestShort = 10000;
  double highestLong = 0;
  double lowestLong = 10000;

  int longMinProfit = 1000000;
  int shortMinProfit = 1000000;
  int hedgeTicket = NONE;
  int hedgeStatus = NONE;

  for(int i = 0; i < OrdersTotal(); i++) {  
    if(OrderSelect(i, SELECT_BY_POS)) {    
    
      if(OrderType() == OP_BUY) {
        if(OrderTakeProfit() == 0 || OrderStopLoss() == 0 || OrderLots() != MIN_LOT) {
          if(0 <= OrderProfit() + OrderCommission() + OrderSwap()) {
            bool closed = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
          }
        }
        else if(OrderLot() == HEDGE_LOT) {
          hedgeStatus = LONG_HEDGE_ON;
          hedgeTicket = OrderTicket();
	}
        else {
          if(OrderOpenPrice() < lowestLong) {
            lowestLong = OrderOpenPrice();
          }
          if(highestLong < OrderOpenPrice()) {
            highestLong = OrderOpenPrice();
          }

          if(OrderProfit() < longMinProfit) {
            longMinProfit = OrderProfit();
	  }
        }
      }
      else if(OrderType() == OP_SELL) {
        if(OrderTakeProfit() == 0 || OrderStopLoss() == 0 || OrderLots() != MIN_LOT) {
          if(0 <= OrderProfit() + OrderCommission() + OrderSwap()) {
            bool closed = OrderClose(OrderTicket(), OrderLots(), Ask, 0);
          }
        }
        else if(OrderLot() == HEDGE_LOT) {
          hedgeStatus = SHORT_HEDGE_ON;
          hedgeTicket = OrderTicket();
	}
        else {
          if(highestShort < OrderOpenPrice()) {
            highestShort = OrderOpenPrice();
          }
          if(OrderOpenPrice() < lowestShort) {
            lowestShort = OrderOpenPrice();
          }

          if(OrderProfit() < shortMinProfit) {
            shortMinProfit = OrderProfit();
	  }
        }
      }
    }
  }

  if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
    previousBid = Bid;
    previousAsk = Ask;
    return;
  }

  int nextHedge = hedgeControl(longMinProfit, shortMinProfit, hedgeStatus);
  if(nextHedge != NONE) {
    if(nextHedge == HEDGE_OFF && OrderSelect(hedgeTicket, SELECT_BY_Ticket)) {
      if(0 <= OrderProfit() + OrderCommission() + OrderSwap()) {
        if(hedgeStatus == SHORT_HEDGE_ON) {
            bool closed = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
          }
	}
        else if(hedgeStatus == LONG_HEDGE_ON) {
          bool closed = OrderClose(OrderTicket(), OrderLots(), Ask, 0);
	}
      }      
    }
    else if(nextHedge == SHORT_HEDGE_ON) {
      int ticket = OrderSend(Symbol(), OP_BUY, HEDGE_LOT, Ask, 0, Ask - HEDGE_SL, 0);      
    }
    else if(nextHedge == LONG_HEDGE_ON) {
      int ticket = OrderSend(Symbol(), OP_SELL, HEDGE_LOT, Bid, 0, Bid + HEDGE_SL, 0);      
    }    
  }

  if(previousBid < Bid) {
    if(Bid < lowestShort - NAMPIN_MARGIN || highestShort + NAMPIN_MARGIN < Bid) {
      int ticket = OrderSend(Symbol(), OP_SELL, MIN_LOT, Bid, 0, Bid + SL, Bid - TP);
    }
  }
  
  if(Ask < previousAsk) {
    if(Ask < lowestLong - NAMPIN_MARGIN || highestLong + NAMPIN_MARGIN < Ask ) {
      int ticket = OrderSend(Symbol(), OP_BUY, MIN_LOT, Ask, 0, Ask - SL, Ask + TP);
    }
  }

  previousBid = Bid;
  previousAsk = Ask;
}
