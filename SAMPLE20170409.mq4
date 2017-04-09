#property  copyright "t.t"
#property link "http://fx-on.com"

extern int MAGIC1 = 1;
extern double Lots = 0.1;
extern int StopLoss = 100;
extern int TakeProfit = 100;
extern int Slippage = 5;
extern string COMMENT = "EAつくーる";
extern double Max_Spread = 10;

int nowbar1;
int Mult = 1;
bool Trade = true;
color ArrowColor[2] = {Blue, Red};

//--------------------------------------------------------------------------------------------------------+
//初期化処理                                                                                              |
//--------------------------------------------------------------------------------------------------------+
int OnInit(){
   if(StringFind(Symbol(), "USDJPY", 0) == -1){
      Trade = false;
      Alert("このEAはUSDJPYでのみ運用できます");
   }

   if(Period() != 5){
      Trade = false;
      Alert("このEAは5分足でのみ運用できます");
   }

   if(IsTradeAllowed() == false) Alert("Enable the setting 'Allow live trading' in the Expert Properties!");
   MultCal();
   return(INIT_SUCCEEDED);
}

//--------------------------------------------------------------------------------------------------------+
//終了処理                                                                                                |
//--------------------------------------------------------------------------------------------------------+
void OnDeinit(const int reason){

}

//--------------------------------------------------------------------------------------------------------+
//メイン処理                                                                                              |
//--------------------------------------------------------------------------------------------------------+
void OnTick(){
   double lots;

   if(Trade == false) return;

   Trade = false;
   if(DayOfWeek() == 1 || DayOfWeek() == 0) Trade = true;
   if(DayOfWeek() == 2) Trade = true;
   if(DayOfWeek() == 3) Trade = true;
   if(DayOfWeek() == 4) Trade = true;
   if(DayOfWeek() == 5) Trade = true;
   if(DayOfWeek() == 6) Trade = true;
   if(Trade == false){
      Trade = true;
      return;
   }

   if(MarketInfo(Symbol(), MODE_SPREAD) > Max_Spread * Mult) return;

   TimeExit(MAGIC1);

   int sig_entry1 = EntrySignal1(MAGIC1);
   if(TradeStopTime(sig_entry1, StartTime1, EndTime1) == 0) sig_entry1 = 0;

   int sig_entry2 = EntrySignal2(MAGIC1);
   if(TradeStopTime(sig_entry2, StartTime1, EndTime1) == 0) sig_entry2 = 0;

   sig_entry1 = HedgeCheck(sig_entry1);
   if(sig_entry1 != 0 && nowbar1 != Bars){
      lots = Lots;
      if(OS(sig_entry1, 0, lots, StopLoss, TakeProfit, MAGIC1, 0) == true){
         //注文成功後の処理
         nowbar1 = Bars;
      }
   }

   sig_entry2 = HedgeCheck(sig_entry2);
   if(sig_entry2 != 0 && nowbar1 != Bars){
      lots = Lots;
      if(OS(sig_entry2, 0, lots, StopLoss, TakeProfit, MAGIC1, 0) == true){
         //注文成功後の処理
         nowbar1 = Bars;
      }
   }

   return;
}

extern int Candle_Stick_Shift1 = 0;
extern int MA_Period1 = 10;
extern int MA_Slide1 = 0;
extern int MA_Shift1 = 0;
int EntrySignal1(int magic){
   int sig;
   int ret;
   double pos = CurrentOrders(magic);
   double val1 = iClose(Symbol(), 0, Candle_Stick_Shift1);
   double val2 = iMA(Symbol(), 0, MA_Period1, MA_Slide1, MODE_SMA, PRICE_CLOSE, MA_Shift1);
   if(val1 > val2) sig = 1;
   if(pos == 0 && sig == 1)  ret = 1;
   if(pos == 0 && sig == -1) ret = -1;
   return(ret);
}

extern int Candle_Stick_Shift2 = 0;
extern int MA_Period2 = 10;
extern int MA_Slide2 = 0;
extern int MA_Shift2 = 0;
int EntrySignal2(int magic){
   int sig;
   int ret;
   double pos = CurrentOrders(magic);
   double val1 = iClose(Symbol(), 0, Candle_Stick_Shift2);
   double val2 = iMA(Symbol(), 0, MA_Period2, MA_Slide2, MODE_SMA, PRICE_CLOSE, MA_Shift2);
   if(val1 < val2) sig = -1;
   if(pos == 0 && sig == 1)  ret = 1;
   if(pos == 0 && sig == -1) ret = -1;
   return(ret);
}


