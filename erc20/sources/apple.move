module erc20::apple {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct APPLE has drop {}

    fun init(witness: APPLE, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(witness, 9, b"APPLE", b"Apple", b"", option::none(), ctx);
        transfer::public_freeze_object(metadata);
        transfer::public_share_object(treasury)
    }

    public entry fun public_transfer(object: Coin<APPLE>, recipient: address) {
        transfer::public_transfer(object, recipient)
    }


    public entry fun mint(cap: &mut TreasuryCap<APPLE>, value: u64, ctx: &mut TxContext) {
        let apple = coin::mint(cap, value, ctx);
        transfer::public_transfer(apple, tx_context::sender(ctx))
    }
}
