//+------------------------------------------------------------------+
//|                                                      PriceAction |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  PROPERTIES                                                      |
//+------------------------------------------------------------------+
#property version "100.001"
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
#include <Expert\ExpertBase.mqh>
#include "Enums/AllowedTimeFrame.mqh"
#include "Enums/CloseOrderType.mqh"
#include "Enums/FilterDxDyMode.mqh"
#include "Enums/OperationDirection.mqh"
#include "Enums/OperationDirectionEnum.mqh"
#include "Enums/OperationDisruption.mqh"
#include "Enums/OperationMode.mqh"
#include "Enums/OrderSendType.mqh"
#include "Enums/TimeInterval.mqh"
#include "Inputs/Global.mqh"
#include "DateTime/DateTimeHelper.mqh"
#include "OnTradeFunction.mqh"


//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
CTrade trade;
CAccountInfo account;
CExpertBase  expertBase;
MqlRates priceInformation[];
static MqlRates lastProcessedBar;
datetime CurrentDateTime;
datetime CurrentTime;
datetime PreviousDateTime;
datetime PreviousTime;
bool     IsNewCandle;
//double   PositionPriceOpen;
//double   PositionPriceCurrent;
//double   PositionPriceDifference;
//ENUM_POSITION_TYPE PositionType;

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
static bool BreakEvenActivated;

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

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
   {
//+------------------------------------------------------------------+
//| Global Variable initialization                                   |
//+------------------------------------------------------------------+
    SelectedTimeframe = AllowedTimeFrame2TimeFrame(input_TimeFrame);
    expertBase.Period(SelectedTimeframe);
    expertBase.EveryTick(true);


    PositionVolume  = input_positionVolume > 0 ? input_positionVolume : 1;

    DailyBeginTime   = TimeIntervalToTime(input_DailyBeginTime);
    Window1BeginTime = TimeIntervalToTime(input_Window1BeginTime);
    Window1EndTime   = TimeIntervalToTime(input_Window1EndTime);
    Window2BeginTime = TimeIntervalToTime(input_Window2BeginTime);
    Window2EndTime   = TimeIntervalToTime(input_Window2EndTime);
    DailyEndTime     = TimeIntervalToTime(input_DailyEndTime);
    DailyCloseTime   = TimeIntervalToTime(input_DailyCloseTime);

    datetime minDateTime = TimeIntervalToTime(t0000);
    datetime maxDateTime = TimeIntervalToTime(t1900);

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

    ArraySetAsSeries(priceInformation, true);

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

       || (StopGain2Avaliable && StopGain1 > StopGain2)
       || (StopGain3Avaliable && StopGain2 > StopGain3)
       || (StopGain4Avaliable && StopGain3 > StopGain4)
       || (StopGain5Avaliable && StopGain4 > StopGain5))
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
    BreakEvenActivated = false;

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
    trade.LogLevel(LOG_LEVEL_ALL); // https://www.mql5.com/en/docs/standardlibrary/tradeclasses/ctrade/ctradeLogLevel
    trade.SetExpertMagicNumber(input_MagicNumber); // https://www.mql5.com/en/docs/standardlibrary/tradeclasses/ctrade/ctradesetexpertmagicnumber
    trade.SetAsyncMode(true); // https://www.mql5.com/en/docs/standardlibrary/tradeclasses/ctrade/ctradesetasyncmode


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
    DayTradeProfit = 0;
    CountDayTrades = 0;
    CloseAllDailyPositions = false;
    DailyBreakEvanActivated = false;
    PreviousDayAcumulatedProfit = AccountInfoDouble(ACCOUNT_BALANCE);
   }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
   {
    IsNewCandle = isNewCandle();
    PreviousDateTime = CurrentDateTime;
    PreviousTime = CurrentTime;
    CurrentDateTime = TimeTradeServer();
    CurrentTime = DateTime2Time(CurrentDateTime);
//PreviousCandle = CurrentCandle;
//CurrentCandle =
    PositionSelect(_Symbol);
    ENUM_POSITION_TYPE PositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

    bool buySignal = false;
    bool sellSignal = false;
    CopyRates(Symbol(), SelectedTimeframe, 0, 3, priceInformation);

    if(IsNewCandle && PreviousTime > CurrentTime)
        ResetDayTrade();

    if(lastProcessedBar.time == NULL)
       {
        lastProcessedBar = priceInformation[0];
       }

    DayTradeProfit = DailyProfit();


    CloseAllDailyPositions = CloseAllDailyPositions
                             || (MayCloseAllPositions()
                                 || (input_dailyStopLossMoney > 0 && DayTradeProfit < 0 && DayTradeProfit < input_dailyStopLossMoney)
                                 || (input_dailyStopGainMoney > 0 && DayTradeProfit > 0 && DayTradeProfit > input_dailyStopGainMoney));

    if(CloseAllDailyPositions)
       {
        CloseAllPositions();
        CancelAllPendingOrders();
        lastProcessedBar.time = NULL;
        return;
       }
    else
       {
        bool canOpenOrder = PositionsTotal() == 0 && OrdersTotal() == 0
                            && DateTimeBetween(CurrentTime, DailyBeginTime, DailyEndTime)
                            && !DateTimeBetween(CurrentTime, Window1BeginTime, Window1EndTime)
                            && !DateTimeBetween(CurrentTime, Window2BeginTime, Window2EndTime);

        if(CountDayTrades >= StopAfterXTrades
           && (input_StopAfterXTradesMode == saBoth
               || (input_StopAfterXTradesMode == saLossing && DayTradeProfit < 0)
               || (input_StopAfterXTradesMode == saWinning && DayTradeProfit > 0)))
           {
            canOpenOrder = false;
           }

        if(canOpenOrder)
           {
            getBuySellSignal(buySignal, sellSignal);

            if(OperationDirection == odBuy)
                sellSignal = false;
            if(OperationDirection == odSell)
                buySignal = false;

            InputOrder(buySignal,  sellSignal);

            ResetStopGainAvaliability();
            TrailingStopWatherMark = 0;
            TrailingStopActivated = false;
            BreakEvenActivated = false;
           }
        double OrdersTotal = OrdersTotal();
        double PositionsTotal = PositionsTotal();

        if(PositionsTotal > 0 || OrdersTotal > 0)
           {
            PositionSelect(_Symbol);
            double PositionPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
            double PositionPriceDifference = priceInformation[0].close - PositionPriceOpen;
            if(PositionType == POSITION_TYPE_SELL)
                PositionPriceDifference = PositionPriceOpen - priceInformation[0].close;

            if(PositionPriceDifference >= 0)
               {
                if(input_StopGainOrderType == cMarket)
                   {
                    bool _ = OutputOrderMarketStopGainProcess(StopGain5Avaliable, StopGain5, StopGain5Volume)
                             || OutputOrderMarketStopGainProcess(StopGain4Avaliable, StopGain4, StopGain4Volume)
                             || OutputOrderMarketStopGainProcess(StopGain3Avaliable, StopGain3, StopGain3Volume)
                             || OutputOrderMarketStopGainProcess(StopGain2Avaliable, StopGain2, StopGain2Volume)
                             || OutputOrderMarketStopGainProcess(StopGain1Avaliable, StopGain1, StopGain1Volume);
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
               }
            else
               {
                if(StopLoss > 0 && PositionPriceDifference >= StopLoss)
                   {
                    CancelAllPendingOrders();
                    CloseAllPositions();
                   }
               }
            bool _ = StopGainBreakEven(StopGain5Avaliable, StopGain5)
                     || StopGainBreakEven(StopGain4Avaliable, StopGain4)
                     || StopGainBreakEven(StopGain3Avaliable, StopGain3)
                     || StopGainBreakEven(StopGain2Avaliable, StopGain2)
                     || StopGainBreakEven(StopGain1Avaliable, StopGain1);
            DailyBreakEven();
            TrailingStop();
           }
       }
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DailyProfit()
   {
//double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    return equity - PreviousDayAcumulatedProfit;
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStop()
   {
    if(TrailingStopDistance == 0)
        return;

    PositionSelect(_Symbol);
    double PositionPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
    double PositionPriceCurrent = priceInformation[0].close;
    ENUM_POSITION_TYPE PositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

    double PositionPriceDifference = PositionPriceCurrent - PositionPriceOpen;
    if(PositionType == POSITION_TYPE_SELL)
        PositionPriceDifference = PositionPriceOpen - PositionPriceCurrent;

    if(!TrailingStopActivated
       && PositionPriceDifference >= TrailingStopActivation)
        TrailingStopActivated = true;

    if(TrailingStopActivated)
       {
        TrailingStopWatherMark = PositionPriceDifference  > TrailingStopWatherMark ? PositionPriceDifference : TrailingStopWatherMark;

        if(PositionPriceDifference + TrailingStopDistance  < TrailingStopWatherMark)
           {
            CancelAllPendingOrders();
            CloseAllPositions();
           }
       }
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool StopGainBreakEven(bool StopGainAvaliable, double StopGain)
   {
    if(StopGain == 0)
        return false;

    PositionSelect(_Symbol);
    double PositionPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
    double PositionPriceCurrent =  priceInformation[0].close;
    ENUM_POSITION_TYPE  PositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

    double PositionPriceDifference = PositionPriceCurrent - PositionPriceOpen;
    if(PositionType == POSITION_TYPE_SELL)
        PositionPriceDifference = PositionPriceOpen - PositionPriceCurrent;

    if(!BreakEvenActivated
       && PositionPriceDifference >= StopGain)
       {
        BreakEvenActivated = true;
        TrailingStopWatherMark = StopGain;
       }

    if(BreakEvenActivated
       && PositionPriceDifference < TrailingStopWatherMark
       && TrailingStopWatherMark == StopGain)
       {
        CancelAllPendingOrders();
        CloseAllPositions();
        return true;
       }

    return false;
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DailyBreakEven()
   {
    if(DailyBreakevenActivationMoney == 0)
        return;

    if(!DailyBreakEvanActivated
       && DayTradeProfit >= DailyBreakevenActivationMoney)
       {
        DailyBreakEvanActivated = true;
       }

    if(DailyBreakEvanActivated)
       {
        DailyBreakevenWatherMark = DayTradeProfit > DailyBreakevenWatherMark ?  DayTradeProfit : DailyBreakevenWatherMark;

        if(DayTradeProfit + DailyBreakevenMaxDrownDownMoney < DailyBreakevenWatherMark)
           {
            CancelAllPendingOrders();
            CloseAllPositions();
            CloseAllDailyPositions = true;
           }
       }
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OutputOrderMarketStopGainProcess(bool &StopGainAvaliable, double StopGain, int StopGainVolume)
   {
    PositionSelect(_Symbol);
    double PositionPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
    double PositionPriceCurrent = priceInformation[0].close;
    ENUM_POSITION_TYPE PositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

    double PositionPriceDifference = PositionPriceCurrent - PositionPriceOpen;
    if(PositionType == POSITION_TYPE_SELL)
        PositionPriceDifference = PositionPriceOpen - PositionPriceCurrent;

    if(StopGainAvaliable && PositionPriceDifference >= StopGain)
       {
        OutputOrderMarket(StopGainVolume);
        StopGainAvaliable = false;
        BreakEvenActivated = false;
        return true;
       }
    return false;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OutputOrderLimitStopGainProcess(bool &StopGainAvaliable, double StopGain, int StopGainVolume)
   {
    int orderTotal = OrdersTotal() + PositionsTotal();
    if(StopGainAvaliable && orderTotal == 1)
       {
        OutputOrderLimit(StopGain, StopGainVolume);
        StopGainAvaliable = false;
        BreakEvenActivated = false;
        return true;
       }
    return false;
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OutputOrderMarket(int Volume)
   {
    PositionSelect(_Symbol);
    ENUM_POSITION_TYPE PositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    string comment = "Market StopGain";

    if(PositionType == POSITION_TYPE_SELL)
       {
        trade.Buy(Volume, _Symbol, 0, 0, 0, comment);
       }
    else
        if(PositionType == POSITION_TYPE_BUY)
           {
            trade.Sell(Volume, _Symbol, 0, 0, 0, comment);
           }
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OutputOrderLimit(double StopGain, int Volume)
   {
    PositionSelect(_Symbol);
    double PositionPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
    double PositionPriceCurrent = priceInformation[0].close;
    ENUM_POSITION_TYPE PositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

    double PositionPriceDifference = PositionPriceCurrent - PositionPriceOpen;
    if(PositionType == POSITION_TYPE_SELL)
        PositionPriceDifference = PositionPriceOpen - PositionPriceCurrent;

    string comment = "Limit StopGain";

    if(PositionType == POSITION_TYPE_SELL)
       {
        double price =  fixPrice(PositionPriceOpen - StopGain);
        trade.BuyLimit(Volume, price, _Symbol, 0, 0, ORDER_TIME_GTC, TimeTradeServer(), comment);
       }
    else
        if(PositionType == POSITION_TYPE_BUY)
           {
            double price = fixPrice(PositionPriceOpen + StopGain);
            trade.SellLimit(Volume, price, _Symbol, 0, 0, ORDER_TIME_GTC, TimeTradeServer(), comment);
           }
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MayCloseAllPositions()
   {
    if(DailyCloseTime == 0)
       {
        return(false);
       }
    return CurrentTime >= DailyCloseTime;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions()
   {
    uint posOpened = PositionsTotal();
    for(uint i = 0; i < posOpened; i++)
       {
        ulong ticket = PositionGetTicket(i);
        Print("Closed Position no.: " + IntegerToString(ticket) + " by day trade time");
        trade.PositionClose(ticket);
       }
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CancelAllPendingOrders()
   {
    uint pendingOrders = OrdersTotal();
    for(uint i = 0; i < pendingOrders; i++)
       {
        ulong ticket = OrderGetTicket(i);
        Print("Canceled Order no.: " + IntegerToString(ticket) + " by day trade time");
        trade.OrderDelete(ticket);
       }
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &OnTradeTransaction,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
   {
    myOnTradeTransaction(OnTradeTransaction, request, result);
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InputOrder(bool buySignal, bool sellSignal)
   {
    if((buySignal || sellSignal) && lastProcessedBar.time != priceInformation[0].time)
       {
        double _positionVolume = fixVolumeValue(PositionVolume);

        if(orderSendType == oMarket)
           {
            if(buySignal)
               {
                string _comment = "Market Buy - ";
                trade.Buy(_positionVolume, _Symbol, 0, 0, 0, _comment);
               }
            else
                if(sellSignal)
                   {
                    string _comment = "Market Sell - " ;
                    trade.Sell(_positionVolume, _Symbol, 0, 0, 0, _comment);
                   }
           }
        else
            if(orderSendType == oLimit)
               {
                PositionSelect(_Symbol);
                ENUM_POSITION_TYPE PositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

                datetime _orderExpiration = TimeTradeServer() + limitOrderExecutionSeconds;
                //trade.SetDeviationInPoints(1000);
                //double _price = priceInformation[0].close;
                double _price = PositionType == POSITION_TYPE_SELL ?  SymbolInfoDouble(_Symbol, SYMBOL_ASKHIGH) :  SymbolInfoDouble(_Symbol, SYMBOL_BIDLOW);

                if(buySignal)
                   {
                    _price += limitOrderSpread;
                    string _comment = "Limit Buy - " ;
                    trade.BuyLimit(_positionVolume, _price, _Symbol, 0, 0, ORDER_TIME_GTC, _orderExpiration, _comment);
                   }
                else
                    if(sellSignal)
                       {
                        _price -= limitOrderSpread;
                        string _comment = "Sell - " ;
                        trade.SellLimit(_positionVolume, _price, _Symbol, 0, 0, ORDER_TIME_GTC, _orderExpiration, _comment);
                       }
               }
        CountDayTrades++;
        lastProcessedBar = priceInformation[0];

       }
   }

//+------------------------------------------------------------------+
//|  Process bars and return Buy and Sell signals                                                                |
//+------------------------------------------------------------------+
void getBuySellSignal(bool &outBuySignal, bool &outSellSignal)
   {
    MqlRates actionBar;
    static MqlRates referenceBar;

    if(operationMode == Close && IsNewCandle)
       {
        actionBar = priceInformation[1];
        if(operationDisruption == Previous)
            referenceBar = priceInformation[2];
        else
            if(operationDisruption == Reference && referenceBar.time == NULL)
               {
                referenceBar = priceInformation[1];
               }
       }
    else
        if(operationMode == Open)
           {
            actionBar = priceInformation[0];
            if(operationDisruption == Previous)
                referenceBar = priceInformation[1];
            else
                if(operationDisruption == Reference && referenceBar.time == NULL)
                   {
                    referenceBar = priceInformation[1];
                   }
           }


//-- If reference candle is smaller than DY will remove buy and sell signals
    if(input_filterDxDyMode == fDY
       && MathAbs(referenceBar.high - referenceBar.low) < DY)
       {
        outBuySignal = false;
        outSellSignal = false;
        return;
       }

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
        outSellSignal = (referenceBar.low - DX) > actionBar.low;

//-- AgainstTrend
    if(operationDirection == AgainstTrend)
       {
        bool aux = outBuySignal;
        outBuySignal = outSellSignal;
        outSellSignal = aux;
       }
   }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double fixVolumeValue(double dblLots)
   {
    double
    dblLotsMinimum = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN),
    dblLotsMaximum = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX),
    dblLotsStep    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

// Adjust Volume for allowable conditions
    double   dblLotsNext = fmin(dblLotsMaximum,                          // Prevent too greater volume
                                fmax(dblLotsMinimum,                     // Prevent too smaller volume
                                     round(dblLots) * dblLotsStep));     // Align to Step value

    return (dblLotsNext);
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double fixPrice(double price)
   {
    double tick_Volume = 5;///SymbolInfoDouble (_Symbol, SYMBOL_TRADE_TICK_Volume);
    double _price = round(price / tick_Volume) * tick_Volume ;
    return (_price);
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
