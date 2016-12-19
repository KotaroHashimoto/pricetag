/*
 * OANDA Calendar Demo. Script that overlays calendar events on part of current chart. 
 */ 

#include <fxlabsnet.mqh>

#property link        "http://www.oanda.com"
#property description "Overlay calendar headlines on current chart."

int init()
{
   init_fxlabs(); 
   ObjectsDeleteAll(); 
   return(0); 
}

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//----
   int firstbar = WindowFirstVisibleBar(); 
   datetime begintime = Time[firstbar]; //TimeCurrent() - 60*60*48;
   
   string symbol = Symbol(); 
   int pos = StringLen(symbol)-3; 
   symbol = StringConcatenate(StringSubstr(symbol, 0, pos), "_", StringSubstr(symbol, pos));

   int cal_ref = calendar(symbol, TimeCurrent()-begintime);
   if (cal_ref < 0) 
   {
      // an error occurred   
      return(0);
   }
   
   int sz = calendar_sz(cal_ref);    
   if (sz < 0) 
   {
      // an error occurred    
      return(0);
   }
   string headlines[];
   int times[];
   string currency[];
   ArrayResize(times, sz);
   ArrayResize(headlines, sz);
   ArrayResize(currency, sz); 
   
   for (int i = 0; i < sz; i++)
   {
      times[i] = calendar_ts(cal_ref, i); 
      headlines[i] = calendar_headline(cal_ref, i); 
      currency[i] = calendar_currency(cal_ref, i); 
   }
    
   convert_to_mt4_time_arr(times);  
   
   for(int i = 0; i < sz; i++) {      
      string headline = headlines[i];
      // alternative way of getting the current headline:
      //string headline = calendar_headline(cal_ref, i); 
            
      int ts = times[i]; 
      // alternative way of the getting the current timestamp:
      //int ts = calendar_ts(cal_ref, i); 
      string label = StringConcatenate("calendar_obj",i);
      double minprice = 10000000; 
      double maxprice = 0; 
      for (int j = 0; j < Bars; j++) {         
         maxprice = High[j]; 
         minprice = Low[j]; 
         if (Time[j] > ts) continue; 
         break; 
      }     
      if(!ObjectCreate(0,label, OBJ_ARROW, 0, ts, minprice))
      {
         Print("error: can't create text_object! code #",GetLastError());
         return(0);
      }
      ObjectSet(label, OBJPROP_ARROWCODE, SYMBOL_STOPSIGN); 
      ObjectSet(label, OBJPROP_COLOR, Orange); 
      ObjectSet(label, OBJPROP_SCALE, 10.0); 
      ObjectSet(label, OBJPROP_BACK, false); 
      
      ObjectSetString(0,label, OBJPROP_TEXT, headline); 
   }
   calendar_free(cal_ref); 
   WindowRedraw();
   
//----
   return(0);
  }

