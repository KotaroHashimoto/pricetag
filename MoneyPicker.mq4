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
int position = NONE;
int ticket = NONE;
double stopLoss = NONE;
double lotSizeFactor = NONE;
double MAX_LOT = NONE;
double stopPrice = NONE;

#define ACCEPTABLE_LOSS (0.01)

//#define C (0.01)
#define C (1) //for XM back test

//#define ACCEPTABLE_SPREAD (4) //for OANDA
#define ACCEPTABLE_SPREAD (3) //for FXTF1000

#define IND_PERIOD (3)

extern int STOP_LOSS = 1;

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
  MAX_LOT = 2.0;
  Print("MAX_LOT=", MAX_LOT);
  
  lotSizeFactor = C * ACCEPTABLE_LOSS / STOP_LOSS;
  Print("lotSizeFactor=", lotSizeFactor);
  Print("Initial Lot=", MathFloor(100.0 * AccountEquity() * lotSizeFactor) / 100.0);
  
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

int nextPosition(int current)
{
  if(current == NONE) {
  
    double pDI = iADX(Symbol(), PERIOD_M1, IND_PERIOD, PRICE_WEIGHTED, 1, 0);
    double nDI = iADX(Symbol(), PERIOD_M1, IND_PERIOD, PRICE_WEIGHTED, 2, 0);
//    Print("+DI(M15, 3)=", pDI);
//    Print("-DI(M15, 3)=", nDI);
    
    if(nDI < pDI) {
      return OP_BUY;
    }
    else if(pDI < nDI) {
      return OP_SELL;
    }
    else {
      return NONE;
    }
  }
  else {
    if(current == OP_BUY) {
      return OP_SELL;
    }
    else if(current == OP_SELL) {
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
//      Print("No entry on Friday night. Hour()=", Hour());
      position = NONE;
      return;
    }
    else if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
//      Print("No entry on wide spread: ", MarketInfo(Symbol(), MODE_SPREAD));
      position = NONE;
      return;
    }

    double lotSize = MathFloor(100.0 * AccountEquity() * lotSizeFactor) / 100.0;
    if(MAX_LOT < lotSize) {
      lotSize = MAX_LOT;
    }
    
    position = nextPosition(position);
    if(position == OP_BUY) {
      ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 0, 0, 0, NULL, 0, 0, NONE);
      stopPrice = Bid - stopLoss;
    }
    else if(position == OP_SELL) {
      ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 0, 0, 0, NULL, 0, 0, NONE); 
      stopPrice = Ask + stopLoss;
    }
    else {
      Print("Something Wrong with nextPositon() !!");
      Print("LastError=", GetLastError());
    }
    
    if(ticket == NONE) {
      position = NONE;
      stopPrice = NONE;
//      Print("OrderSend() failed. LastError=", GetLastError());
    }
  }
  
  else if(OrderSelect(ticket, SELECT_BY_TICKET) == True) {      

    if(OrderType() == OP_BUY) { /*
      if(stopPrice < Bid - stopLoss) {
        stopPrice = Bid - stopLoss;
      }
      else if(Bid < stopPrice) {
        if(OrderClose(ticket, OrderLots(), Bid, 100, NONE)) {
          ticket = NONE;
        }
      } */
      if(OrderOpenPrice() < Bid) {
        if(OrderClose(ticket, OrderLots(), Bid, 0, NONE)) {
          ticket = NONE;
        }
      }

    }
    else if(OrderType() == OP_SELL) { /*
      if(Ask + stopLoss < stopPrice) {
        stopPrice = Ask + stopLoss;
      }
      else if(stopPrice < Ask) {
        if(OrderClose(ticket, OrderLots(), Ask, 100, NONE)) {
          ticket = NONE;
        }
      } */
      if(Ask < OrderOpenPrice()) {
        if(OrderClose(ticket, OrderLots(), Ask, 0, NONE)) {
          ticket = NONE;
        }
      }
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
