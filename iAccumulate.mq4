//+------------------------------------------------------------------+
//|                                                   Accumulate.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//#define FXTF
#define RAKUTEN

#define NONE (-1)

double minLot = NONE;
double stopLoss = NONE;
double priceMargin = NONE;

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
  else if(!StringCompare(symbol, "GBPUSD-cd"))
    ACCEPTABLE_SPREAD = 11;
  else if(!StringCompare(symbol, "AUDJPY-cd"))
    ACCEPTABLE_SPREAD = 14;
  else if(!StringCompare(symbol, "EURGBP-cd"))
    ACCEPTABLE_SPREAD = 16;
// total = 58
  stopLoss = (double)MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
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
  stopLoss = 50.0 * Point;
//  stopLoss = (double)(ACCEPTABLE_SPREAD + 1) * Point;
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

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  bool overLapLong = False;
  bool overLapShort = False;
  double price = (Ask + Bid) / 2.0;
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS) && !StringCompare(OrderSymbol(), symbol)) {
      double openPrice = OrderOpenPrice();
      
      if(OrderType() == OP_BUY) {      
        if(MathAbs(openPrice - price) < priceMargin && !overLapLong) {
          overLapLong = True;
        }
      }
      else if(OrderType() == OP_SELL) {
        if(MathAbs(openPrice - price) < priceMargin && !overLapShort) {
          overLapShort = True;
        }
      }      
    }
  }
  
  if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD))
    return;
    /*
#ifdef RAKUTEN
  stopLoss = iATR(Symbol(), PERIOD_M5, 14, 0);
#endif
*/
  if(!overLapLong) {
    int ticket = OrderSend(symbol, OP_BUY, minLot, Ask, 0, 0, Bid + stopLoss);
  }
  if(!overLapShort) {
    int ticket = OrderSend(symbol, OP_SELL, minLot, Bid, 0, 0, Ask - stopLoss);
  }
}

