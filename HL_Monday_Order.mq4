//+------------------------------------------------------------------+
//|                                              HL_Monday_Order.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- input parameters
input bool Flat_Lot = False;
input double Flat_Lot_Rate = 0.01;

input bool MM_Lot = False;
input double MM_Rate = 100000; // entry lot = AccountEquity() / MM_Rate * 0.01

input bool Auto_Lot = True;
input bool Auto_Lot_Adjust_Times = 1.0;

input int Base_Period_Friday_Hour_Shift = 0;

input double Divided_By_Width_To_Launch = 3.0;
input double TP_Width_To_Launch_Times = 2.0;
input double Buy_Entry_Adjust_Pips = 1.5;
input double Buy_SL_Adjust_Pips = 1.0;
input double Buy_TP_Adjust_Pips = 1.0;
input double Sell_Entry_Adjust_Pips = 1.0;
input double Sell_SL_Adjust_Pips = 1.0;
input double Sell_TP_Adjust_Pips = 1.0;


string thisSymbol;

int sellOrderCount;
int buyOrderCount;

void drawHLine(string id, double pos, string label, color clr = clrGray, int width = 1, int style = 1, bool selectable = false) {

  if(style < 0 || 4 < style) {
    style = 0;
  }
  if(width < 1) {
    width = 1;
  }

  ObjectCreate(id, OBJ_HLINE, 0, 0, pos);
  ObjectSet(id, OBJPROP_COLOR, clr);
  ObjectSet(id, OBJPROP_WIDTH, width);
  ObjectSet(id, OBJPROP_STYLE, style);
  ObjectSet(id, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
  
  ObjectSetInteger(0, id, OBJPROP_SELECTABLE, selectable);
  ObjectSetText(id, label + ": " + DoubleToString(pos, 3), 12, "Arial", clr);
}

double widthToLaunch() {

  double high = ObjectGetDouble(0, "Monady High", OBJPROP_PRICE1);
  double low = ObjectGetDouble(0, "Monady Low", OBJPROP_PRICE1);

  return MathCeil(((high - low) / Divided_By_Width_To_Launch) * 1000.0) / 1000.0;
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

  int dow = DayOfWeek();
  if(dow == 0 || dow == 6) {
    dow = 5
  }

  mondayHigh = iHigh(Symbol(), PERIOD_D1, dow - 1);
  mondayLow = iLow(Symbol(), PERIOD_D1, dow - 1);

  drawHLine("Monday High", monadyHigh, "Monday High");
  drawHLine("Monday Low", monadyHigh, "Monday Low");

  ObjectCreate(0, "Width to Launch", OBJ_LABEL, 0, 0, 0);
  ObjectSetInteger(0, "Width to Launch", OBJPROP_CORNER, CORNER_LEFT_UPPER);

  ObjectSetString(0, "Width to Launch", OBJPROP_TEXT, "Width to Launch: " + DoubleToString(widthToLaunch()));

  thisSymbol = Symbol();

  sellOrderCount = 0;
  buyOrderCount = 0;
  
  //---
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

  ObjectDelete(0, "Monday High");
  ObjectDelete(0, "Monday Low");

  //---   
}

void closeAll() {

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol)) {
        if(OrderType() == OP_BUY) {
          while(!OrderClose(OrderTicket(), OrderLots(), Bid, 0)) {
            Print("Error on closing long order: ", GetLastError());
          }
        }
        if(OrderType() == OP_SELL) {
          while(!OrderClose(OrderTicket(), OrderLots(), Ask, 0)) {
            Print("Error on closing short order: ", GetLastError());
          }
        }
        if(OrderType() == OP_BUYSTOP) {
          while(!OrderDelete(OrderTicket())) {
            Print("Error on deleting buy stop order: ", GetLastError());
          }
        }
        if(OrderType() == OP_SELLSTOP) {
          while(!OrderDelete(OrderTicket())) {
            Print("Error on deleting sell stop order: ", GetLastError());
          }
        }
      }
    }
  }
}


