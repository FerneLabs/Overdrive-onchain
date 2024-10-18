use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Garage {
    #[key]
    pub account: ContractAddress,
    pub cars: u32, //TODO: Implement Array<ContractAddress>
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Account {
    #[key]
    pub address: ContractAddress,
    pub username: felt252,
    pub total_games_played: u256,
    pub total_games_won: u256,
}

#[generate_trait]
impl AccountImpl of AccountTrait {
    fn new(username: felt252, address: ContractAddress) -> Account {
        Account { address, username, total_games_played: 0, total_games_won: 0 }
    }
}
