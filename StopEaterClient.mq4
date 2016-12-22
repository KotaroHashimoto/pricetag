//+------------------------------------------------------------------+
//|                                              StopEaterClient.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define ENTRY_TH_PO (0.50)
#define MARGIN_PIP (0)
#define MAXSL_PIP (200)

double MINLOT;
double MINSL;
double MAXSL;
int ACCEPTABLE_SPREAD;

#define REFLASH_DELAY_S (5)

#define MASK (0)
#define UPDATE (1)
#define READY (2)
char watchOanda;

string symbol;

int pp_sz;
double pp[];
double pendingOrders[];
double positionPressure;
double orderPressure;
string previousTimeStamp;

#define NOOP (0)
#define LONG_NOOP (1)
#define SHORT_NOOP (2)
#define SHORT_TRAIL (4)
#define LONG_TRAIL (8)
#define SHORT_LIMIT (16)
#define LONG_LIMIT (32)

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   symbol = Symbol();
   watchOanda = UPDATE;

   positionPressure = 0.0;
   orderPressure = 0.0;
   previousTimeStamp = "";

   MINLOT = MarketInfo(symbol, MODE_MINLOT);
   MINSL = Point * MarketInfo(Symbol(), MODE_STOPLEVEL);
   MAXSL = Point * MAXSL_PIP;

  if(!StringCompare(symbol, "USDJPY-cd"))
    ACCEPTABLE_SPREAD = 3;
  else if(!StringCompare(symbol, "EURUSD-cd"))
    ACCEPTABLE_SPREAD = 8;
  else if(!StringCompare(symbol, "GBPUSD-cd"))
    ACCEPTABLE_SPREAD = 11;
  else if(!StringCompare(symbol, "GBPJPY-cd"))
    ACCEPTABLE_SPREAD = 20;
  else if(!StringCompare(symbol, "AUDJPY-cd"))
    ACCEPTABLE_SPREAD = 14;
  else if(!StringCompare(symbol, "EURJPY-cd"))
    ACCEPTABLE_SPREAD = 6;
  else
    return -1;
  
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

bool triggerOandaUpdate() {

   int m = Minute();

   if(watchOanda == READY && !(m % 20)) {
      watchOanda = UPDATE;
   }
   else if(watchOanda == MASK && (m == 19 || m == 39 || m == 59)) {
      watchOanda = READY;
   }

   if(watchOanda == UPDATE) {
     if(!(Seconds() % REFLASH_DELAY_S)) {
       return true;
     }
   }

   return false;
}

bool askOandaUpdate() {

   if(!triggerOandaUpdate() && !(positionPressure == 0.0)) {
      return false;
   }

   return readOrderBookInfo();
}

bool readOrderBookInfo() {

   string filepath = Symbol() + ".csv";
 
   if(!FileIsExist(filepath)) {
      return false;
   }

   int fh = FileOpen(filepath, FILE_CSV | FILE_READ, ",");
   if(fh != INVALID_HANDLE) {

      string ts = FileReadString(fh);
      if(!StringCompare(previousTimeStamp, ts)) {
          FileClose(fh);
          return false;
      }
      previousTimeStamp = ts;
      positionPressure = FileReadNumber(fh);
      pp_sz = (int)FileReadNumber(fh);

      ArrayResize(pp, pp_sz);
      ArrayResize(pendingOrders, pp_sz);

      int i;
      for(i = 0; i < pp_sz; i++) {
	      pp[i] = FileReadNumber(fh);
         pendingOrders[i] = FileReadNumber(fh);
      }

      FileClose(fh);
      return (i == pp_sz);
   }
   else {
      return false;
   }
}


double stopLossATR() {

  double atr = iATR(Symbol(), PERIOD_M15, 2, 1);  
  if(atr < MINSL) {
    return MINSL;
  }
  else if(MAXSL < atr) {
    return MAXSL;
  }
  else {
    return atr;
  }
}


