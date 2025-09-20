#include <Trade/Trade.mqh>
CTrade trade;

input group "Operations"
input double LOTS = 0.1; // Lots
input int SL = 200;   // Stop loss
input int TP = 200;   // Take profit

input group "Bollinger bands"
input int bands_period = 20;        // Bands period
input int bands_deviation = 2.0;    // Bands deviation

input group "Operative"
enum CloseType {
   CloseByTP, // Close by TP
   CloseByAverage, // Close by moving average
};
input CloseType closeType = CloseByTP; // Close type

int bb_h;

double upper_band[];
double lower_band[];
double moving_average[];
MqlRates candles[];

bool buy_cross() {
   return candles[1].open > lower_band[1] && candles[1].close < lower_band[1] && candles[0].close >= lower_band[0];
}

bool sell_cross() {
   return candles[1].open < upper_band[1] && candles[1].close > upper_band[1] && candles[0].close <= upper_band[0];
}


int OnInit() {
   bb_h = iBands(_Symbol, _Period, bands_period, 0, bands_deviation, PRICE_CLOSE);
   if (bb_h == INVALID_HANDLE) {
      Print("[ERROR] - The indicator was not loaded correctly.");
      return INIT_FAILED;
   }
   
   ArraySetAsSeries(upper_band, true);
   ArraySetAsSeries(lower_band, true);
   ArraySetAsSeries(moving_average, true);
   ArraySetAsSeries(candles, true);
 
   return INIT_SUCCEEDED;  
}

void OnDeinit(const int reason) {
   if (bb_h != INVALID_HANDLE) IndicatorRelease(bb_h);   
}

void OnTick() {
   int loaded_upper = CopyBuffer(bb_h, UPPER_BAND, 0, 2, upper_band);
   int loaded_lower = CopyBuffer(bb_h, LOWER_BAND, 0, 2, lower_band);
   int loaded_moving_average = CopyBuffer(bb_h, BASE_LINE, 0, 2, moving_average);
   int loaded_candles = CopyRates(_Symbol, _Period, 0, 2, candles);
   
   if (
      loaded_upper < 0 ||
      loaded_lower < 0 ||
      loaded_moving_average < 0 ||
      loaded_candles < 0
   ) {
      Print("[ERROR] - The indicators were not loaded.");
      return;
   }
   
   if (PositionsTotal() == 0) {
      if (buy_cross()) {
         double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
         trade.Buy(
            LOTS,
             _Symbol, 
             ask, 
             ask-SL*_Point,
             closeType == CloseByAverage ? 0 : ask+TP*_Point, 
             "Bollinger bands EA"
          );
      } else if (sell_cross()) {
         double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
         trade.Sell(
            LOTS,
            _Symbol,
            bid,
            bid+SL*_Point,
            closeType == CloseByAverage ? 0 : bid-TP*_Point,
            "Bollinger bands EA"
         );
      }
   } else if (closeType == CloseByAverage) {
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if (
         (type == POSITION_TYPE_BUY && candles[0].close >= moving_average[0]) ||
         (type == POSITION_TYPE_SELL && candles[0].close <= moving_average[0])
      ) {
         ulong ticket = PositionGetTicket(0);
         trade.PositionClose(ticket);
      }
   }
}