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

//int margin = 30; //for USDJPY
extern int initMargin = 80; //initial margin in pips
extern double marginFactor = 0.95; //margin factor
extern int initialPosition = OP_BUY; //0:BUY, 1:SELL

#define NONE (-1)
double MIN_MARGIN;
double SPREAD;
double CONST_LOSS;
double margin;
double previousPrice;
int position = NONE;
bool hasWon = False;
int Ticket = -1;

int nextPosition()
{
  if(position == NONE) {
    return(initialPosition);
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
    if(nextPosition() == OP_BUY) {
      Ticket = OrderSend(Symbol(), OP_BUY, 1, Ask, 3, Bid - (initMargin*Point), 0, NULL, 0, 0, Red);
      previousPrice = Bid;
    }
    else if(nextPosition() == OP_SELL) {
      Ticket = OrderSend(Symbol(), OP_SELL, 1, Bid, 3, Ask + (initMargin*Point), 0, NULL, 0, 0, Blue); 
      previousPrice = Ask;
    }
    else {
      Print("Something Wrong with nextPositon() !!");
    }
    hasWon = False;
    margin = initMargin;
  }
  else if(OrderSelect(Ticket, SELECT_BY_TICKET) == True) {
      
    if(OrderType() == OP_BUY) {
//      if(previousPrice < Bid) {
      if(Bid < previousPrice) {
         margin = margin * marginFactor;
	      if(margin < MIN_MARGIN) {
      	   margin = MIN_MARGIN;

/*      	   
	         if(OrderOpenPrice() < Bid) {
   	         bool modified = OrderClose(OrderTicket(), OrderLots(), Bid, 3, Blue);
   	         return;
	         }
*/
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
//      if(Ask < previousPrice) {
      if(previousPrice < Ask) {
	      margin = margin * marginFactor;
	      if(margin < MIN_MARGIN) {
	         margin = MIN_MARGIN;
/*
	         if(Ask < OrderOpenPrice()) {
   	         bool modified = OrderClose(OrderTicket(), OrderLots(), Ask, 3, Red);
   	         return;
	         }
*/
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
