use overdrive::models::{account_models::{Garage, Account, AccountTrait}};
use overdrive::constants;
use starknet::ContractAddress;

#[dojo::interface]
trait IAccountActions {
    fn create_account(ref world: IWorldDispatcher, username: felt252);
    fn get_account(ref world: IWorldDispatcher);
}

#[dojo::contract]
mod accountActions {
    use super::{IAccountActions, Garage, Account, AccountTrait, constants};
    use starknet::{ContractAddress, get_caller_address};

    #[abi(embed_v0)]
    impl AccountActionsImpl of IAccountActions<ContractState> {
        fn create_account(ref world: IWorldDispatcher, username: felt252) {
            let owner = get_caller_address();

            let new_account: Account = AccountTrait::new(username, owner);

            // let mut existing_account = get!(world, owner, (Account));
            // assert(existing_account.username == username, constants::USERNAME_TAKEN);

            set!(world, (new_account));
        }

        fn get_account(ref world: IWorldDispatcher) {
            let address = get_caller_address();

            let account = get!(world, address, (Account));

            println!(
                "USERNAME: {}, PLAYED: {}, WINS: {}",
                account.username,
                account.total_games_played,
                account.total_games_won
            );
        }
    }
}
