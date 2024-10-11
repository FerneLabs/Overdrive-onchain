use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Garage {
    #[key]
    pub player: ContractAddress,
    pub cars: u32, //TODO Implement Array<ContractAddress>
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Account {
    #[key]
    pub owner: ContractAddress,
    pub username: felt252,
    pub total_games_played: u256,
    pub total_games_won: u256,
}

pub trait AccountTrait {
    fn new(username: felt252, owner: ContractAddress) -> Account;
}

impl AccountImpl of AccountTrait {
    fn new(username: felt252, owner: ContractAddress) -> Account {
        Account { owner, username, total_games_played: 0, total_games_won: 0 }
    }
}
