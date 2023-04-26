module match::order {
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::clock::Clock;
    use sui::transfer;
    use sui::tx_context::{Self,TxContext};
    use deepbook::clob;
    use deepbook::custodian::AccountCap;

    public entry fun create<BaseAsset, QuoteAsset>(
        tick_size: u64, 
        lot_size: u64, 
        creation_fee: Coin<SUI>, 
        ctx: &mut TxContext
    ) {
        clob::create_pool<BaseAsset, QuoteAsset>(tick_size, lot_size, creation_fee, ctx)
    }

    public entry fun create_account(ctx: &mut TxContext) {
        let account1 = clob::create_account(ctx);
        transfer::public_transfer(account1, tx_context::sender(ctx));
    }

    public entry fun deposit_base<BaseAsset, QuoteAsset>(pool: &mut clob::Pool<BaseAsset, QuoteAsset>, coin: Coin<BaseAsset>, account_cap: &AccountCap){
        clob::deposit_base(pool, coin, account_cap)
    }

    public entry fun deposit_quote<BaseAsset, QuoteAsset>(pool: &mut clob::Pool<BaseAsset, QuoteAsset>, coin: Coin<QuoteAsset>, account_cap: &AccountCap){
        clob::deposit_quote(pool, coin, account_cap)
    }

    public entry fun withdraw_base<BaseAsset, QuoteAsset>(
        pool: &mut clob::Pool<BaseAsset, QuoteAsset>,
        quantity: u64,
        account_cap: &AccountCap,
        ctx: &mut TxContext
    ){
        let apple = clob::withdraw_base(pool, quantity, account_cap, ctx);
        transfer::public_transfer(apple, tx_context::sender(ctx))
    }

    public entry fun withdraw_quote<BaseAsset, QuoteAsset>(
        pool: &mut clob::Pool<BaseAsset, QuoteAsset>,
        amount: u64,
        account_cap: &AccountCap,
        ctx: &mut TxContext
    ){
        let dai = clob::withdraw_quote(pool, amount, account_cap, ctx);
        transfer::public_transfer(dai, tx_context::sender(ctx))
    }

    public entry fun place_limit_order<BaseAsset, QuoteAsset>(
        pool: &mut clob::Pool<BaseAsset, QuoteAsset>,
        price: u64,
        quantity: u64,
        is_bid: bool,
        expire_timestamp: u64,
        restriction: u8,
        clock: &Clock,
        account_cap: &AccountCap,
        ctx: &mut TxContext
    ) {
        clob::place_limit_order(
            pool,
            price,
            quantity,
            is_bid,
            expire_timestamp,
            restriction,
            clock,
            account_cap,
            ctx);

    }

    public entry fun cancel_order<BaseAsset, QuoteAsset>(
        pool: &mut clob::Pool<BaseAsset, QuoteAsset>,
        order_id: u64,
        account_cap: &AccountCap
    ){
        clob::cancel_order(pool, order_id, account_cap)
    }

    public entry fun cancel_all_orders<BaseAsset, QuoteAsset>(
        pool: &mut clob::Pool<BaseAsset, QuoteAsset>,
        account_cap: &AccountCap
    ){
        clob::cancel_all_orders(pool, account_cap)
    }

    public entry fun batch_cancel_order<BaseAsset, QuoteAsset>(
        pool: &mut clob::Pool<BaseAsset, QuoteAsset>,
        order_ids: vector<u64>,
        account_cap: &AccountCap
    ){
        clob::batch_cancel_order(pool, order_ids, account_cap)
    }

    public entry fun place_market_order<BaseAsset, QuoteAsset>(
        pool: &mut clob::Pool<BaseAsset, QuoteAsset>,
        quantity: u64,
        is_bid: bool,
        base_coin: Coin<BaseAsset>,
        quote_coin: Coin<QuoteAsset>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let (apple, dai) = clob::place_market_order(
            pool,
            quantity,
            is_bid,
            base_coin,
            quote_coin,
            clock,
            ctx);

        transfer::public_transfer(apple, tx_context::sender(ctx));
        transfer::public_transfer(dai, tx_context::sender(ctx));    
    }
    
    public entry fun swap_exact_quote_for_base<BaseAsset, QuoteAsset>(
        pool: &mut clob::Pool<BaseAsset, QuoteAsset>,
        amount: u64,
        clock: &Clock,
        quote_coin: Coin<QuoteAsset>,
        ctx: &mut TxContext,
    ) {
        let (apple, dai, _) = clob::swap_exact_quote_for_base(
            pool,
            amount,
            clock,
            quote_coin,
            ctx);

        transfer::public_transfer(apple, tx_context::sender(ctx));
        transfer::public_transfer(dai, tx_context::sender(ctx));
    }

    public entry fun swap_exact_base_for_quote<BaseAsset, QuoteAsset>(
        pool: &mut clob::Pool<BaseAsset, QuoteAsset>,
        quantity: u64,
        base_coin: Coin<BaseAsset>,
        quote_coin: Coin<QuoteAsset>,
        clock: &Clock,
        ctx: &mut TxContext,
    ){
        let (apple, dai, _) = clob::swap_exact_base_for_quote(
            pool,
            quantity,
            base_coin,
            quote_coin,
            clock,
            ctx);
        transfer::public_transfer(apple, tx_context::sender(ctx));
        transfer::public_transfer(dai, tx_context::sender(ctx));
    }

    // view fun
    public fun get_level2_book_status_bid_side<BaseAsset, QuoteAsset>(
        pool: &clob::Pool<BaseAsset, QuoteAsset>,
        price_low: u64,
        price_high: u64,
        clock: &Clock
    ): (vector<u64>, vector<u64>){
        clob::get_level2_book_status_bid_side(pool, price_low, price_high, clock)
    }

    public fun get_level2_book_status_ask_side<BaseAsset, QuoteAsset>(
        pool: &clob::Pool<BaseAsset, QuoteAsset>,
        price_low: u64,
        price_high: u64,
        clock: &Clock
    ): (vector<u64>, vector<u64>) {
        clob::get_level2_book_status_ask_side(pool, price_low, price_high, clock)
    }

    public fun list_open_orders<BaseAsset, QuoteAsset>(
        pool: &clob::Pool<BaseAsset, QuoteAsset>,
        account_cap: &AccountCap
    ): vector<clob::Order> {
        clob::list_open_orders(pool, account_cap)
    }

    public fun account_balance<BaseAsset, QuoteAsset>(
        pool: &clob::Pool<BaseAsset, QuoteAsset>,
        account_cap: &AccountCap
    ): (u64, u64, u64, u64) {
        clob::account_balance(pool, account_cap)
    }
 /*
    // deepbook code build error!!!
    public fun get_order_status<BaseAsset, QuoteAsset>(
        pool: &clob::Pool<BaseAsset, QuoteAsset>,
        order_id: u64,
        account_cap: &AccountCap
    ): clob::Order {
        clob::get_order_status(pool, order_id, account_cap)
    }
*/   
}
