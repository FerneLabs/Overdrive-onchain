use overdrive::models::{
    game_models::{
        GameState, GameTrait, 
        GameMode, GameStatus
    }, 
    player_models::{
        PlayerTrait,
        PlayerState
    }
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
    use super::{IGameActions, GameMode, GameStatus, GameTrait, utils, PlayerState, PlayerTrait, constants};
    use starknet::{ContractAddress, contract_address_const, get_caller_address, get_block_timestamp};
    use core::num::traits::Zero;

    #[abi(embed_v0)]
    impl GameActionsImpl of IGameActions<ContractState> {
        fn create_game(ref world: IWorldDispatcher, game_mode: GameMode) {
            let caller_address = get_caller_address();
            
            if (game_mode == GameMode::SinglePlayer) {
                let game_id = world.uuid() + 1;
                let game_state = GameTrait::new_game(
                    game_id,
                    caller_address,
                    caller_address,
                    game_mode
                );

                let mut player_state_1 = get!(world, (game_state.player_1, false), (PlayerState));
                let mut player_state_2 = get!(world, (game_state.player_2, true), (PlayerState));
                PlayerTrait::reset_state(ref player_state_1);
                PlayerTrait::reset_state(ref player_state_2);

                player_state_1.game_id = game_id;
                player_state_2.game_id = game_id;
                player_state_1.playing = true;
                player_state_2.playing = true;
                player_state_1.last_action_time = get_block_timestamp();
                player_state_2.last_action_time = get_block_timestamp();

                println!("Created game with ID: {:?} | {:?}", game_state.id, game_state.mode);

                set!(world, (game_state, player_state_1, player_state_2));
            }
        }

        fn get_game_state(ref world: IWorldDispatcher, game_id: felt252) {
            // let game_id: usize = game_id.try_into().unwrap();
            // let game = get!(world, game_id, (Game));

            // let player_one = get!(world, (game.player_1, game_id), (Player));
            // let player_two = get!(world, (game.player_2, game_id), (Player));

            // println!("GAME ID: {:?}", game.id);
            // println!("GAME STATUS: {:?}", game.game_status);
            // println!("GAME WINNER: {:?}", game.winner_address);
            // println!("GAME RESULT: {:?}", game.result);
            // println!("GAME MODE: {:?}", game.game_mode);
            // println!("PLAYER 1 ADDRESS: {:?}", player_one.address);
            // println!("PLAYER 1 CAR: {:?}", player_one.car);
            // println!("PLAYER 1 SCORE: {:?}", player_one.score);
            // println!("PLAYER 1 ENERGY: {:?}", player_one.energy);
            // println!("PLAYER 1 SHIELD: {:?}", player_one.shield);
            // println!("=======================");
            // println!("PLAYER 2 ADDRESS: {:?}", player_two.address);
            // println!("PLAYER 2 SCORE: {:?}", player_two.score);
            // println!("=======================");
            // println!("PLAYER 1 CIPHERS:");
            // println!(
            //     "  CIPHER 1: {:?} - {:?}",
            //     player_one.cipher_1.cipher_type,
            //     player_one.cipher_1.cipher_value
            // );
            // println!(
            //     "  CIPHER 2: {:?} - {:?}",
            //     player_one.cipher_2.cipher_type,
            //     player_one.cipher_2.cipher_value
            // );
            // println!(
            //     "  CIPHER 3: {:?} - {:?}",
            //     player_one.cipher_3.cipher_type,
            //     player_one.cipher_3.cipher_value
            // );
        }
    }
}