void countOrders() {

  sellOrderCount = 0;
  buyOrderCount = 0;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), symbol)) {
        if(OrderType() == OP_SELL || OrderType() == OP_SELLSTOP)
          sellOrderCount ++;
        else if(OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
          buyOrderCount ++;
      }
    }
  }
}

double calcLot() {

  if(Flat_Lot) {
    return Flat_Lot_Rate;
  }
  else if(Auto_Lot){
    double lot = AccountEquity() * 0.0000001 / widthToLaunch() * Auto_Lot_Adjust_Times
    return MathRound(lot * 100.0) / 100.0;
  }
  else if(MM_Lot) {
    return AccountEquity() / MM_Rate * 0.01;
  }

  return 0.0;
}

bool orderLong(double lot) {

  if(lot == 0.0) {
    return False;
  }

  double high = ObjectGetDouble(0, "Monady High", OBJPROP_PRICE1);
  double low = ObjectGetDouble(0, "Monady Low", OBJPROP_PRICE1);

  double entryPrice = high + (Buy_Entry_Adjust_Pips * Point * 10.0);
  double stopLoss = entryPrice - widthToLaunch() - (Buy_SL_Adjust_Pips * Point * 10.0);
  double takeProfit = entryPrice + (widthToLaunch() * TP_Width_To_Launch_Times) + (Buy_TP_Adjust_Pips * Point * 10.0)

  double minSL = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;

  if(takeProfit - entryPrice < minSL) {
    Print("TP(", takeProfit, ") is too closer to entry point(", entryPrice, ") than minimum stoplevel(", minSL, ")");
    Print("Reconfigure parameters.");
    return False;
  }
  else if(entryPrice - stopLoss < minSL) {
    Print("SL(", stopLoss, ") is too closer to entry point(", entryPrice, ") than minimum stoplevel(", minSL, ")");
    Print("Reconfigure parameters.");
    return False;
  }
  else if(entryPrice - Ask < minSL) {
    return False;
  }
  else {
    int ticket1 = OrderSend(thisSymbol, OP_BUYSTOP, lot, entryPrice, 0, stopLoss, takeProfit);
    int ticket2 = OrderSend(thisSymbol, OP_BUYSTOP, lot, entryPrice, 0, stopLoss, 0);

    if(ticket1 == -1 && ticket2 != -1) {
      while(!OrderDelete(ticket2));
      return False;
    }
    else if(ticket1 != -1 && ticket2 == -1) {
      while(!OrderDelete(ticket1));
      return False;
    }
    else if(ticket1 == -1 && ticket2 == -1) {
      return False;
    }
    else {
      return True;
    }
  }
}

bool orderShort(double lot) {

  if(lot == 0.0) {
    return False;
  }

  double high = ObjectGetDouble(0, "Monady High", OBJPROP_PRICE1);
  double low = ObjectGetDouble(0, "Monady Low", OBJPROP_PRICE1);

  double entryPrice = high - (Sell_Entry_Adjust_Pips * Point * 10.0);
  double stopLoss = entryPrice + widthToLaunch() + (Sell_SL_Adjust_Pips * Point * 10.0);
  double takeProfit = entryPrice - (widthToLaunch() * TP_Width_To_Launch_Times) - (Sell_TP_Adjust_Pips * Point * 10.0)

  double minSL = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;

  if(entryPrice - takeProfit< minSL) {
    Print("TP(", takeProfit, ") is too closer to entry point(", entryPrice, ") than minimum stoplevel(", minSL, ")");
    Print("Reconfigure parameters.");
    return False;
  }
  else if(stopLoss - entryPrice < minSL) {
    Print("SL(", stopLoss, ") is too closer to entry point(", entryPrice, ") than minimum stoplevel(", minSL, ")");
    Print("Reconfigure parameters.");
    return False;
  }
  else if(Bid - entryPrice < minSL) {
    return False;
  }
  else {
    int ticket1 = OrderSend(thisSymbol, OP_SELLSTOP, lot, entryPrice, 0, stopLoss, takeProfit);
    int ticket2 = OrderSend(thisSymbol, OP_SELLSTOP, lot, entryPrice, 0, stopLoss, 0);

    if(ticket1 == -1 && ticket2 != -1) {
      while(!OrderDelete(ticket2));
      return False;
    }
    else if(ticket1 != -1 && ticket2 == -1) {
      while(!OrderDelete(ticket1));
      return False;
    }
    else if(ticket1 == -1 && ticket2 == -1) {
      return False;
    }
    else {
      return True;
    }
  }
}




