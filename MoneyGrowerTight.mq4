//+------------------------------------------------------------------+
//|                                             MoneyGrowerTight.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define FXTF
//#define OANDA
//#deinfe RAKUTEN

#define NONE (-1)
int position = NONE;
int ticket = NONE;
double stopLoss = NONE;
double lotSizeFactor = NONE;
double MAX_LOT = NONE;

#define ACCEPTABLE_LOSS (0.01)

#define C (0.01)
//#define C (1) //for XM back test
#define IND_PERIOD (3)

int ACCEPTABLE_SPREAD = NONE;
string symbol;

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
  
  stopLoss = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
  Print("stopLoss=", stopLoss);
  Print("ASK=", Ask);
  Print("BID=", Bid);
  
  MAX_LOT = MarketInfo(Symbol(), MODE_MAXLOT);
  Print("MAX_LOT=", MAX_LOT);
  
  lotSizeFactor = C * ACCEPTABLE_LOSS / 100.0;
  Print("lotSizeFactor=", lotSizeFactor);
  Print("Initial Lot=", MathFloor(100.0 * AccountEquity() * lotSizeFactor) / 100.0);
  
  symbol = Symbol();
  
#ifdef FXTF
  if(!StringCompare(symbol, "USDJPY-cd"))
    ACCEPTABLE_SPREAD = 3;
  else if(!StringCompare(symbol, "EURUSD-cd"))
    ACCEPTABLE_SPREAD = 8;
  else if(!StringCompare(symbol, "EURJPY-cd"))
    ACCEPTABLE_SPREAD = 6;
#endif
#ifdef RAKUTEN
  if(!StringCompare(symbol, "USDJPY"))
    ACCEPTABLE_SPREAD = 5;
  else if(!StringCompare(symbol, "EURUSD"))
    ACCEPTABLE_SPREAD = 6;
#endif
#ifdef OANDA
  if(!StringCompare(symbol, "USDJPY"))
    ACCEPTABLE_SPREAD = 4;
  else if(!StringCompare(symbol, "EURUSD"))
    ACCEPTABLE_SPREAD = 5;
#endif

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
  if(0 < MarketInfo(Symbol(), MODE_STOPLEVEL)) {
    stopLoss = Point * MarketInfo(Symbol(), MODE_STOPLEVEL);
  }
  else {
    stopLoss = iATR(Symbol(), PERIOD_M15, IND_PERIOD - 1, 1);

#ifdef OANDA
    stopLoss = stopLoss / 4.0;
#endif
#ifdef RAKUTEN
    stopLoss = stopLoss / 3.0;
#endif
  }

  bool isOpen = false;
  double gain = 0.0;
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      gain = gain + OrderProfit() + OrderSwap() + OrderCommission();
      if(!StringCompare(OrderSymbol(), symbol)) {
        isOpen = true;
      }
    }
  }
  
  if(1000 < gain) {
    for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS)) {
        if(OrderType() == OP_BUY)
          bool close = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
        else if(OrderType() == OP_SELL)
          bool close = OrderClose(OrderTicket(), OrderLots(), Ask, 0);
      }
    }
  }

  if(!isOpen) {/*
    if((DayOfWeek() == 5 && 18 < Hour()) || DayOfWeek() == 6) {
//      Print("No entry on Friday night. Hour()=", Hour());
      position = NONE;
      return;
    }
    else if(atr < stopLoss) {
//      Print("No entry on low volatility. ATR(M15, 3)=", atr);
      position = NONE;
      return;
    }*/
    if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
//      Print("No entry on wide spread: ", MarketInfo(Symbol(), MODE_SPREAD));
      position = NONE;
      return;
    }
/*
    double lotSize = MathFloor(100.0 * AccountEquity() * lotSizeFactor) / 100.0;
    if(MAX_LOT < lotSize) {
      lotSize = MAX_LOT;
    }*/
    double lotSize = 1.0;
    
    position = nextPosition(position);
    if(position == OP_BUY) {
      ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 0, Bid - stopLoss, 0);
    }
    else if(position == OP_SELL) {
      ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 0, Ask + stopLoss, 0); 
    }
    else {
      Print("Something Wrong with nextPositon() !!");
      Print("LastError=", GetLastError());
    }
    
    if(ticket == NONE) {
      position = NONE;
//      Print("OrderSend() failed. LastError=", GetLastError());
    }
  }
  
  else if(OrderSelect(ticket, SELECT_BY_TICKET) == True) {      

    if(OrderType() == OP_BUY) {       
      if(OrderStopLoss() < Bid - stopLoss) {
        bool modified = OrderModify(ticket, OrderOpenPrice(), Bid - stopLoss, 0, 0);
      }
    }
    else if(OrderType() == OP_SELL) {
      if(Ask + stopLoss < OrderStopLoss()) {
        bool modified = OrderModify(ticket, OrderOpenPrice(), Ask + stopLoss, 0, 0);
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
