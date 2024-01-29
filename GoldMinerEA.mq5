//+------------------------------------------------------------------+
//|                                                  GoldMinerEA.mq5 |
//|                                   Copyright 2023, Atikur Rahman. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Atikur Rahman."
#property link      "https://www.validatortech.com"

// New version 
#define VERSION "1.0"
#property version VERSION


//+------------------------------------------------------------------+
//| Library Include                                                  |
//+------------------------------------------------------------------+

// Trade
#include <ValidatorTech/Frameworks/Framework_1.0/Trade/Trade.mqh>

// Using TimeRange, For Trading Time Check
#include <ValidatorTech/TimeRange/TimeRange.mqh>

// Utility Classes
#include <ValidatorTech/UtilityClasses/UtilityFunctions.mqh>

// Moving Average Indicators
#include <ValidatorTech/MovingAverage/MAIndicator.mqh>
#include <ValidatorTech/MovingAverage/MATouchSignal.mqh>
#include <ValidatorTech/MovingAverage/MACrossoverSignal.mqh>
#include <ValidatorTech/MovingAverage/MASniperSignal.mqh>

// ADX Indicator
#include <ValidatorTech/ADX/ADXIndicator.mqh>
#include <ValidatorTech/ADX/ADXSignal.mqh>


// Standard Deviation Indicators
#include <ValidatorTech/StandardDeviation/SDIndicator.mqh>


// RSI Indicator
#include <ValidatorTech/RSI/RSIIndicator.mqh>
#include <ValidatorTech/RSI/RSISignal.mqh>


// Stochastic Indicator
#include <ValidatorTech/Stochastic/StochasticIndicator.mqh>
#include <ValidatorTech/Stochastic/StochasticSignal.mqh>


// Shved Supply And Demand Indicators
#include <ValidatorTech/SupplyAndDemand/SupplyAndDemand.mqh>

// Using ShvedSPChartObjectRectangular, For Rectangular Support/Resistance Zone Breakout
#include <ValidatorTech/ChartObjectsClasses/ShvedSPChartObjectRectangular.mqh>

//
#include <ValidatorTech/SortableClasses/RectObjPriceSortable.mqh>

// Candles/Bars Info Update
#include <ValidatorTech/CandleInfoClasses/CandleInfo.mqh>

// Candlestick Pattern
#include <ValidatorTech/CandlestickPattern/CandlestickPattern.mqh>

// Sortable Classess
#include <ValidatorTech/SortableClasses/Sortable.mqh>
#include <ValidatorTech/FindHHHLTrend/FindHHHLTrend.mqh>



/****************************************************************************/
/* Program Defination                                                       */
/****************************************************************************/

#define PROJECT_NAME MQLInfoString(MQL_PROGRAM_NAME)
#define INSTANT_TRADE "INSTANT_TRADE"
#define PREFIX "ChartObj"



//+------------------------------------------------------------------+
//| Inputs Section                                                   |
//+------------------------------------------------------------------+

enum TRADE_TYPE {
   NO_ORDER       =  0,
   BUY            =  1,
   SELL           =  2,
   BUY_LIMIT      =  3,
   BUY_STOP       =  4,
   SELL_LIMIT     =  5,
   SELL_STOP      =  6
};


enum MARTINGALE_LOT_CALCULATION_TYPE {
   ADDITION =  0,
   MULTIPLICATION =  1
};

//+------------------------------------------------------------------+
//| Inputs Section                                                   |
//+------------------------------------------------------------------+


input group    "<===============    Expert Permission     ===============>"
input bool     IsExpertAllowedToTrade           =  true;       // Is Expert Allowed To Trade


input group    "<===============    User Interface     ===============>"
input bool     ShowUserInterface = true;                       // Show user interface
input bool     UserInterfaceTransparent         = false;       // Show user interface as transparent

input group    "#----- Trading Timeframe -----#"
input ENUM_TIMEFRAMES   ChartTimeframe      =  PERIOD_H1;        // Trading Timeframe

input group    "<===============    Trading Hours     ===============>"
input bool     TradingHoursActive = true;                     // Is trading hours active
input int      TradingStartHour                 =  05;         // Trading start hour
input int      TradingStartMin                  =  00;         // Trading start minute
input int      TradingEndHour                   =  21;         // Trading end hour
input int      TradingEndMin                    =  00;         // Trading end minute


input group    "<===============    Order Settings     ===============>"
input int               MaxRunningOrder         =  5;          // Maximum running order
TRADE_TYPE        OrderType                     =  NO_ORDER;   // Order type 
double            PendingOrderPrice             =  0.0;        // Pending order price
input double            OrderLotSize            =  0.01;       // Order lot size
input int               OrderSL                 =  0;          // Order SL         
input int               OrderTP                 =  1000;       // Order TP
input int               OrderGaps               =  1000;       // Gaps between two orders
input ENUM_TIMEFRAMES   SpecifyTimeForOrders    =  PERIOD_H1;  // Specify time for placing number of orders 
input int               NumberOfOrdersInSpecificTime  =  1;    // Enter how many orders will be placed in a specific time
input bool              OrderOpenAfterBigMove   =  true;       // Order will open at the next candle after a big price move


// Remove this section when testing is done
input group    "<===============    Martingale Settings     ===============>"
ENUM_POSITION_TYPE     ManualPositionType       =  POSITION_TYPE_SELL; // Manual order type
double                 ManualOrderPrice         =  2000.00;    // Manual order price
//

double                 ResistancePriceLevel     =  2000.00;    // Enter resistance price level
double                 SupportPriceLevel        =  1950.00;    // Enter support price level

input bool             IsMartingale             =  true;       // Using martingale system
input MARTINGALE_LOT_CALCULATION_TYPE MartingaleLotCalculationType = ADDITION; // Martingale lot calculation type
input double           MartingaleLot = 0.01;                   // Martingale initial lot for calculating addition/multiplication
input double           MartingaleMaxLotSize = 1;               // Define tradable max lot when placing orders by martingale
/* 0.01, 0.02, 0.04, 0.08, 0.16, 0.32, 0.64, 1.28 */

input group    "<=========    Breakeven & Traillingstop Settings    =========>"
input bool     BreakevenActive                     =  true;      // Breakeven active
input double   PlaceBEWhenProfit                   =  8;         // Place breakeven when market favour __ pips 
input double   EntryPriceToBEGap                   =  1.0;        // Entry price to breakeven gaps ___ pips
input bool     TraillingStopActive                 =  true;      // Trailling stop active
input double   TSRunWhenProfit                     =  8;         // Trailling stop run when market favour __ pips
input double   TraillingStopStep                   =  1;          // Trailling stop step


input group    "<===============    Magic, Comments     ===============>"
input int               Magic = 123456;                        // Magic Number
input string            OrderComments = "";                    // Order Comments


//+------------------------------------------------------------------+
//| Variable declaration                                             |
//+------------------------------------------------------------------+

// Trade class
CTradeCustom trade;
CTimeRange *cTimeRange;

// Moving Average Indicator Classes
CMAIndicator *cMAIndicator;
CMATouchSignal *cMATouchSignal;

// Moving Average Indicator Classes
CMAIndicator *tenEMA,   *twentyEMA,     *thirtyEMA,
             *oneFourtyFourEMA, *oneSixtyNineEMA, *twoHundredEMA;
             
CMASniperSignal *sniperSignal;



// ADX Indicator
CADXIndicator *adxIndicator;
CADXSignal *adxSignal;

// Standard Deviation
CSDIndicator *cSDIndicator;

// RSI Indicator
CRSIIndicator *rsiIndicator;
CRSISignal    *rsiSignal;

// Stochastic Variables
CStochasticIndicator *stochIndicator;
CStochasticSignal    *stochSignal;

// Supply Demand Indicator
CSupplyDemandIndicator *cHSDIndicatorCurrentTF, *cHSDIndicatorFifteenMins, *cHSDIndicatorOneHour, 
                           *cHSDIndicatorFourHours, *cHSDIndicatorDaily, *cHSDIndicatorWeekly;

// ChartObjectRectangular
CShvedSPChartObjectRectangular    *cObjRectangle;

// Resistance & Support Zone
CArrayObj *currentTFResistanceZone, *currentTFSupportZone, *fifteenMinsResistanceZone, *fifteenMinsSupportZone, 
          *oneHourResistanceZone, *oneHourSupportZone, *fourHourResistanceZone, *fourHourSupportZone, 
          *dailyResistanceZone, *dailySupportZone, *weeklyResistanceZone, *weeklySupportZone, 
          *dailyWeeklyConfluenceZone;

// Candle Info
CCandleInfo *cCandleInfo;

// Candlestick Pattern
CCandlestickPattern  *candleStickPattern;



int                  mDigits;                                  // Current Symbol Digit
string               mSymbol;                                  // Current Chart Symbol
double               mSpread;
ENUM_TIMEFRAMES      mPeriod;                                  // Current Chart Time Period
ENUM_POSITION_TYPE   mOrderType = -1;                          // Variable fill with first order type


bool visibleUserInterface = false, IsSDInRange = false;
bool newBar = false, newOrderTime = false, hourlyOrderTime = false;
int orderFrequencyCount = 0;                                   // Count no. of orders in a certain time
double lastOrderPrice = 0.0;                                   // Keep last order price
double lastOrderTP = 0.0;                                      // Keep track last order tp price
double lastLotSize = 0.0;                                      // Keep track last lot size for new order
datetime lastOrderTime;                                        // Keep last order place time

int positionTotal = 0;     


// Use this flag for manual entry for testing
int manualOrderFlag = 0;

ulong buyPos = 0, sellPos = 0;
string separator = "#"; 
ushort separatorChar;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---

   buyPos = 0; 
   sellPos = 0;
   
   mSymbol  =  Symbol();
   mPeriod  =  Period();
   mDigits  =  (int)SymbolInfoInteger(mSymbol, SYMBOL_DIGITS);
   mSpread  =  SymbolInfoInteger(mSymbol, SYMBOL_SPREAD);
   separatorChar = StringGetCharacter(separator, 0);
   

   trade.SetMagicNumber(Magic);   
   trade.SetExpertMagicNumber(Magic);
   trade.SetAsyncMode(true);

   if(!trade.SetTypeFillingBySymbol(mSymbol)) {
      trade.SetTypeFilling(ORDER_FILLING_RETURN);
   }
   
   
   // Moving Average
   //cMAIndicator      =  new CMAIndicator(mSymbol, mPeriod, 20.0, 0, MODE_EMA, PRICE_CLOSE);
   //cMATouchSignal    =  new CMATouchSignal(1, 2, 3, cMAIndicator);
   
   SetupSnipperEMA();
   
   // ADX Indicator
   //adxIndicator   =  new CADXIndicator(mSymbol, mPeriod, 14);
   //adxSignal      =  new CADXSignal(adxIndicator); 
   
   
   // Standard Deviation
   //cSDIndicator   =  new CSDIndicator(mSymbol, mPeriod, 20.0, 0, MODE_SMA, PRICE_CLOSE);;
   
   
   // RSI Indicator
   rsiIndicator = new CRSIIndicator(mSymbol, mPeriod, 14, PRICE_CLOSE);
   rsiSignal    = new CRSISignal(30, 70, rsiIndicator);
   
   
   // Stochastic Indicator
   stochIndicator = new CStochasticIndicator(mSymbol, mPeriod, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
   stochSignal    = new CStochasticSignal(20, 80, stochIndicator);
   
   
   
   // Initialize Resistance and Support Zone Array
   currentTFResistanceZone    =  new CArrayObj();
   currentTFSupportZone       =  new CArrayObj();
   
   /*
   fifteenMinsResistanceZone  =  new CArrayObj();
   fifteenMinsSupportZone     =  new CArrayObj();
   
   oneHourResistanceZone      =  new CArrayObj();
   oneHourSupportZone         =  new CArrayObj();
   
   fourHourResistanceZone     =  new CArrayObj();
   fourHourSupportZone        =  new CArrayObj();
   
   dailyResistanceZone        =  new CArrayObj();
   dailySupportZone           =  new CArrayObj();
   
   weeklyResistanceZone       =  new CArrayObj();
   weeklySupportZone          =  new CArrayObj();
   
   dailyWeeklyConfluenceZone  =  new CArrayObj();
   */
                           
   // Supply Demand Indicator
   cHSDIndicatorCurrentTF     =  new CSupplyDemandIndicator(mSymbol, mPeriod, "CTFSRRR");
   /*cHSDIndicatorFifteenMins   =  new CSupplyDemandIndicator(mSymbol, PERIOD_M15, "15MSRRR");
   cHSDIndicatorOneHour       =  new CSupplyDemandIndicator(mSymbol, PERIOD_H1, "1HSRRR");
   cHSDIndicatorFourHours     =  new CSupplyDemandIndicator(mSymbol, PERIOD_H4, "4HSRRR");
   cHSDIndicatorDaily         =  new CSupplyDemandIndicator(mSymbol, PERIOD_D1, "DSRRR");
   cHSDIndicatorWeekly        =  new CSupplyDemandIndicator(mSymbol, PERIOD_W1, "WSRRR");
   */
   
   
   // Initialize CChartObjectTrendline Class Instance
   cObjRectangle  =  new CShvedSPChartObjectRectangular(mSymbol, mPeriod, true);
   
   // Initialize CCandleInfo Class Instance
   cCandleInfo    =  new CCandleInfo(mSymbol, mPeriod);
   
   // Candlestick Pattern
   candleStickPattern =  new CCandlestickPattern(mSymbol, mPeriod);
   
   
   
   // Initialize CTimeRange Instance
   cTimeRange     =  new CTimeRange(mSymbol, mPeriod, TradingStartHour, TradingStartMin,
                                    TradingEndHour, TradingEndMin);
   
   
   
   static bool isInit = false;
   if(!isInit) {
      isInit = true;
      //Print(__FUNCTION__," > EA (re)start...");
      //Print(__FUNCTION__," > EA version ",VERSION,"...");
      for(int i = PositionsTotal()-1; i >= 0; i--) {
         CPositionInfo pos;
         if(pos.SelectByIndex(i)) {
            if(pos.Magic() != Magic)
               continue;
            if(pos.Symbol() != mSymbol)
               continue;

            Print(__FUNCTION__," > Found open position with ticket #",pos.Ticket(),"...");
            if(pos.PositionType() == POSITION_TYPE_BUY)
               buyPos = pos.Ticket();
            if(pos.PositionType() == POSITION_TYPE_SELL)
               sellPos = pos.Ticket();
         }
      }

      for(int i = OrdersTotal()-1; i >= 0; i--) {
         COrderInfo order;
         if(order.SelectByIndex(i)) {
            if(order.Magic() != Magic)
               continue;
            if(order.Symbol() != mSymbol)
               continue;

            Print(__FUNCTION__," > Found pending order with ticket #",order.Ticket(),"...");
            if(order.OrderType() == ORDER_TYPE_BUY_STOP)
               buyPos = order.Ticket();
            if(order.OrderType() == ORDER_TYPE_SELL_STOP)
               sellPos = order.Ticket();
         }
      }
   }
   
   
   IsNewBar(true);
   IsNewOrderTime(true);
   IsHourlyNewBar(true);
   IsDailyNewBar(true);
   
   
   // Create User Interface
   if(ShowUserInterface) createUserInterface();
   
   
//---
   return(INIT_SUCCEEDED);
}


