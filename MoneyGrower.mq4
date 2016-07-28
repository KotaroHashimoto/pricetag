//+------------------------------------------------------------------+
//|                                                  MoneyGrower.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
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
   
  MIN_MARGIN = MarketInfo(Symbol(), MODE_STOPLEVEL);
  spread = MarketInfo(Symbol(), MODE_SPREAD);
  Print("Symbol()=", Symbol());
  Print("MIN_MARGIN=", MIN_MARGIN);
  Print("SPREAD=", spread);
  Print("Point=", Point);
  Print("ASK=", Ask);
  Print("BID=", Bid);
   
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

#define NONE (-1)
double MIN_MARGIN;
double spread;
double margin;
double previousPrice = NONE;
int position = NONE;
bool hasWon = False;
int Ticket = -1;

#define INITIAL_POSITION (0) //0:BUY, 1:SELL
//#define POS_SIZING_FACTOR (0.00002) //position = AccountEquity() * POS_SIZING_FACTOR for USD
#define POS_SIZING_FACTOR (0.0000005) //position = AccountEquity() * POS_SIZING_FACTOR for JPY
#define ACCEPTABLE_SPREAD (4) //for OANDA
//#define ACCEPTABLE_SPREAD (3) //for FXTF

extern int INIT_MARGIN = 200;
extern double MARGIN_FACTOR = 1;

int nextPosition()
{
  if(position == NONE) {
    if(previousPrice < Ask) {
      return OP_BUY;
    }
    else if(Ask < previousPrice) {
      return OP_SELL;
    }
    else {
      return NONE;
    }
  }
  else {
    if(position == OP_BUY) {
      return OP_SELL;
    }
    else if(position == OP_SELL) {
      return OP_BUY;
    }
    else {
      return NONE;
    }
  }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  if(OrdersTotal() == 0) {
  
    if(ACCEPTABLE_SPREAD < MarketInfo(Symbol(), MODE_SPREAD)) {
      previousPrice = NONE;
      position = NONE;
      return;
    }
    else if(previousPrice == NONE) {
      previousPrice = Ask;
      position = NONE;
      return;
    }

    double posSize = MathFloor(10.0 * AccountEquity() * POS_SIZING_FACTOR) * 0.1; //for OANDA
    /*
    if(10 < posSize) {
      posSize = 10.0; // for OANDA basic course
    }*/

    if(nextPosition() == OP_BUY) {
      Ticket = OrderSend(Symbol(), OP_BUY, posSize, Ask, 3, Bid - (INIT_MARGIN*Point), 0, NULL, 0, 0, Red);
      previousPrice = Bid;
    }
    else if(nextPosition() == OP_SELL) {
      Ticket = OrderSend(Symbol(), OP_SELL, posSize, Bid, 3, Ask + (INIT_MARGIN*Point), 0, NULL, 0, 0, Blue); 
      previousPrice = Ask;
    }
    else {
      Print("Something Wrong with nextPositon() !!");
    }
    hasWon = False;
    margin = INIT_MARGIN;
  }

  else if(OrderSelect(Ticket, SELECT_BY_TICKET) == True) {      
  
    if(OrderType() == OP_BUY) {
      if(Bid < previousPrice) {
         margin *= MARGIN_FACTOR;
         if(margin < MIN_MARGIN) {
      	   margin = MIN_MARGIN;
        } //ここを、定数*(previousPrice - Bid)縮めるように変更する
      }
      else if(previousPrice < Bid) {
         margin /= MARGIN_FACTOR;
         if(INIT_MARGIN < margin) {
      	   margin = INIT_MARGIN;
        }
      }
       
      if(OrderStopLoss() < Bid - (margin*Point)) {
        bool modified = OrderModify(Ticket, OrderOpenPrice(), Bid - (margin*Point), 0, 0, Red);

        if(modified && OrderOpenPrice() < OrderStopLoss()) {
          hasWon = True;
        }
      }

      position = OP_BUY;
      previousPrice = Bid;
    }
    else if(OrderType() == OP_SELL) {
      if(previousPrice < Ask) {
         margin *= MARGIN_FACTOR;
         if(margin < MIN_MARGIN) {
      	   margin = MIN_MARGIN;
        }
      }
      else if(Ask < previousPrice) {
         margin /= MARGIN_FACTOR;
         if(INIT_MARGIN < margin) {
      	   margin = INIT_MARGIN;
        }
      }

      if(Ask + (margin*Point) < OrderStopLoss()) {
        bool modified = OrderModify(Ticket, OrderOpenPrice(), Ask + (margin*Point), 0, 0, Blue);

        if(modified && OrderStopLoss() < OrderOpenPrice()) {
          hasWon = True;
        }
      }
                     
      position = OP_SELL;
      previousPrice = Ask;
    }
    else {
      Print("Something Wrong with OrderType() !!");
    }
  }

  else {
    Print("Something Wrong with OrderSelect(Ticket, SELECT_BY_TICKET), Ticket=", Ticket);
  }
}
