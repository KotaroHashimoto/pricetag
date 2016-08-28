//+------------------------------------------------------------------+
//|                                     iMoneyGrowerWithTrailing.mq4 |
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
double sl = NONE;
double tp = NONE;
double lotSizeFactor = NONE;
double MAX_LOT = NONE;

bool trailMode = False;
double trailMargin = NONE;

#define ACCEPTABLE_LOSS (0.01)

//#define C (0.01)
#define C (1)

//#define ACCEPTABLE_SPREAD (4) //for OANDA
//#define ACCEPTABLE_SPREAD (3) //for FXTF1000
#define ACCEPTABLE_SPREAD (5) //for ICMarket

#define IND_PERIOD (3)

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
  
    double pDI = iADX(Symbol(), PERIOD_M15, IND_PERIOD, PRICE_WEIGHTED, 1, 0);
    double nDI = iADX(Symbol(), PERIOD_M15, IND_PERIOD, PRICE_WEIGHTED, 2, 0);
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
  double atr = iATR(Symbol(), PERIOD_M15, IND_PERIOD - 1, 1);
  
  if(atr < Point * MarketInfo(Symbol(), MODE_STOPLEVEL)) {
    stopLoss = Point * MarketInfo(Symbol(), MODE_STOPLEVEL);
  }
  else if(Point * STOP_LOSS < atr) {
    stopLoss = Point * STOP_LOSS;
  }
  else {
    stopLoss = atr;
  }

  if(OrdersTotal() == 0) {
    if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
//      Print("No entry on wide spread: ", MarketInfo(Symbol(), MODE_SPREAD));
//      position = NONE;
      return;
    }/*
    else if((DayOfWeek() == 5 && 18 < Hour()) || DayOfWeek() == 6) {
//      Print("No entry on Friday night. Hour()=", Hour());
      position = NONE;
      return;
    }
    else if(atr < stopLoss) {
//      Print("No entry on low volatility. ATR(M15, 3)=", atr);
      position = NONE;
      return;
    }*/

    double lotSize = MathFloor(100.0 * AccountEquity() * lotSizeFactor) / 100.0;
    if(MAX_LOT < lotSize) {
      lotSize = MAX_LOT;
    }

    position = nextPosition(position);
    if(position == OP_BUY) {
      sl = Bid - stopLoss;
      tp = Bid + stopLoss;
      ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, sl, tp, DoubleToString(atr), 0, 0, Red);
    }
    else if(position == OP_SELL) {
      sl = Ask + stopLoss;
      tp = Ask - stopLoss;
      ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, sl, tp, DoubleToString(atr), 0, 0, Blue); 
    }
    else {
      Print("Something Wrong with nextPositon() !!");
      Print("LastError=", GetLastError());
    }
    
    trailMode = False;
    trailMargin = stopLoss / 4.0;
    
    if(ticket == NONE) {
//      position = NONE;
//      Print("OrderSend() failed. LastError=", GetLastError());
    }
  }
  
  else if(OrderSelect(ticket, SELECT_BY_TICKET) == True) {      

    if(OrderType() == OP_BUY) {       
      if(!trailMode) {
        if(Bid + stopLoss < OrderTakeProfit()) {
          tp = Bid + stopLoss;
//      if(2 * Bid - sl < OrderTakeProfit()) {
//        tp = 2 * Bid - sl;
          bool modified = OrderModify(ticket, OrderOpenPrice(), sl, tp, 0, Red);
        }
        else if(OrderOpenPrice() + stopLoss - trailMargin < Bid) {
          trailMode = True;
          bool modified = OrderModify(ticket, OrderOpenPrice(), Bid - trailMargin, 0, 0, Red);
        }
      }
      else {
        if(OrderStopLoss() < Bid - trailMargin) {
          bool modified = OrderModify(ticket, OrderOpenPrice(), Bid - trailMargin, 0, 0, Red);
        }
      }
    }
    else if(OrderType() == OP_SELL) {
      if(!trailMode) {
        if(OrderTakeProfit() < Ask - stopLoss) {
          tp = Ask - stopLoss;
//      if(OrderTakeProfit() < 2 * Ask - sl) {
//         tp = 2 * Ask - sl;
          bool modified = OrderModify(ticket, OrderOpenPrice(), sl, tp, 0, Blue);
        }
        else if(Ask < OrderOpenPrice() - stopLoss + trailMargin) {
          trailMode = True;
          bool modified = OrderModify(ticket, OrderOpenPrice(), Ask + trailMargin, 0, 0, Blue);
        }
      }
      else {
        if(Ask + trailMargin < OrderStopLoss()) {
          bool modified = OrderModify(ticket, OrderOpenPrice(), Ask + trailMargin, 0, 0, Blue);
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