void SetupSnipperEMA() {

//mSymbol, mPeriod, 20.0, 0, MODE_EMA, PRICE_CLOSE
   // Sniper Signal EMA Strategy     
   tenEMA                  = new CMAIndicator(mSymbol, mPeriod, 5.0,  0, MODE_EMA, PRICE_CLOSE);
   twentyEMA               = new CMAIndicator(mSymbol, mPeriod, 10.0, 0, MODE_EMA, PRICE_CLOSE);
   thirtyEMA               = new CMAIndicator(mSymbol, mPeriod, 20.0, 0, MODE_EMA, PRICE_CLOSE);
  
   oneFourtyFourEMA        = new CMAIndicator(mSymbol, mPeriod, 144.0, 0, MODE_EMA, PRICE_CLOSE);
   oneSixtyNineEMA         = new CMAIndicator(mSymbol, mPeriod, 169.0, 0, MODE_EMA, PRICE_CLOSE);
   twoHundredEMA           = new CMAIndicator(mSymbol, mPeriod, 200.0, 0, MODE_EMA, PRICE_CLOSE);
   
   // Sniper moving average class defines
   sniperSignal            = new CMASniperSignal(1, 2, 3, tenEMA, twentyEMA, thirtyEMA, 
                                                 oneFourtyFourEMA, oneSixtyNineEMA, twoHundredEMA);

}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   
   delete cTimeRange;
   
   delete cMAIndicator;
   delete adxIndicator;
   delete adxSignal;
   //delete cSDIndicator;
   delete rsiIndicator;
   delete rsiSignal;
   delete stochIndicator;
   delete stochSignal;
   
   // Delete CandlestickPattern
   delete candleStickPattern;
   
   
   // Supply Demand Object
   delete cObjRectangle;
   delete cHSDIndicatorCurrentTF;
   delete cHSDIndicatorFifteenMins;
   delete cHSDIndicatorOneHour;
   delete cHSDIndicatorFourHours;
   delete cHSDIndicatorDaily;
   delete cHSDIndicatorWeekly;
   delete cCandleInfo;
   
          
   // Delete Array
   delete currentTFResistanceZone;
   delete currentTFSupportZone;
   delete fifteenMinsResistanceZone;
   delete fifteenMinsSupportZone;
   delete oneHourResistanceZone;
   delete oneHourSupportZone;
   delete fourHourResistanceZone;
   delete fourHourSupportZone;
   delete dailyResistanceZone;    
   delete dailySupportZone;
   delete weeklyResistanceZone;    
   delete weeklySupportZone;
   delete dailyWeeklyConfluenceZone;
   
   
   // Delete User Interface All Objects
   ObjectsDeleteAll(0, PREFIX, 0, -1);
   ObjectsDeleteAll(0, "CTFSRRR", 0, -1);
   ObjectsDeleteAll(0, "15MSRRR", 0, -1);
   ObjectsDeleteAll(0, "1HSRRR", 0, -1);
   ObjectsDeleteAll(0, "4HSRRR", 0, -1);
   ObjectsDeleteAll(0, "DSRRR", 0, -1);
   ObjectsDeleteAll(0, "WSRRR", 0, -1);
   
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   
   // Permissions to allow trades
   if(!permissionsToAllowTrade()) return;
   
   
   // Check if EA is only works on current chart symbol and magic number
   if(mSymbol != Symbol() && Magic != trade.GetMagic()) return; 
   
   
   // UserInterface: Update Account Overview
   if(ShowUserInterface) updateAccountOverview();
   
  
   newBar = IsNewBar(true);
   hourlyOrderTime = IsHourlyNewBar(true);
   IsDailyNewBar(true);
   
   cCandleInfo.UpdateCandlePrice();
   
   /*if(newBar) {
      //string snipperSignal = sniperSignal.sniperSlowMACrossSignal(cCandleInfo);
      string snipperSignal = sniperSignal.sniperSignal(cCandleInfo);
      Print("snipper cross Signal: ", snipperSignal);
   }
   
   return;*/
   
   
   // Update orders breakeven & traillingstop
   if(PositionsTotal() > 0) {
      if(BreakevenActive) updateOrdersBreakeven();
      if(TraillingStopActive) updateOrdersTraillingstop();
   } 
   
   // Filter all all indicators to get signal
   getAllIndicatorsSignal(newBar);
   
   
   // Position total
   positionTotal = PositionsTotal();
   
   
   // Detect first order type
   if(mOrderType == -1) getLastOrderInfo();
   
   
   // Breakeven calculation
   //if(buyPos > 0 && PositionsTotal() == 1)  processPosition(buyPos);
   //if(sellPos > 0 && PositionsTotal() == 1) processPosition(sellPos);
   
   
   // Check new entry is found
   //if(checkIsOrderAvailable()) autoPlacingOrder();
   
    
   // For manual entry, only for testing purpose
   //if(manualOrderFlag != 1) manuallyPlacingOrder();
   
   
}
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void  OnTradeTransaction(const MqlTradeTransaction&    trans,
                         const MqlTradeRequest&        request,
                         const MqlTradeResult&         result) {
   
   if(trans.type == TRADE_TRANSACTION_ORDER_ADD) {
      COrderInfo order;
      if(order.Select(trans.order)) {
         if(order.Magic() == Magic) {
            if(order.OrderType() == ORDER_TYPE_BUY_STOP) {
               buyPos = order.Ticket();
            }
            else
            if(order.OrderType() == ORDER_TYPE_SELL_STOP) {
               sellPos = order.Ticket();
            }
         }
      }
   }
   
   
   ulong newest_deal_ticket = trans.deal;
   HistoryDealSelect(newest_deal_ticket);
   long position_ID           = HistoryDealGetInteger(newest_deal_ticket, DEAL_POSITION_ID);
   long order_ticket          = HistoryDealGetInteger(newest_deal_ticket, DEAL_TICKET);
   long deal_order            = HistoryDealGetInteger(newest_deal_ticket, DEAL_ORDER);
   long deal_magic            = HistoryDealGetInteger(newest_deal_ticket, DEAL_MAGIC);
   int int_deal_magic         = (int)deal_magic;
   datetime transaction_time  = (datetime)HistoryDealGetInteger(newest_deal_ticket,DEAL_TIME);
   ulong deal_reason          = HistoryDealGetInteger(newest_deal_ticket, DEAL_REASON);
   ulong deal_type            = HistoryDealGetInteger(newest_deal_ticket, DEAL_TYPE);
   ulong deal_entry            = HistoryDealGetInteger(newest_deal_ticket, DEAL_ENTRY);
   double deal_price          = HistoryDealGetDouble(newest_deal_ticket, DEAL_PRICE);
   double deal_profit         = HistoryDealGetDouble(newest_deal_ticket, DEAL_PROFIT);
   string symbol              = HistoryDealGetString(newest_deal_ticket, DEAL_SYMBOL);
   string deal_comment        = HistoryDealGetString(newest_deal_ticket, DEAL_COMMENT);
   double volume              = HistoryDealGetDouble(newest_deal_ticket, DEAL_VOLUME);
   double commission          = HistoryDealGetDouble(newest_deal_ticket, DEAL_COMMISSION);
   double swap                = HistoryDealGetDouble(newest_deal_ticket, DEAL_SWAP);
   
   
   if(symbol == mSymbol && deal_magic == Magic) {
      if(deal_type == DEAL_TYPE_BUY || deal_type == DEAL_TYPE_SELL) {
         if((deal_entry == DEAL_ENTRY_IN)) {
            //printf ("111 ticket: "+ order_ticket + ", deal order number: "+ deal_order + " deal is in, comment: " + deal_comment + ", orderFrequencyCount: " + orderFrequencyCount);
            getLastOrderInfo();
            
            // Increment order frequency count for new order
            if(lastOrderTime == TimeCurrent()) orderFrequencyCount++;
            
            
            // Check if current total position is less than MaxRunningOrder
            int totalPosition = PositionsTotal();
            if(MaxRunningOrder > 0 && !(totalPosition > MaxRunningOrder)) return;
            
            
            // Calculate lot size
            if(IsMartingale) {
               if(totalPosition >= 1) {
                  if(MartingaleLotCalculationType == MULTIPLICATION) {
                     //Print("lastLotSize: ", lastLotSize);
                     if(lastLotSize <= MartingaleMaxLotSize || 
                        (lastLotSize*MartingaleLot) <= MartingaleMaxLotSize) {
                        lastLotSize *= MartingaleLot;
                        //Print("Multiplication lastLotSize: ", lastLotSize*MartingaleLot, ", MartingaleLot: ", MartingaleLot);
                     }   
                  }
                  else {
                     //Print("lastLotSize: ", lastLotSize);
                     if(lastLotSize <= MartingaleMaxLotSize || 
                        (lastLotSize+MartingaleLot) <= MartingaleMaxLotSize)
                        lastLotSize += MartingaleLot;
                        //Print("Addition lastLotSize: ", lastLotSize, ", MartingaleLot: ", MartingaleLot);
                  }      
               }   
               else lastLotSize = OrderLotSize;     
            } 
            else lastLotSize = OrderLotSize; 
            
            //Print("111 MartingaleLotCalculationType: ", MartingaleLotCalculationType);
            //Print("111 after deal close orderFrequencyCount: " + orderFrequencyCount + ", lastLotSize: " + lastLotSize);
         }
         if((deal_entry == DEAL_ENTRY_OUT)) {
            //printf ("222 ticket: "+ order_ticket + ", deal order number: "+ deal_order + " deal is out, comment: "+ deal_comment + ", orderFrequencyCount: " + orderFrequencyCount);
            getLastOrderInfo();
            
            // Decrement order frequency count when order is out
            if(lastOrderTime == TimeCurrent()) orderFrequencyCount--;
            
            // Calculate lot size
            if(IsMartingale) {
               //Print("222 lastLotSize: ", lastLotSize, ", MartingaleLot: ", MartingaleLot);
               if(PositionsTotal() >= 1 && MartingaleLotCalculationType == MULTIPLICATION) {
                  lastLotSize /= MartingaleLot; 
                  //Print("222 Reduce Multiplication lastLotSize: ", lastLotSize);
               }   
               else if(PositionsTotal() >= 1 && MartingaleLotCalculationType == ADDITION) {
                  lastLotSize -= MartingaleLot; 
                  //Print("222 Reduce Addition lastLotSize: ", lastLotSize);
               }   
               else lastLotSize = OrderLotSize;   
            }
            else lastLotSize = OrderLotSize; 
            
            //Print("222 MartingaleLotCalculationType: ", MartingaleLotCalculationType);
            //Print("222 after deal open orderFrequencyCount: " + orderFrequencyCount+ ", lastLotSize: ", lastLotSize);
         }
      }
   }            
}

void checkRunningOrders() {

   double currentOrderPrice = 0.0, currentProfit = 0.0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == Magic && 
            PositionGetString(POSITION_SYMBOL) == mSymbol) {
            currentProfit = PositionGetDouble(POSITION_PROFIT);
            currentOrderPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         }   
      }
   }
   
   double open1 = iOpen(mSymbol, PERIOD_D1, 1);
   double close1 = iClose(mSymbol, PERIOD_D1, 1);
   double high1 = iHigh(mSymbol, PERIOD_D1, 1);
   double low1 = iLow(mSymbol, PERIOD_D1, 1);
   
   
   double open2 = iOpen(mSymbol, mPeriod, 2);
   double close2 = iClose(mSymbol, mPeriod, 2);
   double high2 = iHigh(mSymbol, mPeriod, 2);
   double low2 = iLow(mSymbol, mPeriod, 2);
   
   Print("open1: ", open1, ", close1: ", close1, ", high1: ", high1, ", low1: ", low1);
   Print("open2: ", open2, ", close2: ", close2, ", high2: ", high2, ", low2: ", low2);
   Print("currentOrderPrice: ", currentOrderPrice, ", currentProfit: ", currentProfit);
   
   if((close2 > open2 && close1 < open1 && currentOrderPrice > open2 && 
      currentOrderPrice < close2 && currentProfit < 0.0) || 
      (close2 < open2 && close1 > open1 && currentOrderPrice < open2 && 
      currentOrderPrice > close2 && currentProfit < 0.0)) {
      
      closeAllPositions();
   
   }
}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
bool  rsiBuySignal = false, rsiSellSignal = false, stochBuySignal = false, stochSellSignal = false,
      candleBuySignal = false, candleSellSignal = false;
string rectObjLastSignal = "", prevRsiState = "", prevStochState = "";
ENUM_ORDER_TYPE rectObjLastOrderType = -1;

void getAllIndicatorsSignal(bool isNewBar) {
   
   //
   // Trend identification with Moving Average 
   //
   
   double close1 = iClose(mSymbol, mPeriod, 1);
   double open1 = iOpen(mSymbol, mPeriod, 1);
   double high1 = iHigh(mSymbol, mPeriod, 1);
   double low1 = iLow(mSymbol, mPeriod, 1);
   
   string candlePattern = "", rsiSignalMsg = "", rsiState = "", stochSignalMsg = "", stochState = "",
          sniperSignalMsg = "";
   //string maDailyTrend  =  cMAIndicator.GetMarketTrend(PERIOD_D1);
          //maWeeklyTrend =  cMAIndicator.GetMarketTrend(PERIOD_W1);
   string message =  "";//cMATouchSignal.GetMASignal(cCandleInfo);
   
   
   //
   // Get daily and weekly nearest support/resistance
   //
   GetCurrentTFNearestSR();
   /*GetFifteenMinsNearestSR();
   GetOneHourNearestSR();
   GetFourHourNearestSR();
   GetDailyNearestSR();
   GetWeeklyNearestSR();
   GetSRConfluenceZone<double>(dailyWeeklyConfluenceZone);
   */
   ENUM_ORDER_TYPE orderType = -1;
   if(isNewBar) {
      cObjRectangle.Reset();
      
      //
      // Check running orders if current order is in lose
      //
      //checkRunningOrders();
      
      
      //
      //
      //
      //IsSDInRange = cSDIndicator.CheckRange();
      
      //Print("close1: ", close1, ", open1: ", open1, ", high1: ", high1, ", low1: ", low1);
      //Print("maDailyTrend: ", maDailyTrend, ", maWeeklyTrend = ", ", message: ", message);
      
      sniperSignalMsg = sniperSignal.sniperSlowMACrossSignal(cCandleInfo);
      //string snipperSignal = sniperSignal.sniperSignal(cCandleInfo);
      
      bool tradeZoneAvailable = checkFirstSRZoneDistance<double>();
      //Print("Sniper Signal: ", sniperSignalMsg, ", tradeZonrAvailable: ", tradeZoneAvailable);
      
      //
      // Get current candlestick pattern name
      //
      candlePattern = candleStickPattern.CandleStickPatterSignal(cCandleInfo);
      if(StringLen(candlePattern) > 0) Print("candlePattern: ", candlePattern);
      
      
      
      
      
      //
      // Get RSI Signal
      //
      rsiState = rsiSignal.RSICurrentStatus(2);
      rsiSignalMsg = rsiSignal.UpdateRSISignal();
      if(StringLen(rsiSignalMsg) > 0) {
         if(StringFind(rsiSignalMsg, "Buy")) { rsiBuySignal = true; rsiSellSignal = false; }
         if(StringFind(rsiSignalMsg, "Sell")) { rsiBuySignal = false; rsiSellSignal = true; }
         //Print("RSI rsiSignalMsg: ", rsiSignalMsg, ", rsiBuySignal: ", rsiBuySignal, ", rsiSellSignal: ", rsiSellSignal);
      }   
      if(StringLen(rsiState) > 0) {
         if(StringFind(rsiState, "RSIIsEnteredTheOversoldZone") >= 0 || 
            StringFind(rsiState, "RSIHasInPureOversoldZone") >= 0 || 
            StringFind(rsiState, "RSIIsEnteredTheOverboughtZone") >= 0 || 
            StringFind(rsiState, "RSIHasInPureOverboughtZone") >= 0) {
            
            prevRsiState = rsiState;
         }
         //Print("rsiState: ", rsiState);
      }
      
      //
      // Get Stoch Signal
      //
      stochState = stochSignal.StochCurrentStatus(2);
      stochSignalMsg = stochSignal.UpdateStochasticSignal();
      if(StringLen(stochSignalMsg) > 0) {
         if(StringFind(stochSignalMsg, "Buy")) { stochBuySignal = true; stochSellSignal = false; }
         if(StringFind(stochSignalMsg, "Sell")) { stochBuySignal = false; stochSellSignal = true; }
         //Print("Stoch stochSignalMsg: ", stochSignalMsg, ", stochState: ", stochState, ", stochBuySignal: ", stochBuySignal, ", stochSellSignal: ", stochSellSignal);
      }
      if(StringLen(stochState) > 0) {
         if(StringFind(rsiState, "StochIsEnteredTheOversoldZone") >= 0 || 
            StringFind(rsiState, "StochHasInPureOversoldZone") >= 0 || 
            StringFind(rsiState, "StochIsEnteredTheOverboughtZone") >= 0 || 
            StringFind(rsiState, "StochHasInPureOverboughtZone") >= 0) {
            
            prevStochState = stochState;
         }
         //Print("StochState: ", stochState);
      }
   }   
   
    
   //ENUM_ORDER_TYPE orderType = GetOrderSignalFromSRZone();
   //ENUM_ORDER_TYPE orderType = checkCandleBreakout();
   orderType = checkCandleBreakout();
   if(orderType >= 0 && PositionsTotal() == 0 && !daily_candle_breakout_orders_fill) {
      placeFirstOrders(orderType, "", 5);
      daily_candle_breakout_orders_fill = true;
   }
   return;
   
   if(orderType >= 0 && PositionsTotal() == 0 ) {  // && !IsSDInRange
   //if(orderType >= 0) {
      Print("Supply Demand signal orderType: ", orderType);
      bool tradeAllow = false, sniperFastEMASignal = false, priceIsNotExistInSRZone = false, 
           validCandle = false;
      
      //if(!CheckIfPriceIsExistInSRZone<double>()) priceIsNotExistInSRZone = true;
      if(checkPreviousValidCandle()) validCandle = true;
      
      // && StringFind(maDailyTrend, "Uptrend") >= 0
      if(orderType == ORDER_TYPE_BUY) {
         if(StringFind(sniperSignalMsg, "Buy signal found from sniper fast EMA") >= 0) {
            sniperFastEMASignal = true;
         }
         
         if(StringFind(rsiState, "RSIIsAboveTheOversoldZone") >= 0 && 
            StringFind(stochState, "StochIsAboveTheOversoldZone") >= 0) {
            tradeAllow = true;
         }
         else if(StringFind(rsiState, "RSIExitFromTheOversoldZone") >= 0 ||
            StringFind(stochState, "StochExitFromTheOversoldZone") >= 0) {
            tradeAllow = true;
         }
         else if(StringFind(rsiState, "RSIIsEnteredTheOverboughtZone") >= 0 ||
            StringFind(stochState, "StochIsEnteredTheOverboughtZone") >= 0 || 
            StringFind(rsiState, "RSIHasInPureOverboughtZone") >= 0 || 
            StringFind(stochState, "StochHasInPureOverboughtZone") >= 0) {
            tradeAllow = true;
         }
      }
      //&& StringFind(maDailyTrend, "Downtrend") >= 0
      else if(orderType == ORDER_TYPE_SELL) {
         if(StringFind(sniperSignalMsg, "Sell signal found from sniper fast EMA") >= 0) {
            sniperFastEMASignal = true;
         }
         
         if((StringFind(rsiState, "RSIIsBelowTheOverboughtZone") >= 0 && 
            StringFind(stochState, "StochIsBelowTheOverboughtZone") >= 0) || 
            (StringFind(rsiState, "RSIIsAboveTheOversoldZone") >= 0 && 
            StringFind(stochState, "StochIsAboveTheOversoldZone") >= 0)) {
            tradeAllow = true;
         }
         else if(StringFind(rsiState, "RSIExitFromTheOverboughtZone") >= 0 ||
            StringFind(stochState, "StochExitFromTheOverboughtZone") >= 0) {
            tradeAllow = true;
         }
         else if(StringFind(rsiState, "RSIIsEnteredTheOversoldZone") >= 0 ||
            StringFind(stochState, "StochIsEnteredTheOversoldZone") >= 0 || 
            StringFind(rsiState, "RSIHasInPureOversoldZone") >= 0 || 
            StringFind(stochState, "StochHasInPureOversoldZone") >= 0) {
            tradeAllow = true;
         }
      }
      
      //if(tradeAllow && priceIsNotExistInSRZone) placeFirstOrders(orderType);
      //if(tradeAllow) placeFirstOrders(orderType);
      //Print("111 tradeAllow: ", tradeAllow, ", sniperFastEMASignal: ", sniperFastEMASignal, ", validCandle: ", validCandle);
      // Need to uncomment
      if((tradeAllow || sniperFastEMASignal) && validCandle) placeFirstOrders(orderType);
      else
      if(tradeAllow && sniperFastEMASignal && validCandle) placeFirstOrders(orderType, "", 5);
      
      // Need to uncomment
      //rectObjLastOrderType = orderType;
      //Print("rectObjLastOrderType: ", rectObjLastOrderType);
   }  
   /*
   // RSI, Stoch, Candle Pattern combination signal
   else if(orderType < 0 && PositionsTotal() == 0) {  // && !IsSDInRange
   //else if(orderType < 0) {
      bool tradeAllow = false, sniperFastEMASignal = false, priceIsNotExistInSRZone = false, validCandle = false;
      //if(!CheckIfPriceIsExistInSRZone<double>()) priceIsNotExistInSRZone = true;
      if(checkPreviousValidCandle()) validCandle = true;
      
      //StringFind(maDailyTrend, "Uptrend") >= 0 && 
      if(StringLen(candlePattern) > 0 && StringFind(candlePattern, "Bullish") >= 0 &&
         ((StringLen(rsiSignalMsg) > 0 && StringFind(rsiSignalMsg, "Buy") >= 0) || 
         (StringLen(stochSignalMsg) > 0 && StringFind(stochSignalMsg, "Buy") >= 0)) ) {
         orderType = ORDER_TYPE_BUY;
         tradeAllow = true;
      }
      //StringFind(maDailyTrend, "Uptrend") >= 0 && 
      else if((StringFind(rsiState, "RSIExitFromTheOverboughtZone") >= 0 && 
            (StringFind(prevRsiState, "RSIIsEnteredTheOverboughtZone") >= 0 || 
            StringFind(prevRsiState, "RSIHasInPureOverboughtZone") >= 0)) && 
            (StringFind(stochState, "StochExitFromTheOverboughtZone") >= 0 && 
            (StringFind(prevStochState, "StochIsEnteredTheOverboughtZone") >= 0 || 
            StringFind(prevStochState, "StochHasInPureOverboughtZone") >= 0))) {
            orderType = ORDER_TYPE_BUY;
            tradeAllow = true;
            prevRsiState = "";
            prevStochState = "";
      }
      
      //StringFind(maDailyTrend, "Downtrend") >= 0 && 
      else if(StringLen(candlePattern) > 0 && StringFind(candlePattern, "Bearish") >= 0 && 
         ((StringLen(rsiSignalMsg) > 0 && StringFind(rsiSignalMsg, "Sell") >= 0) || 
         (StringLen(stochSignalMsg) > 0 && StringFind(stochSignalMsg, "Sell") >= 0)) ) {
         orderType = ORDER_TYPE_SELL;
         tradeAllow = true;
      } 
      //StringFind(maDailyTrend, "Downtrend") >= 0 &&
      else if((StringFind(rsiState, "RSIExitFromTheOversoldZone") >= 0 && 
            (StringFind(prevRsiState, "RSIIsEnteredTheOversoldZone") >= 0 || 
            StringFind(prevRsiState, "RSIHasInPureOversoldZone") >= 0)) && 
            (StringFind(stochState, "StochExitFromTheOversoldZone") >= 0 && 
            (StringFind(prevStochState, "StochIsEnteredTheOversoldZone") >= 0 || 
            StringFind(prevStochState, "StochHasInPureOversoldZone") >= 0))) {
            orderType = ORDER_TYPE_SELL;
            tradeAllow = true;
            prevRsiState = "";
            prevStochState = "";
      }
     
      
      //if(tradeAllow && priceIsNotExistInSRZone) placeFirstOrders(orderType);  
      //if(tradeAllow) placeFirstOrders(orderType);   
      
      // Need to uncomment
      Print("222 tradeAllow: ", tradeAllow, ", sniperFastEMASignal: ", sniperFastEMASignal, ", validCandle: ", validCandle);
      if((tradeAllow || sniperFastEMASignal) && validCandle) placeFirstOrders(orderType);
   } 
   
   //
   // Get price up/down momentum 
   //
   //bool IsMarketInRange       = adxSignal.IsMarketEnteredInRange(cCandleInfo, 10);
   //bool IsMarketExitFromRange = adxSignal.CheckIfMarketExitFromRange(cCandleInfo, 10);
   //string adxMomentum   =  adxSignal.CheckADXMomentum(5);
   //Print("adxMomentum: ", adxMomentum);
   */
}


