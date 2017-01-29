//+------------------------------------------------------------------+
//|                                                      Harvest.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define FXTF
//#define RAKUTEN

double minLot;
double stopLoss;
double priceMargin;
double minSL;

bool isOpening;
double lastEquity;
double closeProfit;

double TRAILPROFIT;
#define THREASH (0.7)
#define NM (-1000000.0)

int ACCEPTABLE_SPREAD;
string symbol;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  //---
  Print("AccountMargin=", AccountMargin());
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
  lastEquity = AccountEquity();
  closeProfit = NM;
  
#ifdef FXTF
  if(!StringCompare(symbol, "USDJPY-cd"))
    ACCEPTABLE_SPREAD = 3;
  else if(!StringCompare(symbol, "EURUSD-cd"))
    ACCEPTABLE_SPREAD = 8;
  else if(!StringCompare(symbol, "EURJPY-cd"))
    ACCEPTABLE_SPREAD = 6;
  else if(!StringCompare(symbol, "GBPUSD-cd"))
    ACCEPTABLE_SPREAD = 11;
  else if(!StringCompare(symbol, "AUDJPY-cd"))
    ACCEPTABLE_SPREAD = 14;
  else if(!StringCompare(symbol, "EURGBP-cd"))
    ACCEPTABLE_SPREAD = 16;
// total = 58

//  stopLoss = (double)MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
  TRAILPROFIT = 10000.0;
#endif
#ifdef RAKUTEN
  if(!StringCompare(symbol, "USDJPY"))
    ACCEPTABLE_SPREAD = 5;
  else if(!StringCompare(symbol, "EURUSD"))
    ACCEPTABLE_SPREAD = 6;
  else if(!StringCompare(symbol, "EURGBP"))
    ACCEPTABLE_SPREAD = 10;
  else if(!StringCompare(symbol, "EURJPY"))
    ACCEPTABLE_SPREAD = 11;
  else if(!StringCompare(symbol, "GBPUSD"))
    ACCEPTABLE_SPREAD = 12;
  else if(!StringCompare(symbol, "AUDJPY"))
    ACCEPTABLE_SPREAD = 12;
// total = 56

//  stopLoss = (double)(ACCEPTABLE_SPREAD + 1) * Point;
  TRAILPROFIT = 10000.0;
#endif

  priceMargin = (double)ACCEPTABLE_SPREAD * Point;
  Print("priceMargin=", priceMargin);
  
  minSL = (double)MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
  
#ifdef FXTF
  if(!StringCompare(symbol, "USDJPY-cd"))
#endif
#ifdef RAKUTEN
  if(!StringCompare(symbol, "USDJPY"))
#endif
    EventSetTimer(600);

  //---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
#ifdef FXTF
  if(!StringCompare(symbol, "USDJPY-cd"))
#endif
#ifdef RAKUTEN
  if(!StringCompare(symbol, "USDJPY"))
#endif
    EventKillTimer();
  //---   
}

