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
//#define Rakuten
//#define ICMarkets

#define THREASH (0.7)
#define NM (-1000000.0)
#define MAXPOS (256)

double minLot;
double stopLoss;
double priceMargin;

bool isOpening;
double lastEquity;
double closeProfit;
double trailProfit;

int ACCEPTABLE_SPREAD;

string symbol;

#ifdef ICMarkets
double audjpy;
#endif

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
  if(!StringCompare(symbol, "USDJPY-cd")) {
    ACCEPTABLE_SPREAD = 3;
    EventSetTimer(300);
  }
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

  trailProfit = 10000.0;
#endif
#ifdef Rakuten
  if(!StringCompare(symbol, "USDJPY")) {
    ACCEPTABLE_SPREAD = 5;
    EventSetTimer(300);
  }
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

  trailProfit = 10000.0;
#endif
#ifdef ICMarkets
  if(!StringCompare(symbol, "USDJPY")) {
    ACCEPTABLE_SPREAD = 4;
    EventSetTimer(300);
  }
  else if(!StringCompare(symbol, "EURUSD"))
    ACCEPTABLE_SPREAD = 1;
  else if(!StringCompare(symbol, "EURGBP"))
    ACCEPTABLE_SPREAD = 7;
  else if(!StringCompare(symbol, "EURJPY"))
    ACCEPTABLE_SPREAD = 5;
  else if(!StringCompare(symbol, "GBPUSD"))
    ACCEPTABLE_SPREAD = 7;
  else if(!StringCompare(symbol, "AUDJPY"))
    ACCEPTABLE_SPREAD = 5;

//  stopLoss = (double)(ACCEPTABLE_SPREAD + 1) * Point;
  audjpy = (MarketInfo("AUDJPY", MODE_BID) + MarketInfo("AUDJPY", MODE_ASK)) / 2.0;
  trailProfit = 10000.0 / audjpy;
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
#ifdef FXTF
  if(!StringCompare(symbol, "USDJPY-cd"))
#else
  if(!StringCompare(symbol, "USDJPY"))
#endif
    EventKillTimer();
  //---   
}