bool checkPreviousValidCandle() {
   
   double close1 = iClose(mSymbol, mPeriod, 1);
   double open1 = iOpen(mSymbol, mPeriod, 1);
   //double high1 = iHigh(mSymbol, mPeriod, 1);
   //double low1 = iLow(mSymbol, mPeriod, 1);
   
   double close2 = iClose(mSymbol, mPeriod, 2);
   double open2 = iOpen(mSymbol, mPeriod, 2);
   //double high2 = iHigh(mSymbol, mPeriod, 2);
   //double low2 = iLow(mSymbol, mPeriod, 2);
   
   
   double bodySize1 =  MathAbs(open1-close1);
          
   double averageBody = 0.0;       
   for(int i=0; i<10; i++) {
      // Calculate average bodysize of prevous candles 
      averageBody += MathAbs(iOpen(mSymbol, mPeriod, i)-iClose(mSymbol, mPeriod, i));
   }
   averageBody = (averageBody/10.0);
   //Print("averageBody: ", averageBody, ", averageBody*1.3: ", averageBody*1.3, 
   //      ", bodySize1: ", bodySize1);
   //if((bodySize1 > averageBody*1.3) && bodySize1 > 1.3) return (true);
   if((bodySize1 > averageBody*1.3)) return (true);
   
   return (false);
}

ENUM_ORDER_TYPE filterEntrySignal(string message, string objName) {

   ENUM_ORDER_TYPE orderType = -1;
   
   //|| || StringFind(objName, "Untested") > -1
   //   StringFind(objName, "Turncoat") > -1
   if(StringFind(objName, "Proven") > -1 || StringFind(objName, "Verified") > -1 || 
      StringFind(objName, "Turncoat") > -1) {
      
      // Get BUY/SELL signal from moving average on higher and lower timeframe,
      // Check Rectangle object signal
      if(StringLen(message) > 0 && 
         StringFind(message, "from above") > -1 && StringFind(message, "retracing") > -1) {
         orderType = ORDER_TYPE_BUY;
      }
      else if(StringLen(message) > 0 && 
              StringFind(message, "from below") > -1 && StringFind(message, "retracing") > -1) {
         orderType = ORDER_TYPE_SELL;
      }
      
      /*
      bool rectZoneBreak = false;
      // Get BUY/SELL signal from moving average on higher and lower timeframe,
      // Check Rectangle object signal
      if(StringLen(message) > 0 && 
         StringFind(message, "broken") > -1 && StringFind(message, "from above") > -1) { 
         orderType = ORDER_TYPE_SELL; rectZoneBreak = true; 
      }
      else if(StringLen(message) > 0 && 
              StringFind(message, "broken") > -1 && StringFind(message, "from below") > -1) {
         orderType = ORDER_TYPE_BUY; rectZoneBreak = true; 
      }
      
      
      // Special check for Rectangle breaks event
      double lastCloseBar = iClose(mSymbol, mPeriod, 1);
      //if(rectZoneBreak && dailyResistanceZone.Total() > 0) {
      if(rectZoneBreak && currentTFResistanceZone.Total() > 0) {
         //Print("rectZoneBreak: ", rectZoneBreak);
         //if(lastCloseBar > ((CRectObjPriceSortable<double> *)dailyResistanceZone.At(0)).price0)
         if(lastCloseBar > ((CRectObjPriceSortable<double> *)currentTFResistanceZone.At(0)).price0)
            orderType = ORDER_TYPE_BUY;
      }
      //if(rectZoneBreak && dailySupportZone.Total() > 0) {
      if(rectZoneBreak && currentTFSupportZone.Total() > 0) {
         //if(lastCloseBar < ((CRectObjPriceSortable<double> *)dailySupportZone.At(0)).price1)
         if(lastCloseBar < ((CRectObjPriceSortable<double> *)currentTFSupportZone.At(0)).price1)
            orderType = ORDER_TYPE_SELL;
      }*/
   }
   return orderType;
}


ENUM_ORDER_TYPE checkCandleBreakout() {
   
   if(hourlyOrderTime) {
      bool weeklyZoneBreak = false, monthlyZoneBreak = false;
      // Check if price within the weekly and monthly price zone,
      // then no signal will count
      if(checkPriceInWeeklyHighLowZone()) return(-1);
      else weeklyZoneBreak = true;
      if(checkPriceInMonthlyHighLowZone()) return(-1);
      else monthlyZoneBreak = true;
      //Print("weeklyZoneBreak: ", weeklyZoneBreak);
      
      
      double dailyCandleHigh = iHigh(mSymbol, PERIOD_D1, 1);
      double dailyCandleLow = iLow(mSymbol, PERIOD_D1, 1);
      double fourHourCandleClose = iClose(mSymbol, PERIOD_H4, 1);
      double oneHourCandleClose = iClose(mSymbol, PERIOD_H1, 1);
     
      
      // Daily breakout signals
      if(fourHourCandleClose > dailyCandleHigh || oneHourCandleClose > dailyCandleHigh) 
         return ORDER_TYPE_BUY;
      else 
      if(fourHourCandleClose < dailyCandleLow || oneHourCandleClose < dailyCandleLow) 
         return ORDER_TYPE_SELL;   
   }         

   return(-1);
}


bool checkPriceInWeeklyHighLowZone() {
   
   bool IsPriceInWeeklyZone = false;
   double weeklyPipsOffset = 10.0; 
   double weeklyCandleHigh = iHigh(mSymbol, PERIOD_W1, 1);
   double weeklyCandleLow = iLow(mSymbol, PERIOD_W1, 1);
   double weeklyCandleOpen = iOpen(mSymbol, PERIOD_W1, 1);
   double weeklyCandleClose = iClose(mSymbol, PERIOD_W1, 1);
   double fourHourCandleClose = iClose(mSymbol, PERIOD_H4, 1);
   double oneHourCandleClose = iClose(mSymbol, PERIOD_H1, 1);
   
   double weeklyHighZone1 = 0.0, weeklyHighZone2 = 0.0, weeklyLowZone1 = 0.0, weeklyLowZone2 = 0.0;
   if(weeklyCandleClose > weeklyCandleOpen) {
      
      // Top zone check
      weeklyHighZone1 = MathAbs(weeklyCandleHigh - PipsToPrice(weeklyPipsOffset, mSymbol)); 
      weeklyHighZone2 = MathAbs(weeklyCandleHigh + PipsToPrice(weeklyPipsOffset, mSymbol));
      
      // Low zone check   
      weeklyLowZone1 = MathAbs(weeklyCandleLow + PipsToPrice(weeklyPipsOffset, mSymbol)); 
      weeklyLowZone2 = MathAbs(weeklyCandleLow - PipsToPrice(weeklyPipsOffset, mSymbol)); 
      
      
      if((fourHourCandleClose >= weeklyHighZone1 && fourHourCandleClose <= weeklyHighZone2) || 
         (oneHourCandleClose >= weeklyHighZone1 && oneHourCandleClose <= weeklyHighZone2)) {
         /*Print("111 fourHourCandleClose: ", fourHourCandleClose, ", oneHourCandleClose: ", oneHourCandleClose);
         Print("111 weeklyHighZone1: ", weeklyHighZone1, ", weeklyHighZone2: ", weeklyHighZone2);
         Print("111 weeklyLowZone1: ", weeklyLowZone1, ", weeklyLowZone2: ", weeklyLowZone2);
         Print("111 Price close in weekly top zone");*/
         IsPriceInWeeklyZone = true;
      }
      else 
      if((fourHourCandleClose <= weeklyLowZone1 && fourHourCandleClose >= weeklyLowZone2) || 
         (oneHourCandleClose <= weeklyLowZone1 && oneHourCandleClose >= weeklyLowZone2)) {
         /*Print("222 fourHourCandleClose: ", fourHourCandleClose, ", oneHourCandleClose: ", oneHourCandleClose);
         Print("222 weeklyHighZone1: ", weeklyHighZone1, ", weeklyHighZone2: ", weeklyHighZone2);
         Print("222 weeklyLowZone1: ", weeklyLowZone1, ", weeklyLowZone2: ", weeklyLowZone2);
         Print("222 Price close in weekly bottom zone");*/
         IsPriceInWeeklyZone = true;
         
      }
   }
   else 
   if(weeklyCandleClose < weeklyCandleOpen) {
      // Top zone check
      weeklyHighZone1 = MathAbs(weeklyCandleHigh - PipsToPrice(weeklyPipsOffset)); 
      weeklyHighZone2 = MathAbs(weeklyCandleHigh + PipsToPrice(weeklyPipsOffset));
      //Print("333 weeklyHighZone1: ", weeklyHighZone1, ", weeklyHighZone2: ", weeklyHighZone2);
      
      // Low zone check   
      weeklyLowZone1 = MathAbs(weeklyCandleLow + PipsToPrice(weeklyPipsOffset)); 
      weeklyLowZone2 = MathAbs(weeklyCandleLow - PipsToPrice(weeklyPipsOffset)); 
      //Print("444 weeklyLowZone1: ", weeklyLowZone1, ", weeklyLowZone2: ", weeklyLowZone2);
      
      if((fourHourCandleClose >= weeklyHighZone1 && fourHourCandleClose <= weeklyHighZone2) || 
         (oneHourCandleClose >= weeklyHighZone1 && oneHourCandleClose <= weeklyHighZone2)) {
         /*Print("333 fourHourCandleClose: ", fourHourCandleClose, ", oneHourCandleClose: ", oneHourCandleClose);
         Print("333 weeklyHighZone1: ", weeklyHighZone1, ", weeklyHighZone2: ", weeklyHighZone2);
         Print("333 weeklyLowZone1: ", weeklyLowZone1, ", weeklyLowZone2: ", weeklyLowZone2);
         Print("333 Price close in weekly zone");*/
         IsPriceInWeeklyZone = true;
      }
      else 
      if((fourHourCandleClose <= weeklyLowZone1 && fourHourCandleClose >= weeklyLowZone2) || 
         (oneHourCandleClose <= weeklyLowZone1 && oneHourCandleClose >= weeklyLowZone2)) {
         /*Print("444 fourHourCandleClose: ", fourHourCandleClose, ", oneHourCandleClose: ", oneHourCandleClose);
         Print("444 weeklyHighZone1: ", weeklyHighZone1, ", weeklyHighZone2: ", weeklyHighZone2);
         Print("444 weeklyLowZone1: ", weeklyLowZone1, ", weeklyLowZone2: ", weeklyLowZone2);
         Print("444 Price close in weekly zone");*/
         IsPriceInWeeklyZone = true;
      }
   }

   return(IsPriceInWeeklyZone);
}


bool checkPriceInMonthlyHighLowZone() {
   
   bool IsPriceInMonthlyZone = false;
   double monthlyPipsOffset = 20.0; 
   double monthlyCandleHigh = iHigh(mSymbol, PERIOD_MN1, 1);
   double monthlyCandleLow = iLow(mSymbol, PERIOD_MN1, 1);
   double monthlyCandleOpen = iOpen(mSymbol, PERIOD_MN1, 1);
   double monthlyCandleClose = iClose(mSymbol, PERIOD_MN1, 1);
   double fourHourCandleClose = iClose(mSymbol, PERIOD_H4, 1);
   double oneHourCandleClose = iClose(mSymbol, PERIOD_H1, 1);
   
   double monthlyHighZone1 = 0.0, monthlyHighZone2 = 0.0, monthlyLowZone1 = 0.0, monthlyLowZone2 = 0.0;
   if(monthlyCandleClose > monthlyCandleOpen) {
      
      // Top zone check
      monthlyHighZone1 = MathAbs(monthlyCandleHigh - PipsToPrice(monthlyPipsOffset)); 
      monthlyHighZone2 = MathAbs(monthlyCandleHigh + PipsToPrice(monthlyPipsOffset));
      
      // Low zone check   
      monthlyLowZone1 = MathAbs(monthlyCandleLow + PipsToPrice(monthlyPipsOffset, mSymbol)); 
      monthlyLowZone2 = MathAbs(monthlyCandleLow - PipsToPrice(monthlyPipsOffset, mSymbol)); 
      
      if((fourHourCandleClose >= monthlyHighZone1 && fourHourCandleClose <= monthlyHighZone2) || 
         (oneHourCandleClose >= monthlyHighZone1 && oneHourCandleClose <= monthlyHighZone2)) {
         IsPriceInMonthlyZone = true;
      }
      else 
      if((fourHourCandleClose <= monthlyLowZone1 && fourHourCandleClose >= monthlyLowZone2) || 
         (oneHourCandleClose <= monthlyLowZone1 && oneHourCandleClose >= monthlyLowZone2)) {
         IsPriceInMonthlyZone = true;
      }
   }
   else 
   if(monthlyCandleClose < monthlyCandleOpen) {
      // Top zone check
      monthlyHighZone1 = MathAbs(monthlyCandleHigh - PipsToPrice(monthlyPipsOffset)); 
      monthlyHighZone2 = MathAbs(monthlyCandleHigh + PipsToPrice(monthlyPipsOffset));
      
      // Low zone check   
      monthlyLowZone1 = MathAbs(monthlyCandleLow + PipsToPrice(monthlyPipsOffset)); 
      monthlyLowZone2 = MathAbs(monthlyCandleLow - PipsToPrice(monthlyPipsOffset)); 
      
      if((fourHourCandleClose >= monthlyHighZone1 && fourHourCandleClose <= monthlyHighZone2) || 
         (oneHourCandleClose >= monthlyHighZone1 && oneHourCandleClose <= monthlyHighZone2)) {
         IsPriceInMonthlyZone = true;
      }
      else 
      if((fourHourCandleClose <= monthlyLowZone1 && fourHourCandleClose >= monthlyLowZone2) || 
         (oneHourCandleClose <= monthlyLowZone1 && oneHourCandleClose >= monthlyLowZone2)) {
         IsPriceInMonthlyZone = true;
      }
   }

   return(IsPriceInMonthlyZone);
}


