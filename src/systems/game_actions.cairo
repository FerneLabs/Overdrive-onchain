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

#[starknet::interface]
trait IGameActions<T> {
    fn create_game(ref self: T, game_mode: GameMode);
}

#[dojo::contract]
mod gameActions {
    use super::{IGameActions, GameMode, GameStatus, GameTrait, utils, PlayerState, PlayerTrait, constants};
    use starknet::{ContractAddress, contract_address_const, get_caller_address, get_block_timestamp};
    use dojo::world::IWorldDispatcherTrait;
    use dojo::model::{ModelStorage, ModelValueStorage};

    #[abi(embed_v0)]
    impl GameActionsImpl of IGameActions<ContractState> {
        fn create_game(ref self: ContractState, game_mode: GameMode) {
            let caller_address = get_caller_address();
            let mut world = self.world(@"overdrive");
            
            if (game_mode == GameMode::SinglePlayer) {
                let game_id = world.dispatcher.uuid() + 1;
                let game_state = GameTrait::new_game(
                    game_id,
                    caller_address,
                    caller_address,
                    game_mode
                );

                let mut player_state_1: PlayerState = world.read_model((caller_address, false)); // Player
                let mut player_state_2: PlayerState = world.read_model((caller_address, true)); // Bot
                PlayerTrait::reset_state(ref player_state_1);
                PlayerTrait::reset_state(ref player_state_2);

                player_state_1.game_id = game_id;
                player_state_2.game_id = game_id;
                player_state_1.playing = true;
                player_state_2.playing = true;
                player_state_1.last_action_time = get_block_timestamp();
                player_state_2.last_action_time = get_block_timestamp();

                println!("Created game with ID: {:?} | {:?}", game_state.id, game_state.mode);

                world.write_model(@game_state);
                world.write_model(@player_state_1);
                world.write_model(@player_state_2);
            }
        }
    }
}