//--------------------------------------------------------------------------------------------------------+
//売買種別確認関数                                                                                        |
//   処理:特定のマジックナンバーのポジション数を確認し、買いポジションであればロット数を正の値で返す。    |
//        売りポジションであればロット数を負の値で返す。                                                  |
//   引数:売買種別を確認したいポジションのマジックナンバー                                                |
//   戻り値:売買種別(買い:正の値, 売り:負の値, ポジション無し:0)                                          |
//--------------------------------------------------------------------------------------------------------+
double CurrentOrders(int magic){
   double lots = 0.0;
   for(int i=0; i<OrdersTotal(); i++){
      if(OrderSelect(i, SELECT_BY_POS) == false) break;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
      if(OrderType() == OP_BUY) lots += OrderLots();
      if(OrderType() == OP_SELL) lots -= OrderLots();
      if(OrderType() == OP_BUYLIMIT) lots += OrderLots();
      if(OrderType() == OP_SELLLIMIT) lots -= OrderLots();
      if(OrderType() == OP_BUYSTOP) lots += OrderLots();
      if(OrderType() == OP_SELLSTOP) lots -= OrderLots();
   }
   return(lots);
}

//--------------------------------------------------------------------------------------------------------+
//ロット数調整用関数                                                                                      |
//   処理:ロット数がブローカーごとの最大ロット数、最小ロット数、最小取引数量に適しているかを確認する。    |
//        確認後、不適切な数値であれば修正した数値を返す。                                                |
//   引数:ロット数                                                                                        |
//   戻り値:ブローカーに合わせて調整されたロット数                                                        |
//--------------------------------------------------------------------------------------------------------+
double LotsCal(double lots){
   if(lots < MarketInfo(Symbol(), MODE_MINLOT)) lots = MarketInfo(Symbol(), MODE_MINLOT);
   if(lots > MarketInfo(Symbol(), MODE_MAXLOT)) lots = MarketInfo(Symbol(), MODE_MAXLOT);
   if(MarketInfo(Symbol(), MODE_LOTSTEP) == 1){
      lots = NormalizeDouble(lots, 0);
   }else if(MarketInfo(Symbol(), MODE_LOTSTEP) == 0.1){
      lots = NormalizeDouble(lots, 1);
   }else{
      lots = NormalizeDouble(lots, 2);
   }
   return(lots);
}

//--------------------------------------------------------------------------------------------------------+
//レートの桁数対応関数                                                                                    |
//   処理:ブローカーが配信するレートの小数点以下の桁数を確認し、                                          |
//        グローバル変数 Mult の値を適正値に設定する。                                                    |
//   引数:無し                                                                                            |
//   戻り値:無し                                                                                          |
//--------------------------------------------------------------------------------------------------------+
void MultCal(){
   if(Digits == 4 || Digits == 2) Mult = 1;
   if(Digits == 5 || Digits == 3) Mult = 10;
}

