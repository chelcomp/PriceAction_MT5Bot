//+------------------------------------------------------------------+
//|                                                      PriceAction |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
MqlTradeTransaction LastTradeTransaction;
MqlTradeRequest LastTradeRequest;
MqlTradeResult LastTradeResult;


//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void myOnTradeTransaction(const MqlTradeTransaction &trans,
                          const MqlTradeRequest &request,
                          const MqlTradeResult &result)
   {

    LastTradeTransaction = trans;
    LastTradeRequest = request;
    LastTradeResult = result;

//---
    static int counter = 0; // counter of OnTradeTransaction() calls
    static uint lasttime = 0; // time of the OnTradeTransaction() last call
//---
    uint time = GetTickCount();
//--- if the last transaction was performed more than 1 second ago,
    if(time - lasttime > 1000)
       {
        counter = 0; // then this is a new trade operation, an the counter can be reset
        if(IS_DEBUG_MODE)
            Print(" New trade operation");
       }
    lasttime = time;
    counter++;
    Print(counter, ". ", __FUNCTION__);
//--- result of trade request execution
    ulong            lastOrderID   = trans.order;
    ENUM_ORDER_TYPE  lastOrderType = trans.order_type;
    ENUM_ORDER_STATE lastOrderState = trans.order_state;
//--- the name of the symbol, for which a transaction was performed
    string trans_symbol = trans.symbol;
//--- type of transaction
    ENUM_TRADE_TRANSACTION_TYPE  trans_type = trans.type;
    switch(trans.type)
       {
        case  TRADE_TRANSACTION_POSITION:   // position modification
           {
            ulong pos_ID = trans.position;
            PrintFormat("TradeTransaction: Position  #%d %s modified: SL=%.5f TP=%.5f",
                        pos_ID, trans_symbol, trans.price_sl, trans.price_tp);
           }
        break;
        case TRADE_TRANSACTION_REQUEST:     // sending a trade request
            PrintFormat("TradeTransaction: TRADE_TRANSACTION_REQUEST");
            break;
        case TRADE_TRANSACTION_DEAL_ADD:    // adding a trade
           {
            ulong          lastDealID     = trans.deal;
            ENUM_DEAL_TYPE lastDealType   = trans.deal_type;
            double         lastDealVolume = trans.volume;
            //--- Trade ID in an external system - a ticket assigned by an exchange
            string Exchange_ticket = "";
            if(HistoryDealSelect(lastDealID))
                Exchange_ticket = HistoryDealGetString(lastDealID, DEAL_EXTERNAL_ID);
            if(Exchange_ticket != "")
                Exchange_ticket = StringFormat("(Exchange deal=%s)", Exchange_ticket);

            PrintFormat("TradeTransaction: %s deal #%d %s %s %.2f lot   %s", EnumToString(trans_type),
                        lastDealID, EnumToString(lastDealType), trans_symbol, lastDealVolume, Exchange_ticket);
           }
        break;
        case TRADE_TRANSACTION_HISTORY_ADD: // adding an order to the history
           {
            //--- order ID in an external system - a ticket assigned by an Exchange
            string Exchange_ticket = "";
            if(lastOrderState == ORDER_STATE_FILLED)
               {
                if(HistoryOrderSelect(lastOrderID))
                    Exchange_ticket = HistoryOrderGetString(lastOrderID, ORDER_EXTERNAL_ID);
                if(Exchange_ticket != "")
                    Exchange_ticket = StringFormat("(Exchange ticket=%s)", Exchange_ticket);
               }
            PrintFormat("TradeTransaction: %s order #%d %s %s %s   %s", EnumToString(trans_type),
                        lastOrderID, EnumToString(lastOrderType), trans_symbol, EnumToString(lastOrderState), Exchange_ticket);
           }
        break;
        default: // other transactions
           {
            //--- order ID in an external system - a ticket assigned by Exchange
            string Exchange_ticket = "";
            if(lastOrderState == ORDER_STATE_PLACED)
               {
                if(OrderSelect(lastOrderID))
                    Exchange_ticket = OrderGetString(ORDER_EXTERNAL_ID);
                if(Exchange_ticket != "")
                    Exchange_ticket = StringFormat("Exchange ticket=%s", Exchange_ticket);
               }
            PrintFormat("TradeTransaction: %s order #%d %s %s   %s", EnumToString(trans_type),
                        lastOrderID, EnumToString(lastOrderType), EnumToString(lastOrderState), Exchange_ticket);
           }
        break;
       }
//--- order ticket
    ulong orderID_result = result.order;
    string retcode_result = GetRetcodeID(result.retcode);
    if(orderID_result != 0)
        PrintFormat("MqlTradeResult: order #%d retcode=%s ", orderID_result, retcode_result);
//---
   }
