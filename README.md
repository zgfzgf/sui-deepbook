# deepbook(match + swap)

**caballeros 研究员 zgf**
**diem(libra)(aptos) 源代码贡献者**


## 源码解读

学习源代码过程，先复习的中心交易所的撮合系统，再看代码就比较容易理解。代码难度主要业务，如果从代码角度来看与sui_programmability/examples下面代码难度相同。
deepbook就是中心化交易所的撮合系统与实时交易结合体，就是把中心化的撮合系统用Move开发，同时增加接口实现实时交易(不需要帐户)。
为更好理解源代码，从创建交易对角色，限价挂单角色，实时交易角色来解读代码，同时也列出中心化交易所与实时交易的函数。

### 源代码结构

mystenLabs/sui/crates/sui-framework/packages/deepbook/sources
├── clob.move 核心代码实现
├── critbit.move critbit树实现(critbit rust实现，不需要太多观注，也可以参考treemap)
├── custodian.move 资产管理
└── math.move 工具类

#### 订单存储结构体

```
struct TickLevel has store {
    price: u64,
    // The key is order order id.
    open_orders: LinkedTable<u64, Order>, //u64 订单号
}

struct CritbitTree<V: store> has store{ // V为TickLevel
    root: u64,
    internal_nodes: Table<u64, InternalNode>,
    // A leaf contains orders at that price level.
    leaves: Table<u64, Leaf<V>>,
    min_leaf: u64,
    max_leaf: u64,
    next_internal_node_index: u64,
    next_leaf_index: u64
}
```

critbit树的实现节点的价格排序
各个节点是同一个价格表
这个俩个结构体是重点，别的结构体与原来中心化交易所基本一样

### 创建交易对角色

```
public fun create_pool<BaseAsset, QuoteAsset>(
        tick_size: u64,
        lot_size: u64,
        creation_fee: Coin<SUI>,
        ctx: &mut TxContext,
    ) { ... ... }
```

与中心交易所的主要区别creation_fee,创建交易对的费用为100SUI。
可以理解为初始化订存储结构体与参数，taker_fee_rate与maker_rebate_rate是常量，以后接口有可能会这俩个参数。
交易对的Pool是共享对象。
创建交易对角色现在只有这一个接口。现在交易费用无法使用，能否提供接口给社区等等？

```
struct Pool<phantom BaseAsset, phantom QuoteAsset> has key {
        ... ...
        /// Stores the fee paid to create this pool. These funds are not accessible.
        creation_fee: Balance<SUI>,  // 现在为100SUI
        /// Stores the trading fees paid in `BaseAsset`. These funds are not accessible.
        base_asset_trading_fees: Balance<BaseAsset>,
         /// Stores the trading fees paid in `QuoteAsset`. These funds are not accessible.
        quote_asset_trading_fees: Balance<QuoteAsset>,
    }
```

这代块码的个人心得体会：要多看注释(这块代码注释整体比较好)，原来以为这些费用可以提取的，这也是与中心化交易所不同的地方

### 限价挂单角色

限价挂单角色需要有帐户，另的角色不需要帐户。这块代码基本就是中心交易所的Move实现。

```
public fun create_account(ctx: &mut TxContext): AccountCap {
        mint_account_cap(ctx)
    }
     public fun mint_account_cap(ctx: &mut TxContext): AccountCap {
        AccountCap { id: object::new(ctx) }
    }
```

可以看到Move创建帐户就是一个UID，这是Move最简单的对象。
接下中心交易所里该充值交易了

```
public fun deposit_base<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        coin: Coin<BaseAsset>,
        account_cap: &AccountCap
    ) {
        custodian::increase_user_available_balance(&mut pool.base_custodian, object::id(account_cap), coin::into_balance(coin))
    }
```

```
struct Account<phantom T> has store {
        available_balance: Balance<T>,
        locked_balance: Balance<T>,
    }
```

资金的操作都在custodian实现，上面代码可以看到充值就是放在available帐户上面(后面的提现代码差不多一样的)。从上面结构体可以分析出来生成委托单时从available帐户到locked帐户，与中心化交易所完全一样。
充值就可以挂单了