//--------------------------------------------------------------------------------------------------------+
//エントリー注文送信用関数                                                                                |
//   処理:エントリー注文に必要な数値が正しいかを確認し、エントリー注文を送信する。                        |
//        続けてエントリーしたポジションに対して、                                                        |
//        ストップロスとテイクプロフィットを設定するための注文を送信する。                                |
//   引数:売買種別(買い:正の整数, 売り:負の整数), ロット数, ストップロス, テイクプロフィット              |
//         マジックナンバー                                                                               |
//   戻り値:処理結果(true:注文成功, false:注文失敗)                                                       |
//--------------------------------------------------------------------------------------------------------+
bool OS(int sig, double price, double lots, double sl, double tp, int magic, int sec){
   int type = -1;
   double pos = CurrentOrders(magic);
   datetime expiration = 0;
   lots = LotsCal(lots);
   if(sig == 1 && pos <= 0){
      type = 0;
      price = Ask;
      if(sl > 0) sl = Ask - sl * Point * Mult;
      if(tp > 0) tp = Ask + tp * Point * Mult;
   }
   if(sig == -1 && pos >= 0){
      type = 1;
      price = Bid;
      if(sl > 0) sl = Bid + sl * Point * Mult;
      if(tp > 0) tp = Bid - tp * Point * Mult;
   }
   if(sig == 2 && pos <= 0){
      type = 2;
      expiration = TimeCurrent() + sec;
      if(sl > 0) sl = price - sl * Point * Mult;
      if(tp > 0) tp = price + tp * Point * Mult;
   }
   if(sig == -2 && pos >= 0){
      type = 3;
      expiration = TimeCurrent() + sec;
      if(sl > 0) sl = price + sl * Point * Mult;
      if(tp > 0) tp = price - tp * Point * Mult;
   }
   if(sig == 3 && pos <= 0){
      type = 4;
      expiration = TimeCurrent() + sec;
      if(sl > 0) sl = price - sl * Point * Mult;
      if(tp > 0) tp = price + tp * Point * Mult;
   }
   if(sig == -3 && pos >= 0){
      type = 5;
      expiration = TimeCurrent() + sec;
      if(sl > 0) sl = price + sl * Point * Mult;
      if(tp > 0) tp = price - tp * Point * Mult;
   }
   if(sec == 0) expiration = 0;
   if(type >= 0 && price != 0){
      price = NormalizeDouble(price, Digits);
      sl = NormalizeDouble(sl, Digits);
      tp = NormalizeDouble(tp, Digits);
      int starttime = GetTickCount();
      while(true){
         if(GetTickCount() - starttime > 10 * 1000){
            Alert("OrderSend timeout. Check the experts log.");
            return(false);
         }
         if(IsTradeAllowed() == true){
            RefreshRates();
            if(type == 0 || type == 1){
               if(OrderSend(Symbol(), type, lots, price, Slippage * Mult, 0, 0, COMMENT, magic, expiration, ArrowColor[type]) != -1){
                  OM(sl, tp, magic);
                  return(true);
               }
            }else{
               if(OrderSend(Symbol(), type, lots, price, Slippage * Mult, sl, tp, COMMENT, magic, expiration, ArrowColor[type]) != -1){
                  return(true);
               }
            }
            int err = GetLastError();
            Print("[OrderSendError] : ", err, " ", ErrorDescription(err));
            if(err == 129) break;
            if(err == 130){
               Print("INVALID_STOPS Price:", price, " SL:", sl, "TP:", tp);
               break;
            }
         }
         Sleep(100);
      }
   }
   return(false);
}

//--------------------------------------------------------------------------------------------------------+
//ポジション情報(ストップロス, テイクプロフィット)変更用関数                                              |
//   処理:オープンポジションのストップロス、テイクプロフィットの変更注文を送信する。                      |
//   引数:ストップロス, テイクプロフィットを変更するポジションのマジックナンバー                          |
//   戻り値:処理結果(true:変更成功, false:変更失敗)                                                       |
//--------------------------------------------------------------------------------------------------------+
bool OM(double sl, double tp, int magic){
   int ticket = 0;
   for(int i = 0; i < OrdersTotal(); i++){
      if(OrderSelect(i, SELECT_BY_POS) == false) break;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
      int type = OrderType();
      if(type == OP_BUY || type == OP_SELL){
         ticket = OrderTicket();
         break;
      }
   }
   if(ticket == 0) return(false);
   sl = NormalizeDouble(sl, Digits);
   tp = NormalizeDouble(tp, Digits);
   if(sl == 0) sl = OrderStopLoss();
   if(tp == 0) tp = OrderTakeProfit();
   if(OrderStopLoss() == sl && OrderTakeProfit() == tp) return(false);
   int starttime = GetTickCount();
   while(true){
      if(GetTickCount() - starttime > 10 * 1000){
         Alert("OrderModify timeout. Check the experts log.");
         return(false);
      }
      if(IsTradeAllowed() == true){
         if(OrderModify(ticket, 0, sl, tp, 0) == true) return(true);
         int err = GetLastError();
         Print("[OrderModifyError] : ", err, " ", ErrorDescription(err));
         if(err == 1) break;
         if(err == 130) break;
      }
      Sleep(100);
   }
   return(false);
}

