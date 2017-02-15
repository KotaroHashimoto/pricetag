//+------------------------------------------------------------------+
//|                                                   AutoNampin.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define FXTF
//#define Rakuten
//#define Gaitame

#ifdef Rakuten
#define MAXPOS (256)
#endif

#ifdef FXTF
#define MAXPOS (512)
#endif

#ifdef Gaitame
#define MAXPOS (1024)
#endif

double minLot;
double stopLoss;
double priceMargin;

double dailyEquity;
double dailyBalance;
bool newDay;

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

  string cp = sign(currentProfit) + DoubleToStr(currentProfit, 0);
  string bp = sign(baseProfit) + DoubleToStr(baseProfit, 0) + sign(p) + DoubleToStr(p, 0);
  string ot = IntegerToString(OrdersTotal());
  string eq = DoubleToStr(equity, 0);

  bool mail = SendMail(sbj + cp + " (" + bp + ")", "Equity:" + eq + "  Positions:" + ot + "  Margin:" + DoubleToStr(margin) + "  Profit:" + cp + " (" + bp + ")");
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

  stopLoss = iATR(symbol, PERIOD_M15, 7, 0);

  int mostProfitTicket = -1;
  double largestProfit = -100000.0;

  bool overLapLong = False;
  bool overLapShort = False;
  double price = (Ask + Bid) / 2.0;
  
  int longPos = 0;
  double longProfit = 0.0;
  double longPrice = 0.0;
  int shortPos = 0;
  double shortProfit = 0.0;
  double shortPrice = 0.0;
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), symbol)) {
        if(OrderType() == OP_BUY) {
          longPos += 1;
          longPrice += OrderOpenPrice();
          longProfit += OrderProfit() + OrderCommission() + OrderSwap();
          
          if(MathAbs(OrderOpenPrice() - price) < priceMargin && !overLapLong) {
            overLapLong = True;
          }
        }
        else if(OrderType() == OP_SELL) {
          shortPos += 1;
          shortPrice += OrderOpenPrice();
          shortProfit += OrderProfit() + OrderCommission() + OrderSwap();
          
          if(MathAbs(OrderOpenPrice() - price) < priceMargin && !overLapShort) {
            overLapShort = True;
          }
        }
      }

      double profit = OrderProfit() + OrderCommission() + OrderSwap();
      if(largestProfit < profit) {
        largestProfit = profit;
        mostProfitTicket = OrderTicket();
      }
    }
  }

  bool closeLong = False;
  if(0 < longPos)
    closeLong = (stopLoss / (double)longPos < (Ask - longPrice / (double)longPos));

  bool closeShort = False;
  if(0 < shortPos)
    closeShort = (stopLoss / (double)shortPos < (shortPrice / (double)shortPos) - Bid);

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), symbol)) {
        if(OrderType() == OP_BUY) {
          if(closeLong) {
            if(OrderClose(OrderTicket(), OrderLots(), Bid, 0))
              continue;
          }
        }
        else if(OrderType() == OP_SELL) {
          if(closeShort) {
            if(OrderClose(OrderTicket(), OrderLots(), Ask, 0))
              continue;
          }
        }
      }
    }
  }


  if(!overLapLong && !closeLong) {
    int ticket = OrderSend(symbol, OP_BUY, minLot * (double)(longPos + 1), Ask, 0, 0, 0);
  }
  if(!overLapShort && !closeShort) {
    int ticket = OrderSend(symbol, OP_SELL, minLot * (double)(shortPos + 1), Bid, 0, 0, 0);
  }
}
