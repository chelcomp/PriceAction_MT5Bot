enum enum_AllowedTimeFrame   // Time Frame
  {
   tfCurrent = 0,      // [0] Current
  
   tfOne = 1,          // [1]  1 Minute
   tfTwo = 5,          // [2]  5 Minute
   tfFive = 10,        // [3] 10 Minute
   tfFifteem = 15,     // [4] 15 Minute
   tfThirty = 30,      // [5] 30 Minute
   tfsixty = 60,       // [6] 60 Minute
    
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES AllowedTimeFrame2TimeFrame(enum_AllowedTimeFrame _timeFrame)
  {
  
   switch(_timeFrame)
     {
      case tfOne :
         return(PERIOD_M1);
      case tfTwo :
         return(PERIOD_M2);
      case tfFive :
         return(PERIOD_M5);
      case tfFifteem :
         return(PERIOD_M15);
      case tfThirty :
         return(PERIOD_M30);
      case tfsixty :
         return(PERIOD_H1);
     }
     
   return(PERIOD_CURRENT);
  }