/*********************************************************************
***  MA Trading Signal
**********************************************************************/

int candleCount = 0;
string currentTrend = "";
void checkMATouchSignal() {
   
   ENUM_ORDER_TYPE orderType = -1;
   bool maBreaksUpToDown = false, maBreaksDownToUp = false;
   double maLastTouchPrice = 0.0;
   static string tmpTrend = "";
   string message = cMATouchSignal.GetMASignal(cCandleInfo);
   Print("message: ", message);
   
   if(StringLen(message) > 0) {
      if(StringFind(message, "Price breaks the MA from above to below") >=0 ) {
         maBreaksUpToDown = true;
         maBreaksDownToUp = false;
         //candleCount = 0;
         //currentTrend = "Downtrend";
      }
      if(StringFind(message, "Price breaks the MA from below to above") >= 0) {
         maBreaksDownToUp = true;
         maBreaksUpToDown = false;
         //candleCount = 0;
         //currentTrend = "Uptrend";
      }
      
      if(maBreaksDownToUp && 
         StringFind(message, "Uptrend, price touches the MA from above and retracing") >= 0) {
         orderType = ORDER_TYPE_BUY;
         maLastTouchPrice = iLow(mSymbol, mPeriod, 1);
         maBreaksDownToUp = false;
         maBreaksUpToDown = false;
         //candleCount = 0;
      }
      else 
      if(maBreaksUpToDown && 
         StringFind(message, "Downtrend, price touches the MA from below and retracing") >= 0) {
         orderType = ORDER_TYPE_SELL;
         maLastTouchPrice = iHigh(mSymbol, mPeriod, 1);
         maBreaksDownToUp = false;
         maBreaksUpToDown = false;
         //candleCount = 0;
      }
      if(StringFind(currentTrend, "Uptrend") >=0  && 
         StringFind(message, "Uptrend, price touches the MA from above and retracing") >= 0) {
         //currentTrend = "Downtrend";
         orderType = ORDER_TYPE_BUY;
         maLastTouchPrice = iLow(mSymbol, mPeriod, 1);
      }
      else 
      if(StringFind(currentTrend, "Downtrend") >=0 && 
         StringFind(message, "Downtrend, price touches the MA from below and retracing") >= 0) {
         orderType = ORDER_TYPE_SELL;
         maLastTouchPrice = iHigh(mSymbol, mPeriod, 1);
      }
      else if(message == "Uptrend") {
         currentTrend = message;
         if(!maBreaksUpToDown && !maBreaksDownToUp) orderType = ORDER_TYPE_BUY;
      }
      else if(message == "Downtrend") {
         currentTrend = message;
         if(!maBreaksUpToDown && !maBreaksDownToUp) orderType = ORDER_TYPE_SELL;
      }
   }
   
   
   // After price breaks the MA, check if price touch the MA within the count,
   // If not touched, then reset these flags
   if(candleCount >= 5) {
      maBreaksDownToUp  =  false;
      maBreaksUpToDown  =  false;
      //candleCount = 0;
   }
   
   // Count candle if the price breaks the MA
   if(maBreaksDownToUp || maBreaksUpToDown) candleCount++;
   
   //Print("maBreaksDownToUp: ", maBreaksDownToUp, ", maBreaksUpToDown: ", maBreaksUpToDown, ", candleCount: ", candleCount);
   
   // Place order
   //if(orderType > -1 && totalOrders < 1) {
      if(orderType == 0) Print("BUY order executed");
      else if(orderType == 1) Print("SELL order executed");
      //placeFirstOrders(orderType, maLastTouchPrice);  
   //}
   
}


/*********************************************************************
***  Find out Demand & Supply Zone, Signal
**********************************************************************/

ENUM_ORDER_TYPE GetOrderSignalFromSRZone() {

   ENUM_ORDER_TYPE orderSignal = -1;
   double bidPrice = NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits);
   int totalObj   =  ObjectsTotal(0, 0, OBJ_RECTANGLE);
   for(int i=totalObj-1; i>=0; i--) {
      // Get object name
      string objName = ObjectName(0, i, 0, OBJ_RECTANGLE);
      
      //
      // Check Rectangular Object Touch/Retrace/Break Signal
      //
      if(StringFind(objName, "DSRRR", 0) >= 0 || 
         StringFind(objName, "WSRRR", 0) >= 0 || 
         StringFind(objName, "CTFSRRR", 0) >= 0 || 
         StringFind(objName, "Rectangle", 0) >= 0) {
         string message = cObjRectangle.CheckPriceOnRectangle(newBar, objName, bidPrice, cCandleInfo);
         
         if(StringLen(message) > 0) {
            //return message;
            rectObjLastSignal = message;
            Print("OBJ_RECTANGLE objName: ", objName, ", message: "+ message);
            orderSignal = filterEntrySignal(message, objName);
            return orderSignal;
            //Print("OBJ_RECTANGLE objName: ", objName, ", message: "+message, ", orderSignal: ", orderSignal);
            /*if(orderSignal >= 0) {
               string tmpObjName = getLastRetraceOrBreakRectObj(orderSignal, objName);
               pendingOrderLevel = getPendingOrderLevel(orderSignal, tmpObjName);
               //Print("orderSignal: ", orderSignal, ", pendingOrderLevel: ", pendingOrderLevel);
               placeFirstOrders(orderSignal);  
            }*/   
         }   
         message = "";   
      }
   }
   return orderSignal;
} 


template <typename T>
void GetSRConfluenceZone(CArrayObj &arr) {
   
   // Delete previous all elements
   arr.DeleteRange(0, arr.Total()-1);
   
   // Get daily weekly support confluence zone
   for(int i=0; i<dailySupportZone.Total(); i++) {
      CRectObjPriceSortable<T> *dailyNode = (CRectObjPriceSortable<T> *)dailySupportZone.At(i);
      for(int j=0; j<weeklySupportZone.Total(); j++) {
         CRectObjPriceSortable<T> *weeklyNode = (CRectObjPriceSortable<T> *)weeklySupportZone.At(j);
         if(dailyNode.price0 <= weeklyNode.price0 && dailyNode.price1 >= weeklyNode.price1)
            arr.Add(weeklyNode);
      } 
   } 
   
   
   // Get daily weekly resistance confluence zone
   for(int i=0; i<dailyResistanceZone.Total(); i++) {
      CRectObjPriceSortable<T> *dailyNode = (CRectObjPriceSortable<T> *)dailyResistanceZone.At(i);
      for(int j=0; j<weeklyResistanceZone.Total(); j++) {
         CRectObjPriceSortable<T> *weeklyNode = (CRectObjPriceSortable<T> *)weeklyResistanceZone.At(j);
         if(dailyNode.price0 <= weeklyNode.price0 && dailyNode.price1 >= weeklyNode.price1)
            arr.Add(weeklyNode);
      } 
   } 
   
   /*
   Print("##################################");
   Print("Start Daily Weekly Confluence Zone");
   PrintToArr<double>(arr, "ConfluenceZone");
   Print("End Daily Weekly Confluence Zone");
   Print("##################################");
   */
}


template <typename T>
bool CheckIfPriceIsExistInSRZone() {
   
   bool priceExistInSRZone = false;
   double bidPrice = NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits);
   
   // Check 15 mintues SR Zone
   for(int i=0; i<fifteenMinsResistanceZone.Total(); i++) {
      CRectObjPriceSortable<T> *node = (CRectObjPriceSortable<T> *)fifteenMinsResistanceZone.At(i);
      if(bidPrice <= node.price0 && bidPrice >= node.price1) return (true);
   }
   for(int i=0; i<fifteenMinsSupportZone.Total(); i++) {
      CRectObjPriceSortable<T> *node = (CRectObjPriceSortable<T> *)fifteenMinsSupportZone.At(i);
      if(bidPrice <= node.price0 && bidPrice >= node.price1) return (true);
   } 
   
   
   // Check One Hour SR Zone
   for(int i=0; i<oneHourResistanceZone.Total(); i++) {
      CRectObjPriceSortable<T> *node = (CRectObjPriceSortable<T> *)oneHourResistanceZone.At(i);
      if(bidPrice <= node.price0 && bidPrice >= node.price1) return (true);
   }
   for(int i=0; i<oneHourSupportZone.Total(); i++) {
      CRectObjPriceSortable<T> *node = (CRectObjPriceSortable<T> *)oneHourSupportZone.At(i);
      if(bidPrice <= node.price0 && bidPrice >= node.price1) return (true);
   } 
   
   
   // Check Four Hour SR Zone
   for(int i=0; i<fourHourResistanceZone.Total(); i++) {
      CRectObjPriceSortable<T> *node = (CRectObjPriceSortable<T> *)fourHourResistanceZone.At(i);
      if(bidPrice <= node.price0 && bidPrice >= node.price1) return (true);
   }
   for(int i=0; i<fourHourSupportZone.Total(); i++) {
      CRectObjPriceSortable<T> *node = (CRectObjPriceSortable<T> *)fourHourSupportZone.At(i);
      if(bidPrice <= node.price0 && bidPrice >= node.price1) return (true);
   } 
   
   
   // Check Daily SR Zone
   for(int i=0; i<dailyResistanceZone.Total(); i++) {
      CRectObjPriceSortable<T> *node = (CRectObjPriceSortable<T> *)dailyResistanceZone.At(i);
      if(bidPrice <= node.price0 && bidPrice >= node.price1) return (true);
   }
   for(int i=0; i<dailySupportZone.Total(); i++) {
      CRectObjPriceSortable<T> *node = (CRectObjPriceSortable<T> *)dailySupportZone.At(i);
      if(bidPrice <= node.price0 && bidPrice >= node.price1) return (true);
   }
   
   
   // Check Weekly SR Zone
   for(int i=0; i<weeklyResistanceZone.Total(); i++) {
      CRectObjPriceSortable<T> *node = (CRectObjPriceSortable<T> *)weeklyResistanceZone.At(i);
      if(bidPrice <= node.price0 && bidPrice >= node.price1) return (true);
   }
   for(int i=0; i<weeklySupportZone.Total(); i++) {
      CRectObjPriceSortable<T> *node = (CRectObjPriceSortable<T> *)weeklySupportZone.At(i);
      if(bidPrice <= node.price0 && bidPrice >= node.price1) return (true);
   }
   
   return (false);
}


//
// Check for tradable supply and demand zone 
//
template <typename T>
bool checkFirstSRZoneDistance() {
   double zoneDistance = 0.0;
   if(currentTFResistanceZone.Total() > 0 && currentTFSupportZone.Total() > 0) {
      CRectObjPriceSortable<T> *firstResistance = (CRectObjPriceSortable<T> *)currentTFResistanceZone.At(0);
      CRectObjPriceSortable<T> *firstSupport = (CRectObjPriceSortable<T> *)currentTFSupportZone.At(0);
      
      zoneDistance = PriceToPips(MathAbs(firstResistance.price1 - firstSupport.price0), mSymbol);
      
      // If first supply and demand zones are found beyond 50 pips, then 
      // this zone is available for trade 
      if(zoneDistance > 30) return true;
   }
   return false;
}


// Get nearest support resistance from Supply And Demand
void GetCurrentTFNearestSR() {
   double bidPrice = NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits);
   
   // Remove all items from the array
   currentTFResistanceZone.DeleteRange(0, currentTFResistanceZone.Total()-1);
   currentTFSupportZone.DeleteRange(0, currentTFSupportZone.Total()-1);
   
               
   int totalObj   =  ObjectsTotal(0, 0, OBJ_RECTANGLE);
   for(int i=totalObj-1; i>=0; i--) {
      // Get object name
      string objName = ObjectName(0, i, 0, OBJ_RECTANGLE);
      if(StringFind(objName, "CTFSRRR") >= 0) {
         double price0        =  ObjectGetDouble(0, objName, OBJPROP_PRICE, 0);  // High price
         double price1        =  ObjectGetDouble(0, objName, OBJPROP_PRICE, 1);  // Low price 
         datetime startTime   =  ObjectGetInteger(0, objName, OBJPROP_TIME, 0);  // Most left time
         datetime endTime     =  ObjectGetInteger(0, objName, OBJPROP_TIME, 1);  // Recent right time
            
         if(price0 > bidPrice && price1 > bidPrice) {
            //Print("111 bidPrice: ", bidPrice, ", price0: ", price0, ", price1: ", price1, ", startTime: ", startTime, ", endTime: ", endTime);
            AddToArray(currentTFResistanceZone, price0, price1, startTime, endTime, objName);
         }
         else if(price0 < bidPrice && price1 < bidPrice) {
            //Print("222 bidPrice: ", bidPrice, ", price0: ", price0, ", price1: ", price1, ", startTime: ", startTime, ", endTime: ", endTime);
            AddToArray(currentTFSupportZone, price0, price1, startTime, endTime, objName);
         }
      }      
   }
   
   currentTFResistanceZone.Sort(1);
   currentTFSupportZone.Sort(2);
   
   /*
   Print("##################################");
   Print("Start Daily Support & Resistance");
   PrintToArr<double>(currentTFResistanceZone, "Resistance"); 
   PrintToArr<double>(currentTFSupportZone, "Support"); 
   Print("End Daily Support & Resistance");
   Print("##################################");
   */
}

// Get nearest support resistance from Supply And Demand
void GetFifteenMinsNearestSR() {
   double bidPrice = NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits);
   
   // Remove all items from the array
   fifteenMinsResistanceZone.DeleteRange(0, fifteenMinsResistanceZone.Total()-1);
   fifteenMinsSupportZone.DeleteRange(0, fifteenMinsSupportZone.Total()-1);
   
               
   int totalObj   =  ObjectsTotal(0, 0, OBJ_RECTANGLE);
   for(int i=totalObj-1; i>=0; i--) {
      // Get object name
      string objName = ObjectName(0, i, 0, OBJ_RECTANGLE);
      if(StringFind(objName, "15MSRRR") >= 0) {
         double price0        =  ObjectGetDouble(0, objName, OBJPROP_PRICE, 0);  // High price
         double price1        =  ObjectGetDouble(0, objName, OBJPROP_PRICE, 1);  // Low price 
         datetime startTime   =  ObjectGetInteger(0, objName, OBJPROP_TIME, 0);  // Most left time
         datetime endTime     =  ObjectGetInteger(0, objName, OBJPROP_TIME, 1);  // Recent right time
            
         if(price0 > bidPrice && price1 > bidPrice) {
            //Print("111 bidPrice: ", bidPrice, ", price0: ", price0, ", price1: ", price1, ", startTime: ", startTime, ", endTime: ", endTime);
            AddToArray(fifteenMinsResistanceZone, price0, price1, startTime, endTime, objName);
         }
         else if(price0 < bidPrice && price1 < bidPrice) {
            //Print("222 bidPrice: ", bidPrice, ", price0: ", price0, ", price1: ", price1, startTime: ", startTime, ", endTime: ", endTime);
            AddToArray(fifteenMinsSupportZone, price0, price1, startTime, endTime, objName);
         }
      }      
   }
   
   fifteenMinsResistanceZone.Sort(1);
   fifteenMinsSupportZone.Sort(2);
   
   /*
   Print("##################################");
   Print("Start Daily Support & Resistance");
   PrintToArr<double>(dailyResistanceZone, "Resistance"); 
   PrintToArr<double>(dailySupportZone, "Support"); 
   Print("End Daily Support & Resistance");
   Print("##################################");
   */
}

// Get nearest support resistance from Supply And Demand
void GetOneHourNearestSR() {
   double bidPrice = NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits);
   
   // Remove all items from the array
   oneHourResistanceZone.DeleteRange(0, oneHourResistanceZone.Total()-1);
   oneHourSupportZone.DeleteRange(0, oneHourSupportZone.Total()-1);
   
               
   int totalObj   =  ObjectsTotal(0, 0, OBJ_RECTANGLE);
   for(int i=totalObj-1; i>=0; i--) {
      // Get object name
      string objName = ObjectName(0, i, 0, OBJ_RECTANGLE);
      if(StringFind(objName, "1HSRRR") >= 0) {
         double price0        =  ObjectGetDouble(0, objName, OBJPROP_PRICE, 0);  // High price
         double price1        =  ObjectGetDouble(0, objName, OBJPROP_PRICE, 1);  // Low price 
         datetime startTime   =  ObjectGetInteger(0, objName, OBJPROP_TIME, 0);  // Most left time
         datetime endTime     =  ObjectGetInteger(0, objName, OBJPROP_TIME, 1);  // Recent right time
            
         if(price0 > bidPrice && price1 > bidPrice) {
            //Print("111 bidPrice: ", bidPrice, ", price0: ", price0, ", price1: ", price1, ", startTime: ", startTime, ", endTime: ", endTime);
            AddToArray(oneHourResistanceZone, price0, price1, startTime, endTime, objName);
         }
         else if(price0 < bidPrice && price1 < bidPrice) {
            //Print("222 bidPrice: ", bidPrice, ", price0: ", price0, ", price1: ", price1, startTime: ", startTime, ", endTime: ", endTime);
            AddToArray(oneHourSupportZone, price0, price1, startTime, endTime, objName);
         }
      }      
   }
   
   oneHourResistanceZone.Sort(1);
   oneHourSupportZone.Sort(2);
   
   /*
   Print("##################################");
   Print("Start Daily Support & Resistance");
   PrintToArr<double>(dailyResistanceZone, "Resistance"); 
   PrintToArr<double>(dailySupportZone, "Support"); 
   Print("End Daily Support & Resistance");
   Print("##################################");
   */
}

