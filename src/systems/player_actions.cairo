use overdrive::models::{player_models::{Garage, Statistics}};


#[dojo::interface]
trait IPlayerActions {
    fn create_account(ref world: IWorldDispatcher);
    fn get_account(ref world: IWorldDispatcher);
    fn add_win(ref world: IWorldDispatcher);
}

#[dojo::contract]
mod playerActions {
    use super::{IPlayerActions, Garage, Statistics};
    use starknet::{ContractAddress, get_caller_address};

    #[abi(embed_v0)]
    impl PlayerActionsImpl of IPlayerActions<ContractState> {
        fn create_account(ref world: IWorldDispatcher) {
            let player = get_caller_address();

            set!(world, (Garage { player, cars: 2 }, Statistics { player, wins: 0, elo: 1000 },));
        }

        fn get_account(ref world: IWorldDispatcher) {
            let player = get_caller_address();

            let (garage, stats) = get!(world, player, (Garage, Statistics));

            println!("CARS: {}, WINS: {}, ELO: {}", garage.cars, stats.wins, stats.elo);
        }

        fn add_win(ref world: IWorldDispatcher) {
            let player = get_caller_address();

            let mut stats = get!(world, player, (Statistics));

            stats.elo += 500;
            stats.wins += 1;

            set!(world, (stats));
        }
    }
}
