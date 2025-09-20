#include <Trade/Trade.mqh>
CTrade trade;

input group "Operations"
input double LOTS = 0.1; // Lots
input int SL = 200;   // Stop loss
input int TP = 200;   // Take profit

input group "Moving averages"
input int periods_fast = 20;  // Fast MA periods
input int periods_slow = 200; // Slow MA periods

int fast_h;
int slow_h;

double fast[];
double slow[];

bool buy_cross() {
   return fast[0] > slow[0] && fast[1] < slow[0];
}

bool sell_cross() {
   return fast[0] < slow[0] && fast[1] > slow[0];
}


int OnInit() {
   fast_h = iMA(_Symbol, _Period, periods_fast, 0, MODE_EMA, PRICE_CLOSE);
   if (fast_h == INVALID_HANDLE) {
      Print("[ERROR] - The fast moving average did not load.");
      return INIT_FAILED;
   }
   
   slow_h = iMA(_Symbol, _Period, periods_slow, 0, MODE_EMA, PRICE_CLOSE);
   if (slow_h == INVALID_HANDLE) {
      Print("[ERROR] - The slow moving average did not load.");
      return INIT_FAILED;
   }
   
   ArraySetAsSeries(fast, true);
   ArraySetAsSeries(slow, true);
   
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   if (fast_h != INVALID_HANDLE) IndicatorRelease(fast_h);
   if (slow_h != INVALID_HANDLE) IndicatorRelease(slow_h);
}

void OnTick() {
   int loaded_fast = CopyBuffer(fast_h, 0, 1, 2, fast);
   int loaded_slow = CopyBuffer(slow_h, 0, 1, 2, slow);
   
   if (loaded_fast < 0 || loaded_slow < 0) {
      Print("[ERROR] - Couldn't load the moving averages.");
      return;
   }
   
   if (PositionsTotal() == 0) {
      if (buy_cross()) {
         double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
         trade.Buy(LOTS, _Symbol, ask, ask - SL*_Point, ask + TP*_Point, "MA operation");
      } else if (sell_cross()) {
         double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
         trade.Sell(LOTS, _Symbol, bid, bid + SL*_Point, bid - TP*_Point, "MA operation");
      }
   }
}


