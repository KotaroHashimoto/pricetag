//+------------------------------------------------------------------+
//|                                                  TakaKeimoto.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//#define FXTF
#define Rakuten
//#define Gaitame

define LOT (0.01)

double dailyEquity;
double dailyBalance;
bool newDay;

int ACCEPTABLE_SPREAD;

#define NONE (-1)

int crossCondition = NONE;
double ma125 = NONE;
double ma21_2 = NONE;
double ma21_1 = NONE;
double ma7_2 = NONE;
double ma7_1 = NONE;

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
  
  Print("minLot=", MarketInfo(Symbol(), MODE_MINLOT));
  Print("maxLot=", MarketInfo(Symbol(), MODE_MAXLOT));

  symbol = Symbol();
  dailyEquity = AccountEquity();
  dailyBalance = AccountBalance();
  newDay = True;

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
#endif
#ifdef Gaitame
  if(!StringCompare(symbol, "USDJPY")) {
    ACCEPTABLE_SPREAD = 4;
    EventSetTimer(300);
  }
  else if(!StringCompare(symbol, "EURUSD"))
    ACCEPTABLE_SPREAD = 4;
  else if(!StringCompare(symbol, "EURGBP"))
    ACCEPTABLE_SPREAD = 7;
  else if(!StringCompare(symbol, "EURJPY"))
    ACCEPTABLE_SPREAD = 5;
  else if(!StringCompare(symbol, "GBPUSD"))
    ACCEPTABLE_SPREAD = 12;
  else if(!StringCompare(symbol, "AUDJPY"))
    ACCEPTABLE_SPREAD = 5;

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

string sign(double v) {
  if(v < 0.0)
    return "";
  else
    return "+";
}

void OnTimer() {

  double equity = AccountEquity();
  double currentProfit = equity - dailyEquity;

  double balance = AccountBalance();
  double baseProfit = balance - dailyBalance;

  double p = AccountProfit();

  double margin;
  if(AccountMargin() == 0.0)
    margin = -1.0;
  else
    margin = (equity / AccountMargin()) * 100.0;

#ifdef FXTF
  string sbj = "FXTF:";
#endif
#ifdef Rakuten
  string sbj = "Rakuten:";
#endif
#ifdef Gaitame
  string sbj = "Gaitame:";
#endif

  double lots = 0.0;
  for(int i = 0; i < OrdersTotal(); i++)
    if(OrderSelect(i, SELECT_BY_POS))
      lots += OrderLots();

  string cp = sign(currentProfit) + DoubleToStr(currentProfit, 0);
  string bp = sign(baseProfit) + DoubleToStr(baseProfit, 0) + sign(p) + DoubleToStr(p, 0);
  string ot = DoubleToStr(lots * 10.0, 1);
  string eq = DoubleToStr(equity, 0);

#ifdef FXTF
  string us = "USDJPY-cd";
  string es = "EURJPY-cd";
  string gs = "GBPJPY-cd";
  string as = "AUDJPY-cd";
#else
  string us = "USDJPY";
  string es = "EURJPY";
  string gs = "GBPJPY";
  string as = "AUDJPY";
#endif
  string usdjpy = DoubleToStr((MarketInfo(us, MODE_ASK) + MarketInfo(us, MODE_BID)) / 2.0, 3);
  string eurjpy = DoubleToStr((MarketInfo(es, MODE_ASK) + MarketInfo(es, MODE_BID)) / 2.0, 3);
  string gbpjpy = DoubleToStr((MarketInfo(gs, MODE_ASK) + MarketInfo(gs, MODE_BID)) / 2.0, 3);
  string audjpy = DoubleToStr((MarketInfo(as, MODE_ASK) + MarketInfo(as, MODE_BID)) / 2.0, 3);

  bool mail = SendMail(sbj + cp + " (" + bp + ")", "Equity:" + eq + ", Lots:" + ot + ", Margin:" + DoubleToStr(margin, 2) + ", Profit:" + cp + " (" + bp + ")" + ", USDJPY:" + usdjpy + ", EURJPY:" + eurjpy + ", GBPJPY:" + gbpjpy + ", AUDJPY:" + audjpy);
}