// Get nearest support resistance from Supply And Demand
void GetFourHourNearestSR() {
   double bidPrice = NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits);
   
   // Remove all items from the array
   fourHourResistanceZone.DeleteRange(0, fourHourResistanceZone.Total()-1);
   fourHourSupportZone.DeleteRange(0, fourHourSupportZone.Total()-1);
   
               
   int totalObj   =  ObjectsTotal(0, 0, OBJ_RECTANGLE);
   for(int i=totalObj-1; i>=0; i--) {
      // Get object name
      string objName = ObjectName(0, i, 0, OBJ_RECTANGLE);
      if(StringFind(objName, "4HSRRR") >= 0) {
         double price0        =  ObjectGetDouble(0, objName, OBJPROP_PRICE, 0);  // High price
         double price1        =  ObjectGetDouble(0, objName, OBJPROP_PRICE, 1);  // Low price 
         datetime startTime   =  ObjectGetInteger(0, objName, OBJPROP_TIME, 0);  // Most left time
         datetime endTime     =  ObjectGetInteger(0, objName, OBJPROP_TIME, 1);  // Recent right time
            
         if(price0 > bidPrice && price1 > bidPrice) {
            //Print("111 bidPrice: ", bidPrice, ", price0: ", price0, ", price1: ", price1, ", startTime: ", startTime, ", endTime: ", endTime);
            AddToArray(fourHourResistanceZone, price0, price1, startTime, endTime, objName);
         }
         else if(price0 < bidPrice && price1 < bidPrice) {
            //Print("222 bidPrice: ", bidPrice, ", price0: ", price0, ", price1: ", price1, startTime: ", startTime, ", endTime: ", endTime);
            AddToArray(fourHourSupportZone, price0, price1, startTime, endTime, objName);
         }
      }      
   }
   
   fourHourResistanceZone.Sort(1);
   fourHourSupportZone.Sort(2);
   
   /*
   Print("##################################");
   Print("Start Daily Support & Resistance");
   PrintToArr<double>(dailyResistanceZone, "Resistance"); 
   PrintToArr<double>(dailySupportZone, "Support"); 
   Print("End Daily Support & Resistance");
   Print("##################################");
   */
}

// Get nearest support resistance from Supply And Demand
void GetDailyNearestSR() {
   double bidPrice = NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits);
   
   // Remove all items from the array
   dailyResistanceZone.DeleteRange(0, dailyResistanceZone.Total()-1);
   dailySupportZone.DeleteRange(0, dailySupportZone.Total()-1);
   
               
   int totalObj   =  ObjectsTotal(0, 0, OBJ_RECTANGLE);
   for(int i=totalObj-1; i>=0; i--) {
      // Get object name
      string objName = ObjectName(0, i, 0, OBJ_RECTANGLE);
      if(StringFind(objName, "DSRRR") >= 0 && StringFind(objName, "WSRRR") <= -1) {
         double price0        =  ObjectGetDouble(0, objName, OBJPROP_PRICE, 0);  // High price
         double price1        =  ObjectGetDouble(0, objName, OBJPROP_PRICE, 1);  // Low price 
         datetime startTime   =  ObjectGetInteger(0, objName, OBJPROP_TIME, 0);  // Most left time
         datetime endTime     =  ObjectGetInteger(0, objName, OBJPROP_TIME, 1);  // Recent right time
            
         if(price0 > bidPrice && price1 > bidPrice) {
            //Print("111 bidPrice: ", bidPrice, ", price0: ", price0, ", price1: ", price1, ", startTime: ", startTime, ", endTime: ", endTime);
            AddToArray(dailyResistanceZone, price0, price1, startTime, endTime, objName);
         }
         else if(price0 < bidPrice && price1 < bidPrice) {
            //Print("222 bidPrice: ", bidPrice, ", price0: ", price0, ", price1: ", price1, startTime: ", startTime, ", endTime: ", endTime);
            AddToArray(dailySupportZone, price0, price1, startTime, endTime, objName);
         }
      }      
   }
   
   dailyResistanceZone.Sort(1);
   dailySupportZone.Sort(2);
   
   /*
   Print("##################################");
   Print("Start Daily Support & Resistance");
   PrintToArr<double>(dailyResistanceZone, "Resistance"); 
   PrintToArr<double>(dailySupportZone, "Support"); 
   Print("End Daily Support & Resistance");
   Print("##################################");
   */
}


void GetWeeklyNearestSR() {
   double bidPrice = NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits);
   
   // Remove all items from the array
   weeklyResistanceZone.DeleteRange(0, weeklyResistanceZone.Total()-1);
   weeklySupportZone.DeleteRange(0, weeklySupportZone.Total()-1);
   
               
   int totalObj   =  ObjectsTotal(0, 0, OBJ_RECTANGLE);
   for(int i=totalObj-1; i>=0; i--) {
      // Get object name
      string objName = ObjectName(0, i, 0, OBJ_RECTANGLE);
      if(StringFind(objName, "WSRRR") >= 0) {
         double price0        =  ObjectGetDouble(0, objName, OBJPROP_PRICE, 0);  // High price
         double price1        =  ObjectGetDouble(0, objName, OBJPROP_PRICE, 1);  // Low price 
         datetime startTime   =  ObjectGetInteger(0, objName, OBJPROP_TIME, 0);  // Most left time
         datetime endTime     =  ObjectGetInteger(0, objName, OBJPROP_TIME, 1);  // Recent right time
            
         if(price0 > bidPrice && price1 > bidPrice) {
            //Print("111 bidPrice: ", bidPrice, ", price0: ", price0, ", price1: ", price1, ", startTime: ", startTime, ", endTime: ", endTime);
            AddToArray(weeklyResistanceZone, price0, price1, startTime, endTime, objName);
         }
         else if(price0 < bidPrice && price1 < bidPrice) {
            //Print("222 bidPrice: ", bidPrice, ", price0: ", price0, ", price1: ", price1, startTime: ", startTime, ", endTime: ", endTime);
            AddToArray(weeklySupportZone, price0, price1, startTime, endTime, objName);
         }
      }      
   }
   
   weeklyResistanceZone.Sort(1);
   weeklySupportZone.Sort(2);
   
   /*
   Print("##################################");
   Print("Start Weekly Support & Resistance");
   PrintToArr<double>(weeklyResistanceZone, "Resistance"); 
   PrintToArr<double>(weeklySupportZone, "Support"); 
   Print("End Weekly Support & Resistance");
   Print("##################################");
   */
}

template <typename T>
void PrintToArr(CArrayObj &arr, string arrName) {
   for(int i=0; i<arr.Total(); i++) {
      CRectObjPriceSortable<T> *node = (CRectObjPriceSortable<T> *)arr.At(i);
      Print(arrName, ", array[",i,"]:", ", objName: ", node.objName, ", price0: ", node.price0, ", price1: ", node.price1);
   }   
}


template <typename T>
void AddToArray(CArrayObj &arr, T key, double price1, 
                datetime startTime, datetime endTime, string objName) {
   CRectObjPriceSortable<T> *node = new CRectObjPriceSortable<T>();
   node.key =  key;
   node.objName = objName; 
   node.price0 =  key;
   node.price1 =  price1;
   node.startTime = startTime;
   node.endTime = endTime;
   arr.Add(node);
}

/*********************************************************************
***  Detect first order type
**********************************************************************/

void getOrderTypeForFirstTrade() {
   
   // && (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY || 
   //     PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL) == mSymbol && PositionGetInteger(POSITION_MAGIC) == Magic) {
            mOrderType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         }
      }
   }          
}


void getLastOrderInfo() {
   //Print(__FUNCTION__, " => ", "positionTotal: ", positionTotal);
   if(PositionsTotal() > 0) {
      for(int i=PositionsTotal()-1; i>=0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0 && PositionSelectByTicket(ticket)) {
            if(PositionGetString(POSITION_SYMBOL) == mSymbol && PositionGetInteger(POSITION_MAGIC) == Magic) {
               mOrderType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               lastOrderPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               lastOrderTP = PositionGetDouble(POSITION_TP);
               //lastLotSize = PositionGetDouble(POSITION_VOLUME);
               lastOrderTime = PositionGetInteger(POSITION_TIME);
               //Print("mOrderType: ", mOrderType, ", lastOrderPrice: ", lastOrderPrice, ", lastOrderTime: ", lastOrderTime);
               break;
            }
         }
      }
   }
   else {
      mOrderType = -1;
      orderFrequencyCount = 0;                    
      lastOrderPrice = 0.0;                    
      lastOrderTP = 0.0;                       
      lastOrderTime = 0;
      
      // Remove after testing
      manualOrderFlag = 0;
   }      
}

bool checkIsOrderAvailable() {
   
   if(mOrderType == -1) return false;
   
   datetime currentTime   =  TimeCurrent();
   double price   =  (mOrderType == POSITION_TYPE_BUY) ?
                     NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_ASK), mDigits) : 
                     NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits) ;
   
   
   int orderGap   =  (mOrderType == ORDER_TYPE_BUY) ?
                     DoubleToPoints(lastOrderPrice-price, mSymbol) :
                     DoubleToPoints(price-lastOrderPrice, mSymbol);
   int orderTpGap =  (mOrderType == ORDER_TYPE_BUY) ?
                     DoubleToPoints(lastOrderTP-price, mSymbol) :
                     DoubleToPoints(price-lastOrderTP, mSymbol);    
   //Print("orderGap: ", orderGap, ", orderTpGap: ", orderTpGap, ", price: ", price, ", lastOrderPrice: ", lastOrderPrice, ", lastOrderTP: ", lastOrderTP);
   if(orderGap < OrderGaps || orderTpGap <= OrderGaps || lastOrderTP <= 0) return false;
   //if(orderTpGap <= 100 || lastOrderTP <= 0) return false;
   
   
   //lastOrderTime >= currentTime &&    
   // Check if new entry found
   if(orderGap >= OrderGaps && mOrderType != -1 && lastOrderPrice > 0.0) {
      //Print("111 Next entry found!, orderGap: ", orderGap, ", orderTpGap: ", orderTpGap, ", lastOrderTP: ", lastOrderTP);
      if(orderFrequencyCount < NumberOfOrdersInSpecificTime) {
         //Print("222 Next entry found!, orderGap: ", orderGap, ", orderTpGap: ", orderTpGap, ", lastOrderTP: ", lastOrderTP); 
         //Print("price: ", price, ", priceGap: ", MathAbs(price-lastOrderPrice), ", orderGap: ", orderGap, ", tpGap: ", MathAbs(price-lastOrderTP),", OrderGaps: ", OrderGaps, ", mOrderType: ", mOrderType,
         //", lastOrderPrice: ", lastOrderPrice, ", lastOrderTime: ", lastOrderTime, ", orderFrequencyCount: ", orderFrequencyCount, " == ", NumberOfOrdersInSpecificTime);
         return true;
      }
   }   
               
   return false;
   
}


/*********************************************************************
***  Order management block
**********************************************************************/

void manuallyPlacingOrder() {
   
   // Calculate lot size
   if( positionTotal <= 0) lastLotSize = OrderLotSize;
       
   
   double entry = (ManualPositionType == POSITION_TYPE_BUY) ?
                   NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_ASK), mDigits) : 
                   NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits) ;
   
   if(entry >= ResistancePriceLevel) {   
   
      double slPrice = 0.0;
      double tpPrice = 0.0;
      if(OrderSL > 0) {
         slPrice = NormalizeDouble(PointsToDouble(OrderSL, mSymbol), mDigits); 
         slPrice = (ManualPositionType == POSITION_TYPE_BUY) ? entry-slPrice : entry+slPrice;
      } 
        
      if(OrderTP > 0) { 
         tpPrice = NormalizeDouble(PointsToDouble(OrderTP, mSymbol), mDigits);
         tpPrice = (ManualPositionType == POSITION_TYPE_BUY) ? entry+tpPrice : entry-tpPrice;
      }
      
      manualOrderFlag = 1;
      
      //Print(__FUNCTION__, ", entry: ", entry, ", slPrice: ", slPrice, ", tpPrice: ", tpPrice);
                
      executeSell(entry, slPrice, tpPrice, lastLotSize, SELL, 0, OrderComments);
      
      /*if(ManualPositionType == POSITION_TYPE_BUY)
         executeBuy(entry, slPrice, tpPrice, OrderLotSize, BUY, 0, OrderComments);
      else if(ManualPositionType == POSITION_TYPE_SELL)  
         executeSell(entry, slPrice, tpPrice, OrderLotSize, SELL, 0, OrderComments);*/
   }
   else if(entry <= SupportPriceLevel) {   
      
      double slPrice = 0.0;
      double tpPrice = 0.0;
      if(OrderSL > 0) {
         slPrice = NormalizeDouble(PointsToDouble(OrderSL, mSymbol), mDigits); 
         slPrice = entry-slPrice;
      } 
        
      if(OrderTP > 0) { 
         tpPrice = NormalizeDouble(PointsToDouble(OrderTP, mSymbol), mDigits);
         tpPrice = entry+tpPrice;
      }
      
      manualOrderFlag = 1;
      
      //Print(__FUNCTION__, ", entry: ", entry, ", slPrice: ", slPrice, ", tpPrice: ", tpPrice);
      
      executeBuy(entry, slPrice, tpPrice, lastLotSize, BUY, 0, OrderComments);
                
      /*if(ManualPositionType == POSITION_TYPE_BUY)
         executeBuy(entry, slPrice, tpPrice, OrderLotSize, BUY, 0, OrderComments);
      else if(ManualPositionType == POSITION_TYPE_SELL)  
         executeSell(entry, slPrice, tpPrice, OrderLotSize, SELL, 0, OrderComments);
      */   
   }
   
}

void autoPlacingOrder() {

   // Check if current total position is less than MaxRunningOrder
   //int totalPosition = PositionsTotal();
   if(positionTotal > MaxRunningOrder) return;
   
   
   // Check lastLotSize is less than MartingaleMaxLotSize
   
   if(IsMartingale && !(lastLotSize <= MartingaleMaxLotSize || 
      ((lastLotSize*MartingaleLot) <= MartingaleMaxLotSize) || 
      ((lastLotSize+MartingaleLot) <= MartingaleMaxLotSize))) return; 
   
   
   // Calculate lot size
   if(positionTotal <= 0) lastLotSize = OrderLotSize;  
   if(MaxRunningOrder > 0 && OrderLotSize <= 0.0) lastLotSize = OrderLotSize; 
   else if(MaxRunningOrder > 0 && OrderLotSize > 0.0 && lastLotSize <= 0.0) lastLotSize = 0.01;
   
   double entry = (mOrderType == POSITION_TYPE_BUY) ?
                   NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_ASK), mDigits) : 
                   NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits) ;
   
   double slPrice = 0.0;
   double tpPrice = 0.0;
   
   if(entry >= ResistancePriceLevel) { 
      if(OrderSL > 0) {
         slPrice = NormalizeDouble(PointsToDouble(OrderSL, mSymbol), mDigits); 
         slPrice = (mOrderType == POSITION_TYPE_BUY) ? entry-slPrice : entry+slPrice;
      } 
        
      if(OrderTP > 0) { 
         tpPrice = NormalizeDouble(PointsToDouble(OrderTP, mSymbol), mDigits);
         tpPrice = (mOrderType == POSITION_TYPE_BUY) ? entry+tpPrice : entry-tpPrice;
      }
      
      //Print(__FUNCTION__, ", entry: ", entry, ", slPrice: ", slPrice, ", tpPrice: ", tpPrice, ", lastLotSize: ", lastLotSize);
          
      executeSell(entry, slPrice, tpPrice, lastLotSize, SELL, 0, OrderComments);
                           
      /*if(mOrderType == POSITION_TYPE_BUY)
         executeBuy(entry, slPrice, tpPrice, OrderLotSize, BUY, 0, OrderComments);
      else if(mOrderType == POSITION_TYPE_SELL)  
         executeSell(entry, slPrice, tpPrice, OrderLotSize, SELL, 0, OrderComments); 
      */   
   }
   else if(entry <= SupportPriceLevel) { 
      if(OrderSL > 0) {
         slPrice = NormalizeDouble(PointsToDouble(OrderSL, mSymbol), mDigits); 
         slPrice = entry-slPrice;
      } 
        
      if(OrderTP > 0) { 
         tpPrice = NormalizeDouble(PointsToDouble(OrderTP, mSymbol), mDigits);
         tpPrice = entry+tpPrice;
      }
      
      //Print(__FUNCTION__, ", entry: ", entry, ", slPrice: ", slPrice, ", tpPrice: ", tpPrice, ", lastLotSize: ", lastLotSize);
             
      executeBuy(entry, slPrice, tpPrice, lastLotSize, BUY, 0, OrderComments);
                           
      /*if(mOrderType == POSITION_TYPE_BUY)
         executeBuy(entry, slPrice, tpPrice, OrderLotSize, BUY, 0, OrderComments);
      else if(mOrderType == POSITION_TYPE_SELL)  
         executeSell(entry, slPrice, tpPrice, OrderLotSize, SELL, 0, OrderComments); 
      */   
   }
         
 
} 


double calculatTP(double entry, ENUM_ORDER_TYPE orderType) {
   double takeProfit = 0.0, fixedTP = 100.0;
   double sniperTP   = sniperSignal.getTakeProfitFromSnipperEMA(entry, orderType);
   
   if(orderType == ORDER_TYPE_BUY) {
      /*8if(currentTFResistanceZone.Total() > 0) {
         takeProfit = ((CRectObjPriceSortable<double>*)currentTFResistanceZone.At(0)).price1;
         if(sniperTP < takeProfit) takeProfit = sniperTP;
      }
      else {
         takeProfit =  entry + PipsToPrice(fixedTP, mSymbol);
      }*/
      
      takeProfit =  entry + PipsToPrice(10.0, mSymbol);
      //return takeProfit;   
      //Print("111 ORDER_TYPE_BUY, entry: ", entry, ", takeProfit: ", takeProfit);   
   }
   else 
   if(orderType == ORDER_TYPE_SELL) {
      //takeProfit =  entry - PipsToPrice(PendingOrderGaps*RRRatio+mSpread, mSymbol);
      /*if(currentTFSupportZone.Total() > 0) {
         takeProfit = ((CRectObjPriceSortable<double>*)currentTFSupportZone.At(0)).price0;
         if(sniperTP > takeProfit) takeProfit = sniperTP;
      }
      else {
         takeProfit =  entry - PipsToPrice(fixedTP, mSymbol);
      }*/
      takeProfit =  entry - PipsToPrice(10.0, mSymbol);      
      //Print("333 ORDER_TYPE_SELL, entry: ", entry, ", takeProfit: ", takeProfit);     
   }   

   return(takeProfit);
}