//+------------------------------------------------------------------+
//| convert numeric response codes to string mnemonics               |
//+------------------------------------------------------------------+
string GetRetcodeID(int retcode)
   {
    switch(retcode)
       {
        case 10004:
            return("TRADE_RETCODE_REQUOTE");
            break;
        case 10006:
            return("TRADE_RETCODE_REJECT");
            break;
        case 10007:
            return("TRADE_RETCODE_CANCEL");
            break;
        case 10008:
            return("TRADE_RETCODE_PLACED");
            break;
        case 10009:
            return("TRADE_RETCODE_DONE");
            break;
        case 10010:
            return("TRADE_RETCODE_DONE_PARTIAL");
            break;
        case 10011:
            return("TRADE_RETCODE_ERROR");
            break;
        case 10012:
            return("TRADE_RETCODE_TIMEOUT");
            break;
        case 10013:
            return("TRADE_RETCODE_INVALID");
            break;
        case 10014:
            return("TRADE_RETCODE_INVALID_VOLUME");
            break;
        case 10015:
            return("TRADE_RETCODE_INVALID_PRICE");
            break;
        case 10016:
            return("TRADE_RETCODE_INVALID_STOPS");
            break;
        case 10017:
            return("TRADE_RETCODE_TRADE_DISABLED");
            break;
        case 10018:
            return("TRADE_RETCODE_MARKET_CLOSED");
            break;
        case 10019:
            return("TRADE_RETCODE_NO_MONEY");
            break;
        case 10020:
            return("TRADE_RETCODE_PRICE_CHANGED");
            break;
        case 10021:
            return("TRADE_RETCODE_PRICE_OFF");
            break;
        case 10022:
            return("TRADE_RETCODE_INVALID_EXPIRATION");
            break;
        case 10023:
            return("TRADE_RETCODE_ORDER_CHANGED");
            break;
        case 10024:
            return("TRADE_RETCODE_TOO_MANY_REQUESTS");
            break;
        case 10025:
            return("TRADE_RETCODE_NO_CHANGES");
            break;
        case 10026:
            return("TRADE_RETCODE_SERVER_DISABLES_AT");
            break;
        case 10027:
            return("TRADE_RETCODE_CLIENT_DISABLES_AT");
            break;
        case 10028:
            return("TRADE_RETCODE_LOCKED");
            break;
        case 10029:
            return("TRADE_RETCODE_FROZEN");
            break;
        case 10030:
            return("TRADE_RETCODE_INVALID_FILL");
            break;
        case 10031:
            return("TRADE_RETCODE_CONNECTION");
            break;
        case 10032:
            return("TRADE_RETCODE_ONLY_REAL");
            break;
        case 10033:
            return("TRADE_RETCODE_LIMIT_ORDERS");
            break;
        case 10034:
            return("TRADE_RETCODE_LIMIT_VOLUME");
            break;
        case 10035:
            return("TRADE_RETCODE_INVALID_ORDER");
            break;
        case 10036:
            return("TRADE_RETCODE_POSITION_CLOSED");
            break;
        default:
            return("TRADE_RETCODE_UNKNOWN=" + IntegerToString(retcode));
            break;
       }
//---
   }
//+------------------------------------------------------------------+