uchar getStrategy() {

  for(int i = 1; i < pp_sz; i++) {
    double price = (Bid + Ask) / 2.0;
    if(pp[i - 1] < price && price < pp[i]) {
      orderPressure = pendingOrders[i];
      if(ENTRY_TH_PO < MathAbs(pendingOrders[i])) {
        if(0 < pendingOrders[i]) {
          if(0 < positionPressure)
            return LONG_TRAIL;
	       else
	         return LONG_LIMIT;
	     }
        else {
          if(positionPressure < 0)
            return SHORT_TRAIL;
	       else
	         return SHORT_LIMIT;
	     }
      }
      else {
        if(0 < positionPressure)
          return LONG_NOOP;
        else
          return SHORT_NOOP;
      }
    }
  }

  return NOOP;
}

int openPosition(double stopLoss, uchar strategy, bool isOpen) {

  if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD) || !isOpen) {
    return -1;
  }

  int ticket = -1;

  if(!!(strategy & LONG_TRAIL))
    ticket = OrderSend(symbol, OP_BUY, MINLOT, Ask, 0, Bid - stopLoss, 0);
  else if(!!(strategy & SHORT_TRAIL))
    ticket = OrderSend(symbol, OP_SELL, MINLOT, Bid, 0, Ask + stopLoss, 0);
  else if(!!(strategy & LONG_LIMIT))
    ticket = OrderSend(symbol, OP_BUY, MINLOT, Ask, 0, Bid - stopLoss, Bid + stopLoss);
  else if(!!(strategy & SHORT_LIMIT))
    ticket = OrderSend(symbol, OP_SELL, MINLOT, Bid, 0, Ask + stopLoss, Ask - stopLoss);

  return ticket;
}


bool scanPositions(double stopLoss, uchar strategy) {

  double highestPos = 0.0;
  double lowestPos = 10000.0;

  for(int i = 0; i < OrdersTotal(); i++) {
    bool closed = False;

    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderType() == OP_BUY && !StringCompare(OrderSymbol(), symbol)) {
        if(!!(strategy & (SHORT_LIMIT | SHORT_TRAIL | SHORT_NOOP))) {
          closed = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
	     }
        else if(0.0 == OrderTakeProfit()) { // if trailing
          if(!!(strategy & (/*LONG_LIMIT | */LONG_NOOP))) {
	         bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - stopLoss, Bid + stopLoss, 0);
          }
          else if(!!(strategy & (LONG_LIMIT | LONG_TRAIL))) {
            if(OrderStopLoss() < Bid - stopLoss) {
              bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - stopLoss, 0, 0);
            }
	       }
        }
	     else {
	       if(!!(strategy & LONG_TRAIL)) {
            bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - stopLoss, 0, 0);	  
	       }
	     }
      }
      else if(OrderType() == OP_SELL && !StringCompare(OrderSymbol(), symbol)) {
        if(!!(strategy & (LONG_LIMIT | LONG_TRAIL | LONG_NOOP))) {
          closed = OrderClose(OrderTicket(), OrderLots(), Ask, 0);
	     }
        else if(0.0 == OrderTakeProfit()) { // if trailing
          if(!!(strategy & (/*SHORT_LIMIT | */SHORT_NOOP))) {
	         bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + stopLoss, Ask - stopLoss, 0);
          }
          else if(!!(strategy & (SHORT_LIMIT | SHORT_TRAIL))) {
            if(OrderStopLoss() < Ask + stopLoss) {
              bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + stopLoss, 0, 0);
            }
	       }
        }
	     else {
	       if(!!(strategy & SHORT_TRAIL)) {
            bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + stopLoss, 0, 0);	  
	       }
        }	
      }
    }

    if(!closed) {
      if(OrderOpenPrice() < lowestPos) {
        lowestPos = OrderOpenPrice();
      }
      if(OrderOpenPrice() < highestPos) {
        highestPos = OrderOpenPrice();
      }
    }
  }

  return (Ask < lowestPos - MARGIN_PIP || highestPos + MARGIN_PIP < Bid);
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---

   if(askOandaUpdate()) {
      watchOanda = MASK;
   }

   uchar strategy = getStrategy();
   double stopLoss = stopLossATR();
   
   Print("s = ", strategy, "  pp = ", positionPressure, "  op = ", orderPressure);
   openPosition(stopLoss, strategy, scanPositions(stopLoss, strategy));
}
//+------------------------------------------------------------------+
