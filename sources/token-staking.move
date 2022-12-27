//! Contract to stake objects in s
//! Created by Mokshya Protocol
module suistaking::tokenstaking
{
    use std::string::{Self,String};
    use std::vector;
    use std::hash;
    use std::bcs;
    use sui::object::{Self, UID,ID};
    use sui::transfer;
    use sui::sui::SUI;
    use sui::balance::{Self,Balance};
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};

    struct MokshyaStaking<phantom T> has key {
        id:UID,
        // amount of token paid in a week for staking one token,
        // changed to dpr (daily percentage return)in place of apr addressing demand
        dpr:u64,
        //SENDER
        sender:address,
        //the balance of coin to be distributed
        amount:Balance<T>,
    }
     struct AdminCap has key, store {
        id: UID,
        obj_id: ID,
    }

    struct MokshyaReward<phantom T> has key {
        id:UID,
        //staker
        staker:address,
        //balance
        amount:Balance<T>,
        //withdrawn amount
        withdraw_amount:u64,
        //time
        start_time:u64,
    }
    const ENO_NO_COLLECTION:u64=0;
    const ENO_STAKING_EXISTS:u64=1;
    const ENO_NO_STAKING:u64=2;
    const ENO_NO_TOKEN_IN_TOKEN_STORE:u64=3;
    const ENO_STOPPED:u64=4;
    const ENO_COINTYPE_MISMATCH:u64=5;
    const ENO_STAKER_MISMATCH:u64=6;
    const ENO_INSUFFICIENT_FUND:u64=7;
    const ENO_INSUFFICIENT_TOKENS:u64=7;


    //Functions

    //Function for creating and modifying staking
    public entry fun create_staking<T,D>(
        ctx: &mut TxContext,
        dpr:u64,//rate of payment,
        balance:Coin<T>,
        stake_coin: Coin<D>
    )
    {
        let sender = tx_context::sender(ctx);
        let balance = coin::into_balance(balance);
        let id = object::new(ctx);
        let obj_id = object::uid_to_inner(&id);
        let obj = MokshyaStaking { id, dpr,sender , amount:balance };
        transfer::share_object(obj);
        // give the creator admin permissions
        let admin_cap= AdminCap { id: object::new(ctx), obj_id };
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }
    //Functions for staking 
    public entry fun stake_token<T,P>(
        ctx: &mut TxContext,
        coin: Coin<T>,
        staking: &MokshyaStaking<P>,
        sender: address,
        amount:u64,
    )
    {
        let staker = tx_context::sender(ctx);
        let deposited_coin = coin::into_balance(coin);
        let id = object::new(ctx);
        let obj_id = object::uid_to_inner(&id);
        let withdraw_amount=0;
        let start_time=100000;
        let obj = MokshyaReward { id,staker,amount:deposited_coin,withdraw_amount,start_time };
        transfer::share_object(obj);
        // give the creator admin permissions
        let admin_cap= AdminCap { id: object::new(ctx), obj_id };
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    public entry fun receiver_reward<T,P>(
        ctx: &mut TxContext,
        staking: &mut MokshyaStaking<T>,
        reward: &mut MokshyaReward<P>,
        sender: address,
    )
    {
        let staker = tx_context::sender(ctx);
        let now = 200000;
        let value = balance::value( reward.amount);
        let payable_amount = ((now-reward.start_time)*value)/86400-reward.withdraw_amount;
        transfer::transfer(coin::take(staking.amount, payable_amount, ctx), staker);
        reward.withdraw_amount= reward.withdraw_amount+payable_amount;

    }
    public entry fun unstake_fund(
        ctx: &mut TxContext,
        staking: &mut MokshyaStaking,
        reward: &mut MokshyaReward,
        sender: address,
    )
    {
        let staker = tx_context::sender(ctx);
        let total_amount = staking.amount; 
        let now = 200000;
        let staked_amount = reward.amount;
        let value = Balance::value(staked_amount);
        let payable_amount = ((now-reward.start_time)*value)/86400-reward.withdraw_amount;
        transfer::transfer(coin::take(total_amount, payable_amount, ctx), staker);
        reward.withdraw_amount= reward.withdraw_amount+payable_amount;
        // transferring all the staked coins to the staker
          transfer::transfer(coin::take(staked_amount, value, ctx), staker);
    }
}


