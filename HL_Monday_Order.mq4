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
input double MM_Rate = 100000;
 // entry lot = AccountEquity() / MM_Rate * 0.01

input bool Auto_Lot = True;
input double Auto_Lot_Adjust_Times = 1.0;

input int Base_Period_Friday_Hour_Shift = 2;

input double Divided_By_Width_To_Launch = 3.0;
input double TP_Width_To_Launch_Times = 2.0;
input double Buy_Entry_Adjust_Pips = 1.5;
input double Buy_SL_Adjust_Pips = 1.0;
input double Buy_TP_Adjust_Pips = 1.0;
input double Sell_Entry_Adjust_Pips = 1.0;
input double Sell_SL_Adjust_Pips = 1.0;
input double Sell_TP_Adjust_Pips = 1.0;


string thisSymbol;

double mondayHigh;
double mondayLow;

int sellOrderCount;
int buyOrderCount;

const string hLineID = "Monday High";
const string lLineID = "Monday Low";
const string w2lID = "Width to Launch";
const string closeID = "Closing Time";


#define  HR2400 86400       // 24 * 3600
int      TimeOfDay(datetime when){  return( when % HR2400          );         }
datetime DateOfDay(datetime when){  return( when - TimeOfDay(when) );         }
datetime Today(){                   return(DateOfDay( TimeCurrent() ));       }
datetime Tomorrow(int shift){       return(Today() + HR2400 * shift);         }



double widthToLaunch() {
  return MathCeil(((mondayHigh - mondayLow) / Divided_By_Width_To_Launch) * 1000.0) / 1000.0;
}


void drawHLine(string id, double pos, string label, color clr = clrYellow, int width = 1, int style = 1, bool selectable = false) {

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
//  ObjectSetText(id, label + ": " + DoubleToString(pos, 3), 12, "Arial", clr);
}


void drawVLine(string hour, string minute, color clr = clrAqua, int width = 1, int style = 1) {

  if(style < 0 || 4 < style) {
    style = 0;
  }
  if(width < 1) {
    width = 1;
  }

  time = StrToTime(TimeToStr(Tomorrow(DayOfWeek() - 5), TIME_DATE) + " " + hour + ":" + minute);

  ObjectCreate(closeID, OBJ_VLINE, 0, time, 0);
  ObjectSet(closeID, OBJPROP_WIDTH, width);
  ObjectSet(closeID, OBJPROP_COLOR, clr);
  ObjectSet(closeID, OBJPROP_STYLE, style);
  ObjectSet(closeID, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
  
  ObjectSetInteger(0, id + "t", OBJPROP_SELECTABLE, false);
//  ObjectSetText(id + "t", label, 12, "Arial", clr);
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  int dow = DayOfWeek();
  if(dow == 0 || dow == 6) {
    dow = 5;
  }
  
  mondayHigh = iHigh(Symbol(), PERIOD_D1, dow - 1);
  mondayLow = iLow(Symbol(), PERIOD_D1, dow - 1);

  drawHLine(hLineID, mondayHigh, hLineID);
  drawHLine(lLineID, mondayLow, lLineID);

  drawVLine(23 - Base_Period_Friday_Hour_Shift, 59);
  
  ObjectCreate(0, w2lID, OBJ_LABEL, 0, 0, 0);
  ObjectSetInteger(0, w2lID, OBJPROP_CORNER, CORNER_LEFT_UPPER);

  ObjectSet(w2lID, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
  
  ObjectSetInteger(0, w2lID, OBJPROP_SELECTABLE, false);
  
//  string lbl = "Monday High: " + DoubleToStr(iHigh(Symbol(), PERIOD_D1, dow - 1)) + "¥n";
//  lbl = lbl + "Monday Low: " + DoubleToStr(iLow(Symbol(), PERIOD_D1, dow - 1)) + "¥n";
//  lbl = lbl + "Width to Launch: " + DoubleToString(widthToLaunch(), 3);
  string lbl = "Width to Launch: " + DoubleToString(widthToLaunch(), 3);
  ObjectSetText(w2lID, lbl, 16, "Arial", clrYellow);
  
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
  ObjectDelete(0, hLineID);
  ObjectDelete(0, lLineID);
  ObjectDelete(0, w2lID);
  ObjectDelete(0, closeID);

  //---   
}

bool closeAll(bool pendingOnly = False) {

  int toClose = 0;
  int initialTotal = OrdersTotal();

  for(int i = 0; i < initialTotal; i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol)) {
        if(OrderType() == OP_BUY && !pendingOnly) {
          toClose ++;
          if(!OrderClose(OrderTicket(), OrderLots(), MarketInfo(thisSymbol, MODE_BID), 0)) {
            Print("Error on closing long order: ", GetLastError());
          }
        }
        else if(OrderType() == OP_SELL && !pendingOnly) {
          toClose ++;
          if(!OrderClose(OrderTicket(), OrderLots(), MarketInfo(thisSymbol, MODE_ASK), 0)) {
            Print("Error on closing short order: ", GetLastError());
          }
        }
        else if(OrderType() == OP_BUYSTOP) {
          toClose ++;
          if(!OrderDelete(OrderTicket())) {
            Print("Error on deleting buy stop order: ", GetLastError());
          }
        }
        else if(OrderType() == OP_SELLSTOP) {
          toClose ++;
          if(!OrderDelete(OrderTicket())) {
            Print("Error on deleting sell stop order: ", GetLastError());
          }
        }
      }
    }
  }
  
  return (initialTotal - toClose == OrdersTotal());
}