//--------------------------------------------------------------------------------------------------------+
//ポジション決済用関数                                                                                    |
//   処理:ポジションの決済注文を送信する。                                                                |
//   引数:決済するポジションのマジックナンバー                                                            |
//   戻り値:処理結果(true:決済成功, false:決済失敗)                                                       |
//--------------------------------------------------------------------------------------------------------+
bool OC(int magic){
   double pos = CurrentOrders(magic);
   while(pos != 0){
      int ticket = 0;
      for(int i=0; i<OrdersTotal(); i++){
         if(OrderSelect(i, SELECT_BY_POS) == false) break;
         if(OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
         int type = OrderType();
         if(type == OP_BUY || type == OP_SELL){
            ticket = OrderTicket();
            break;
         }
      }
      if(ticket == 0) break;
      int starttime = GetTickCount();
      while(true){
         if(GetTickCount() - starttime > 10 * 1000){
            Alert("OrderClose timeout. Check the experts log.");
            return(false);
         }
         if(IsTradeAllowed() == true){
            RefreshRates();
            if(OrderClose(ticket, OrderLots(), OrderClosePrice(), Slippage, ArrowColor[type]) == true) break;
            int err = GetLastError();
            Print("[OrderCloseError] : ", err, " ", ErrorDescription(err));
            if(err == 129) break;
         }
         Sleep(100);
         pos = CurrentOrders(magic);
      }
   }
   return(false);
}

//--------------------------------------------------------------------------------------------------------+
//損益取得関数                                                                                            |
//   処理:ポジションの損益を取得。                                                                        |
//   引数:損益を取得するポジションのマジックナンバー                                                      |
//   戻り値:ポジションの損益                                                                              |
//--------------------------------------------------------------------------------------------------------+
double getOrderProfit(int magic){
   double profit;
   for(int i = 0; i < OrdersTotal(); i++){
      if(OrderSelect(i, SELECT_BY_POS,MODE_TRADES) == false) break;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
      if(OrderType() == OP_BUY || OrderType() == OP_SELL){
         profit += OrderProfit();
      }
   }
   return(profit);
}

//--------------------------------------------------------------------------------------------------------+
//損益取得関数Pips                                                                                        |
//   処理:ポジションの損益を取得。                                                                        |
//   引数:損益を取得するポジションのマジックナンバー                                                      |
//   戻り値:ポジションの損益Pips                                                                          |
//--------------------------------------------------------------------------------------------------------+
double getOrderProfitPips(int magic, bool all){
   double profit;
   for(int i = 0; i < OrdersTotal(); i++){
      if(OrderSelect(i, SELECT_BY_POS,MODE_TRADES) == false) break;
      if(OrderSymbol() != Symbol()) continue;
      if(all == true){
         if(OrderType() == OP_BUY){
            profit += (Bid - OrderOpenPrice()) / Point / Mult;
         }
         if(OrderType() == OP_SELL){
            profit += (OrderOpenPrice() - Ask) / Point / Mult;
         }
      }
      else{
         if(OrderMagicNumber() != magic) continue;
         if(OrderType() == OP_BUY){
            profit += (Bid - OrderOpenPrice()) / Point / Mult;
         }
         if(OrderType() == OP_SELL){
            profit += (OrderOpenPrice() - Ask) / Point / Mult;
         }
      }
   }
   return(profit);
}

//--------------------------------------------------------------------------------------------------------+
//合計ポジション数取得関数                                                                                |
//   処理:口座全体のポジション数を取得。                                                                  |
//   引数:無し                                                                                            |
//   戻り値:ポジションの合計数                                                                            |
//--------------------------------------------------------------------------------------------------------+
double TotalLots(){
   double lots = 0;
   for(int i = 0; i < OrdersTotal(); i++){
      if(OrderSelect(i, SELECT_BY_POS,MODE_TRADES) == false) break;
      if(OrderType() == OP_BUY || OrderType() == OP_SELL){
         lots += OrderLots();
      }
   }
   return(lots);
}
//--------------------------------------------------------------------------------------------------------+
//ドル建て->円建て変換関数                                                                                |
//   処理:ドル建ての金額を円建ての金額へ変更。                                                            |
//   引数:ドル建ての数値                                                                                    |
//   戻り値:円建ての数値                                                                                |
//--------------------------------------------------------------------------------------------------------+
double exchange(double price){
   string _symbol = Symbol();
   if(AccountCurrency() == "JPY"){
      return(price);
   }
   if(AccountCurrency() == "USD"){
      if(iClose(CorrectSymbol("USDJPY"), 0, 0) >  0) price = price * iClose(CorrectSymbol("USDJPY"), 0, 0);
      if(iClose(CorrectSymbol("USDJPY"), 0, 0) == 0) price = price * 120;
   }
   return(price);
}
//--------------------------------------------------------------------------------------------------------+
//通貨ペア名修正関数                                                                                      |
//   処理:通貨ペアの後ろに付属している文字を調べ、引数に付加して返す。                                    |
//   引数:通貨ペア名                                                                                      |
//   戻り値:修正後の通貨ペア名                                                                            |
//--------------------------------------------------------------------------------------------------------+
string CorrectSymbol(string symbol){
   int length = StringLen(Symbol());
   if(length > 6) symbol += StringSubstr(Symbol(), 6, length-6);
   return(symbol);
}
//--------------------------------------------------------------------------------------------------------+
//取引時間帯制限フィルター                                                                                |
//   処理:現在の時刻が取引可能時間かを調べる。                                                            |
//        取引時間外であればエントリーシグナルを解除する。                                                |
//   引数:売買シグナル(買い:正の整数, 売り:負の整数)                                                      |
//   戻り値:取引時間帯制限フィルター適用後の売買シグナル                                                  |
//--------------------------------------------------------------------------------------------------------+
extern string StartTime1 = "4:00";
extern string EndTime1 = "6:00";
int TradeStopTime(int signal, string start_time, string end_time){
   int ret = 0;
   string time = TimeToStr(TimeCurrent(), TIME_DATE);
   datetime t_start = StrToTime(time + " " + start_time);
   datetime t_end = StrToTime(time + " " + end_time);
   if(t_start < t_end){
      if(TimeCurrent() >= t_start && TimeCurrent() < t_end){
         ret = signal;
      }else ret = 0;
   }else{
      if(TimeCurrent() >= t_end && TimeCurrent() < t_start){
         ret = 0;
      }else ret = signal;
   }
   return(ret);
}

//--------------------------------------------------------------------------------------------------------+
//指定時刻に決済                                                                                          |
//   処理:特定の時刻にポジションを決済する。                                                              |
//   引数:決済するポジションのマジックナンバー                                                            |
//   戻り値:無し                                                                                          |
//--------------------------------------------------------------------------------------------------------+
extern string ExitTime ="9:00";
void TimeExit(int magic){
   string time = TimeToStr(TimeCurrent(), TIME_DATE);
   datetime exit = StrToTime(time + " " + ExitTime);
   if(TimeCurrent() >= exit && TimeCurrent() < exit + 180){
      if(DayOfWeek() == 1) OC(magic);
      if(DayOfWeek() == 2) OC(magic);
      if(DayOfWeek() == 3) OC(magic);
      if(DayOfWeek() == 4) OC(magic);
      if(DayOfWeek() == 5) OC(magic);
      if(DayOfWeek() == 6) OC(magic);
   }
}

//--------------------------------------------------------------------------------------------------------+
//両建て防止関数                                                                                          |
//   処理:全てのオープンポジションをチェックし、                                                          |
//        エントリー方向と逆のポジション持っていたらエントリーさせない。                                  |
//   引数:エントリーシグナル                                                                              |
//   戻り値:判定後のエントリーシグナル                                                                    |
//--------------------------------------------------------------------------------------------------------+
int HedgeCheck(int sig){
   for(int i=0; i<OrdersTotal(); i++){
      if(OrderSelect(i, SELECT_BY_POS) == false) break;
      if(OrderSymbol() != Symbol()) continue;
      if(sig > 0){
         if(OrderType() == OP_SELL){
            sig = 0;
            break;
         }
      }
      if(sig < 0){
         if(OrderType() == OP_BUY){
            sig = 0;
            break;
         }
      }
   }
   return(sig);
}

//--------------------------------------------------------------------------------------------------------+
//エラー内容確認                                                                                          |
//   処理:エラー内容を文字列に変換する。                                                                  |
//   引数:エラーコード                                                                                    |
//   戻り値:エラー内容                                                                                    |
//--------------------------------------------------------------------------------------------------------+
string ErrorDescription(int error_code){
   string error_string;
   switch(error_code){
      case 0:
      case 1:   error_string = "no error";                                                  break;
      case 2:   error_string = "common error";                                              break;
      case 3:   error_string = "invalid trade parameters";                                  break;
      case 4:   error_string = "trade server is busy";                                      break;
      case 5:   error_string = "old version of the client terminal";                        break;
      case 6:   error_string = "no connection with trade server";                           break;
      case 7:   error_string = "not enough rights";                                         break;
      case 8:   error_string = "too frequent requests";                                     break;
      case 9:   error_string = "malfunctional trade operation (never returned error)";      break;
      case 64:  error_string = "account disabled";                                          break;
      case 65:  error_string = "invalid account";                                           break;
      case 128: error_string = "trade timeout";                                             break;
      case 129: error_string = "invalid price";                                             break;
      case 130: error_string = "invalid stops";                                             break;
      case 131: error_string = "invalid trade volume";                                      break;
      case 132: error_string = "market is closed";                                          break;
      case 133: error_string = "trade is disabled";                                         break;
      case 134: error_string = "not enough money";                                          break;
      case 135: error_string = "price changed";                                             break;
      case 136: error_string = "off quotes";                                                break;
      case 137: error_string = "broker is busy (never returned error)";                     break;
      case 138: error_string = "requote";                                                   break;
      case 139: error_string = "order is locked";                                           break;
      case 140: error_string = "long positions only allowed";                               break;
      case 141: error_string = "too many requests";                                         break;
      case 145: error_string = "modification denied because order too close to market";     break;
      case 146: error_string = "trade context is busy";                                     break;
      case 147: error_string = "expirations are denied by broker";                          break;
      case 148: error_string = "amount of open and pending orders has reached the limit";   break;
      case 149: error_string = "hedging is prohibited";                                     break;
      case 150: error_string = "prohibited by FIFO rules";                                  break;
      //---- mql4 errors
      case 4000: error_string = "no error (never generated code)";                          break;
      case 4001: error_string = "wrong function pointer";                                   break;
      case 4002: error_string = "array index is out of range";                              break;
      case 4003: error_string = "no memory for function call stack";                        break;
      case 4004: error_string = "recursive stack overflow";                                 break;
      case 4005: error_string = "not enough stack for parameter";                           break;
      case 4006: error_string = "no memory for parameter string";                           break;
      case 4007: error_string = "no memory for temp string";                                break;
      case 4008: error_string = "not initialized string";                                   break;
      case 4009: error_string = "not initialized string in array";                          break;
      case 4010: error_string = "no memory for array' string";                             break;
      case 4011: error_string = "too long string";                                          break;
      case 4012: error_string = "remainder from zero divide";                               break;
      case 4013: error_string = "zero divide";                                              break;
      case 4014: error_string = "unknown command";                                          break;
      case 4015: error_string = "wrong jump (never generated error)";                       break;
      case 4016: error_string = "not initialized array";                                    break;
      case 4017: error_string = "dll calls are not allowed";                                break;
      case 4018: error_string = "cannot load library";                                      break;
      case 4019: error_string = "cannot call function";                                     break;
      case 4020: error_string = "expert function calls are not allowed";                    break;
      case 4021: error_string = "not enough memory for temp string returned from function"; break;
      case 4022: error_string = "system is busy (never generated error)";                   break;
      case 4050: error_string = "invalid function parameters count";                        break;
      case 4051: error_string = "invalid function parameter value";                         break;
      case 4052: error_string = "string function internal error";                           break;
      case 4053: error_string = "some array error";                                         break;
      case 4054: error_string = "incorrect series array using";                             break;
      case 4055: error_string = "custom indicator error";                                   break;
      case 4056: error_string = "arrays are incompatible";                                  break;
      case 4057: error_string = "global variables processing error";                        break;
      case 4058: error_string = "global variable not found";                                break;
      case 4059: error_string = "function is not allowed in testing mode";                  break;
      case 4060: error_string = "function is not confirmed";                                break;
      case 4061: error_string = "send mail error";                                          break;
      case 4062: error_string = "string parameter expected";                                break;
      case 4063: error_string = "integer parameter expected";                               break;
      case 4064: error_string = "double parameter expected";                                break;
      case 4065: error_string = "array as parameter expected";                              break;
      case 4066: error_string = "requested history data in update state";                   break;
      case 4099: error_string = "end of file";                                              break;
      case 4100: error_string = "some file error";                                          break;
      case 4101: error_string = "wrong file name";                                          break;
      case 4102: error_string = "too many opened files";                                    break;
      case 4103: error_string = "cannot open file";                                         break;
      case 4104: error_string = "incompatible access to a file";                            break;
      case 4105: error_string = "no order selected";                                        break;
      case 4106: error_string = "unknown symbol";                                           break;
      case 4107: error_string = "invalid price parameter for trade function";               break;
      case 4108: error_string = "invalid ticket";                                           break;
      case 4109: error_string = "trade is not allowed in the expert properties";            break;
      case 4110: error_string = "longs are not allowed in the expert properties";           break;
      case 4111: error_string = "shorts are not allowed in the expert properties";          break;
      case 4200: error_string = "object is already exist";                                  break;
      case 4201: error_string = "unknown object property";                                  break;
      case 4202: error_string = "object is not exist";                                      break;
      case 4203: error_string = "unknown object type";                                      break;
      case 4204: error_string = "no object name";                                           break;
      case 4205: error_string = "object coordinates error";                                 break;
      case 4206: error_string = "no specified subwindow";                                   break;
      default:   error_string = "unknown error";
   }
   return(error_string);
}


