/*
 * OANDA Historical Position Ratios Demo.  MQL script that overlays historical position ratios on part of current chart.  
 */ 
#include <fxlabsnet.mqh>

#property link        "http://www.oanda.com"
#property description "Overlay historical client position ratios on current chart."

int init()
{
   ObjectsDeleteAll(); 
   init_fxlabs(); 
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
   datetime endtime = TimeCurrent();
   
   string symbol = Symbol(); 
   int pos = StringLen(symbol)-3; 
   symbol = StringConcatenate(StringSubstr(symbol, 0, pos), "_", StringSubstr(symbol, pos));
      
   int hpr_ref = hpr(symbol, TimeCurrent() - begintime);
   int sz = hpr_sz(hpr_ref); 
   
   double minprice = 10000000; 
   double maxprice = 0; 
   for (int j = 0; j < Bars; j++) {
      if (maxprice < High[j]) maxprice = High[j]; 
      if (minprice > Low[j]) minprice = Low[j];         
      if (Time[j] < begintime) break; 
   }
   double midpt = (minprice + maxprice)/2.0; 
      
   for(int i = 0; i < sz; i++) {
      
      int ts = convert_to_mt4_time(hpr_ts(hpr_ref, i)); 
      
      int next_ts = TimeCurrent(); 
      if (i < sz-1) {      
         next_ts = convert_to_mt4_time(hpr_ts(hpr_ref,i+1)); 
      }
            
      double perc = hpr_percentage(hpr_ref,i); 
      
      double npl = 2.0*perc - 100.0; 
      double percshort = 100.0 - perc; 
      double rprice; 
      
      double rpriceshort = midpt - (midpt-minprice)*(percshort/100.0); 
      double rpricelong = midpt + (maxprice-midpt)*(perc/100.0); 
      if (npl < 0.0) {
         rprice = midpt + (midpt-minprice)*(npl/100.0); 
      } else {
         rprice = midpt + (maxprice-midpt)*(npl/100.0); 
      }
      
      string labellong = StringConcatenate("hpr_long",i);
      string labelshort = StringConcatenate("hpr_short",i);
      
      if(!ObjectCreate(labellong, OBJ_RECTANGLE, 0, ts, midpt, next_ts, rpricelong))
      {
         Print("error: can't create text_object! code #",GetLastError());
         return(0);
      }
      if(!ObjectCreate(labelshort, OBJ_RECTANGLE, 0, ts, midpt, next_ts, rpriceshort))
      {
         Print("error: can't create text_object! code #",GetLastError());
         return(0);
      }
      ObjectSet(labelshort, OBJPROP_COLOR, OrangeRed); 
      ObjectSet(labellong, OBJPROP_COLOR, BurlyWood); 
      string dlong = StringConcatenate(perc, " % long"); 
      string dshort = StringConcatenate(percshort, " % short"); 
      ObjectSetText(labelshort, dshort, 10, "Times New Roman", Orange); 
      ObjectSetText(labellong, dlong, 10, "Times New Roman", Orange); 
      
   }
   hpr_free(hpr_ref); 
   WindowRedraw();

   
//----
   return(0);
  }
//+------------------------------------------------------------------+
