//+------------------------------------------------------------------+
//|                                          TriangularArbitrage.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//#define ACCEPTABLE_SPREAD (5) //for Rakuten
//#define ACCEPTABLE_SPREAD (4) //for OANDA
#define ACCEPTABLE_SPREAD (3) //for FXTF1000, Gaitame
//#define ACCEPTABLE_SPREAD (0) //for ICMarket
//#define ACCEPTABLE_SPREAD (16) //for XMTrading

#define SPREAD_USDJPY (4)
#define SPREAD_EURUSD (5)
#define SPREAD_EURJPY (13)

#define N_CONDITION (-0.01)
#define P_CONDITION (0.01)
#define LOT (1.0)

int t_usdjpy = -1;
int t_eurjpy = -1;
int t_eurusd = -1;
int aCondition = 0;

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
  Print("AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)=", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
   
  Print("Symbol()=", Symbol());
  Print("MIN_SL=", Point * MarketInfo(Symbol(), MODE_STOPLEVEL));

  Print("SPREAD=", MarketInfo(Symbol(), MODE_SPREAD));
  Print("POINT=", MarketInfo(Symbol(), MODE_POINT));
  
  Print("ASK=", Ask);
  Print("BID=", Bid);

  Print("MIN_LOT=", MarketInfo(Symbol(), MODE_MINLOT));
  
  t_usdjpy = -1;
  t_eurjpy = -1;
  t_eurusd = -1;
  aCondition = 0;

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


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  double usdjpy = MarketInfo("USDJPY", MODE_BID);
  double eurusd = MarketInfo("EURUSD", MODE_BID);
  double eurjpy = MarketInfo("EURJPY", MODE_BID);
    
  double price = usdjpy - eurjpy / eurusd;
//  Print("USDJPY - EURJPY/EURUSD = ", price);

  if(SPREAD_USDJPY < MarketInfo("USDJPY", MODE_SPREAD) || SPREAD_EURUSD < MarketInfo("EURUSD", MODE_SPREAD) || SPREAD_EURJPY < MarketInfo("EURJPY", MODE_SPREAD)) {
    return;
  }

  if(t_usdjpy == -1 && t_eurjpy == -1 && t_eurusd == -1) {
    if(price < N_CONDITION) {
      t_usdjpy = OrderSend("USDJPY", OP_BUY, LOT, MarketInfo("USDJPY", MODE_ASK), 0, 0, 0);
      t_eurjpy = OrderSend("EURJPY", OP_BUY, LOT, MarketInfo("EURJPY", MODE_ASK), 0, 0, 0);
      t_eurusd = OrderSend("EURUSD", OP_SELL, LOT, MarketInfo("EURUSD", MODE_BID), 0, 0, 0);
      aCondition = 1;
    }
    else if(P_CONDITION < price) {
      t_usdjpy = OrderSend("USDJPY", OP_SELL, LOT, MarketInfo("USDJPY", MODE_BID), 0, 0, 0);
      t_eurjpy = OrderSend("EURJPY", OP_SELL, LOT, MarketInfo("EURJPY", MODE_BID), 0, 0, 0);
      t_eurusd = OrderSend("EURUSD", OP_BUY, LOT, MarketInfo("EURUSD", MODE_ASK), 0, 0, 0);
      aCondition = -1;
    }
  }
  else if(t_usdjpy != -1 && t_eurjpy != -1 && t_eurusd != -1){
    if(N_CONDITION < price && price < P_CONDITION) {
      bool closed;
      if(aCondition == 1) {
        closed = OrderClose(t_usdjpy, LOT, MarketInfo("USDJPY", MODE_BID), 0);
        closed = OrderClose(t_eurjpy, LOT, MarketInfo("EURJPY", MODE_BID), 0);
        closed = OrderClose(t_eurusd, LOT, MarketInfo("EURUSD", MODE_ASK), 0);
      }
      else if(aCondition == -1) {
        closed = OrderClose(t_usdjpy, LOT, MarketInfo("USDJPY", MODE_ASK), 0);
        closed = OrderClose(t_eurjpy, LOT, MarketInfo("EURJPY", MODE_ASK), 0);
        closed = OrderClose(t_eurusd, LOT, MarketInfo("EURUSD", MODE_BID), 0);
      }
    }
  }
  else { //error case
    bool closed;
    if(aCondition == 1) {
      if(t_usdjpy != -1){closed = OrderClose(t_usdjpy, LOT, MarketInfo("USDJPY", MODE_BID), 0);}
      if(t_eurjpy != -1){closed = OrderClose(t_eurjpy, LOT, MarketInfo("EURJPY", MODE_BID), 0);}
      if(t_eurusd != -1){closed = OrderClose(t_eurusd, LOT, MarketInfo("EURUSD", MODE_ASK), 0);}
    }
    else if(aCondition == -1) {
      if(t_usdjpy != -1){closed = OrderClose(t_usdjpy, LOT, MarketInfo("USDJPY", MODE_ASK), 0);}
      if(t_eurjpy != -1){closed = OrderClose(t_eurjpy, LOT, MarketInfo("EURJPY", MODE_ASK), 0);}
      if(t_eurusd != -1){closed = OrderClose(t_eurusd, LOT, MarketInfo("EURUSD", MODE_BID), 0);}
    }
  }
}
