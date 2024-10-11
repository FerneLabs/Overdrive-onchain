use overdrive::models::{player_models::{Garage, Account, AccountTrait}};

pub mod Errors {
    pub const ADDRESS_ZERO: felt252 = 'Cannot create from zero address';
    pub const USERNAME_TAKEN: felt252 = 'username already taken';
    pub const USERNAME_NOT_FOUND: felt252 = 'player with username not found';
    pub const USERNAME_EXIST: felt252 = 'username already exist';
    pub const ONLY_OWNER_USERNAME: felt252 = 'only user can udpate username';
}

#[dojo::interface]
trait IPlayerActions {
    fn create_account(ref world: IWorldDispatcher, username: felt252);
    fn get_account(ref world: IWorldDispatcher);
}

#[dojo::contract]
mod playerActions {
    use super::Errors;
    use super::{IPlayerActions, Garage, Account, AccountTrait};
    use starknet::{ContractAddress, get_caller_address};

    #[abi(embed_v0)]
    impl PlayerActionsImpl of IPlayerActions<ContractState> {
        fn create_account(ref world: IWorldDispatcher, username: felt252) {
            let owner = get_caller_address();

            let new_account: Account = AccountTrait::new(username, owner);

            // let mut existing_account = get!(world, owner, (Account));

            // assert(existing_account.username == username, Errors::USERNAME_TAKEN);

            set!(world, (new_account));
        }

        fn get_account(ref world: IWorldDispatcher) {
            let player = get_caller_address();

            let account = get!(world, player, (Account));

            println!(
                "USERNAME: {}, PLAYED: {}, WINS: {}",
                account.username,
                account.total_games_played,
                account.total_games_won
            );
        }
    }
}
