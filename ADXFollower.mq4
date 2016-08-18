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
int direction = NONE;
int ticket = NONE;
double stopLoss = NONE;
double lotSizeFactor = NONE;
double MAX_LOT = NONE;

#define ACCEPTABLE_LOSS (0.01)

//#define C (0.01)
#define C (0.01) //for XM back test

#define ACCEPTABLE_SPREAD (4) //for OANDA
//#define ACCEPTABLE_SPREAD (3) //for FXTF1000

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

int getDirection()
{
  double adx = iADX(Symbol(), PERIOD_M1, IND_PERIOD, PRICE_MEDIAN, 0, 0);
  double pDI = iADX(Symbol(), PERIOD_M1, IND_PERIOD, PRICE_MEDIAN, 1, 0);
  double nDI = iADX(Symbol(), PERIOD_M1, IND_PERIOD, PRICE_MEDIAN, 2, 0);
//  Print("ADX(M1, 3)=", adx);
//  Print("+DI(M1, 3)=", pDI);
//  Print("-DI(M1, 3)=", nDI);
 
  if(adx < 50.0) {
    return NONE;
  }
  else if(nDI < pDI) {
    return OP_BUY;
  }
  else if(pDI < nDI) {
    return OP_SELL;
  }
  else {
    return NONE;
  }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{  
  direction = getDirection();

  if(OrdersTotal() == 0) {
    if((DayOfWeek() == 5 && 22 < Hour()) || DayOfWeek() == 6) {
//      Print("No entry on Friday night. Hour()=", Hour());
      return;
    }
    else if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
//      Print("No entry on wide spread: ", MarketInfo(Symbol(), MODE_SPREAD));
      return;
    }

    double lotSize = MathFloor(100.0 * AccountEquity() * lotSizeFactor) / 100.0;
    if(MAX_LOT < lotSize) {
      lotSize = MAX_LOT;
    }
    
    if(direction == OP_BUY) {
      ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, Ask - stopLoss, 0, NULL, 0, 0, Red);
    }
    else if(direction == OP_SELL) {
      ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, Bid + stopLoss, 0, NULL, 0, 0, Blue); 
    }
    
    if(ticket == NONE) {
//      Print("OrderSend() failed. LastError=", GetLastError());
    }
  }
  
  else if(OrderSelect(ticket, SELECT_BY_TICKET) == True) {      

    if(OrderType() == OP_BUY && direction != OP_BUY) {
      if(OrderClose(ticket, OrderLots(), Bid, 0, Cyan)) {
        ticket = NONE;
      }
    }
    else if(OrderType() == OP_SELL && direction != OP_SELL) {
      if(OrderClose(ticket, OrderLots(), Ask, 0, Magenta)) {
        ticket = NONE;
      }
    }
  }

  else {
    Print("Something Wrong with OrderSelect(ticket, SELECT_BY_TICKET), ticket=", ticket);
    Print("LastError=", GetLastError());
  }
}