//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  if(DayOfWeek() < 2 || DayOfWeek() == 6) {
    return;
  }
  else if(DayOfWeek() == 5) {
    // close everything at Friday (24 - Base_Period_Friday_Hour_Shift):59
    if(1438 < 60 * (Hour() + Base_Period_Friday_Hour_Shift) + 59) {
      closeAll();
    }
  }

  countOrders();

   
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), symbol)) {
        if(OrderType() == OP_BUY) {
          longPos += 1;
          longPrice += OrderOpenPrice() * OrderLots();
          longLots += OrderLots();

          if(MathAbs(OrderOpenPrice() - price) < priceMargin && !overLapLong) {
            overLapLong = True;
          }

          double profit = OrderProfit() + OrderCommission() + OrderSwap();
          if(profit < lLargestLoss) {
            lLargestLoss = profit;
            lMostLostTicket = OrderTicket();
          }
        }
        else if(OrderType() == OP_SELL) {
          shortPos += 1;
          shortPrice += OrderOpenPrice() * OrderLots();
          shortLots += OrderLots();

          if(MathAbs(price - OrderOpenPrice()) < priceMargin && !overLapShort) {
            overLapShort = True;
          }
          
          double profit = OrderProfit() + OrderCommission() + OrderSwap();
          if(profit < sLargestLoss) {
            sLargestLoss = profit;
            sMostLostTicket = OrderTicket();
          }
        }
      }

      double profit = OrderProfit() + OrderCommission() + OrderSwap();
      if(profit < largestLoss) {
        largestLoss = profit;
        mostLostTicket = OrderTicket();
      }
    }
  }

  double stopLoss = iATR(symbol, PERIOD_M15, 7, 0);

  bool closeLong = False;
  bool closeLongLoss = False;  
  if(0.0 < longLots) {
    closeLong = (stopLoss / (longLots * 100.0) < Bid - (longPrice / longLots));
    closeLongLoss = (stopLoss < (longPrice / longLots - Ask));
  }

  bool closeShort = False;
  bool closeShortLoss = False;
  if(0.0 < shortLots) {
    closeShort = (stopLoss / (shortLots * 100.0) < (shortPrice / shortLots) - Ask);
    closeShortLoss = (stopLoss < (Bid - shortPrice / shortLots));
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
    if(OrderSelect(mostLostTicket, SELECT_BY_TICKET)) {
    
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
  
  if(closeLongLoss) {
    if(OrderSelect(lMostLostTicket, SELECT_BY_TICKET))
      if(OrderType() == OP_BUY)
        bool closed = OrderClose(lMostLostTicket, OrderLots(), Bid, 0);
  }
  
  if(closeShortLoss) {
    if(OrderSelect(sMostLostTicket, SELECT_BY_TICKET))
      if(OrderType() == OP_SELL)
        bool closed = OrderClose(sMostLostTicket, OrderLots(), Ask, 0);
  }
  
  
  if(!overLapLong && !closeLong) {
    if(longLots == 0.0) {
      longPrice = 1000.0;
      longLots = 1.0;
    }
    if(Ask < longPrice / longLots) {
      int ticket = OrderSend(symbol, OP_BUY, minLot, Ask, 0, 0, 0);
    }
  }
  if(!overLapShort && !closeShort) {
    if(shortLots == 0.0) {
      shortPrice = 0.0;
      shortLots = 1.0;
    }
    if(shortPrice / shortLots < Bid) {
      int ticket = OrderSend(symbol, OP_SELL, minLot, Bid, 0, 0, 0);
    }
  }
}

