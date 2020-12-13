//+------------------------------------------------------------------+
//|                                                      PriceAction |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include "../Enums/AllowedTimeFrame.mqh"
#include "../Enums/CloseOrderType.mqh"
#include "../Enums/FilterDxDyMode.mqh"
#include "../Enums/OperationDirection.mqh"
#include "../Enums/OperationDirectionEnum.mqh"
#include "../Enums/OperationDisruption.mqh"
#include "../Enums/OperationMode.mqh"
#include "../Enums/OrderSendType.mqh"
#include "../Enums/TimeInterval.mqh"
#include "../Enums/StopAfterXTrades.mqh"


sinput string Comment1 = "NOT PRODUCTION ENABLED"; // PriceAction Bot - Only for study ( Demo Account ) on B3 and MBF
sinput string Comment2 = "This bot was created based on options available on Price Action bot, but there is no guarantee of equivalency."; // Disclaimer: No relation with Smarttbot.com.br
sinput string Comment3 = "michelpurper@gmail.com"; // Developper Contact
sinput string Comment4 = "FREE FOR USE"; // This bot can't be sold
input  string BotName  = ""; // Bot Name

//+------------------------------------------------------------------+
//|  Graphic input section                                           |
//+------------------------------------------------------------------+
input group "Graphic"
input enum_AllowedTimeFrame input_TimeFrame = tfCurrent; // Time Frame
input enum_OperationMode operationMode = Close; // Operation Mode
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  Operation Type input section                                    |
//+------------------------------------------------------------------+
input group "Operation Type"
input enum_OperationDisruption operationDisruption = Previous; // Operation disruption
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  Order Management input section                                  |
//+------------------------------------------------------------------+
input group "Order Management"
input int input_positionVolume = 2; // Position Volume (Quantity of Order or Contracts)
input enum_OperationDirection OperationDirection = odBoth; // Operation Direction
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  Entry Criteria input section                                    |
//+------------------------------------------------------------------+
input group "Entry Criteria"
input enum_OrderSendType orderSendType = oMarket; // Position Volume ( Quantity of Order or Contracts )


input ulong input_LimitOrderSpread = 5.0; // Limit order spread execution
input int input_LimitOrderExecutionSeconds = 60; // Limit order execution ( Seconds )
/*enum enum_LimitOrderExpirationAction
  {
   MarketExecution = 0, // Market Execution
   Cancel = 1 // Cancel
  };
input enum_LimitOrderExpirationAction limitOrderExpirationAction = Cancel; // Limit order operation action
*/

input operationDirectionEnum operationDirection = AgainstTrend; // Operation Direction
input enum_FilterDxDyMode input_filterDxDyMode = fNone; // Filter to use
input double filterDxDy = NULL; // Filter DX/DY
input double stockVariation = NULL; // Stock Variation %
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  Close Setup input section                                   |
//+------------------------------------------------------------------+
input group "Close Setup"
input enum_CloseOrderType input_StopGainOrderType = cMarket; // Order Gain Type

input double input_StopGain1 = 100; // Stop Gain 1
input double input_StopGain2 = NULL; // Stop Gain 2
input double input_StopGain3 = NULL; // Stop Gain 3
input double input_StopGain4 = NULL; // Stop Gain 4
input double input_StopGain5 = NULL; // Stop Gain 5
input bool Input_StopGainBreakEven = false; // Break Even ( Stop Gain )

input double input_StopLoss = 100; // Stop Loss
input double input_TrailingStopActivation = NULL; // Trailing Stop Activation
input double input_TrailingStopDistance = NULL; // Trailing Stop Movel Distance
//+------------------------------------------------------------------+






//+------------------------------------------------------------------+
//|  Close Daily Settings                                            |
//+------------------------------------------------------------------+
input group "Daily Restriction"
input double input_dailyStopLossMoney = NULL; // Stop Loss $
input double input_dailyStopGainMoney = NULL; // Stop Gain $

input enum_StopAfterXTrades input_StopAfterXTradesMode = saNone; // Stop after X Trades If Daily Balance
input int input_StopAfterXTrades = NULL; // Stop after X Trades

input double input_DailyBreakevenActivationMoney = NULL; //Breakeven Activation $
input double input_DailyBreakevenMaxDrownDownMoney = NULL; //Breakeven Max Drowndown $
//+------------------------------------------------------------------+






//+------------------------------------------------------------------+
//|  Daily Restriction                                               |
//+------------------------------------------------------------------+
input group "Daily Restriction - Operation Time Window"
input enum_TimeInterval  input_DailyBeginTime = t0900; // Open position Start time

//+------------------------------------------------------------------+
//|  Window1                                                         |
//+------------------------------------------------------------------+
input enum_TimeInterval  input_Window1BeginTime = t0000; // Window1: Begin
input enum_TimeInterval  input_Window1EndTime = t0000;  // Window1: End

//+------------------------------------------------------------------+
//| Window2                                                          |
//+------------------------------------------------------------------+
input enum_TimeInterval  input_Window2BeginTime = t0000; // Window2: Begin
input enum_TimeInterval  input_Window2EndTime = t0000;  // Window2: End
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  Close Daily Settings                                            |
//+------------------------------------------------------------------+
input enum_TimeInterval input_DailyEndTime = t1740;  // Stop open position time
input enum_TimeInterval input_DailyCloseTime = t1750; // Reset wallet

//+------------------------------------------------------------------+
//|  Trade Settings                                                  |
//+------------------------------------------------------------------+
input group "Setting"
input long input_MagicNumber = -1; // Magic Number