double calculatSL(double entry, ENUM_ORDER_TYPE orderType) {
   double rsStopLoss = 0.0, stopLoss = 0.0, offset = 5.0, fixedSL = 50.0;
   double sniperSL   = sniperSignal.getTakeProfitFromSnipperEMA(entry, orderType);
   if(orderType == ORDER_TYPE_BUY) {
      stopLoss =  entry - PipsToPrice(fixedSL+offset+mSpread, mSymbol);
      if(currentTFSupportZone.Total() > 0) {
         rsStopLoss = ((CRectObjPriceSortable<double>*)currentTFSupportZone.At(0)).price1 - 
                      PipsToPrice(mSpread, mSymbol);
      }
      
      if(sniperSL > stopLoss) stopLoss = sniperSL;
      if(rsStopLoss > sniperSL) stopLoss = rsStopLoss;

      
      // RS takeprofit ratio 
      //if(rsStopLoss > 0 && rsStopLoss < stopLoss) 
         //stopLoss = rsStopLoss;
         
      //Print("333 entry: ", entry, ", stopLoss: ", stopLoss, ", rsStopLoss: ", rsStopLoss);     
   }
   else 
   if(orderType == ORDER_TYPE_SELL) {
      stopLoss =  entry + PipsToPrice(fixedSL+offset+mSpread, mSymbol);
      if(currentTFResistanceZone.Total() > 0) {
         rsStopLoss = ((CRectObjPriceSortable<double>*)currentTFResistanceZone.At(0)).price0 + 
                      PipsToPrice(mSpread, mSymbol);
      }
      
      // RS takeprofit ratio 
      if(sniperSL < stopLoss) stopLoss = sniperSL;
      if(rsStopLoss < sniperSL) stopLoss = rsStopLoss;
         
      //Print("444 entry: ", entry, ", stopLoss: ", stopLoss, ", rsStopLoss: ", rsStopLoss);     
   }   
   return(stopLoss);
}


void placeFirstOrders(ENUM_ORDER_TYPE orderType, string maSignal = "", int noOfOrders = 1) {
   //Print("mSymbol: ", mSymbol, ", Symbol(): ", Symbol(), ", Magic: ", Magic,  ", trade magic: ", trade.RequestMagic());
  
   double buyEntry   =  NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_ASK), mDigits);
   double sellEntry  =  NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits);
   //double entry    =  SymbolInfoDouble(mSymbol, SYMBOL_LAST);
  
   double sl = 0.0, tp = 0.0, lot = 0.01;
   /*if(LotsType == FIXED_LOT) { 
      if(StringFind(maSignal, "Strong") >= 0) lot = 0.05;
      else lot = FixedLotSize;
   }   
   else 
      lot = calcLots(PipsToPrice(10, mSymbol));
   */
   //Print("Current lot: "+lot);    
   
   
   
   //if(InstantOrderType == BUY) {
   //maBuyOrderFound || 
   //|| StringFind(bbOrderSignal, "BUY") > -1
   if(orderType == ORDER_TYPE_BUY) {
      // Calculate pending order gaps with entry price
      //buyEntry          =  buyEntry + PipsToPrice(PendingOrderGaps, mSymbol);
      //sellEntry         =  sellEntry - PipsToPrice(PendingOrderGaps, mSymbol);
   
      lot   =  MathMin(lot,SymbolInfoDouble(mSymbol,SYMBOL_VOLUME_MAX));
      lot   =  MathMax(lot,SymbolInfoDouble(mSymbol,SYMBOL_VOLUME_MIN));  
      //lastLotSize   =  lot; 
      
     
      //sl =  buyEntry - PipsToPrice(PendingOrderGaps, mSymbol);
      //tp    =  buyEntry + PipsToPrice(10, mSymbol);
      tp    =  calculatTP(buyEntry, orderType);
      sl    =  calculatSL(buyEntry, orderType);
      
      if(noOfOrders == 1) executeBuy(buyEntry, 0.0, tp, lot, BUY, 0, OrderComments); 
      else {
         for(int i=0; i<noOfOrders; i++) {
            executeBuy(buyEntry, 0.0, tp, lot, BUY, 0, OrderComments); 
         }
      }
      
      
   }
   //else if(InstantOrderType == SELL) {
   //maSellOrderFound || 
   //|| StringFind(bbOrderSignal, "SELL") > -1
   else if(orderType == ORDER_TYPE_SELL) {
      // Calculate pending order gaps with entry price
      //buyEntry          =  buyEntry + PipsToPrice(PendingOrderGaps, mSymbol);
      //sellEntry         =  sellEntry - PipsToPrice(PendingOrderGaps, mSymbol);
   
      lot   =  MathMin(lot,SymbolInfoDouble(mSymbol,SYMBOL_VOLUME_MAX));
      lot   =  MathMax(lot,SymbolInfoDouble(mSymbol,SYMBOL_VOLUME_MIN));  
      //lastLotSize   =  lot; 
      
      
      //sl =  buyEntry - PipsToPrice(PendingOrderGaps, mSymbol);
      //tp =  sellEntry - PipsToPrice(10, mSymbol);
      //sl    =  calculatSL(sellEntry, mOrderType);
      //sl =  sellEntry + PipsToPrice(100, mSymbol);
      //tp    =  calculatTP(sellEntry, mOrderType);
      tp    =  calculatTP(sellEntry, orderType);
      sl    =  calculatSL(sellEntry, orderType);
      
      if(noOfOrders == 1) executeSell(sellEntry, 0.0, tp, lot, SELL, 0, OrderComments);
      else {
         for(int i=0; i<noOfOrders; i++) {
            executeSell(sellEntry, 0.0, tp, lot, SELL, 0, OrderComments);
         }
      } 
      
      
   }
   
   
   //Print("placeFirstOrders orderType: ", orderType, ", orderGaps: ", orderGaps);
   
}


/*********************************************************************
***  Auto set breakeven and trailing stop
**********************************************************************/

void processPosition(ulong &posTicket) {
   //Print(__FUNCTION__, ", posTicket: "+posTicket);
   if(posTicket <= 0)
      return;
   if(OrderSelect(posTicket))
      return;

   //Print(__FUNCTION__, ", Order is selected by ticket: "+posTicket);

   double offset = 0;
   CPositionInfo pos;
   if(!pos.SelectByTicket(posTicket)) {
      posTicket = 0;
      return;
   }
   else {
      if(pos.PositionType() == POSITION_TYPE_BUY) {
         double bid = SymbolInfoDouble(mSymbol,SYMBOL_BID);
         if(bid > (pos.PriceOpen() + PipsToPrice(2.0, mSymbol))) {
            double sl = bid - PipsToPrice(2.0, mSymbol);
            sl = NormalizeDouble(sl, mDigits);
            
            if(sl > pos.StopLoss()) {
               trade.PositionModify(pos.Ticket(), sl, pos.TakeProfit());
            }
         }
      }
      else
      if(pos.PositionType() == POSITION_TYPE_SELL) {
         double ask = SymbolInfoDouble(mSymbol,SYMBOL_ASK);
         if(ask < (pos.PriceOpen() - PipsToPrice(2.0, mSymbol))) {
            double sl = ask + PipsToPrice(2.0, mSymbol);
            sl = NormalizeDouble(sl, mDigits);
            
            if(sl < pos.StopLoss() || pos.StopLoss() == 0) {
               trade.PositionModify(pos.Ticket(), sl, pos.TakeProfit());
            }
         }
      }
   }
}


void updateOrdersBreakeven() {

   for(int i=PositionsTotal(); i>=0; i--) {
      CPositionInfo pos;
      if(pos.SelectByIndex(i)) {
         if(pos.Magic() != Magic || pos.Symbol() != mSymbol)
            continue;
     
         if(pos.PositionType() == POSITION_TYPE_BUY) {
            double bid  =  SymbolInfoDouble(mSymbol,SYMBOL_BID);
            double bePrice =  (pos.PriceOpen() + PipsToPrice(PlaceBEWhenProfit, mSymbol));
            //Print("111 bid: ", bid, ", PriceOpen: ", pos.PriceOpen(), ", PlaceBEWhenProfit: "+PipsToPrice(PlaceBEWhenProfit, mSymbol), ", bePrice: ", bePrice);
            if(bid > bePrice) {
               double sl = pos.PriceOpen() + PipsToPrice(EntryPriceToBEGap, mSymbol);
               //double tp = pos.TakeProfit() + PipsToPrice(EntryPriceToBEGap, mSymbol);
               sl = NormalizeDouble(sl, mDigits);
               //tp = NormalizeDouble(tp, mDigits);
               //Print("111 sl: ", sl);
               if(sl > pos.StopLoss() || pos.StopLoss() == 0) {
                  trade.PositionModify(pos.Ticket(), sl, pos.TakeProfit());
                  //trade.PositionModify(pos.Ticket(), sl, tp);
               }   
            }  
         }
         else if(pos.PositionType() == POSITION_TYPE_SELL) {
            double ask = SymbolInfoDouble(mSymbol,SYMBOL_ASK);
            double bePrice =  (pos.PriceOpen() - PipsToPrice(PlaceBEWhenProfit, mSymbol));
            //Print("222 ask: ", ask, ", PriceOpen: ", pos.PriceOpen(), ", PlaceBEWhenProfit: "+PipsToPrice(PlaceBEWhenProfit, mSymbol), ", bePrice: ", bePrice);
            if(ask < bePrice) {
               double sl = pos.PriceOpen() - PipsToPrice(EntryPriceToBEGap, mSymbol);
               //double tp = pos.TakeProfit() - PipsToPrice(EntryPriceToBEGap, mSymbol);
               sl = NormalizeDouble(sl, mDigits);
               //tp = NormalizeDouble(tp, mDigits);
               
               if(sl < pos.StopLoss() || pos.StopLoss() == 0) {
                  trade.PositionModify(pos.Ticket(), sl, pos.TakeProfit());
                  //trade.PositionModify(pos.Ticket(), sl, tp);
               }   
            }
         }   
      }
   }
}

void updateOrdersTraillingstop() {

   for(int i=PositionsTotal(); i>=0; i--) {
      CPositionInfo pos;
      if(pos.SelectByIndex(i)) {
         if(pos.Magic() != Magic || pos.Symbol() != mSymbol)
            continue;
     
         if(pos.PositionType() == POSITION_TYPE_BUY) {
            double bid  =  SymbolInfoDouble(mSymbol,SYMBOL_BID);
            double tsPrice =  (pos.PriceOpen() + PipsToPrice(TSRunWhenProfit, mSymbol));
            //Print("111 POSITION_TYPE_BUY ask: ", bid, ", tsPrice: ", tsPrice);
            if(bid > tsPrice) {
               double sl = bid - (PipsToPrice(TSRunWhenProfit, mSymbol) + 
                                  PipsToPrice(EntryPriceToBEGap, mSymbol) + 
                                  PointsToDouble(TraillingStopStep, mSymbol));
               double tp = bid + (PipsToPrice(EntryPriceToBEGap, mSymbol) + 
                                  PipsToPrice(TSRunWhenProfit, mSymbol) +
                                  PointsToDouble(TraillingStopStep, mSymbol));
                                 
               sl = NormalizeDouble(sl, mDigits);
               tp = NormalizeDouble(tp, mDigits);
               
               //Print("111 POSITION_TYPE_BUY bid: ", bid, ", tsPrice: ", tsPrice, ", sl: ", sl, ", tp: ", tp);
               
               if(sl > pos.StopLoss() || tp > pos.TakeProfit()) {
                  //trade.PositionModify(pos.Ticket(), sl, pos.TakeProfit());
                  trade.PositionModify(pos.Ticket(), sl, tp);
               }   
            } 
         }
         else if(pos.PositionType() == POSITION_TYPE_SELL) {
            double ask = SymbolInfoDouble(mSymbol,SYMBOL_ASK);
            double tsPrice =  (pos.PriceOpen() - PipsToPrice(TSRunWhenProfit, mSymbol));
            //Print("222 POSITION_TYPE_SELL ask: ", ask, ", tsPrice: ", tsPrice);
            if(ask < tsPrice) {
               double sl = ask + (PipsToPrice(EntryPriceToBEGap, mSymbol) + 
                                  PipsToPrice(TSRunWhenProfit, mSymbol) +
                                  PointsToDouble(TraillingStopStep, mSymbol));
               double tp = ask - (PipsToPrice(EntryPriceToBEGap, mSymbol) + 
                                  PipsToPrice(TSRunWhenProfit, mSymbol) +
                                  PointsToDouble(TraillingStopStep, mSymbol));
               //double tp = pos.TakeProfit() - PipsToPrice(TraillingStopStep, mSymbol);;
               sl = NormalizeDouble(sl, mDigits);
               tp = NormalizeDouble(tp, mDigits);
               
               //Print("222 POSITION_TYPE_SELL ask: ", ask, ", tsPrice: ", tsPrice, ", sl: ", sl, ", tp: ", tp);
               
               if((sl < pos.StopLoss() || pos.StopLoss() == 0) || tp < pos.TakeProfit()) {
                  //trade.PositionModify(pos.Ticket(), sl, pos.TakeProfit());
                  trade.PositionModify(pos.Ticket(), sl, tp);
               }   
            }
         }   
      }
   }
}


void executeBuy(double entry, double slPrice, double tpPrice, double lots, TRADE_TYPE tradeType, 
                int orderExecutionType, string comment) {
   //return;
   bool result = false;
   //while(!result) {
      
      double tp = 0.0, sl = 0.0;
      if(tradeType == BUY_LIMIT || tradeType == BUY_STOP) {
         entry = NormalizeDouble(entry, mDigits);  
      }
      else {
         entry = (entry > 0) ? NormalizeDouble(entry, mDigits) : 
                               NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_ASK), mDigits);
      }
      
      if(tpPrice > 0) {
         tp = NormalizeDouble(tpPrice, mDigits);  
      }   
      
      if(slPrice > 0) {
         sl = NormalizeDouble(slPrice, mDigits);   
      } 
      
      if(lots > 0.0) lots = lots;      
      if(lots <= 0.0) {
         Alert("Please enter a valid lot size.");
         return;
      }
  
      
      //Print("222 entry: "+entry+", sl: "+sl+", tp: "+tp+", lots: "+lots+ ", tradeType: "+tradeType
      //   +", orderExecutionType: "+orderExecutionType+", comment: "+comment);
         
      if(orderExecutionType == 0) {
         result = trade.Buy(lots, mSymbol, entry, sl, tp, comment);
         buyPos = trade.ResultOrder();
         //Print("111 result: "+result);
      }
      else {
         // Buy Limit places at the price lower than current market price
         if(tradeType == BUY_LIMIT) {
            result = trade.BuyLimit(lots, entry, mSymbol, sl, tp, ORDER_TIME_GTC, 0, comment);
            buyPos = trade.ResultOrder();
         }
         
         // Buy Stop places at the price higher than current market price
         else if(tradeType == BUY_STOP) {
            result = trade.BuyStop(lots, entry, mSymbol, sl, tp, ORDER_TIME_GTC, 0, comment);
            buyPos = trade.ResultOrder();
         }
      }
      
   //}
}


void executeSell(double entry, double slPrice, double tpPrice, double lots, TRADE_TYPE tradeType,
                 int orderExecutionType, string comment) {
   //return;
   bool result = false;
   //while(!result) {
   
      double tp = 0.0, sl = 0.0;
      if(tradeType == SELL_LIMIT || tradeType == SELL_STOP) {
         entry = NormalizeDouble(entry, mDigits);
      }
      else {
         entry = (entry > 0) ? NormalizeDouble(entry, mDigits) : 
                               NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), mDigits);
      }
      
      
      if(tpPrice > 0) {
         tp = NormalizeDouble(tpPrice, mDigits);  
      }   
      
      if(slPrice > 0) {
         sl = NormalizeDouble(slPrice, mDigits);  
      }   
   
      if(lots > 0.0) lots = lots;
      if(lots <= 0.0) {
         Alert("Please enter a valid lot size.");
         return;
      }
      
   
      //Print("333 entry: "+entry+", sl: "+sl+", tp: "+tp+", lots: "+lots + ", tradeType: "+tradeType
      //   +", orderExecutionType: "+orderExecutionType+", comment: "+comment);
      
      if(orderExecutionType == 0) {
         result = trade.Sell(lots, mSymbol, entry, sl, tp, comment);
         sellPos = trade.ResultOrder();
         //Print("222 result: "+result);
      }
      else {
         // Sell Limit places at the price higher than current market price
         if(tradeType == SELL_LIMIT) {
            result = trade.SellLimit(lots, entry, mSymbol, sl, tp, ORDER_TIME_GTC, 0, comment);
            sellPos = trade.ResultOrder();
         }
         
         // Sell Stop places at the price lower than current market price
         else if(tradeType == SELL_STOP) {
            result = trade.SellStop(lots, entry, mSymbol, sl, tp, ORDER_TIME_GTC, 0, comment);
            sellPos = trade.ResultOrder();
         }
      }
    
   //}      
}



/*********************************************************************
***  Permissions block
**********************************************************************/

