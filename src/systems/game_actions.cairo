use overdrive::models::{
    game_models::{Game, GameTrait, GameMode, GameStatus}, player_models::{Player}
};
use overdrive::utils;
use overdrive::constants;
use starknet::{ContractAddress, contract_address_const};

#[dojo::interface]
trait IGameActions {
    fn create_game(ref world: IWorldDispatcher, game_mode: GameMode);
    fn get_game_state(ref world: IWorldDispatcher, game_id: felt252);
}

#[dojo::contract]
mod gameActions {
    use super::{IGameActions, Game, GameMode, GameStatus, GameTrait, utils, Player, constants};
    use starknet::{ContractAddress, contract_address_const, get_caller_address};
    use core::num::traits::Zero;

    #[abi(embed_v0)]
    impl GameActionsImpl of IGameActions<ContractState> {
        fn create_game(ref world: IWorldDispatcher, game_mode: GameMode) {
            let zero_address = contract_address_const::<0x0>();
            let caller_address = get_caller_address();
            let game_id = world.uuid();

            // TODO: Handle user already playing - maybe add playing bool to account struct
            // TODO: In GameTrait::new_game a new user will be created using PlayerTrait::create_user.
            //       Does this re-use the player in the Player model or creates a new one?

            let (new_game, new_player_one, new_player_two) = GameTrait::new_game(
                game_id,
                caller_address,
                zero_address,
                game_mode
            );
            println!("Created game with ID: {:?} | {:?}", game_id, game_mode);
            set!(world, (new_game, new_player_one, new_player_two));
        }

        fn get_game_state(ref world: IWorldDispatcher, game_id: felt252) {
            let game_id: usize = game_id.try_into().unwrap();
            let game = get!(world, game_id, (Game));

            let player_one = get!(world, (game.player_1, game_id), (Player));
            let player_two = get!(world, (game.player_2, game_id), (Player));

            println!("GAME ID: {:?}", game.id);
            println!("GAME STATUS: {:?}", game.game_status);
            println!("GAME WINNER: {:?}", game.winner_address);
            println!("GAME RESULT: {:?}", game.result);
            println!("GAME MODE: {:?}", game.game_mode);
            println!("PLAYER 1 ADDRESS: {:?}", player_one.address);
            println!("PLAYER 1 CAR: {:?}", player_one.car);
            println!("PLAYER 1 SCORE: {:?}", player_one.score);
            println!("PLAYER 1 ENERGY: {:?}", player_one.energy);
            println!("PLAYER 1 SHIELD: {:?}", player_one.shield);
            println!("=======================");
            println!("PLAYER 2 ADDRESS: {:?}", player_two.address);
            println!("PLAYER 2 SCORE: {:?}", player_two.score);
            println!("=======================");
            println!("PLAYER 1 CIPHERS:");
            println!(
                "  CIPHER 1: {:?} - {:?}",
                player_one.cipher_1.cipher_type,
                player_one.cipher_1.cipher_value
            );
            println!(
                "  CIPHER 2: {:?} - {:?}",
                player_one.cipher_2.cipher_type,
                player_one.cipher_2.cipher_value
            );
            println!(
                "  CIPHER 3: {:?} - {:?}",
                player_one.cipher_3.cipher_type,
                player_one.cipher_3.cipher_value
            );
        }
    }
}
