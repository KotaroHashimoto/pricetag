//+------------------------------------------------------------------+
//|                                                   Pyramiding.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define FXTF
//#define OANDA
//#define RAKUTEN

#define NONE (-1)

double minLot = NONE;
double priceMargin = NONE;
double stopLoss = NONE;


int TIMEFRAME = NONE;
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
  
  Print("stopLoss=", MarketInfo(Symbol(), MODE_STOPLEVEL) * Point);
  Print("ASK=", Ask);
  Print("BID=", Bid);
  
  minLot = MarketInfo(Symbol(), MODE_MINLOT);
  Print("minLot=", minLot);
  
  symbol = Symbol();
  
#ifdef FXTF
  if(!StringCompare(symbol, "USDJPY-cd"))
    ACCEPTABLE_SPREAD = 3;
  else if(!StringCompare(symbol, "EURUSD-cd"))
    ACCEPTABLE_SPREAD = 8;
  else if(!StringCompare(symbol, "EURJPY-cd"))
    ACCEPTABLE_SPREAD = 6;
    
  TIMEFRAME = PERIOD_M1;
  stopLoss = (double)MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
#endif
#ifdef RAKUTEN
  if(!StringCompare(symbol, "USDJPY"))
    ACCEPTABLE_SPREAD = 5;
  else if(!StringCompare(symbol, "EURUSD"))
    ACCEPTABLE_SPREAD = 6;
    
  TIMEFRAME = PERIOD_M15;    
#endif
#ifdef OANDA
  if(!StringCompare(symbol, "USDJPY"))
    ACCEPTABLE_SPREAD = 4;
  else if(!StringCompare(symbol, "EURUSD"))
    ACCEPTABLE_SPREAD = 5;

  TIMEFRAME = PERIOD_M5;
#endif

  priceMargin = (double)ACCEPTABLE_SPREAD * Point;
  Print("priceMargin=", priceMargin);
    
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

int currentDecision()
{
  double adx1 = iADX(Symbol(), TIMEFRAME, 14, PRICE_WEIGHTED, 0, 1);
  if(adx1 < 25.0) {
    return NONE;
  }

  double adx2 = iADX(Symbol(), TIMEFRAME, 14, PRICE_WEIGHTED, 0, 2);
  if(adx2 >= adx1) {
    return NONE;
  }
  
  double pDI = iADX(Symbol(), TIMEFRAME, 14, PRICE_WEIGHTED, 1, 1);
  double nDI = iADX(Symbol(), TIMEFRAME, 14, PRICE_WEIGHTED, 2, 1);
    
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

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

  int decision = currentDecision();
  bool overLap = False;
  
#ifdef FXTF
#else
  stopLoss = iATR(Symbol(), TIMEFRAME, 14, 1);
#endif

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS) && !StringCompare(OrderSymbol(), symbol)) {
      bool close = False;
      if(OrderType() == OP_BUY) {
        if(decision != OP_BUY)
          close = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
          
        if(!close && (OrderStopLoss() < Bid - stopLoss)) {
          bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - stopLoss, 0, 0);
        }
      }
      else if(OrderType() == OP_SELL) {
        if(decision != OP_SELL)
          close = OrderClose(OrderTicket(), OrderLots(), Ask, 0);

        if(!close && (Ask + stopLoss < OrderStopLoss())) {
          bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + stopLoss, 0, 0);
        }
      }
      
      if(!close && !overLap) {
        double openPrice = OrderOpenPrice();
        double price = (Ask + Bid) / 2.0;
        if(MathAbs(openPrice - price) < priceMargin) {
          overLap = True;
        }
      }
    }
  }
  
  if(decision == NONE) {
    return;
  }
/*
  if((DayOfWeek() == 5 && 18 < Hour()) || DayOfWeek() == 6) {
    Print("No entry on Friday night. Hour()=", Hour());
    position = NONE;
    return;
  }
*/
  if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
//    Print("No entry on wide spread: ", MarketInfo(Symbol(), MODE_SPREAD));
    return;
  }
  
  
  if(!overLap) {
    if(decision == OP_BUY) {
      int ticket = OrderSend(symbol, OP_BUY, minLot, Ask, 0, Bid - stopLoss, 0);
    }
    if(decision == OP_SELL) {
      int ticket = OrderSend(symbol, OP_SELL, minLot, Bid, 0, Ask + stopLoss, 0);
    }
  }
}