```
public fun place_limit_order<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        price: u64,
        quantity: u64,
        is_bid: bool,
        expire_timestamp: u64, // Expiration timestamp in ms in absolute value inclusive.
        restriction: u8,
        clock: &Clock,
        account_cap: &AccountCap,
        ctx: &mut TxContext
    ): (u64, u64, bool, u64) {
        ... ...
        let user = object::id(account_cap);
        ... ...

        if (is_bid) {
            ... ... 与下面类似
        } else {
            ... ... 
            let (base_balance_left, quote_balance_filled) = match_ask(
                pool,
                price,
                clock::timestamp_ms(clock),
                base_balance,
            );
            ... ...
            
        };

        let order_id;
        if (restriction == IMMEDIATE_OR_CANCEL) {
            return (base_quantity_filled, quote_quantity_filled, false, 0)
        };
        if (restriction == FILL_OR_KILL) {
            assert!(base_quantity_filled == quantity, EOrderCannotBeFullyFilled);
            return (base_quantity_filled, quote_quantity_filled, false, 0)
        };
        if (restriction == POST_OR_ABORT) {
            assert!(base_quantity_filled == 0, EOrderCannotBeFullyPassive);
            order_id = inject_limit_order(pool, price, quantity, is_bid, expire_timestamp, account_cap, ctx);
            return (base_quantity_filled, quote_quantity_filled, true, order_id)
        } else {
            assert!(restriction == NO_RESTRICTION, EInvalidRestriction);
            order_id = inject_limit_order(pool, price,
                quantity - base_quantity_filled,
                is_bid, expire_timestamp,account_cap, ctx);
            return (base_quantity_filled, quote_quantity_filled, true, order_id)
        }
    }
```

从上面代码可以看到首先撮合交易。撮合交易代码后面会详解。restriction为NO_RESTRICTION例子说明:
撮合交易后，然后用剩余quantity去生成委托单，初次测试最用NO_RESTRICTION
这次撮合成功或者委托单以后被另的单子撮合，就可以提现。提现代码与充值类似。
还有一个取消委托单的函数，就是删除委托单，解锁账单。

```
public fun cancel_order<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        order_id: u64,
        account_cap: &AccountCap
    )
```

### 实时交易角色

市场价交易

```
public fun place_market_order<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        quantity: u64,
        is_bid: bool,
        base_coin: Coin<BaseAsset>,
        quote_coin: Coin<QuoteAsset>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): (Coin<BaseAsset>, Coin<QuoteAsset>) {
        if (is_bid) {
            ... ... 与下面类似
        } else {
            assert!(quantity <= coin::value(&base_coin), EInvalidBaseCoin);
            let (base_balance_left, quote_balance_filled) = match_ask(
                pool,
                MIN_PRICE,
                clock::timestamp_ms(clock),
                coin::into_balance(base_coin),
            );
            base_coin = coin::from_balance(base_balance_left, ctx);
            join(
                &mut quote_coin,
                coin::from_balance(quote_balance_filled, ctx),
            );
        };
        (base_coin, quote_coin)
    }
```

市场价成交就是就是只用撮合交易，这也是中心化交易所里面的实时交易，不过中心化交易所的实时交易需要帐户，同时需要充值与提现操作。

```
// for smart routing
    public fun swap_exact_base_for_quote<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        quantity: u64,
        base_coin: Coin<BaseAsset>,
        quote_coin: Coin<QuoteAsset>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): (Coin<BaseAsset>, Coin<QuoteAsset>, u64) {
        let original_val = coin::value(&quote_coin);
        let (ret_base_coin, ret_quote_coin) = place_market_order(... ...
        );
        let ret_val = coin::value(&ret_quote_coin);
        (ret_base_coin, ret_quote_coin, ret_val - original_val)
    }
```

swap_exact_quote_for_base也类似

### 中心化交易所函数

public fun place_limit_order 限价挂单

public fun create_account 创建账户
public fun create_pool 创建交易池

public fun deposit_base 充值
public fun deposit_quote 充值

public fun withdraw_base 提现
public fun withdraw_quote 提现

public fun cancel_order 取消订单
public fun cancel_all_orders(参考cancel_order)
public fun batch_cancel_order(参考cancel_order)

### 实时交易函数

public fun swap_exact_base_for_quote 实时交易
public fun swap_exact_quote_for_base 实时交易
public fun place_market_order(原来中心化交易所函数) 市场价成交

### 视图函数

public fun list_open_orders  账户的订单
public fun account_balance 账户的资产

public fun get_level2_book_status_bid_side 买单深度
public fun get_level2_book_status_ask_side 卖单深度
public fun get_order_status 订单状态(代码错误?)

### 主要内部函数

fun match_ask 撮合卖单
fun match_bid 撮合买单
fun match_bid_with_quote_quantity 参考match_bid
fun inject_limit_order 下委托单
match_ask与match_bid的原理相同的，只讲解其一就行了

### match的原理

