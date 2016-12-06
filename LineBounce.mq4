//+------------------------------------------------------------------+
//|                                                   LineBounce.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#property  indicator_chart_window
#property  indicator_buffers    2
#property  indicator_color1    clrYellow
#property  indicator_color2    clrYellow
#property  indicator_width1    1
#property  indicator_width2    1
#property  indicator_type1     DRAW_LINE
#property  indicator_type2     DRAW_LINE
#property  indicator_style1    STYLE_DASHDOT
#property  indicator_style2    STYLE_DASHDOT

double highLine[];
double lowLine[];

#define ACCEPTABLE_SPREAD (3) //for FXTF1000
//#define ACCEPTABLE_SPREAD (4) //for OANDA, Gaitame, ICMarket
//#define ACCEPTABLE_SPREAD (5) //for Rakuten


#define STOP_LOSS 100
#define WAIT 1

double LOT;
double previousAsk;
double previousBid;
string symbol;
double lines[2];

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
  
//  LOT = MarketInfo(Symbol(), MODE_LOT);
  LOT = 1.0;
  Print("LOT=", LOT);
  
  symbol = Symbol();
  Print("symbol = ", symbol)

  SetIndexBuffer(0, highLine);
  SetIndexBuffer(1, lowLine);
  
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

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{

  for(int i = 0; i < 1500; i++) {
    highLine[i] = lines[0];
    lowLine[i] = lines[1];
  }

  return(rates_total)
}

  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
  double atr = iATR(Symbol(), PERIOD_M15, 2, 1);
  double stopLoss;

  if(atr < Point * MarketInfo(Symbol(), MODE_STOPLEVEL)) {
    stopLoss = Point * MarketInfo(Symbol(), MODE_STOPLEVEL);
  }
  else if(Point * STOP_LOSS < atr) {
    stopLoss = Point * STOP_LOSS;
  }
  else {
    stopLoss = atr;
  }
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderType() == OP_BUY) {
        if(OrderStopLoss() < Bid - stopLoss) {
          bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - stopLoss, 0, 0);
        }/*
        if(OrderLots() == LOT && OrderOpenPrice() + stopLoss < Bid) {
          bool closed = OrderClose(OrderTicket(), LOT / 2.0, Bid, 0);
        }*/
      }
      else if(OrderType() == OP_SELL) {
        if(Ask + stopLoss < OrderStopLoss()) {
          bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + stopLoss, 0, 0);
     	  }/*
        if(OrderLots() == LOT && Ask < OrderOpenPrice() - stopLoss) {
          bool closed = OrderClose(OrderTicket(), LOT / 2.0, Ask, 0);
        }*/
      }
    }
  }

  if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD) || 0 < OrdersTotal()/* || Hour() < 3 || 7 < Hour()*/) {
    previousBid = Bid;
    previousAsk = Ask;
    return;
  }

  lines[0] = High[iHighest(symbol, PERIOD_M1, MODE_HIGH, 1440, 60)];
  lines[1] = Low[iLowest(symbol, PERIOD_M1, MODE_HIGH, 1440, 60)];
//  lines[2] = High[iHighest(symbol, PERIOD_M1, MODE_HIGH, 1440, 1500)];
//  lines[3] = Low[iLowest(symbol, PERIOD_M1, MODE_HIGH, 1440, 1500)];
  
  for(int i = 0; i < 2; i++) {
    
    if(iLow(symbol, PERIOD_M1, 1 + WAIT) < lines[i] && lines[i] < iHigh(symbol, PERIOD_M1, 1 + WAIT)) {
//      Print(lines[i]);
      for(int j = 0; j < WAIT; j++) {
        if(iLow(symbol, PERIOD_M1, 1 + j) < lines[i])
          break;
        if(j == WAIT - 1)
          int ticket = OrderSend(symbol, OP_BUY, LOT, Ask, 0, Bid - stopLoss, 0);
      }
      for(int j = 0; j < WAIT; j++) {
        if(lines[i] < iHigh(symbol, PERIOD_M1, 1 + j))
          break;
        if(j == WAIT - 1)
        int ticket = OrderSend(symbol, OP_SELL, LOT, Bid, 0, Ask + stopLoss, 0);
      }
    }
  
//    Print("highest = ", lines[0]);
//    Print("lowest = ", lines[1]);
  }
  
}
//+------------------------------------------------------------------+