void OnTimer() {
  if(0 < DayOfWeek() && DayOfWeek() < 6) {
  
    double currentProfit = AccountEquity() - lastEquity;
    
    double equity = AccountEquity();
    int margin;
    if(AccountMargin() == 0.0)
      margin = -1;
    else
      margin = (int)((equity / AccountMargin()) * 100.0);

#ifdef FXTF
    bool mail = SendMail("FXTF: " + DoubleToStr(currentProfit, 0), "profit:" + DoubleToStr(currentProfit) + "    positions:" + IntegerToString(OrdersTotal()) + "    margin: " + DoubleToStr(margin) + "    equity:" + DoubleToStr(equity));
#endif
#ifdef RAKUTEN
    bool mail = SendMail("RAKUTEN: " + DoubleToStr(currentProfit, 0), "profit:" + DoubleToStr(currentProfit) + "    positions:" + IntegerToString(OrdersTotal()) + "    margin: " + DoubleToStr(margin) + "    equity:" + DoubleToStr(equity));
#endif
  }
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD))
    return;

  double currentProfit = AccountEquity() - lastEquity;
  if(closeProfit == NM) {
    if(TRAILPROFIT < currentProfit) {
      closeProfit = currentProfit * THREASH;
      
#ifdef FXTF
      if(!StringCompare(symbol, "USDJPY-cd"))
        bool mail = SendMail("FXTF Tail ON: " + DoubleToStr(currentProfit, 0), "profit:" + DoubleToStr(currentProfit) + "    positions:" + IntegerToString(OrdersTotal()) + "    equity:" + DoubleToStr(AccountEquity()));
#endif
#ifdef RAKUTEN
      if(!StringCompare(symbol, "USDJPY"))
        bool mail = SendMail("RAKUTEN Tail ON: " + DoubleToStr(currentProfit, 0), "profit:" + DoubleToStr(currentProfit) + "    positions:" + IntegerToString(OrdersTotal()) + "    equity:" + DoubleToStr(AccountEquity()));
#endif
    }
  }
  else {
    if(closeProfit < currentProfit * THREASH) {
      closeProfit = currentProfit * THREASH;
    }
  }
  
  isOpening = (closeProfit < currentProfit);
  if(!isOpening && OrdersTotal() == 0) {
    closeProfit = NM;
    lastEquity = AccountEquity();
    
#ifdef FXTF
    if(!StringCompare(symbol, "USDJPY-cd"))
      bool mail = SendMail("FXTF Tail OFF: " + DoubleToStr(currentProfit, 0), "profit:" + DoubleToStr(currentProfit) + "    equity:" + DoubleToStr(AccountEquity()));
#endif
#ifdef RAKUTEN
    if(!StringCompare(symbol, "USDJPY"))
      bool mail = SendMail("RAKUTEN Tail OFF: " + DoubleToStr(currentProfit, 0), "profit:" + DoubleToStr(currentProfit) + "    equity:" + DoubleToStr(AccountEquity()));
#endif
  }
#ifdef FXTF
  else if(!StringCompare(symbol, "USDJPY-cd")){
#endif
#ifdef RAKUTEN
  else if(!StringCompare(symbol, "USDJPY")){
#endif
    double equity = AccountEquity();
    int margin;
    if(AccountMargin() == 0.0)
      margin = -1;
    else
      margin = (int)((AccountEquity() / AccountMargin()) * 100.0);
    
    if(isOpening)
      Print("trail = ", closeProfit, ", profit = ", currentProfit, ", margin = ", margin, ", equity = ", (int)equity, ", opening...");
    else
      Print("trail = ", closeProfit, ", profit = ", currentProfit, ", margin = ", margin, ", equity = ", (int)equity, ", closing...");
  }


#ifdef FXTF
  stopLoss = iATR(symbol, PERIOD_M5, 14, 0);
#endif
#ifdef RAKUTEN
  stopLoss = iATR(symbol, PERIOD_M15, 14, 0);
#endif

  bool overLapLong = False;
  bool overLapShort = False;
  double price = (Ask + Bid) / 2.0;
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS) && !StringCompare(OrderSymbol(), symbol)) {
      double openPrice = OrderOpenPrice();
      
      if(OrderType() == OP_BUY) {      
        if(!isOpening || openPrice - Ask < stopLoss)
          bool closed = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
        else if(MathAbs(openPrice - price) < priceMargin && !overLapLong) {
          overLapLong = True;
        }
      }
      else if(OrderType() == OP_SELL) {
        if(!isOpening || Bid - openPrice < stopLoss)
          bool closed = OrderClose(OrderTicket(), OrderLots(), Ask, 0);
        else if(MathAbs(openPrice - price) < priceMargin && !overLapShort) {
          overLapShort = True;
        }
      }      
    }
  }
  
  if(!isOpening)
    return;
 
  if(!overLapLong) {
    int ticket = OrderSend(symbol, OP_BUY, minLot, Ask, 0, 0, 0);
  }
  if(!overLapShort) {
    int ticket = OrderSend(symbol, OP_SELL, minLot, Bid, 0, 0, 0);
  }
}
