//+------------------------------------------------------------------+
//|                                                     nolosefx.mq4 |
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

double dailyEquity;
double dailyBalance;
bool openTime;

int ACCEPTABLE_SPREAD;
#define NONE (-1)

double lotSize[] = {0.01, 0.01, 0.04, 0.06, 0.15, 0.30, 0.69, 1.46, 3.20, 6.89, 15.0};
int lotIndex;
bool finished;

string symbol;

#define SL (0.4)
#define TP (0.2)
#define LOSSCUT_MARGIN (1.2)

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
  Print("minlot=", MarketInfo(Symbol(), MODE_MINLOT));
  Print("maxlot=", MarketInfo(Symbol(), MODE_MAXLOT));

  Print("ASK=", Ask);
  Print("BID=", Bid);

  symbol = Symbol();
  dailyEquity = AccountEquity();
  dailyBalance = AccountBalance();
  openTime = False;

  lotIndex = 0;  
  finished = True;
  
#  for(int i = 0; i < 11; i ++)
#    lotSize[i] *= 10.0;

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

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  if(ACCEPTABLE_SPREAD < MarketInfo(symbol, MODE_SPREAD))
    return;

  if(2 == Hour() && Minute() < 5 && !openTime && finished) {
    dailyEquity = AccountEquity();
    dailyBalance = AccountBalance();
    openTime = True;
    finished = False;
    lotIndex = 0;
    
    while(OrderSend(symbol, OP_BUY, lotSize[lotIndex], Ask, 0, 0, 0) == -1) {
      if(GetLastError() == ERR_NOT_ENOUGH_MONEY) {
        finished = True;
        return;
      }
    }
    while(OrderSend(symbol, OP_SELL, lotSize[lotIndex], Bid, 0, 0, 0) == -1) {
      if(GetLastError() == ERR_NOT_ENOUGH_MONEY) {
        finished = True;
        return;
      }
    }
        
    lotIndex ++;
  }
  else if((7 == Hour() && openTime) || finished) {
    openTime = False;
    finished = True;
    
    for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS)) {
        if(OrderType() == OP_BUY) {
          while(!OrderClose(OrderTicket(), OrderLots(), Bid, 0));
        }
        else if(OrderType() == OP_SELL) {
          while(!OrderClose(OrderTicket(), OrderLots(), Ask, 0));
        }
      }
    }
  }

  if(0.0 < AccountMargin()) {
    if(AccountEquity() / AccountMargin() < LOSSCUT_MARGIN) {
      finished = True;
      return;
    }
  }

  if(openTime && !finished) {

    for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS)) {
        if(OrderType() == OP_BUY) {
          if(Bid < OrderOpenPrice() - SL) {
            while(!OrderClose(OrderTicket(), OrderLots(), Bid, 0));

            lotIndex ++;
            if(10 < lotIndex) {
              finished = True;
              return;
            }
            while(OrderSend(symbol, OP_BUY, lotSize[lotIndex], Ask, 0, 0, 0) == -1) {
              if(GetLastError() == ERR_NOT_ENOUGH_MONEY) {
                finished = True;
                return;
              }
            }
          }
          else if(OrderOpenPrice() + TP < Bid) {
            while(!OrderClose(OrderTicket(), OrderLots(), Bid, 0));

            lotIndex ++;
            if(10 < lotIndex || 0 < AccountEquity() - dailyEquity) {
              finished = True;
              return;
            }
            while(OrderSend(symbol, OP_SELL, lotSize[lotIndex], Bid, 0, 0, 0) == -1) {
              if(GetLastError() == ERR_NOT_ENOUGH_MONEY) {
                finished = True;
                return;
              }
            }
          }
        }
        else if(OrderType() == OP_SELL) {
          if(OrderOpenPrice() + SL < Ask) {
            while(!OrderClose(OrderTicket(), OrderLots(), Ask, 0));

            lotIndex ++;
            if(10 < lotIndex) {
              finished = True;
              return;
            }
            while(OrderSend(symbol, OP_SELL, lotSize[lotIndex], Bid, 0, 0, 0) == -1) {
              if(GetLastError() == ERR_NOT_ENOUGH_MONEY) {
                finished = True;
                return;
              }
            }
          }
          else if(Ask < OrderOpenPrice() - TP) {
            while(!OrderClose(OrderTicket(), OrderLots(), Ask, 0));

            lotIndex ++;
            if(10 < lotIndex || 0 < AccountEquity() - dailyEquity) {
              finished = True;
              return;
            }
            while(OrderSend(symbol, OP_BUY, lotSize[lotIndex], Ask, 0, 0, 0) == -1) {
              if(GetLastError() == ERR_NOT_ENOUGH_MONEY) {
                finished = True;
                return;
              }
            }
          }
        }
      }
    }
  }
}
