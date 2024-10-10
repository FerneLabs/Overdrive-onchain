use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Garage {
    #[key]
    pub player: ContractAddress,
    pub cars: u32, //TODO Implementar ContractAddress
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Statistics {
    #[key]
    pub player: ContractAddress,
    pub wins: u8,
    pub elo: u32,
}
