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
  Print("AccountCredit=", AccountCredit());
  Print("AccountName=", AccountName());
  Print("AccountProfit=", AccountProfit());
  Print("IsDemo=", IsDemo());
  Print("AccountNumber=", AccountNumber());
  Print("AccountFreeMargin=", AccountFreeMargin());
   
  MIN_MARGIN = MarketInfo(Symbol(), MODE_STOPLEVEL);
  SPREAD = MarketInfo(Symbol(), MODE_SPREAD);
  Print("Symbol()=", Symbol());
  Print("MIN_MARGIN=", MIN_MARGIN);
  Print("SPREAD=", SPREAD);
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
double SPREAD;
double CONST_LOSS;
double margin;
double previousPrice;
int position = NONE;
bool hasWon = False;
int Ticket = -1;

#define MOD_ON_PROFIT (0)
#define MOD_ON_LOSS (1)

#define INITIAL_POSITION (0) //0:BUY, 1:SELL
#define POS_SIZING_FACTOR (0.0001) //position = AccountEquity() * POS_SIZING_FACTOR

extern int INIT_MARGIN = 80; //initial margin in pips
extern double MARGIN_FACTOR = 0.95; //margin factor
extern bool STRATEGY = 1; // 0:MOD_ON_PROFIT, 1:MOD_ON_LOSS

int nextPosition()
{
  if(position == NONE) {
    return(INITIAL_POSITION);
  }
  else if(hasWon) {
    return(position);
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
  //---
  /*
  int CurrentPosition = -1;
  int i;
  for(i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS))
      if(OrderSymbol() == Symbol())
         CurrentPosition = i;
     Print("i=", i);
  }
 
  if(CurrentPosition == -1) {
  */

  if(OrdersTotal() == 0) {

    double posSize = MathFloor(10.0 * AccountEquity() * POS_SIZING_FACTOR) * 0.1;

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
      if((STRATEGY == MOD_ON_LOSS && Bid < previousPrice) || (STRATEGY == MOD_ON_PROFIT && previousPrice < Bid)) {
         margin *= MARGIN_FACTOR;
         if(margin < MIN_MARGIN) {
      	   margin = MIN_MARGIN;
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
      if((STRATEGY == MOD_ON_LOSS && previousPrice < Ask) || (STRATEGY == MOD_ON_PROFIT && Ask < previousPrice)) {
        margin *= MARGIN_FACTOR;
        if(margin < MIN_MARGIN) {
          margin = MIN_MARGIN;
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
//+------------------------------------------------------------------+
