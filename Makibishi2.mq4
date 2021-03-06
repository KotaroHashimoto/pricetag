//+------------------------------------------------------------------+
//|                                                  MoneyGrower.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define NONE (-1)
int position = NONE;
int ticket = NONE;
double MAX_LOT = NONE;
bool timerStart = False;
uint time = 0;
double previousPrice = NONE;
double spread = NONE;

//#define C (0.01)
#define C (1) //for XM back test

//#define ACCEPTABLE_SPREAD (4) //for OANDA
#define ACCEPTABLE_SPREAD (3) //for FXTF1000

#define IND_PERIOD (3)

extern uint closeLimit = 10000; // in ms

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
  spread = ACCEPTABLE_SPREAD * Point;
  
  Print("ASK=", Ask);
  Print("BID=", Bid);
  
  MAX_LOT = MarketInfo(Symbol(), MODE_MAXLOT);
  MAX_LOT = 1.0;
  Print("MAX_LOT=", MAX_LOT);

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

int nextPosition(int current)
{
  if(current == NONE) {
    double pDI = iADX(Symbol(), PERIOD_M1, IND_PERIOD, PRICE_WEIGHTED, 1, 0);
    double nDI = iADX(Symbol(), PERIOD_M1, IND_PERIOD, PRICE_WEIGHTED, 2, 0);
//    Print("+DI(M15, 3)=", pDI);
//    Print("-DI(M15, 3)=", nDI);
    
    if(nDI < pDI) {
      return OP_BUY;
    }
    else if(pDI < nDI) {
      return OP_SELL;
    }
    else {
      return NONE;
    }
  }
  else {
    return current;
    /*
    if(current == OP_BUY) {
      if(previousPrice < Ask) {
        return OP_BUY;
      }
      else {
        return OP_SELL;
      }
    }
    else {
      if(previousPrice < Bid) {
        return OP_BUY;
      }
      else {
        return OP_SELL;
      }
    }*/
  }
}

void status() {
  
  int profit = (int)OrderProfit();
  string p;
  if(0 < profit) {
    p = ", Profit = +";
  }
  else {
    p = ", Profit = ";
  }
  
  if(timerStart) {
    Comment("Equity = ", AccountEquity(), p, profit, ", Time = ", closeLimit / 1000 - (GetTickCount() - time) / 1000);
  }
  else {
    Comment("Equity = ", AccountEquity(), p, profit);
  }
  
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{  
  if(OrdersTotal() == 0) {
    if((DayOfWeek() == 5 && 22 < Hour()) || DayOfWeek() == 6) {
//      Print("No entry on Friday night. Hour()=", Hour());
      position = NONE;
      return;
    }
    else if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
//      Print("No entry on wide spread: ", MarketInfo(Symbol(), MODE_SPREAD));
      position = NONE;
      return;
    }
/*
    double lotSize = MathFloor(100.0 * AccountEquity() * lotSizeFactor) / 100.0;
    if(MAX_LOT < lotSize) {
      lotSize = MAX_LOT;
    }*/
    
    position = nextPosition(position);
    if(position == OP_BUY) {
      ticket = OrderSend(Symbol(), OP_BUY, MAX_LOT, Ask, 0, Ask - 100 * Point, 0, NULL, 0, 0, NONE);
      previousPrice = Ask;
      timerStart = False;
    }
    else if(position == OP_SELL) {
      ticket = OrderSend(Symbol(), OP_SELL, MAX_LOT, Bid, 0, Bid + 100 * Point, 0, NULL, 0, 0, NONE);
      previousPrice = Bid;
      timerStart = False;
    }
    else {
      Print("Something Wrong with nextPositon() !!");
      Print("LastError=", GetLastError());
    }
/*
    if(ticket == NONE) {
      previousPrice = 
      position = nextPosition(position);
//      position = NONE;
//      stopPrice = NONE;
//      Print("OrderSend() failed. LastError=", GetLastError());
    }*/
  }
  
  else if(OrderSelect(ticket, SELECT_BY_TICKET) == True) {
    
    if(OrderType() == OP_BUY) {
      
      if((!timerStart) && Ask < OrderOpenPrice() - spread) {
        time = GetTickCount();
        timerStart = True;
//        Print("Timer started.");
      }
      else if(OrderOpenPrice() - spread <= Ask) {
        if(timerStart) {
//          Print("Timer canceled: ", closeLimit / 1000 - (GetTickCount() - time) / 1000);
        }
        timerStart = False;
      }
      else if(timerStart) {
//          Print("Timer: ", closeLimit / 1000 - (GetTickCount() - time) / 1000);
      }

      if((OrderOpenPrice() < Bid && OrderOpenPrice() < previousPrice - spread) || (timerStart && (closeLimit <= GetTickCount() - time))) {
        if(OrderProfit() < 0) {
          position = OP_SELL;
        }
        if(OrderClose(ticket, OrderLots(), Bid, 0, NONE)) {
          ticket = NONE;
        }
      }
      
      previousPrice = Ask;
    }
    else if(OrderType() == OP_SELL) {
      
      if((!timerStart) && OrderOpenPrice() + spread < Bid) {
        time = GetTickCount();
        timerStart = True;
//        Print("Timer started.");
      }
      else if(Bid <= OrderOpenPrice() + spread) {
        if(timerStart) {
//          Print("Timer canceled: ", closeLimit / 1000 - (GetTickCount() - time) / 1000);
        }
        timerStart = False;
      }
      else if(timerStart) {
//          Print("Timer: ", closeLimit / 1000 - (GetTickCount() - time) / 1000);
      }
      
      if((Ask < OrderOpenPrice() && previousPrice + spread < OrderOpenPrice()) || (timerStart && (closeLimit <= GetTickCount() - time))) {
        if(OrderProfit() < 0) {
          position = OP_BUY;
        }
        if(OrderClose(ticket, OrderLots(), Ask, 0, NONE)) {
          ticket = NONE;
        }
      }

      previousPrice = Bid;
    }
    else {
      Print("Something Wrong with OrderType() !!");
      Print("LastError=", GetLastError());
    }
    
//    status();
  }

  else {
    Print("Something Wrong with OrderSelect(ticket, SELECT_BY_TICKET), ticket=", ticket);
    Print("LastError=", GetLastError());
  }
}
