//+------------------------------------------------------------------+
//|                                                      PriceAction |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  PROPERTIES                                                      |
//+------------------------------------------------------------------+
#property version "100.005"
#property description "Price Action Bot ( Mimic SmartBot PriceAction Bot )"
#property script_show_inputs
//---
#property indicator_applied_price PRICE_CLOSE
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   1
#property indicator_type1   DRAW_CANDLES
#property indicator_width1  3
#property indicator_label1  "C open;C high;C low;C close"



//+------------------------------------------------------------------+
//| INCLUDE SECTION                                                  |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
#include <Trade/AccountInfo.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Expert/ExpertBase.mqh>


#include "Enums/AllowedTimeFrame.mqh"
#include "Enums/CloseOrderType.mqh"
#include "Enums/FilterDxDyMode.mqh"
#include "Enums/OperationDirection.mqh"
#include "Enums/OperationDirectionEnum.mqh"
#include "Enums/OperationDisruption.mqh"
#include "Enums/OperationMode.mqh"
#include "Enums/OrderSendType.mqh"
#include "Enums/TimeInterval.mqh"
#include "Inputs/PriceAction.mqh"
#include "DateTime/DateTimeHelper.mqh"



//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
CTrade Trade;
CAccountInfo AccountInfo;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;
CSymbolInfo SymbolInfo;
CExpertBase ExpertBase;

MqlRates SelectedRates[];
static MqlRates lastProcessedBar;
datetime CurrentDateTime;
datetime CurrentTime;
datetime PreviousDateTime;
datetime PreviousTime;
bool     IsNewCandle;
//double   PositionPriceOpen;
//double   PositionPriceCurrent;
//double   PositionPriceDifference;

ENUM_TIMEFRAMES SelectedTimeframe;

static double DayTradeProfit;
static bool CloseAllDailyPositions;
static double PreviousDayAcumulatedProfit;
static int CountDayTrades;

static int PositionVolume;
static datetime DailyBeginTime;
static datetime Window1BeginTime;
static datetime Window1EndTime;
static datetime Window2BeginTime;
static datetime Window2EndTime;
static datetime DailyEndTime;
static datetime DailyCloseTime;

static int DX;
static int DY;

static int StopGainQuantity;
static double StopGain1; // Stop Gain 1
static double StopGain2; // Stop Gain 2
static double StopGain3; // Stop Gain 3
static double StopGain4; // Stop Gain 4
static double StopGain5; // Stop Gain 5
static int StopGain1Volume; // Stop Gain 1
static int StopGain2Volume; // Stop Gain 2
static int StopGain3Volume; // Stop Gain 3
static int StopGain4Volume; // Stop Gain 4
static int StopGain5Volume; // Stop Gain 5
static bool StopGain1Avaliable; // Stop Gain 1 Is Avaliable
static bool StopGain2Avaliable; // Stop Gain 2 Is Avaliable
static bool StopGain3Avaliable; // Stop Gain 3 Is Avaliable
static bool StopGain4Avaliable; // Stop Gain 4 Is Avaliable
static bool StopGain5Avaliable; // Stop Gain 5 Is Avaliable
static bool StopGainBreakEven;
static bool StopGainBreakEvenActivated;

static double StopLoss;
static double TrailingStopActivation;
static double TrailingStopDistance;
static bool TrailingStopActivated;
static double TrailingStopWatherMark;

static int StopAfterXTrades;

static bool DailyBreakEvanActivated;
static double DailyBreakevenActivationMoney;
static double DailyBreakevenMaxDrownDownMoney;
static double DailyBreakevenWatherMark;

static MqlRates referenceBar;

datetime g_trial_date = __DATE__; // D'2020.12.31';

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
   g_trial_date += 30*24*60*60;
   if(TimeCurrent() >= g_trial_date)
     {
      MessageBox("Demo expired","Warning !");
      Print("This bot version is expired.");
      return(INIT_FAILED);
     }