int determineEntryCondition() {

  ma125 = iMA(NULL, PERIOD_CURRENT, 125, 0, MODE_SMA, PRICE_WEIGHTED, 1);
  ma21_1 = iMA(NULL, PERIOD_CURRENT, 21, 0, MODE_SMA, PRICE_WEIGHTED, 1);
  ma7_1 = iMA(NULL, PERIOD_CURRENT, 7, 0, MODE_SMA, PRICE_WEIGHTED, 1);
  ma21_2 = iMA(NULL, PERIOD_CURRENT, 21, 0, MODE_SMA, PRICE_WEIGHTED, 2);
  ma7_2 = iMA(NULL, PERIOD_CURRENT, 7, 0, MODE_SMA, PRICE_WEIGHTED, 2);


  if(ma7_2 < ma21_2 && ma21_1 < ma7_1)
    crossCondition = OP_BUY;
  else if(ma7_2 > ma21_2 && ma21_1 > ma7_1)
    crossCondition = OP_SELL;

  int m = getMajorTrend();

  if(crossCondition == OP_BUY) {
    if(ma21_2 < ma21_1 && ma21_1 < ma125)
      if(ma21_1 < iLow(NULL, PERIOD_CURRENT, 1) && m == OP_BUY)
        return OP_BUY;
  }
  else if(crossCondition == OP_SELL) {
    if(ma21_2 > ma21_1 && ma21_1 > ma125)
      if(ma21_1 > iHigh(NULL, PERIOD_CURRENT, 1) && m == OP_SELL)
        return OP_SELL;
  }

  else
    return NONE;
}

bool determineExitCondition(int ticket) {

  int orderType = NONE;
  double openPrice = NONE;
  double stopLoss = NONE;
  
  if(OrderSelect(ticket, SELECT_BY_TICKET)) {
    orderType = OrderType();
    openPrice = OrderOpenPrice();
    stopLoss = OrderStopLoss();
  }
  else
    return False;


  if(orderType == OP_BUY)
    if(stopLoss < ma125 && ma125 < iLow(NULL, PERIOD_CURRENT, 1))
      bool m = OrderModify(ticket, openPrice, ma125, 0, 0, Magenta)

  else if(orderType == OP_SELL)
    if(stopLoss > ma125 && ma125 > iHigh(NULL, PERIOD_CURRENT, 1))
      bool m = OrderModify(ticket, openPrice, ma125, 0, 0, Cyan)


  if(stopLoss == 0.0) {
    if(lossCut(orderType, openPrice))
      return True;
  }
  else {
    if(orderType == OP_BUY && crossCondition == OP_SELL)
      return True;
    else if(orderType == OP_SELL && crossCondition == OP_BUY)
      return True;
  }
  
  return False;
}

bool lossCut(int orderType, double openPrice) {

  if(orderType == OP_BUY && crossCondition == OP_SELL)
    if(ma21_1 > iHigh(NULL, PERIOD_CURRENT, 1))
      if(200.0 < (openPrice - Bid) / Point)
        return True;

  else if(orderType == OP_SELL && crossCondition == OP_BUY)
    if(ma21_1 < iLow(NULL, PERIOD_CURRENT, 1))
      if(200.0 < (Ask - openPrice) / Point)
        return True;

  else
    return False;
}


double closePrice(int orderType) {

  if(orderType == OP_BUY)
    return Bid;
  else if(orderType == OP_SELL)
    return Ask;

  else
    return 0.0;
}

int getMajorTrend() {

  int current = Period();
  int major = NONE;

  if(current == PERIOD_M1)
    major = PERIOD_M15;
  else if(current == PERIOD_M5)
    major = PERIOD_M30;
  else if(current == PERIOD_M15)
    major = PERIOD_H1;
  else if(current == PERIOD_M30)
    major = PERIOD_H4;
  else if(current == PERIOD_H1)
    major = PERIOD_D1;
  else if(current == PERIOD_H4)
    major = PERIOD_W1;
  else if(current == PERIOD_D1)
    major = PERIOD_MN1;

  ma125_1 = iMA(NULL, major, 125, 0, MODE_SMA, PRICE_WEIGHTED, 1);
  ma125_2 = iMA(NULL, major, 125, 0, MODE_SMA, PRICE_WEIGHTED, 2);  

  if(ma125_1 < ma125_2)
    return OP_BUY;
  else// if(ma125_1 > ma125_2)
    return OP_SELL;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  if(0 == Hour() && !newDay) {
    dailyEquity = AccountEquity();
    dailyBalance = AccountBalance();
    newDay = True;
  }
  else if(23 == Hour() && newDay) {
    newDay = False;
  }

  if(ACCEPTABLE_SPREAD < MarketInfo(symbol, MODE_SPREAD))
    return;

  int c = determineEntryCondition();
      
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS))
      if(!StringCompare(OrderSymbol(), symbol))
        if(determineExitCondition(OrderTicket())
          bool c = OrderClose(OrderTicket(), OrderLots(), closePrice(OrderType()), 0, Green)
  }

  if(OrdersTotal == 0) {
    if(c == OP_BUY) {
      int ticket = OrderSend(symbol, OP_BUY, LOT, Ask, 0, 0, 0, NULL, 0, 0, Red);
    }
    else if(c == OP_SELL) {
      int ticket = OrderSend(symbol, OP_SELL, LOT, Bid, 0, 0, 0, NULL, 0, 0, Blue);
    }
  }

}
