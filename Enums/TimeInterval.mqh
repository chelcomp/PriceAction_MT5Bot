//+------------------------------------------------------------------+
//|                                                      PriceAction |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
enum enum_TimeInterval
   {
    t0000, // -
    t0900, // 9:00
    t0905, // 9:05
    t0910, // 9:10
    t0915, // 9:15
    t0920, // 9:20
    t0925, // 9:25
    t0930, // 9:30
    t0935, // 9:35
    t0940, // 9:40
    t0945, // 9:45
    t0950, // 9:50
    t0955, // 9:55
    t1000, // 10:00
    t1005, // 10:05
    t1010, // 10:10
    t1015, // 10:15
    t1020, // 10:20
    t1025, // 10:25
    t1030, // 10:30
    t1035, // 10:35
    t1040, // 10:40
    t1045, // 10:45
    t1050, // 10:50
    t1055, // 10:55
    t1100, // 11:00
    t1105, // 11:05
    t1110, // 11:10
    t1115, // 11:15
    t1120, // 11:20
    t1125, // 11:25
    t1130, // 11:30
    t1135, // 11:35
    t1140, // 11:40
    t1145, // 11:45
    t1150, // 11:50
    t1155, // 11:55
    t1200, // 12:00
    t1205, // 12:05
    t1210, // 12:10
    t1215, // 12:15
    t1220, // 12:20
    t1225, // 12:25
    t1230, // 12:30
    t1235, // 12:35
    t1240, // 12:40
    t1245, // 12:45
    t1250, // 12:50
    t1255, // 12:55
    t1300, // 13:00
    t1305, // 13:05
    t1310, // 13:10
    t1315, // 13:15
    t1320, // 13:20
    t1325, // 13:25
    t1330, // 13:30
    t1335, // 13:35
    t1340, // 13:40
    t1345, // 13:45
    t1350, // 13:50
    t1355, // 13:55
    t1400, // 14:00
    t1405, // 14:05
    t1410, // 14:10
    t1415, // 14:15
    t1420, // 14:20
    t1425, // 14:25
    t1430, // 14:30
    t1435, // 14:35
    t1440, // 14:40
    t1445, // 14:45
    t1450, // 14:50
    t1455, // 14:55
    t1500, // 15:00
    t1505, // 15:05
    t1510, // 15:10
    t1515, // 15:15
    t1520, // 15:20
    t1525, // 15:25
    t1530, // 15:30
    t1535, // 15:35
    t1540, // 15:40
    t1545, // 15:45
    t1550, // 15:50
    t1555, // 15:55
    t1600, // 16:00
    t1605, // 16:05
    t1610, // 16:10
    t1615, // 16:15
    t1620, // 16:20
    t1625, // 16:25
    t1630, // 16:30
    t1635, // 16:35
    t1640, // 16:40
    t1645, // 16:45
    t1650, // 16:50
    t1655, // 16:55
    t1700, // 17:00
    t1705, // 17:05
    t1710, // 17:10
    t1715, // 17:15
    t1720, // 17:20
    t1725, // 17:25
    t1730, // 17:30
    t1735, // 17:35
    t1740, // 17:40
    t1745, // 17:45
    t1750, // 17:50
    t1755, // 17:55
    t1800, // 18:00
    t1805, // 18:05
    t1810, // 18:10
    t1815, // 18:15
    t1820  // 18:20
   };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime TimeIntervalToTime(enum_TimeInterval timeInterval)
   {
    string auxTime1 = EnumToString(timeInterval);
    datetime auxTime2 = StringToTime(StringFormat("1970.01.01 %s:%s", StringSubstr(auxTime1, 1, 2), StringSubstr(auxTime1, 3, 2)));
    return(auxTime2);
   }
//+------------------------------------------------------------------+