按照价格优先，相同价格情况的挂单时间优先去成交
代码用到俩个while语句。第一个while就是用critbit找到最优价格，第二个while就是用linked_table的相同价格的最早挂单时间

### match_ask的源代码注释

```
fun match_ask<BaseAsset, QuoteAsset>(
    pool: &mut Pool<BaseAsset, QuoteAsset>,
    price_limit: u64,
    current_timestamp: u64,
    base_balance: Balance<BaseAsset>,
): (Balance<BaseAsset>, Balance<QuoteAsset>) {
    ... ... 
    let all_open_orders = &mut pool.bids;
    if (critbit::is_empty(all_open_orders)) {
        return (base_balance_left, quote_balance_filled)
    };
    let (tick_price, tick_index) = max_leaf(all_open_orders);
    while (!is_empty<TickLevel>(all_open_orders) && tick_price >= price_limit) {  // critbit树的节点
        let tick_level = borrow_mut_leaf_by_index(all_open_orders, tick_index);
        let order_id = *option::borrow(linked_table::front(&tick_level.open_orders));
        while (!linked_table::is_empty(&tick_level.open_orders)) { // 节点的TickLevel 
            ... ...

            if (maker_order.expire_timestamp <= current_timestamp) {
                ... ...
            } else {
                //  撮合交易
                let taker_base_quantity_remaining = balance::value(&base_balance_left);  // 成交单剩余资产
                let filled_base_quantity =
                    if (taker_base_quantity_remaining >= maker_base_quantity) { maker_base_quantity } // 成交量
                    else { taker_base_quantity_remaining };
                // filled_quote_quantity from maker, need to round up, but do in decrease stage
                let filled_quote_quantity = clob_math::mul(filled_base_quantity, maker_order.price); // 成交金额
                // rebate_fee to maker, no need to round up
                let maker_rebate = clob_math::mul(filled_quote_quantity, pool.maker_rebate_rate);  // 委托费用
                let (is_round_down, taker_commission) = clob_math::mul_round(filled_quote_quantity, pool.taker_fee_rate);
                if (is_round_down) taker_commission = taker_commission + 1; // 成交费用 

                maker_base_quantity = maker_base_quantity - filled_base_quantity; // 完成这一笔交易后委托单剩余资产
                // maker in bid side, decrease maker's locked quote asset, increase maker's available base asset
                let locked_quote_balance = custodian::decrease_user_locked_balance<QuoteAsset>(
                    &mut pool.quote_custodian,
                    maker_order.owner,
                    filled_quote_quantity
                ); // 减少委托单locker的base资产 
                let taker_commission_balance = balance::split(
                    &mut locked_quote_balance,
                    taker_commission,
                ); // 成交费用账单 
                custodian::increase_user_available_balance<QuoteAsset>(
                    &mut pool.quote_custodian,
                    maker_order.owner,
                    balance::split(
                        &mut taker_commission_balance,
                        maker_rebate,
                    ),
                ); 增加委托单的available资产的委托费用
                balance::join(&mut pool.quote_asset_trading_fees, taker_commission_balance); // 增加池费用账单(成交费用-委托费用)
                balance::join(&mut quote_balance_filled, locked_quote_balance); 增加成交单账单 (委托单成交账单 - 成交费用)

                custodian::increase_user_available_balance<BaseAsset>(
                    &mut pool.base_custodian,
                    maker_order.owner,
                    balance::split(
                        &mut base_balance_left,
                        filled_base_quantity,
                    ),
                );  // 增加委托单报价账单available资产
                ... ... 事件              
            };

            if (skip_order || maker_base_quantity == 0) {
               ... ... 
            } else {
                ... ...
            };
            if (balance::value(&base_balance_left) == 0) {
                break
            };
        };
        if (linked_table::is_empty(&tick_level.open_orders)) {
            ... ...
        };
        if (balance::value(&base_balance_left) == 0) {
            break
        };
    };
    return (base_balance_left, quote_balance_filled)
}
```

### 术语

clob (central limit order book) 中央限价订单簿
match 撮合
BaseAsset/QuoteAsset 例子:BTC/USD，BTC是基础资产，USD是报价资产
bid price 买方出价
ask price 卖方出价
market  市价成交
limit  限价成交
maker order 委托单
take order 成交单
tick-size 最小报价单位
lot_size 最小交易单位

### deepbook代码问题

lot_size的实现还有点问题，swap_exact_quote_for_base函数等
对public fun get_order_status<BaseAsset, QuoteAsset>(... ...): &Order的返回值还有疑惑
