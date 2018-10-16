//+------------------------------------------------------------------+
//|                                                  NampinRSI4H.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define ACCEPTABLE_SPREAD (5)
#define NAMPIN_SPAN (0.01)
#define TP (0.1)
#define NONE (-1)

double MIN_LOT = NONE;
double MIN_SL = NONE;
double previousAsk = NONE;
double previousBid = NONE;

double mailSent = false;
bool BEAR = true;

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

  MIN_SL = Point * MarketInfo(Symbol(), MODE_STOPLEVEL);
  Print("MIN_SL=", MIN_SL);

  Print("SPREAD=", MarketInfo(Symbol(), MODE_SPREAD));
  Print("POINT=", MarketInfo(Symbol(), MODE_POINT));
  
  Print("ASK=", Ask);
  Print("BID=", Bid);

  previousAsk = Ask;
  previousBid = Bid;
  
  MIN_LOT = MarketInfo(Symbol(), MODE_MINLOT);
  Print("MIN_LOT=", MIN_LOT);
  
  BEAR = true;
  
  EventSetTimer(600);
  
  //---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  EventKillTimer();
  //---   
}

void determineRSI(double& rsi0, double& rsi1) {

  rsi0 = iRSI(Symbol(), PERIOD_H4, 14, PRICE_WEIGHTED, 0);
  rsi1 = iRSI(Symbol(), PERIOD_H4, 14, PRICE_WEIGHTED, 1);
  
  if(rsi1 > 70 && 70 > rsi0) {
    BEAR = true;
  }
  else if(rsi1 < 30 && 30 < rsi0) {
    BEAR = false;
  }
}

void countPosAmount(double& sells, double& buys, double& sp, double& bp) {

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderType() == OP_SELL) {
        sells += OrderLots();
        sp += OrderProfit();
      }
      else if(OrderType() == OP_BUY) {
        buys += OrderLots();
        bp += OrderProfit();
      }
    }
  }
}

void OnTimer(){

  double buys = 0.0;
  double sells = 0.0;
  double bp = 0.0;
  double sp = 0.0;
  countPosAmount(sells, buys, sp, bp);
  
  double rsi0 = 0.0;
  double rsi1 = 0.0;
  determineRSI(rsi0, rsi1);  

  if(0 < AccountMargin()) {
    mailSent = SendMail(DoubleToString((Ask + Bid) / 2.0, 3) + 
               ", eq:" + DoubleToString(AccountEquity(), 0) + "(" + DoubleToString(AccountProfit(), 0) + "), " + DoubleToString(AccountEquity() / AccountMargin() * 100.0, 2) + "%, " 
               + (BEAR ? "bear(" : "bull(") + DoubleToString(rsi1, 1) + "-" + DoubleToString(rsi0, 1) + ")", 
               "buy:" + DoubleToString(buys, 2) + "(" + DoubleToString(bp, 0) + "), sell:" + DoubleToString(sells, 2) + "(" + DoubleToString(sp, 0) + "), " + 
               DoubleToString(AccountEquity() / AccountMargin() * 100.0, 2) + "%, "
               + (BEAR ? "BEAR (RSI 4H:" : "BULL (RSI 4H:") + DoubleToString(rsi1, 1) + "-" + DoubleToString(rsi0, 1) + "), "
               "USDJPY: " + DoubleToString(Bid, 3) + " -" + DoubleToString(MarketInfo(Symbol(), MODE_SPREAD), 0) + "- " + DoubleToString(Ask, 3) + ", " + 
               "EURJPY: " + DoubleToString(MarketInfo("EURJPY", MODE_BID), 3) + " -" + DoubleToString(MarketInfo("EURJPY", MODE_SPREAD), 0) + "- " + DoubleToString(MarketInfo("EURJPY", MODE_ASK), 3) + ", " + 
               "GBPJPY: " + DoubleToString(MarketInfo("GBPJPY", MODE_BID), 3) + " -" + DoubleToString(MarketInfo("GBPJPY", MODE_SPREAD), 0) + "- " + DoubleToString(MarketInfo("GBPJPY", MODE_ASK), 3) + ", " + 
               "EURUSD: " + DoubleToString(MarketInfo("EURUSD", MODE_BID), 5) + " -" + DoubleToString(MarketInfo("EURUSD", MODE_SPREAD), 0) + "- " + DoubleToString(MarketInfo("EURUSD", MODE_ASK), 5));
  }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{  
  double buys = 0.0;
  double sells = 0.0;
  double bp = 0.0;
  double sp = 0.0;
  countPosAmount(sells, buys, sp, bp);
  
  double rsi0 = 0.0;
  double rsi1 = 0.0;
  determineRSI(rsi0, rsi1);
  
  if(sells == 0.0 && buys == 0.0) {
    previousBid = Bid;
    previousAsk = Ask;
    return;
  }

  double highestShort = 0;
  double lowestShort = 10000;
  double highestLong = 0;
  double lowestLong = 10000;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderType() == OP_SELL) {
        if(OrderOpenPrice() < lowestShort) {
          lowestShort = OrderOpenPrice();
        }
        if(highestShort < OrderOpenPrice()) {
          highestShort = OrderOpenPrice();
	     }
      }
      else if(OrderType() == OP_BUY) {
        if(OrderOpenPrice() < lowestLong) {
          lowestLong = OrderOpenPrice();
        }
        if(highestLong < OrderOpenPrice()) {
          highestLong = OrderOpenPrice();
	     }
      }      
    }
  }
  
  if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
    previousBid = Bid;
    previousAsk = Ask;
    return;
  }
  else if(AccountEquity() / AccountMargin() < 1.5) {
    previousBid = Bid;
    previousAsk = Ask;
    return;
  }
  


  if(2.0 < AccountEquity() / AccountMargin()) {
    if(BEAR && highestShort + NAMPIN_SPAN < Bid) {
      int ticket = OrderSend(Symbol(), OP_SELL, MIN_LOT, Bid, 0, 0, Bid - TP);
    }
    else if(!BEAR && Ask < lowestLong - NAMPIN_SPAN) {
      int ticket = OrderSend(Symbol(), OP_BUY, MIN_LOT, Ask, 0, 0, Ask + TP);
    }
  }
  
  previousBid = Bid;
  previousAsk = Ask;
}