//+------------------------------------------------------------------+
//| Global Variable initialization                                   |
//+------------------------------------------------------------------+
   SelectedTimeframe = AllowedTimeFrame2TimeFrame(input_TimeFrame);

   if(MQLInfoInteger(MQL_OPTIMIZATION) || MQLInfoInteger(MQL_FORWARD) || MQLInfoInteger(MQL_PROFILER))
      ChartSetSymbolPeriod(0, _Symbol, PERIOD_M1);
   else
      ChartSetSymbolPeriod(0, _Symbol, SelectedTimeframe);

   SymbolInfo.Name(_Symbol);
   SymbolInfo.CheckMarketWatch();
   SymbolInfo.Select(true);

   PositionVolume  = input_positionVolume > 0 ? input_positionVolume : 1;

   DailyBeginTime   = TimeIntervalToTime(input_DailyBeginTime);
   Window1BeginTime = TimeIntervalToTime(input_Window1BeginTime);
   Window1EndTime   = TimeIntervalToTime(input_Window1EndTime);
   Window2BeginTime = TimeIntervalToTime(input_Window2BeginTime);
   Window2EndTime   = TimeIntervalToTime(input_Window2EndTime);
   DailyEndTime     = TimeIntervalToTime(input_DailyEndTime);
   DailyCloseTime   = TimeIntervalToTime(input_DailyCloseTime);

   datetime minDateTime = TimeIntervalToTime(t0000);
   datetime maxDateTime = TimeIntervalToTime(t1820);

   if(
      (DailyCloseTime > minDateTime
       && (
          DailyCloseTime < MathMax(MathMax(MathMax(MathMax(MathMax(MathMax(DailyEndTime, DailyEndTime), Window2EndTime), Window2BeginTime), Window1EndTime), Window1BeginTime), DailyBeginTime)
       ))
      || (DailyEndTime > minDateTime
          && (
             DailyEndTime < MathMax(MathMax(MathMax(MathMax(MathMax(DailyEndTime, Window2EndTime), Window2BeginTime), Window1EndTime), Window1BeginTime), DailyBeginTime)
          ))
      || (Window2EndTime > minDateTime
          && (
             Window2EndTime < Window2BeginTime
             || Window2EndTime < MathMax(MathMax(MathMax(Window2BeginTime, Window1EndTime), Window1BeginTime), DailyBeginTime)
             || Window2BeginTime == minDateTime
          ))
      || (Window2BeginTime > minDateTime
          && (
             Window2BeginTime < MathMax(MathMax(Window1EndTime, Window1BeginTime), DailyBeginTime)
          ))

      || (Window1EndTime > minDateTime
          && (
             Window1EndTime < Window1BeginTime
             || Window1EndTime < MathMax(Window1BeginTime, DailyBeginTime)
             || Window1BeginTime == minDateTime
          ))
      || (Window1BeginTime > minDateTime
          && (
             Window1BeginTime < DailyBeginTime
          ))
   )
     {
      Print("Please check the window dates parameters.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   DailyEndTime = DailyEndTime == minDateTime ? maxDateTime : DailyEndTime;

   DX = input_filterDxDyMode == fDX ? (int)filterDxDy : 0 ;
   DY = input_filterDxDyMode == fDY ? (int)filterDxDy : 0;

   ArraySetAsSeries(SelectedRates, true);

//+------------------------------------------------------------------+
//|  Partial Gain Validation                                         |
//+------------------------------------------------------------------+
   StopGain1 = input_StopGain1;
   StopGain2 = input_StopGain2;
   StopGain3 = input_StopGain3;
   StopGain4 = input_StopGain4;
   StopGain5 = input_StopGain5;

   ResetStopGainAvaliability();

   if((StopGain5Avaliable && PositionVolume < 5)
      || (StopGain4Avaliable && PositionVolume < 4)
      || (StopGain3Avaliable && PositionVolume < 3)
      || (StopGain2Avaliable && PositionVolume < 2)
      || (StopGain1Avaliable && PositionVolume < 1)

      || (StopGain2Avaliable && StopGain1 >= StopGain2)
      || (StopGain3Avaliable && StopGain2 >= StopGain3)
      || (StopGain4Avaliable && StopGain3 >= StopGain4)
      || (StopGain5Avaliable && StopGain4 >= StopGain5))
     {
      Print("Please check the StopGain parameters.");
      return(INIT_PARAMETERS_INCORRECT);
     }

//+------------------------------------------------------------------+
//| Stop Gain Setting                                                |
//+------------------------------------------------------------------+
   StopGainQuantity = 0;
   StopGainQuantity += StopGain1Avaliable ? 1 : 0;
   StopGainQuantity += StopGain2Avaliable ? 1 : 0;
   StopGainQuantity += StopGain3Avaliable ? 1 : 0;
   StopGainQuantity += StopGain4Avaliable ? 1 : 0;
   StopGainQuantity += StopGain5Avaliable ? 1 : 0;

   StopGain1Volume = StopGain1Avaliable ? (int)(PositionVolume) / (StopGainQuantity) : 0;
   StopGain2Volume = StopGain2Avaliable ? (int)(PositionVolume - StopGain1Volume) / (StopGainQuantity - 1) : 0;
   StopGain3Volume = StopGain3Avaliable ? (int)(PositionVolume - StopGain1Volume - StopGain2Volume) / (StopGainQuantity - 2) : 0;
   StopGain4Volume = StopGain4Avaliable ? (int)(PositionVolume - StopGain1Volume - StopGain2Volume - StopGain3Volume) / (StopGainQuantity - 3) : 0;
   StopGain5Volume = StopGain5Avaliable ? (int)(PositionVolume - StopGain1Volume - StopGain2Volume - StopGain3Volume - StopGain4Volume) / (StopGainQuantity - 4) : 0;

   StopGainBreakEven = StopGain1Avaliable ? Input_StopGainBreakEven : false;

   StopLoss = input_StopLoss > 0 ? input_StopLoss : 0;
   TrailingStopActivation = input_TrailingStopActivation > 0 ? input_TrailingStopActivation : 0;
   TrailingStopDistance = input_TrailingStopDistance > 0 ? input_TrailingStopDistance : 0;
   TrailingStopActivated = false;
   TrailingStopWatherMark = 0;

   if((TrailingStopActivation == 0 && TrailingStopActivation > 0)
      || (TrailingStopActivation > 0 && TrailingStopActivation == 0))
     {
      Print("Please check the Traling Stop parameters.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(StopGain1 > 0 && TrailingStopActivation >= MathMax(MathMax(MathMax(MathMax(StopGain1, StopGain2), StopGain3), StopGain4), StopGain5))
     {
      Print("Please check the Traling Activation vs GainStop setting.");
      return(INIT_PARAMETERS_INCORRECT);
     }

//TesterWithdrawal()
   StopGainBreakEvenActivated = false;

   StopAfterXTrades = input_StopAfterXTrades;
   if(input_StopAfterXTradesMode != saNone && StopAfterXTrades == 0)
     {
      Print("Please check the Stop after X Trades parameters.");
      return(INIT_PARAMETERS_INCORRECT);
     }

//+------------------------------------------------------------------+
//| Daily BreakEven                                                  |
//+------------------------------------------------------------------+
   DailyBreakEvanActivated = false;
   DailyBreakevenActivationMoney = input_DailyBreakevenActivationMoney;
   DailyBreakevenMaxDrownDownMoney = input_DailyBreakevenMaxDrownDownMoney;
   if((DailyBreakevenActivationMoney == 0 && DailyBreakevenMaxDrownDownMoney > 0)
      || (DailyBreakevenActivationMoney > 0 && DailyBreakevenMaxDrownDownMoney == 0))
     {
      Print("Please check the Breakeven parameters.");
      return(INIT_PARAMETERS_INCORRECT);
     }

//+------------------------------------------------------------------+
//| Trade Settings                                                   |
//+------------------------------------------------------------------+
   Trade.LogLevel(LOG_LEVEL_ALL); // https://www.mql5.com/en/docs/standardlibrary/tradeclasses/ctrade/ctradeLogLevel
   Trade.SetExpertMagicNumber(input_MagicNumber); // https://www.mql5.com/en/docs/standardlibrary/tradeclasses/ctrade/ctradesetexpertmagicnumber
   Trade.SetAsyncMode(false); // https://www.mql5.com/en/docs/standardlibrary/tradeclasses/ctrade/ctradesetasyncmode
//Trade.SetTypeFilling(ORDER_FILLING_FOK);
   Trade.SetTypeFillingBySymbol(_Symbol);

   ResetDayTrade();
   PrintFormat("LAST PING=%.f ms", TerminalInfoInteger(TERMINAL_PING_LAST) / 1000.);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetStopGainAvaliability()
  {
   StopGain1Avaliable = StopGain1 > 0;
   StopGain2Avaliable = StopGain2 > 0;
   StopGain3Avaliable = StopGain3 > 0;
   StopGain4Avaliable = StopGain4 > 0;
   StopGain5Avaliable = StopGain5 > 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetDayTrade()
  {
   CountDayTrades = 0;
   CloseAllDailyPositions = false;
   DailyBreakEvanActivated = false;
   PreviousDayAcumulatedProfit = AccountInfo.Balance();
   lastProcessedBar.time = NULL;
   referenceBar.time = NULL;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetTrade()
  {
   ResetStopGainAvaliability();
   TrailingStopActivated = false;
   StopGainBreakEvenActivated = false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HasOrder ;
bool HasPosition;


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//+------------------------------------------------------------------+
//| TRIAL VERION VERIFICATION                                        |
//+------------------------------------------------------------------+
   if(TimeCurrent() >= g_trial_date)
     {
      MessageBox("Demo expired","Warning !");
      Print("This bot version is expired. Please contact the developer to get a new version.");
      ExpertRemove();
     }

   CopyRates(Symbol(), SelectedTimeframe, 0, 3, SelectedRates);
   PreviousDateTime = CurrentDateTime;
   PreviousTime = CurrentTime;
   CurrentDateTime = SelectedRates[0].time;
   CurrentTime = DateTime2Time(CurrentDateTime);

   if(PreviousTime > CurrentTime && isNewCandle())
      ResetDayTrade();

   int ot = OrdersTotal();
   int pt = PositionsTotal();
   HasOrder = ot > 0;
   HasPosition = pt > 0;
   IsNewCandle = isNewCandle();

   if(!HasOrder && !HasPosition)
     {
      if(OutOfDailyOpperatonalTimeWindow())
         return;
      if(SelectedRates[0].high < SelectedRates[1].high && SelectedRates[0].low > SelectedRates[1].low)
         return;
      if(lastProcessedBar.high == SelectedRates[0].high && lastProcessedBar.low == SelectedRates[0].low)
         return;
      ResetTrade();
     }

   if(HasOrder || HasPosition || lastProcessedBar.time == NULL)
      lastProcessedBar = SelectedRates[0];



   PositionInfo.Select(_Symbol);
   SymbolInfo.Refresh();
   SymbolInfo.RefreshRates();

   DayTradeProfit = DailyProfit();

   if(HasOrder || HasPosition)
     {
      // --- Process Close
      CloseAllDailyPositions = CloseAllDailyPositions || OutOfDailyOpperatonalTimeWindow();
      CloseAllDailyPositions = CloseAllDailyPositions || DailyStopLoss();
      CloseAllDailyPositions = CloseAllDailyPositions || DailyStopGain();

      if(CloseAllDailyPositions)
        {
         OrderCancel();
         PositionClose();
        }

      if(CloseAllDailyPositions)
         return;

      if(HasOrder && orderSendType == oLimit)
        {
         bool orderRemoved = CancelPendingOrders(input_LimitOrderExecutionSeconds);
         if(orderRemoved)
            return;
        }
     }

// --- Process Input
   bool canOpenOrder = !StopAfterXDailyTrades() && !HasOrder  && !HasPosition && !CloseAllDailyPositions;
   if(canOpenOrder)
     {
      canOpenOrder = canOpenOrder && DateTimeBetween(CurrentTime, DailyBeginTime, DailyEndTime);
      canOpenOrder = canOpenOrder && !DateTimeBetween(CurrentTime, Window1BeginTime, Window1EndTime);
      canOpenOrder = canOpenOrder && !DateTimeBetween(CurrentTime, Window2BeginTime, Window2EndTime);

      if(canOpenOrder)
        {
         bool buySignal = false;
         bool sellSignal = false;
         getBuySellSignal(buySignal, sellSignal);
         InputOrder(buySignal, sellSignal);
        }
     }

// --- Process Output
   if(HasPosition)
     {
      //-- Gain
      if(input_StopGainOrderType == cMarket)
        {
         bool orderCreated = PositionCloseWhenStopGain(StopGain5Avaliable, StopGain5, StopGain5Volume)
                             || PositionCloseWhenStopGain(StopGain4Avaliable, StopGain4, StopGain4Volume)
                             || PositionCloseWhenStopGain(StopGain3Avaliable, StopGain3, StopGain3Volume)
                             || PositionCloseWhenStopGain(StopGain2Avaliable, StopGain2, StopGain2Volume)
                             || PositionCloseWhenStopGain(StopGain1Avaliable, StopGain1, StopGain1Volume);
         if(orderCreated)
            return;
        }
      else
         if(input_StopGainOrderType == cLimit)
           {
            bool _ = OutputOrderLimitStopGainProcess(StopGain1Avaliable, StopGain1, StopGain1Volume)
                     || OutputOrderLimitStopGainProcess(StopGain2Avaliable, StopGain2, StopGain2Volume)
                     || OutputOrderLimitStopGainProcess(StopGain3Avaliable, StopGain3, StopGain3Volume)
                     || OutputOrderLimitStopGainProcess(StopGain4Avaliable, StopGain4, StopGain4Volume)
                     || OutputOrderLimitStopGainProcess(StopGain5Avaliable, StopGain5, StopGain5Volume);
           }

      //-- Loss
      if(StopLoss > 0 && getPositionPriceDifference() <= (StopLoss * -1))
        {
         OrderCancel();
         PositionClose();
         return;
        }

      bool orderCreated = StopGainBreakEven(StopGain1);
      if(orderCreated)
         return;

      orderCreated = DailyBreakEven();
      if(orderCreated)
         return;

      orderCreated = TrailingStop();
      if(orderCreated)
         return;
     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CancelPendingOrders(int timeoutSeconds)
  {
   bool orderCanceled = NULL;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
        {
         if(OrderGetString(ORDER_SYMBOL) == _Symbol
            && OrderGetInteger(ORDER_MAGIC) == Trade.RequestMagic())
           {
            if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_LIMIT ||
               OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_LIMIT)
              {
               if(OrderGetInteger(ORDER_TIME_SETUP) + timeoutSeconds < TimeCurrent())
                  orderCanceled = orderCanceled | Trade.OrderDelete(ticket);
              }
           }
        }
     }
   return orderCanceled;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getPositionPriceDifference()
  {
   if(PositionInfo.Ticket() > 0)
     {
      double current = PositionInfo.PriceCurrent();
      double open = PositionInfo.PriceOpen();

      if(PositionInfo.PositionType() == POSITION_TYPE_BUY)
         return current - open;

      if(PositionInfo.PositionType() == POSITION_TYPE_SELL)
         return open - current;
     }
   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DailyProfit()
  {
   return AccountInfo.Equity() - PreviousDayAcumulatedProfit;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TrailingStop()
  {
   if(TrailingStopDistance == 0)
      return false;

   double PositionPriceDifference = getPositionPriceDifference();

   if(!TrailingStopActivated
      && PositionPriceDifference >= TrailingStopActivation)
     {
      TrailingStopActivated = true;
      TrailingStopWatherMark  = 0;
     }

   if(TrailingStopActivated)
     {
      TrailingStopWatherMark = MathMax(TrailingStopWatherMark, PositionInfo.PriceCurrent());

      if(PositionInfo.PriceCurrent() < TrailingStopWatherMark - TrailingStopDistance)
        {
         OrderCancel();
         PositionClose();
         return true;
        }
     }

   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool StopGainBreakEven(double StopGain)
  {
   if(StopGain <= 0 || !Input_StopGainBreakEven)
      return false;

   double PositionDifference = getPositionPriceDifference();

   if(!StopGainBreakEvenActivated
      && PositionDifference >= StopGain)
     {
      StopGainBreakEvenActivated = true;
     }

   if(StopGainBreakEvenActivated
      && PositionInfo.Profit() <= 0)
     {
      OrderCancel();
      PositionClose();
      return true;
     }

   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool DailyBreakEven()
  {
   if(DailyBreakevenActivationMoney == 0)
      return false;

   if(!DailyBreakEvanActivated
      && DayTradeProfit >= DailyBreakevenActivationMoney)
     {
      DailyBreakEvanActivated = true;
      DailyBreakevenWatherMark = 0;
     }

   if(DailyBreakEvanActivated)
     {
      DailyBreakevenWatherMark = MathMax(DayTradeProfit, DailyBreakevenWatherMark);

      if(DayTradeProfit < DailyBreakevenWatherMark - DailyBreakevenMaxDrownDownMoney)
        {
         OrderCancel();
         PositionClose();
         CloseAllDailyPositions = true;
         return true;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PositionCloseWhenStopGain(bool & StopGainAvaliable, double StopGain, int StopGainVolume)
  {
   if(StopGain <= 0)
      return false;

   double PositionPriceDifference = getPositionPriceDifference();
   if(StopGainAvaliable && PositionPriceDifference >= StopGain)
     {
      Print(__FUNCTION__);
      bool orderCreated = PositionClose(StopGainVolume);
      StopGainAvaliable = !orderCreated;
      return orderCreated;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OutputOrderLimitStopGainProcess(bool & StopGainAvaliable, double StopGain, int StopGainVolume)
  {
   if(StopGain <= 0)
      return false;

   int orderTotal = OrdersTotal() + PositionsTotal();
   if(StopGainAvaliable && orderTotal == 1)
     {
      Print(__FUNCTION__);
      bool orderCreated = OutputOrderLimit(StopGain, StopGainVolume);
      StopGainAvaliable = !orderCreated;
      return orderCreated;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsHedging()
  {
   ENUM_ACCOUNT_MARGIN_MODE margmod = AccountInfo.MarginMode();
   return(margmod == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OutputOrderLimit(double StopGain, int Volume)
  {
   Trade.SetDeviationInPoints(1);
   double price = PositionInfo.PriceOpen();
   string comment = "Limit StopGain";
   if(PositionInfo.PositionType() == POSITION_TYPE_BUY)
     {
      Print(__FUNCTION__);
      price = SymbolInfo.NormalizePrice(price + StopGain);
      //return Trade.SellLimit(Volume, price, _Symbol, 0, 0, ORDER_TIME_GTC, TimeTradeServer(), comment);
      return Trade.SellLimit(Volume, price,NULL,0,0,ORDER_TIME_DAY);
     }

   if(PositionInfo.PositionType() == POSITION_TYPE_SELL)
     {
      Print(__FUNCTION__);
      price =  SymbolInfo.NormalizePrice(price - StopGain);
      //        return Trade.BuyLimit(Volume, price, _Symbol, 0, 0, ORDER_TIME_GTC, TimeTradeServer(), comment);
      return Trade.BuyLimit(Volume, price,NULL,0,0,ORDER_TIME_DAY);
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OutOfDailyOpperatonalTimeWindow()
  {
   if(DailyCloseTime == 0)
     {
      return(false);
     }
   return DateTime2Time(TimeCurrent())>= DailyCloseTime;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool DailyStopLoss()
  {
   if(input_dailyStopLossMoney > 0 && DayTradeProfit < 0 && MathAbs(DayTradeProfit) >= input_dailyStopLossMoney)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool DailyStopGain()
  {
   if(input_dailyStopGainMoney > 0 && DayTradeProfit > 0 && DayTradeProfit > input_dailyStopGainMoney)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool StopAfterXDailyTrades()
  {
   static ulong lastPositionTicket = 0;
   if(lastPositionTicket != PositionInfo.Ticket() && PositionInfo.Ticket() != 0)
     {
      CountDayTrades++;
      lastPositionTicket = PositionInfo.Ticket();
     }

   if(CountDayTrades >= StopAfterXTrades
      && (input_StopAfterXTradesMode == saBoth
          || (input_StopAfterXTradesMode == saLossing && DayTradeProfit < 0)
          || (input_StopAfterXTradesMode == saWinning && DayTradeProfit > 0)))
     {
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PositionClose(double volume = 0)
  {
   if(PositionInfo.Ticket() == 0)
      return false;

   Print(__FUNCTION__);

   Trade.SetDeviationInPoints(ULONG_MAX);

//-- Partial Close
   if(volume > 0 && volume < PositionInfo.Volume())
     {
      if(!IsHedging())
        {
         volume = MathMin(volume, PositionInfo.Volume());

         Print("Closed Partial Position");
         if(PositionInfo.PositionType() == POSITION_TYPE_BUY)
           {
            return Trade.Sell(volume, _Symbol);
           }
         else
            if(PositionInfo.PositionType() == POSITION_TYPE_SELL)
              {
               return Trade.Buy(volume, _Symbol);
              }
        }
      else
         return Trade.PositionClosePartial(_Symbol, volume);

     }
//-- Close all
   else
     {
      Print("Closed Total Position");
      return Trade.PositionClose(_Symbol);
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderCancel()
  {
   if(OrderInfo.Ticket() == 0)
      return;

   Print(__FUNCTION__);

   uint pendingOrders = OrdersTotal();
   for(uint i = 0; i < pendingOrders; i++)
     {
      ulong ticket = OrderGetTicket(i);
      Print("Canceled Order no.: " + IntegerToString(ticket) + " by day trade time");
      Trade.OrderDelete(ticket);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction & OnTradeTransaction,
                        const MqlTradeRequest & request,
                        const MqlTradeResult & result)
  {
//myOnTradeTransaction(OnTradeTransaction, request, result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool InputOrder(bool buySignal, bool sellSignal)
  {
   if((!buySignal && !sellSignal) || (buySignal && sellSignal))
      return false;

   Print(__FUNCTION__);

   OrderCancel();
   PositionClose();

   double _positionVolume = NomalizeSymbolVolume(PositionVolume);

   if(orderSendType == oMarket)
     {
      Trade.SetDeviationInPoints(ULONG_MAX);
      if(buySignal)
        {
         string _comment = "Market Buy";
         return Trade.Buy(_positionVolume, _Symbol, 0, 0, 0, _comment);
        }
      if(sellSignal)
        {
         string _comment = "Market Sell" ;
         return Trade.Sell(_positionVolume, _Symbol, 0, 0, 0, _comment);
        }
     }

   if(orderSendType == oLimit)
     {
      Trade.SetDeviationInPoints(input_LimitOrderSpread);
      datetime expiration = TimeCurrent() + input_LimitOrderExecutionSeconds;

      if(buySignal)
        {
         double _price =  SymbolInfo.NormalizePrice(SymbolInfo.Last() - input_LimitOrderSpread);
         string _comment = "Limit Buy";
         return Trade.BuyLimit(_positionVolume, _price, _Symbol, 0, 0, ORDER_TIME_DAY, expiration);
        }
      if(sellSignal)
        {
         double _price = SymbolInfo.NormalizePrice(SymbolInfo.Last() + input_LimitOrderSpread);;
         string _comment = "Limit Sell";
         return Trade.SellLimit(_positionVolume, _price, _Symbol, 0, 0, ORDER_TIME_DAY, expiration);
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//|  Process bars and return Buy and Sell signals                                                                |
//+------------------------------------------------------------------+
void getBuySellSignal(bool & outBuySignal, bool & outSellSignal)
  {
   outBuySignal = false;
   outSellSignal = false;

   MqlRates actionBar;


//-- should try buy/sell only once by candle
   if(lastProcessedBar.time == SelectedRates[0].time)
     {
      return;
     }

   if(operationMode == Close && IsNewCandle)
     {
      actionBar = SelectedRates[1];
      if(operationDisruption == Previous)
         referenceBar = SelectedRates[2];
      else
         if(operationDisruption == Reference && referenceBar.time == NULL)
            referenceBar = SelectedRates[0];
     }
   else
      if(operationMode == Open)
        {
         actionBar = SelectedRates[0];
         if(operationDisruption == Previous)
            referenceBar = SelectedRates[1];
         else
            if(operationDisruption == Reference && referenceBar.time == NULL)
               referenceBar = SelectedRates[1];
        }

   if(referenceBar.time == actionBar.time)
      return;

//-- If reference candle is smaller than DY will remove buy and sell signals
   if(input_filterDxDyMode == fDY
      && MathAbs(referenceBar.high - referenceBar.low) < DY)
      return;

//-- Stock Variation
   if(stockVariation != NULL && stockVariation > 0)
     {
      double dayOpenRate = getOpenDayRate();
      double variationHigh = 100 * (referenceBar.high - dayOpenRate) / dayOpenRate;
      double variationLow  = 100 * (dayOpenRate - referenceBar.low) / referenceBar.low;
      if((variationHigh > 0 && variationHigh > stockVariation)
         && (variationLow  > 0 && variationLow  > stockVariation))
        {
         outBuySignal = false;
         outSellSignal = false;
         return;
        }
     }

//-- FollowingTrend
   outBuySignal = (referenceBar.high + DX) < actionBar.high;
   if(!outBuySignal)
      outSellSignal = (referenceBar.low - actionBar.low) > DX;

//-- AgainstTrend
   if(operationDirection == AgainstTrend)
     {
      bool aux = outBuySignal;
      outBuySignal = outSellSignal;
      outSellSignal = aux;
     }

   if(OperationDirection == odBuy)
      outSellSignal = false;

   if(OperationDirection == odSell)
      outBuySignal = false;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NomalizeSymbolVolume(double dblLots)
  {
   double
   dblLotsMinimum = SymbolInfo.LotsMin(),
   dblLotsMaximum = SymbolInfo.LotsMax(),
   dblLotsStep    = SymbolInfo.LotsStep();

// Adjust Volume for allowable conditions
   double   dblLotsNext = fmin(dblLotsMaximum,                          // Prevent too greater volume
                               fmax(dblLotsMinimum,                     // Prevent too smaller volume
                                    round(dblLots) * dblLotsStep));     // Align to Step value

   return (dblLotsNext);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getOpenDayRate()
  {
   MqlRates rate[];
   CopyRates(Symbol(), PERIOD_D1, 0, 1, rate);
   return (rate[0].open);
  }

//+------------------------------------------------------------------+
//|  Custom Fuctions                                                  |
//+------------------------------------------------------------------+
bool isNewCandle()
  {
   static datetime last_time = 0;
   datetime lastbar_time = (datetime)SeriesInfoInteger(Symbol(), SelectedTimeframe, SERIES_LASTBAR_DATE);
   if(last_time == 0)
     {
      last_time = lastbar_time;
      return(false);
     }
   if(last_time != lastbar_time)
     {
      last_time = lastbar_time;
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
