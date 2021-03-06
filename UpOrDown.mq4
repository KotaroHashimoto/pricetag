//+------------------------------------------------------------------+
//|                                                     UpOrDown.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

string buttonID = "BI";
string CurrencyPairs[] = {"EURUSD", "EURJPY", "USDJPY", "GBPUSD", "GBPJPY", 
                          "AUDUSD", "AUDJPY", "EURGBP", "EURAUD", "GBPAUD"};

int OnInit()
  {
//---
  ObjectCreate(0, buttonID, OBJ_BUTTON, 0, 100, 100);
  ObjectSetInteger(0, buttonID, OBJPROP_COLOR, clrWhite);
  ObjectSetInteger(0, buttonID, OBJPROP_BGCOLOR, clrGray);
  ObjectSetInteger(0, buttonID, OBJPROP_XDISTANCE, 30);
  ObjectSetInteger(0, buttonID, OBJPROP_YDISTANCE, 50);
  ObjectSetInteger(0, buttonID, OBJPROP_XSIZE, 150);
  ObjectSetInteger(0, buttonID, OBJPROP_YSIZE, 50);
  ObjectSetString(0, buttonID, OBJPROP_FONT, "Arial");
  ObjectSetString(0, buttonID, OBJPROP_TEXT, "Generate File");
  ObjectSetInteger(0, buttonID, OBJPROP_FONTSIZE, 15);
  ObjectSetInteger(0, buttonID, OBJPROP_SELECTABLE, 0);

//---
  return(INIT_SUCCEEDED);
}

string determine(double ma, double price) {

  if(ma == 0 || price == 0) {
    return "err";
  }
  else if(price < ma) {
    return "下落";
  }
  else {
    return "上昇";
  }
}

void generateFile() {

  int isLive = MarketInfo(Symbol(), MODE_TRADEALLOWED);
  string date = string(Year()) + "_" + string(Month()) + "_" + string((Day() - isLive));
  int handle=FileOpen("TrendAnalysis.csv", FILE_CSV|FILE_WRITE, ',');
  if(handle < 0) {
    Print("File write error. " + string(GetLastError()));
    return;
  }
  else {
    FileWrite(handle, date);
    FileWrite(handle, "CurrencyPair", "5SMA", "25SMA");
  }
   
  for(int i = 0; i < 10; i++) {
  
    double ma5 = iMA(CurrencyPairs[i], PERIOD_D1, 5, 0, MODE_SMA, PRICE_CLOSE, isLive);
    double ma25 = iMA(CurrencyPairs[i], PERIOD_D1, 25, 0, MODE_SMA, PRICE_CLOSE, isLive);
    double price = iClose(CurrencyPairs[i], PERIOD_D1, isLive);
    
    FileWrite(handle, CurrencyPairs[i], determine(ma5, price), determine(ma25, price));
    Print(CurrencyPairs[i], " = ", price, ", ma5 = ", ma5, ", ma25 = ", ma25);
  }
  
  FileClose(handle);
  Print(date, " file write succeeded.");
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ObjectDelete(0, buttonID);   
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
  if(id == CHARTEVENT_OBJECT_CLICK) {
    string clickedChartObject = sparam;
    if(clickedChartObject == buttonID) {
      generateFile();
      
      Sleep(500);
      ObjectSetInteger(0, buttonID, OBJPROP_STATE, 0);      
    }
  }
}