bool permissionsToAllowTrade() {
   
   // Check if expert allow to trade
   if(!IsExpertAllowedToTrade) return false;
      
   // Quick check if trading is possible
   if(!IsTradeAllowed()) return false;

   // Check if market is open
   if(!IsMarketOpen(mSymbol, TimeCurrent())) return false;


   // Return if trading time is not time range
   if(TradingHoursActive) {
      if(!cTimeRange.InsideRange()) {
         Print("Trading hours are over!");
         //resetProgram();
         return false;
      }
   } 
   
   return true;  
}


bool IsTradeAllowed() {

   return((bool)MQLInfoInteger(MQL_TRADE_ALLOWED) &&              // Trading allowed in input dialog
          (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) &&    // Trading allowed in terminal
          (bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) &&      // Is account able to trade, not
          (bool)AccountInfoInteger(ACCOUNT_TRADE_EXPERT)          // Is account able to auto trade
         );
}

bool IsMarketOpen(string symbol, datetime time) {

   static string lastSymbol = "";
   static bool isOpen = false;
   static datetime sessionStart = 0, sessionEnd = 0;

   if(lastSymbol == symbol && sessionEnd > sessionStart) {
      if((isOpen && time >= sessionStart && time <= sessionEnd) ||
         (!isOpen && time > sessionStart && time < sessionEnd))
         return isOpen;
      }

   lastSymbol = symbol;

   MqlDateTime mTime;
   TimeToStruct(time, mTime);
   datetime seconds = mTime.hour*3600+mTime.min*60+mTime.sec;

   MqlDateTime mTime2 = mTime;
   mTime2.hour = 0;
   mTime2.min = 0;
   mTime2.sec = 0;

   datetime dayStart = StructToTime(mTime2);
   datetime dayEnd = dayStart + 86400;

   datetime fromTime, toTime;
   sessionStart = dayStart;
   sessionEnd = dayEnd;

   for(int session=0; ; session++) {
      if(!SymbolInfoSessionTrade(symbol, (ENUM_DAY_OF_WEEK)mTime.day_of_week, session, fromTime, toTime)) {
         sessionEnd = dayEnd;
         isOpen = false;
         return isOpen;
      }

      if(seconds < fromTime) {    // Not inside a session
         sessionEnd = dayStart + fromTime;
         isOpen = false;
         return isOpen;
      }

      if(seconds > toTime) {      // maybe a later session
         sessionStart = dayStart + toTime;
         continue;
      }


      // At this point must be inside a session
      sessionStart = dayStart + fromTime;
      sessionEnd = dayStart + toTime;
      isOpen = true;
      return isOpen;
   }

   return false;
}


/*********************************************************************
***  Chcek newbar is created
**********************************************************************/

// Check if there is a new bar has created
bool IsNewBar(bool first_call = false) {

   static bool result = false;
   if(!first_call)
      return result;

   //Print("first_call = "+first_call);
   static datetime previousBarTime = 0;
   datetime currentBarTime = iTime(mSymbol, mPeriod, 0);
   result = false;

   if(currentBarTime != previousBarTime) {
      previousBarTime = currentBarTime;
      result = true;
   }

   return result;
}


// Check if there is a new bar has created
bool IsNewOrderTime(bool first_call = false) {

   static bool result = false;
   if(!first_call)
      return result;

   //Print("first_call = "+first_call);
   static datetime previousBarTime = 0;
   datetime currentBarTime = iTime(mSymbol, SpecifyTimeForOrders, 0);
   result = false;

   if(currentBarTime != previousBarTime) {
      previousBarTime = currentBarTime;
      orderFrequencyCount = 0;
      //Print("Reset orderFrequencyCount: " + orderFrequencyCount);
      result = true;
   }

   return result;
}

// Check if there is a new bar has created
bool IsHourlyNewBar(bool first_call = false) {

   static bool result = false;
   if(!first_call)
      return result;

   //Print("first_call = "+first_call);
   static datetime previousBarTime = 0;
   datetime currentBarTime = iTime(mSymbol, PERIOD_H1, 0);
   result = false;

   if(currentBarTime != previousBarTime) {
      previousBarTime = currentBarTime;
      result = true;
   }

   return result;
}

bool daily_candle_breakout_orders_fill = false;
// Check if there is a new bar has created
bool IsDailyNewBar(bool first_call = false) {

   static bool result = false;
   if(!first_call)
      return result;

   //Print("first_call = "+first_call);
   static datetime previousDailyBarTime = 0;
   datetime currentBarTime = iTime(mSymbol, PERIOD_D1, 0);
   result = false;

   if(currentBarTime != previousDailyBarTime) {
      previousDailyBarTime = currentBarTime;
      result = true;
      daily_candle_breakout_orders_fill = false;
   }

   return result;
}


//+------------------------------------------------------------------+
//| Web Request functions                                            |
//+------------------------------------------------------------------+

bool getDataFromWeb(string &data) {
   
   string   headers = "";
   char     postData[];
   char     resultData[];
   string   resultHeaders;
   int      timeout = 5000;   // 1 second, may be too short for a slow connection
   // https://github.com/devatikurrahman/EALicence.git
   string   baseUrl = "https://drive.google.com";
   string   api = StringFormat(baseUrl,"");
   
   ResetLastError();
   int response = WebRequest("GET", api, headers, timeout, postData, resultData, resultHeaders);
   int errorCode = GetLastError();
   data = CharArrayToString(resultData);
   
   switch(response) {
      case -1:
         Print("Error in WebRequest. Error code = ", errorCode);
         Print("Add the address " + baseUrl + "in the list of allowed URLs");
         return false;
         break;
      case 200:
         // Request success
         return true;
         break;
      default:
         return false;
         break;          
   }
   
}



//+------------------------------------------------------------------+
//| Order close function                                             |
//+------------------------------------------------------------------+
void closeAllPositions() {

   // close all positions
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == Magic) {
            bool result = false;
            result = trade.PositionClose(ticket);
         }   
      }
   }

   // delete all positions
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 && OrderSelect(ticket)) {
         if(OrderGetInteger(ORDER_MAGIC) == Magic) {
            bool result = false;
            result = trade.OrderDelete(ticket);
         }      
      }
   }
}


void closeExpertAdvisorAllPositions() {

   // close all positions
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      
      //Print("111 ticket: "+ticket + ", symbol: "+PositionGetString(POSITION_SYMBOL) + ", magic: "+ PositionGetInteger(POSITION_MAGIC));
      
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == Magic) {
            bool result = false;
            result = trade.PositionClose(ticket);
         }   
      }
   }

   // delete all positions
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong ticket = OrderGetTicket(i);
      
      //Print("222 ticket: "+ticket + ", symbol: "+OrderGetString(ORDER_SYMBOL) + ", magic: "+ OrderGetInteger(ORDER_MAGIC));
      
      if(ticket > 0 && OrderSelect(ticket)) {
         if(OrderGetInteger(ORDER_MAGIC) == Magic) {
            bool result = false;
            result = trade.OrderDelete(ticket);
         }      
      }
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllBuyPositions() {
   //Print("Called closeAllBuyPositions");
   // close all positions
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL)==mSymbol && PositionGetInteger(POSITION_MAGIC) == Magic && 
            PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_BUY) {
            bool result = false;
            while(!result) {
               result = trade.PositionClose(ticket);
            }
         }   
      }
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkLossPositions(ENUM_POSITION_TYPE positionType) {
   bool result = false;
   // close all positions
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL)==mSymbol && PositionGetInteger(POSITION_MAGIC) == Magic && 
            PositionGetInteger(POSITION_TYPE)==positionType && PositionGetDouble(POSITION_PROFIT) < 0) {
            result = true;
            break;
         }   
      }
   }
   return result;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllLossBuyPositions() {
   //Print("Called closeAllLossBuyPositions");
   // close all positions
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL)==mSymbol && PositionGetInteger(POSITION_MAGIC) == Magic && 
            PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_BUY && PositionGetDouble(POSITION_PROFIT) < 0) {
            bool result = false;
            while(!result) {
               result = trade.PositionClose(ticket);
            }
         }   
      }
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllSellPositions() {
   //Print("Called closeAllSellPositions");
   // close all positions
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL)==mSymbol && PositionGetInteger(POSITION_MAGIC) == Magic && 
            PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_SELL) {
            bool result = false;
            while(!result) {
               result = trade.PositionClose(ticket);
            }
         }   
      }
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllLossSellPositions() {
   //Print("Called closeAllLossSellPositions");
   // close all positions
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL)==mSymbol && PositionGetInteger(POSITION_MAGIC) == Magic && 
            PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_SELL && PositionGetDouble(POSITION_PROFIT) < 0) {
            bool result = false;
            while(!result) {
               result = trade.PositionClose(ticket);
            }
         }   
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllProfitPositions() {
   // close all positions
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
         //if(PositionGetString(POSITION_SYMBOL)==symbol && PositionGetInteger(POSITION_MAGIC) == Magic)
         if(PositionGetDouble(POSITION_PROFIT) > 0 && 
            PositionGetString(POSITION_SYMBOL) == mSymbol && PositionGetInteger(POSITION_MAGIC) == Magic) {
            bool result = false;
            while(!result) {
               result = trade.PositionClose(ticket);
            }
         }   
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllLossPositions() {
   // close all positions
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
         //if(PositionGetString(POSITION_SYMBOL)==symbol && PositionGetInteger(POSITION_MAGIC) == Magic)
         if(PositionGetDouble(POSITION_PROFIT) < 0 && 
            PositionGetString(POSITION_SYMBOL) == mSymbol && PositionGetInteger(POSITION_MAGIC) == Magic) {
            bool result = false;
            while(!result) result = trade.PositionClose(ticket);
         }   
      }
   }
}


//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
bool is_button_hovered=false;
string prev_button_name = "";
void  OnChartEvent(
   const int       id,       // event ID 
   const long&     lparam,   // long type event parameter
   const double&   dparam,   // double type event parameter
   const string&   sparam    // string type event parameter
   ) {
   //updateAccountOverview();
   if(id == CHARTEVENT_OBJECT_CLICK && StringLen(sparam) > 0) {
      //Print("Clicked on object: " + sparam);
      //return;
      if(sparam == PREFIX+"ButtonMenu") {
         if(visibleUserInterface) {
            visibleUserInterface = false;
            ButtonTextChange(0, PREFIX+"ButtonMenu", "▼");
            toggleUserInterface(false);
         }   
         else { 
            visibleUserInterface = true;
            ButtonTextChange(0, PREFIX+"ButtonMenu", "▲");
            toggleUserInterface(true);
         } 
         ObjectSetInteger(0, PREFIX+"ButtonMenu", OBJPROP_STATE, false);
      }
      else 
      if(sparam == PREFIX+"Button12") {
         // math_flag = 0, means subtraction
         // math_flag = 1, means addition
         ChangeLotSize(0);
      }
      else 
      if(sparam == PREFIX+"Button14") {
         // math_flag = 0, means subtraction
         // math_flag = 1, means addition
         ChangeLotSize(1);
      }
      else 
      if(sparam == PREFIX+"Button16") {
         // math_flag = 0, means subtraction
         // math_flag = 1, means addition
         ChangeTP(0);
      }
      else 
      if(sparam == PREFIX+"Button18") {
         // math_flag = 0, means subtraction
         // math_flag = 1, means addition
         ChangeTP(1);
      }
      else 
      if(sparam == PREFIX+"Button20") {
         // math_flag = 0, means subtraction
         // math_flag = 1, means addition
         ChangeSL(0);
      }
      else 
      if(sparam == PREFIX+"Button22") {
         // math_flag = 0, means subtraction
         // math_flag = 1, means addition
         ChangeSL(1);
      }
      else 
      if(sparam == PREFIX+"Button23") {
         // Open BUY Order
         string text = ObjectGetString(0, PREFIX+"EditTextBox13", OBJPROP_TEXT, 0);
         double lots  = StringToDouble(text);
         if(lots <= 0.0) {
            Alert("Please increase lots size");
            return;
         }
         
         
         text = ObjectGetString(0, PREFIX+"EditTextBox17", OBJPROP_TEXT, 0);
         int tp  = (int)StringToInteger(text);
         if(tp < 0) {
            Alert("Please enter a valid tp");
            return;
         }
         
         text = ObjectGetString(0, PREFIX+"EditTextBox21", OBJPROP_TEXT, 0);
         int sl  = (int)StringToInteger(text);
         if(sl < 0) {
            Alert("Please enter a valid sl");
            return;
         }
         
         double entry = NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_ASK), _Digits);
         if(entry > 0 && positionTotal < MaxRunningOrder) {
         
            double slPrice = 0.0;
            double tpPrice = 0.0;
            
            if(sl > 0) {
               slPrice = NormalizeDouble(PointsToDouble(sl, mSymbol), mDigits); 
               slPrice = entry-slPrice;
            } 
              
            if(tp > 0) { 
               tpPrice = NormalizeDouble(PointsToDouble(tp, mSymbol), mDigits);
               tpPrice = entry+tpPrice;
            }
            
            //Print("BUY ", ", entry: ", entry, ", slPrice: ", slPrice, ", tpPrice: ", tpPrice);
              
            // Set last lot size
            lastLotSize = lots;
            
            // Get last order info
            //getLastOrderInfo();
            
            
            executeBuy(entry, slPrice, tpPrice, lots, BUY, 0, OrderComments);
         }   
      }
      else 
      if(sparam == PREFIX+"Button24") {
         // Open SELL Order
         string text = ObjectGetString(0, PREFIX+"EditTextBox13", OBJPROP_TEXT, 0);
         double lots  = StringToDouble(text);
         if(lots <= 0.0) {
            Alert("Please increase lots size");
            return;
         }
         
         
         text = ObjectGetString(0, PREFIX+"EditTextBox17", OBJPROP_TEXT, 0);
         int tp  = (int)StringToInteger(text);
         if(tp < 0) {
            Alert("Please enter a valid tp");
            return;
         }
         
         text = ObjectGetString(0, PREFIX+"EditTextBox21", OBJPROP_TEXT, 0);
         int sl  = (int)StringToInteger(text);
         if(sl < 0) {
            Alert("Please enter a valid sl");
            return;
         }
         
         double entry = NormalizeDouble(SymbolInfoDouble(mSymbol, SYMBOL_BID), _Digits);
         if(entry > 0 && positionTotal < MaxRunningOrder) {
            double slPrice = 0.0;
            double tpPrice = 0.0;
            
            if(sl > 0) {
               slPrice = NormalizeDouble(PointsToDouble(sl, mSymbol), mDigits); 
               slPrice = entry+slPrice;
            } 
              
            if(tp > 0) { 
               tpPrice = NormalizeDouble(PointsToDouble(tp, mSymbol), mDigits);
               tpPrice = entry-tpPrice;
            }
            
            //Print("SELL ", ", entry: ", entry, ", slPrice: ", slPrice, ", tpPrice: ", tpPrice);
            
    
            // Set last lot size
            lastLotSize = lots;
            
            // Get last order info
            //getLastOrderInfo();
            
            executeSell(entry, slPrice, tpPrice, lots, SELL, 0, OrderComments);
         }    
      }
      else 
      if(sparam == PREFIX+"Button25") {
         // Close All Profit Orders
         //Print("Close All Profit");
         closeAllProfitPositions();
      }
      else 
      if(sparam == PREFIX+"Button26") {
         // Close All Loss Orders
         //Print("Close All Loss");
         closeAllLossPositions();
      }
      else 
      if(sparam == PREFIX+"Button27") {
         // Close This EAs All Orders
         //Print("Close All Orders");
         //closeAllPositions();
         closeExpertAdvisorAllPositions();
      }
      else {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
   }
   if(id == CHARTEVENT_MOUSE_MOVE) {
      string objectName = ButtonZone(lparam, dparam);
      //Print("Mouse over on object: " + objectName);
      if(StringLen(objectName) <= 0) return;
      
      if(!is_button_hovered) {
         ObjectSetInteger(0, objectName, OBJPROP_STATE, true);
         //Print("Mouse over on object: " + objectName);
         is_button_hovered = true;
      }
      if(StringLen(prev_button_name) > 0 && prev_button_name != objectName && is_button_hovered) {
         ObjectSetInteger(0, prev_button_name, OBJPROP_STATE, false);
         //Print("Mouse out from object: " + prev_button_name);
         is_button_hovered = false;
      }
      prev_button_name = objectName;
   }
   //Print(id, " ", lparam, " ", dparam, " ", sparam);   
   ChartRedraw();
}


void updateAccountOverview() {

   // Profit
   if(ObjectFind(0, PREFIX+"Label3") >= 0) {
      double profit = AccountInfoDouble(ACCOUNT_PROFIT);
      if(profit >= 0.0) ObjectSetInteger(0, PREFIX+"Label3", OBJPROP_COLOR, clrMediumBlue);
      else ObjectSetInteger(0, PREFIX+"Label3", OBJPROP_COLOR, clrRed);
      
      ObjectSetString(0, PREFIX+"Label3", OBJPROP_TEXT, DoubleToString(profit, 2) + " " +
         AccountInfoString(ACCOUNT_CURRENCY));
   }
   
   // Equity
   if(ObjectFind(0, PREFIX+"Label5") >= 0) {
      ObjectSetString(0, PREFIX+"Label5", OBJPROP_TEXT, DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) 
                      + " " + AccountInfoString(ACCOUNT_CURRENCY));
   }
   
   // Balance
   if(ObjectFind(0, PREFIX+"Label7") >= 0) {
      ObjectSetString(0, PREFIX+"Label7", OBJPROP_TEXT, DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2)
                      + " " + AccountInfoString(ACCOUNT_CURRENCY));
   }
   
   // Total Running Order
   if(ObjectFind(0, PREFIX+"Label8") >= 0) {
      if(PositionsTotal() > 1)
         ObjectSetString(0, PREFIX+"Label8", OBJPROP_TEXT, "Total running orders: ");
      else  
         ObjectSetString(0, PREFIX+"Label8", OBJPROP_TEXT, "Total running order: ");  
   }
   if(ObjectFind(0, PREFIX+"Label9") >= 0) {
      ObjectSetString(0, PREFIX+"Label9", OBJPROP_TEXT, IntegerToString(PositionsTotal()));
   }
   
}


