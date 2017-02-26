//+------------------------------------------------------------------+
//|                                                   AutoNampin.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//#define FXTF
//#define Rakuten
#define Gaitame

#define LOSS_CUT (1.2)  //120%

double minLot;
double maxLot;
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

  maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
  Print("maxLot=", maxLot);

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

  bool mail = SendMail(sbj + cp + " (" + bp + ")", "Equity:" + eq + ", Lots:" + ot + ", Margin:" + DoubleToStr(margin, 2) + ", Profit:" + cp + " (" + bp + ")");
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

  int mostProfitTicket = -1;
  double largestProfit = -100000.0;

  bool overLapLong = False;
  bool overLapShort = False;
  double price = (Ask + Bid) / 2.0;
  
  int longPos = 0;
  double longLots = 0.0;
  double longPrice = 0.0;
//  double longProfit = 0.0;
  
  int shortPos = 0;
  double shortLots = 0.0;
  double shortPrice = 0.0;
//  double shortProfit = 0.0;
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), symbol)) {
        if(OrderType() == OP_BUY) {
          longPos += 1;
          longPrice += OrderOpenPrice() * OrderLots();
          longLots += OrderLots();
//          longProfit += OrderProfit() + OrderCommission() + OrderSwap();

          if(MathAbs(OrderOpenPrice() - price) < priceMargin && !overLapLong) {
            overLapLong = True;
          }
        }
        else if(OrderType() == OP_SELL) {
          shortPos += 1;
          shortPrice += OrderOpenPrice() * OrderLots();
          shortLots += OrderLots();
//          shortProfit += OrderProfit() + OrderCommission() + OrderSwap();

          if(MathAbs(price - OrderOpenPrice()) < priceMargin && !overLapShort) {
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

  double stopLoss = iATR(symbol, PERIOD_M15, 7, 0);

  bool closeLong = False;
  if(0.0 < longLots) {
//    closeLong = (stopLoss < (Ask - longPrice / longLots));
    closeLong = (stopLoss / (longLots * 100.0) < (longPrice / longLots - Ask));
  }

  bool closeShort = False;
  if(0.0 < shortLots) {
//    closeShort = (stopLoss < (shortPrice / shortLots) - Bid);
    closeShort = (stopLoss / (shortLots * 100.0) < (Bid - shortPrice / shortLots));
  }

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

  double margin = AccountMargin();
  if(0.0 < margin)
    margin = AccountEquity() / margin;
  else
    margin = 1000.0;

  if(margin < LOSS_CUT) {
    if(OrderSelect(mostProfitTicket, SELECT_BY_TICKET)) {
    
      int cutType = OrderType();
      string cutSymbol = OrderSymbol();
      double cutPrice = MarketInfo(cutSymbol, MODE_BID);
      if(cutType == OP_SELL)
        cutPrice = MarketInfo(cutSymbol, MODE_ASK);

      for(int i = 0; i < OrdersTotal(); i++)
        if(OrderSelect(i, SELECT_BY_POS))
          if(!StringCompare(OrderSymbol(), cutSymbol))
            if(OrderType() == cutType)
              if(OrderClose(OrderTicket(), OrderLots(), cutPrice, 0))
                continue;
    }
  }
  else {
    if(0.0 == longLots) {
      longPrice = 10000.0;
      longLots = 1.0;
    }
    if(!overLapLong && !closeLong && (Ask < longPrice / longLots)) {
      double lots = minLot * (double)(longPos + 1.0);
      if(maxLot < lots)
        lots = maxLot;
      int ticket = OrderSend(symbol, OP_BUY, lots, Ask, 0, 0, 0);
    }
    
    if(0.0 == shortLots) {
      shortPrice = 0.0;
      shortLots = 1.0;
    }
    if(!overLapShort && !closeShort && (shortPrice / shortLots < Bid)) {
      double lots = minLot * (double)(shortPos + 1.0);
      if(maxLot < lots)
        lots = maxLot;
      int ticket = OrderSend(symbol, OP_SELL, lots, Bid, 0, 0, 0);
    }
  }
}