bool validateParameters() {

  if(MM_Rate == 0.0) {
    Print("MM_Rate must be grater than zero.");
    return False;
  }
  else if(Divided_By_Width_To_Launch == 0.0) {
    Print("Divided_By_Width_To_Launch must be grater than zero.");
    return False;
  }
  else if(mondayHigh == mondayLow) {
    return False;
  }

  return True;
}


void countOrders() {

  sellOrderCount = 0;
  buyOrderCount = 0;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol)) {
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
    double lot = AccountEquity() * 0.0000001 / widthToLaunch() * Auto_Lot_Adjust_Times;
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

  double entryPrice = mondayHigh + (Buy_Entry_Adjust_Pips * Point * 10.0);
  double stopLoss = entryPrice - widthToLaunch() - (Buy_SL_Adjust_Pips * Point * 10.0);
  double takeProfit = entryPrice + (widthToLaunch() * TP_Width_To_Launch_Times) + (Buy_TP_Adjust_Pips * Point * 10.0);

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
      while(!OrderDelete(ticket2)) {
        Sleep(1000);
      }
      return False;
    }
    else if(ticket1 != -1 && ticket2 == -1) {
      while(!OrderDelete(ticket1)) {
        Sleep(1000);
      }
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

  double entryPrice = mondayLow - (Sell_Entry_Adjust_Pips * Point * 10.0);
  double stopLoss = entryPrice + widthToLaunch() + (Sell_SL_Adjust_Pips * Point * 10.0);
  double takeProfit = entryPrice - (widthToLaunch() * TP_Width_To_Launch_Times) - (Sell_TP_Adjust_Pips * Point * 10.0);

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
      while(!OrderDelete(ticket2)) {
        Sleep(1000);
      }
      return False;
    }
    else if(ticket1 != -1 && ticket2 == -1) {
      while(!OrderDelete(ticket1)) {
        Sleep(1000);
      }
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
  if(!validateParameters()) {
    return;
  }
  else if(DayOfWeek() < 2 || DayOfWeek() == 6) {
    if(mondayHigh != 0.0) {
      OnDeinit(0);
      mondayHigh = 0.0;
    }
    return;
  }
  else if(DayOfWeek() == 2) {
    if(mondayHigh == 0.0) {
      OnInit();
    }
  }
  else if(DayOfWeek() == 5) {
    // close everything at Friday (24 - Base_Period_Friday_Hour_Shift):59
    if(1438 < 60 * (Hour() + Base_Period_Friday_Hour_Shift) + 59) {
      closeAll();
      return;
    }
  }

  countOrders();

  if(buyOrderCount == 0) {
    orderLong(calcLot());
  }
  if(sellOrderCount == 0) {
    orderShort(calcLot());
  }
}