string prevObjName = "";
long Prev_X_Start=0, Prev_X_End=0, Prev_Y_Start=0, Prev_Y_End=0;
string ButtonZone(long lparam, double dparam) {

   if( lparam >= Prev_X_Start && lparam <= Prev_X_End && dparam >= Prev_Y_Start && dparam <= Prev_Y_End ) return(prevObjName);

   long ChartX = ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
   long ChartY = ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   for( int i=ObjectsTotal(0, 0, OBJ_BUTTON); i>=0; i-- ) {
      string name = ObjectName(0, i);
      long X_Start=0, X_Size=0, X_End=0, Y_Start=0, Y_Size=0, Y_End=0;
      if(StringFind(name, PREFIX+"Button") < 0) continue;
      X_Size = (int)ObjectGetInteger(0,name,OBJPROP_XSIZE);
      Y_Size = (int)ObjectGetInteger(0,name,OBJPROP_YSIZE);
      switch((int)ObjectGetInteger(0,name,OBJPROP_CORNER)) {
         case CORNER_LEFT_UPPER : { 
            X_Start = (long)ObjectGetInteger(0,name,OBJPROP_XDISTANCE);
            Y_Start = (long)ObjectGetInteger(0,name,OBJPROP_YDISTANCE);
            break;
         }
         case CORNER_RIGHT_UPPER : { 
            X_Start = ChartX-(long)ObjectGetInteger(0,name,OBJPROP_XDISTANCE);
            Y_Start = (long)ObjectGetInteger(0,name,OBJPROP_YDISTANCE);
            break;
         }
         case CORNER_LEFT_LOWER : { 
            X_Start = (long)ObjectGetInteger(0,name,OBJPROP_XDISTANCE);
            Y_Start = ChartY-(long)ObjectGetInteger(0,name,OBJPROP_YDISTANCE);
            break;
         }
         case CORNER_RIGHT_LOWER : { 
            X_Start = ChartX-(long)ObjectGetInteger(0,name,OBJPROP_XDISTANCE);
            Y_Start = ChartY-(long)ObjectGetInteger(0,name,OBJPROP_YDISTANCE);
            break;
         }
      }
      X_End   = X_Start + X_Size;
      Y_End   = Y_Start + Y_Size;
      if( lparam >= X_Start && lparam <= X_End && dparam >= Y_Start && dparam <= Y_End ) {
         Prev_X_Start=X_Start; Prev_X_End=X_End; Prev_Y_Start=Y_Start; Prev_Y_End=Y_End;
         prevObjName = name;
         return(name);
      }   
   }
   return("");
}


void ChangeLotSize(int math_flag) {
   string text = ObjectGetString(0, PREFIX+"EditTextBox13", OBJPROP_TEXT, 0);
   double lot  = StringToDouble(text);
   if(lot >= 0.00) {
      if(math_flag) lot += 0.01;
      else          lot -= 0.01; 
      if(lot < 0.0) return;
      text = DoubleToString(lot, 2);
      EditTextChange(0, PREFIX+"EditTextBox13", text);
   }
}


void ChangeTP(int math_flag) {
   string text = ObjectGetString(0, PREFIX+"EditTextBox17", OBJPROP_TEXT, 0);
   int points  = (int)StringToInteger(text);
   if(points >= 0) {
      if(math_flag) points += 1;
      else          points -= 1; 
      if(points < 0.0) return;
      text = IntegerToString(points);
      EditTextChange(0, PREFIX+"EditTextBox17", text);
   }
}


void ChangeSL(int math_flag) {
   string text = ObjectGetString(0, PREFIX+"EditTextBox21", OBJPROP_TEXT, 0);
   int points  = (int)StringToInteger(text);
   if(points >= 0) {
      if(math_flag) points += 1;
      else          points -= 1; 
      if(points < 0) return;
      text = IntegerToString(points);
      EditTextChange(0, PREFIX+"EditTextBox21", text);
   }
}


bool EditTextChange(const long   chart_ID=0,    // chart's ID
                      const string name="EditTextBox", // button name
                      const string text="Text")   // text
  {
//--- reset the error value
   ResetLastError();
//--- change object text
   if(!ObjectSetString(chart_ID, name, OBJPROP_TEXT, text))
     {
      Print(__FUNCTION__,
            ": failed to change the text! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
}


bool ButtonTextChange(const long   chart_ID=0,    // chart's ID
                      const string name="Button", // button name
                      const string text="Text")   // text
  {
//--- reset the error value
   ResetLastError();
//--- change object text
   if(!ObjectSetString(chart_ID, name, OBJPROP_TEXT, text))
     {
      Print(__FUNCTION__,
            ": failed to change the text! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
}


void toggleUserInterface(bool flag) {
   for(int i=ObjectsTotal(0, 0, -1)-1; i>=0; i--) {
      string objName = ObjectName(0, i, 0, -1); 
      if(StringFind(objName, PREFIX) < 0) continue;
      if(flag) {
         ObjectSetInteger(0, objName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      }   
      else {
         if(objName == PREFIX+"ButtonMenu") continue;
         ObjectSetInteger(0, objName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
      }
   }
}

//+------------------------------------------------------------------+
//| Create User Interface On Chart                                   |
//+------------------------------------------------------------------+
long z_index = 1000;
void createUserInterface() {
   
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   
   string font1 = "Arial",
          font2 = "Arial Bold";
   int x = 0, y = 20, i = 0;
   
   // Create Rectangle Background 
   createRectangle(PREFIX+"Rect", x, y, 290, 400, clrWhiteSmoke, 2, CORNER_LEFT_UPPER, z_index+i);
   
   
   // Create Labels
   // --------- Account Overview ---------
   x = 10; y += 10; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y, "------------  Account Overview  -----------", font2, 12, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   
   
   x = 10; y += 15 + 10; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y, "Profit:", font2, 11, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   x += 120 + 10; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y+2, "0.0 USD", font2, 11, clrMediumBlue, CORNER_LEFT_UPPER, z_index+i);
   
   
   x = 10; y += 15 + 10; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y, "Equity:", font2, 11, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   x += 120 + 10; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y+2, "0.0 USD", font2, 11, clrMediumBlue, CORNER_LEFT_UPPER, z_index+i);
   
   
   x = 10; y += 15 + 10; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y, "Balance:", font2, 11, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   x += 120 + 10; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y+2, "0.0 USD", font2, 11, clrMediumBlue, CORNER_LEFT_UPPER, z_index+i);
   
   
   x = 10; y += 15 + 15; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y, "Total running order: ", font2, 11, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   x += 120 + 30; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y, "0", font2, 11, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   
   
   
   
   // --------- Trade Management ---------
   x = 10; y += 25 + 10; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y, "-----------  Order Management  -----------", font2, 12, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   
   x = 10; y += 20 + 20; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y+3, "Enter Lot Size:", font1, 11, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   x += 105+20; i++;
   createButton(PREFIX+"Button"+IntegerToString(i), x, y, 30, 28, "-", font1, 18, clrWhite, clrGreen, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   x += 30; i++;
   createEditTextBox(PREFIX+"EditTextBox"+IntegerToString(i), x, y, 85, 28, "0.01", font2, 11, clrBlack, clrWhite, CORNER_LEFT_UPPER, z_index+i);
   x += 85; i++;
   createButton(PREFIX+"Button"+IntegerToString(i), x, y, 30, 28, "+", font1, 18, clrWhite, clrGreen, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   
   
   x = 10; y += 20 + 10; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y+3, "Enter TP (points) :", font1, 11, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   x += 105+20; i++;
   createButton(PREFIX+"Button"+IntegerToString(i), x, y, 30, 28, "-", font1, 18, clrWhite, clrGreen, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   x += 30; i++;
   createEditTextBox(PREFIX+"EditTextBox"+IntegerToString(i), x, y, 85, 28, "1000", font2, 11, clrBlack, clrWhite, CORNER_LEFT_UPPER, z_index+i);
   x += 85; i++;
   createButton(PREFIX+"Button"+IntegerToString(i), x, y, 30, 28, "+", font1, 18, clrWhite, clrGreen, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   
   
   x = 10; y += 20 + 10; i++;
   createLabel(PREFIX+"Label"+IntegerToString(i), x, y+3, "Enter SL (points):", font1, 11, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   x += 105+20; i++;
   createButton(PREFIX+"Button"+IntegerToString(i), x, y, 30, 28, "-", font1, 18, clrWhite, clrGreen, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   x += 30; i++;
   createEditTextBox(PREFIX+"EditTextBox"+IntegerToString(i), x, y, 85, 28, "1000", font2, 11, clrBlack, clrWhite, CORNER_LEFT_UPPER, z_index+i);
   x += 85; i++;
   createButton(PREFIX+"Button"+IntegerToString(i), x, y, 30, 28, "+", font1, 18, clrWhite, clrGreen, clrBlack, CORNER_LEFT_UPPER, z_index+i);
   
   
   
   // Create Buttons
   // clrBlack, clrYellowGreen
   x = 10; y += 35 + 10; i++;
   createButton(PREFIX+"Button"+IntegerToString(i), x, y, 135, 30, "Open Buy", font1, 11, clrWhite, clrRoyalBlue, clrWhite, CORNER_LEFT_UPPER, z_index+i);
   x += 130 + 10; i++;
   createButton(PREFIX+"Button"+IntegerToString(i), x, y, 130, 30, "Open Sell", font1, 11, clrWhite, clrOrangeRed, clrWhite, CORNER_LEFT_UPPER, z_index+i);
   
   x = 10; y += 28 + 5; i++;
   createButton(PREFIX+"Button"+IntegerToString(i), x, y, 135, 30, "Close All Profit", font1, 11, clrWhite, clrRoyalBlue, clrWhite, CORNER_LEFT_UPPER, z_index+i);
   x += 130 + 10; i++;
   createButton(PREFIX+"Button"+IntegerToString(i), x, y, 130, 30, "Close All Loss", font1, 11, clrWhite, clrOrangeRed, clrWhite, CORNER_LEFT_UPPER, z_index+i);
   
   
   x = 10; y += 28 + 5; i++;
   //createButton(PREFIX+"Button"+IntegerToString(i), x, y, 135, 30, "Close All Pending", font1, 11, clrWhite, clrRoyalBlue, clrWhite, CORNER_LEFT_UPPER, z_index+i);
   //x += 130 + 10; i++;
   createButton(PREFIX+"Button"+IntegerToString(i), x, y, 135+135, 30, "Close All", font1, 11, clrWhite, clrOrangeRed, clrWhite, CORNER_LEFT_UPPER, z_index+i);
 
         
   // Bottom left toggle button
   x = 5; y = 35 + 5; i++;
   createButton(PREFIX+"ButtonMenu", x, y, 40, 35, "▲", font1, 14, clrWhite, clrForestGreen, clrBlack, CORNER_LEFT_LOWER, z_index+i);
         
                      
   visibleUserInterface = true;
   
   
   ChartRedraw();
   
}

bool createRectangle(string objName, int x, int y, int width, int height, 
                     color clrBk, int line_width, ENUM_BASE_CORNER corner, long z_order=0) {

   //--- reset the error value
   ResetLastError();
   //--- create a rectangle label
   if(!ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
      Print(__FUNCTION__, ": failed to create a rectangle label! Error code = ",GetLastError());
      return(false);
   }
   
   
   //--- set label coordinates
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   //--- set label size
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
   //--- set background color
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrBk);
   //--- set border type
   ObjectSetInteger(0, objName, OBJPROP_BORDER_TYPE, BORDER_SUNKEN);
   //--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(0, objName, OBJPROP_CORNER, corner);
   //--- set flat border color (in Flat mode)
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrBlack);
   //--- set flat border line style
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
   //--- set flat border width
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, line_width);
   //--- display in the foreground (false) or background (true)
   ObjectSetInteger(0, objName, OBJPROP_BACK, UserInterfaceTransparent);
   //--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
   //--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
   //--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, z_order);
  
   
   return true;
}


bool createButton(string objName, int x, int y, int width, int height, string text, 
                  string font, int font_size, color clrTxt, color clrBk, color clrBorder, 
                  ENUM_BASE_CORNER corner, const long z_order=0) {

   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, 0)) {
      Print(__FUNCTION__, ": failed to create the button! Error code = ",GetLastError());
      return(false);
   }

   //--- set button coordinates
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   //--- set button size
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
   //--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(0, objName, OBJPROP_CORNER, corner);
   //--- set the text
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   //--- set text font
   ObjectSetString(0, objName, OBJPROP_FONT, font);
   //--- set font size
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, font_size);
   //--- set text color
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrTxt);
   //--- set background color
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrBk);
   //--- set border color
   ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrBorder);
   //--- display in the foreground (false) or background (true)
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   //--- set button state
   ObjectSetInteger(0, objName, OBJPROP_STATE, false);
   //--- enable (true) or disable (false) the mode of moving the button by mouse
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
   //--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
   //--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, z_order);
   
   return true;
}



bool createLabel(string objName, int x, int y, string text, 
                 string font, int font_size, color clrTxt, 
                 ENUM_BASE_CORNER corner, long z_order=0) {

   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0)) {
      Print(__FUNCTION__, ": failed to create text label! Error code = ",GetLastError());
      return(false);
   }

   //--- set button coordinates
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   //--- set button size
   //ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
   //ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
   //--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(0, objName, OBJPROP_CORNER, corner);
   //--- set the text
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   //--- set text font
   ObjectSetString(0, objName, OBJPROP_FONT, font);
   //--- set font size
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, font_size);
   //--- set the slope angle of the text
   ObjectSetDouble(0, objName, OBJPROP_ANGLE, 0);
   //--- set anchor type
   ObjectSetInteger(0, objName, OBJPROP_ANCHOR, 0);
   //--- set text color
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrTxt);
   //--- set background color
   //ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrBk);
   //--- set border color
   //ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrBk);
   //--- display in the foreground (false) or background (true)
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   //--- set button state
   ObjectSetInteger(0, objName, OBJPROP_STATE, false);
   //--- enable (true) or disable (false) the mode of moving the button by mouse
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
   //--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
   //--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, z_order);
   
   return true;
}



bool createEditTextBox(string objName, int x, int y, int width, int height, string text, 
                       string font, int font_size, color clrTxt, color clrBk, 
                       ENUM_BASE_CORNER corner, long z_order=0) {

   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_EDIT, 0, 0, 0)) {
      Print(__FUNCTION__, ": failed to create \"Edit\" object! Error code = ",GetLastError());
      return(false);
   }

   //--- set button coordinates
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   //--- set button size
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
   //--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(0, objName, OBJPROP_CORNER, corner);
   //--- set the text
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   //--- set text font
   ObjectSetString(0, objName, OBJPROP_FONT, font);
   //--- set font size
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, font_size);
   //--- set the type of text alignment in the object
   ObjectSetInteger(0, objName, OBJPROP_ALIGN, ALIGN_CENTER);
   //--- enable (true) or cancel (false) read-only mode
   ObjectSetInteger(0, objName, OBJPROP_READONLY, false);
   //--- set text color
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrTxt);
   //--- set background color
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrBk);
   //--- set border color
   ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrBlack);
   //--- display in the foreground (false) or background (true)
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   //--- set button state
   //ObjectSetInteger(0, objName, OBJPROP_STATE, false);
   //--- enable (true) or disable (false) the mode of moving the button by mouse
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
   //--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
   //--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, z_order);
   
   return true;
}



bool BitmapLabelCreate(const long              chart_ID=0,               // chart's ID
                       const string            name="BmpLabel",          // label name
                       const int               sub_window=0,             // subwindow index
                       const int               x=0,                      // X coordinate
                       const int               y=0,                      // Y coordinate
                       const string            file_on="",               // image in On mode
                       const string            file_off="",              // image in Off mode
                       const int               width=0,                  // visibility scope X coordinate
                       const int               height=0,                 // visibility scope Y coordinate
                       const int               x_offset=10,              // visibility scope shift by X axis
                       const int               y_offset=10,              // visibility scope shift by Y axis
                       const bool              state=false,              // pressed/released
                       const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                       const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type 
                       const color             clr=clrRed,               // border color when highlighted
                       const ENUM_LINE_STYLE   style=STYLE_SOLID,        // line style when highlighted
                       const int               point_width=1,            // move point size
                       const bool              back=false,               // in the background
                       const bool              selection=false,          // highlight to move
                       const bool              hidden=true,              // hidden in the object list
                       const long              z_order=0)                // priority for mouse click
{
//--- reset the error value
   ResetLastError();
//--- create a bitmap label
   if(!ObjectCreate(chart_ID,name,OBJ_BITMAP_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create \"Bitmap Label\" object! Error code = ",GetLastError());
      return(false);
     }
//--- set the images for On and Off modes
   if(!ObjectSetString(chart_ID,name,OBJPROP_BMPFILE,0,file_on))
     {
      Print(__FUNCTION__,
            ": failed to load the image for On mode! Error code = ",GetLastError());
      return(false);
     }
   if(!ObjectSetString(chart_ID,name,OBJPROP_BMPFILE,1,file_off))
     {
      Print(__FUNCTION__,
            ": failed to load the image for Off mode! Error code = ",GetLastError());
      return(false);
     }
//--- set label coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set visibility scope for the image; if width or height values
//--- exceed the width and height (respectively) of a source image,
//--- it is not drawn; in the opposite case,
//--- only the part corresponding to these values is drawn
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the part of an image that is to be displayed in the visibility scope
//--- the default part is the upper left area of an image; the values allow
//--- performing a shift from this area displaying another part of the image
   ObjectSetInteger(chart_ID,name,OBJPROP_XOFFSET,x_offset);
   ObjectSetInteger(chart_ID,name,OBJPROP_YOFFSET,y_offset);
//--- define the label's status (pressed or released)
   ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set anchor type
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- set the border color when object highlighting mode is enabled
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set the border line style when object highlighting mode is enabled
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set a size of the anchor point for moving an object
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,point_width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
}
//+------------------------------------------------------------------+
