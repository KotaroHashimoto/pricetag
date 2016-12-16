//+------------------------------------------------------------------+
//|                                                   LineBounce.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define ACCEPTABLE_SPREAD (3) //for FXTF1000
//#define ACCEPTABLE_SPREAD (4) //for OANDA, Gaitame, ICMarket
//#define ACCEPTABLE_SPREAD (5) //for Rakuten

#define SYMBOL "USDJPY"
//#define SYMBOL "EURUSD"
//#define SYMBOL "GBPUSD"

#define STOP_LOSS (100)
#define WAIT (1)
#define MAXPOS (300)

double MINLOT;
double previousAsk;
double previousBid;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
  previousAsk = Ask;
  previousBid = Bid;
  Print("ASK=", Ask);
  Print("BID=", Bid);
  
  MINLOT = MarketInfo(SYMBOL, MODE_MINLOT);
  Print("MINLOT=", MINLOT);
  
//  SYMBOL = SYMBOL();
  
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
//---
  double atr = iATR(SYMBOL, PERIOD_M15, 2, 1);
  double stopLoss;

  if(atr < Point * MarketInfo(SYMBOL, MODE_STOPLEVEL)) {
    stopLoss = Point * MarketInfo(SYMBOL, MODE_STOPLEVEL);
  }
  else if(Point * STOP_LOSS < atr) {
    stopLoss = Point * STOP_LOSS;
  }
  else {
    stopLoss = atr;
  }
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderType() == OP_BUY && OrderSymbol() == SYMBOL) {
        if(OrderStopLoss() < Bid - stopLoss) {
          bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - stopLoss, 0, 0);
        }
      }
      else if(OrderType() == OP_SELL && OrderSymbol() == SYMBOL) {
        if(Ask + stopLoss < OrderStopLoss()) {
          bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + stopLoss, 0, 0);
        }
      }
    }
  }

  if(ACCEPTABLE_SPREAD < MarketInfo(SYMBOL, MODE_SPREAD) || MAXPOS < OrdersTotal()) {
    previousBid = Bid;
    previousAsk = Ask;
    return;
  }

  double lines[2];
//  lines[0] = High[iHighest(SYMBOL, PERIOD_M1, MODE_HIGH, 1440, 60)];
//  lines[1] = Low[iLowest(SYMBOL, PERIOD_M1, MODE_LOW, 1440, 60)];
  lines[0] = High[iHighest(SYMBOL, PERIOD_M5, MODE_HIGH, 288, 12)];
  lines[1] = Low[iLowest(SYMBOL, PERIOD_M5, MODE_LOW, 288, 12)];
  
  for(int i = 0; i < 2; i++) {
    
    if(iLow(SYMBOL, PERIOD_M5, 1 + WAIT) < lines[i] && lines[i] < iHigh(SYMBOL, PERIOD_M5, 1 + WAIT)) {
//      Print(lines[i]);
      for(int j = 0; j < WAIT; j++) {
        if(iLow(SYMBOL, PERIOD_M5, 1 + j) < lines[i])
          break;
        if(j == WAIT - 1 && lines[i] < Bid - stopLoss / 2.0)
          int ticket = OrderSend(SYMBOL, OP_BUY, MINLOT, Ask, 0, Bid - stopLoss, 0);
      }
      for(int j = 0; j < WAIT; j++) {
        if(lines[i] < iHigh(SYMBOL, PERIOD_M5, 1 + j))
          break;
        if(j == WAIT - 1 && Ask + stopLoss / 2.0 < lines[i])
        int ticket = OrderSend(SYMBOL, OP_SELL, MINLOT, Bid, 0, Ask + stopLoss, 0);
      }
    }

//    Print("highest = ", lines[0]);
//    Print("lowest = ", lines[1]);
  }
  
}
//+------------------------------------------------------------------+