void OnTimer() {

  double currentProfit = AccountEquity() - lastEquity;
    
  double equity = AccountEquity();
  double margin;
  if(AccountMargin() == 0.0)
    margin = -1.0;
  else
    margin = (equity / AccountMargin()) * 100.0;

#ifdef FXTF
  bool mail = SendMail("FXTF: " + DoubleToStr(currentProfit, 0), "profit:" + DoubleToStr(currentProfit) + "    positions:" + IntegerToString(OrdersTotal()) + "    margin: " + DoubleToStr(margin) + "    equity:" + DoubleToStr(equity) + "    trailProfit:" + DoubleToStr(closeProfit));
#endif
#ifdef Rakuten
  bool mail = SendMail("Rakuten: " + DoubleToStr(currentProfit, 0), "profit:" + DoubleToStr(currentProfit) + "    positions:" + IntegerToString(OrdersTotal()) + "    margin: " + DoubleToStr(margin) + "    equity:" + DoubleToStr(equity) + "    trailProfit:" + DoubleToStr(closeProfit));
#endif
#ifdef ICMarkets
  audjpy = (MarketInfo("AUDJPY", MODE_BID) + MarketInfo("AUDJPY", MODE_ASK)) / 2.0;
  trailProfit = 10000.0 / audjpy;

  bool mail = SendMail("ICMarkets: " + DoubleToStr(currentProfit * audjpy, 0), "profit:" + DoubleToStr(currentProfit * audjpy) + "    positions:" + IntegerToString(OrdersTotal()) + "    margin: " + DoubleToStr(margin) + "    equity:" + DoubleToStr(equity * audjpy) + "    trailProfit:" + DoubleToStr(closeProfit * audjpy));
#endif
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  if(ACCEPTABLE_SPREAD < MarketInfo(symbol, MODE_SPREAD))
    return;

#ifdef ICMarkets
  audjpy = (MarketInfo("AUDJPY", MODE_BID) + MarketInfo("AUDJPY", MODE_ASK)) / 2.0;
  trailProfit = 10000.0 / audjpy;
#endif

  double currentProfit = AccountEquity() - lastEquity;
  if(closeProfit == NM) {
    if(trailProfit < currentProfit) {
      closeProfit = currentProfit * THREASH;
      
#ifdef FXTF
      if(!StringCompare(symbol, "USDJPY-cd"))
        bool mail = SendMail("FXTF Trail ON: " + DoubleToStr(currentProfit, 0), "profit:" + DoubleToStr(currentProfit) + "    positions:" + IntegerToString(OrdersTotal()) + "    equity:" + DoubleToStr(AccountEquity()) + "    trailProfit:" + DoubleToStr(closeProfit));
#endif
#ifdef Rakuten
      if(!StringCompare(symbol, "USDJPY"))
        bool mail = SendMail("Rakuten Trail ON: " + DoubleToStr(currentProfit, 0), "profit:" + DoubleToStr(currentProfit) + "    positions:" + IntegerToString(OrdersTotal()) + "    equity:" + DoubleToStr(AccountEquity()) + "    trailProfit:" + DoubleToStr(closeProfit);
#endif
#ifdef ICMarkets
      if(!StringCompare(symbol, "USDJPY"))
        bool mail = SendMail("ICMarkets Trail ON: " + DoubleToStr(currentProfit * audjpy, 0), "profit:" + DoubleToStr(currentProfit * audjpy) + "    positions:" + IntegerToString(OrdersTotal()) + "    equity:" + DoubleToStr(AccountEquity() * audjpy) + "    trailProfit:" + DoubleToStr(closeProfit * audjpy);
#endif
    }
  }
  else {
    if(closeProfit < currentProfit * THREASH) {
      closeProfit = currentProfit * THREASH;
    }
  }
  
  isOpening = (closeProfit < currentProfit);
  if(!isOpening && 0 == OrdersTotal()) {
    closeProfit = NM;
    lastEquity = AccountEquity();
    
#ifdef FXTF
    if(!StringCompare(symbol, "USDJPY-cd"))
      bool mail = SendMail("FXTF Trail OFF: " + DoubleToStr(currentProfit, 0), "profit:" + DoubleToStr(currentProfit) + "    equity:" + DoubleToStr(AccountEquity()) + "    trailProfit:" + DoubleToStr(closeProfit));
#endif
#ifdef Rakuten
    if(!StringCompare(symbol, "USDJPY"))
      bool mail = SendMail("Rakuten Trail OFF: " + DoubleToStr(currentProfit, 0), "profit:" + DoubleToStr(currentProfit) + "    equity:" + DoubleToStr(AccountEquity()) + "    trailProfit:" + DoubleToStr(closeProfit));
#endif
#ifdef ICMarkets
    if(!StringCompare(symbol, "USDJPY"))
      bool mail = SendMail("ICMarkets Trail OFF: " + DoubleToStr(currentProfit * audjpy, 0), "profit:" + DoubleToStr(currentProfit * audjpy) + "    equity:" + DoubleToStr(AccountEquity() * audjpy) + "    trailProfit:" + DoubleToStr(closeProfit * audjpy));
#endif

    Sleep(10000);
  }
#ifdef FXTF
  else if(!StringCompare(symbol, "USDJPY-cd")){
#else
  else if(!StringCompare(symbol, "USDJPY")){
#endif
    double equity = AccountEquity();
    int margin;
    if(AccountMargin() == 0.0)
      margin = -1;
    else
      margin = (int)((AccountEquity() / AccountMargin()) * 100.0);
    
    if(!isOpening)
#ifdef ICMarkets
      Print("trail = ", closeProfit * audjpy, ", profit = ", currentProfit * audjpy, ", margin = ", margin, ", equity = ", (int)(equity * audjpy), ", closing...");
#else
      Print("trail = ", closeProfit, ", profit = ", currentProfit, ", margin = ", margin, ", equity = ", (int)equity, ", closing...");
#endif
//    else
//      Print("trail = ", closeProfit, ", profit = ", currentProfit, ", margin = ", margin, ", equity = ", (int)equity, ", opening...");
  }

#ifdef FXTF
  stopLoss = iATR(symbol, PERIOD_M5, 14, 0);
#endif
#ifdef Rakuten
  stopLoss = iATR(symbol, PERIOD_M15, 14, 0);
#endif
#ifdef ICMarkets
  stopLoss = iATR(symbol, PERIOD_M30, 14, 0);
#endif

  int mostProfitableTicket = NM;
  double largestProfit = NM;

  bool overLapLong = False;
  bool overLapShort = False;
  double price = (Ask + Bid) / 2.0;
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), symbol)) {
        double openPrice = OrderOpenPrice();

        if(OrderType() == OP_BUY) {      
          if(!isOpening || stopLoss < openPrice - Ask) {
            if(OrderClose(OrderTicket(), OrderLots(), Bid, 0))
              continue;
	  }
          else if(MathAbs(openPrice - price) < priceMargin && !overLapLong) {
            overLapLong = True;
          }
        }
        else if(OrderType() == OP_SELL) {
          if(!isOpening || stopLoss < Bid - openPrice) {
            if(OrderClose(OrderTicket(), OrderLots(), Ask, 0))
              continue;
	  }
          else if(MathAbs(openPrice - price) < priceMargin && !overLapShort) {
            overLapShort = True;
          }
        }
      }

      double pt = OrderProfit() + OrderCommission() + OrderSwap();
      if(largestProfit < pt) {
        largestProfit = pt;
        mostProfitableTicket = OrderTicket();
      }
    }
  }
  
  if(!isOpening) {
    return;
  }
  else if(MAXPOS < OrdersTotal()) {
    OrderSelect(mostProfitableTicket, SELECT_BY_TICKET);
    if(OrderType() == OP_BUY)
      bool closed = OrderClose(mostProfitableTicket, OrderLots(), Bid, symbol);
    else if(OrderType() == OP_SELL)
      bool closed = OrderClose(mostProfitableTicket, OrderLots(), Ask, symbol);
  }
  else {
    if(!overLapLong) {
      int ticket = OrderSend(symbol, OP_BUY, minLot, Ask, 0, 0, 0);
    }
    if(!overLapShort) {
      int ticket = OrderSend(symbol, OP_SELL, minLot, Bid, 0, 0, 0);
    }
  }
}
