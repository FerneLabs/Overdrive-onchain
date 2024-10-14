use overdrive::models::{game_models::{Game, GamePlayer, GameTrait, GameMode, CipherTypes}};
use starknet::{ContractAddress};

pub mod Errors {
    pub const ADDRESS_ZERO: felt252 = 'Cannot create from zero address';
    pub const USERNAME_TAKEN: felt252 = 'username already taken';
    pub const USERNAME_NOT_FOUND: felt252 = 'player with username not found';
    pub const USERNAME_EXIST: felt252 = 'username already exist';
    pub const ONLY_OWNER_USERNAME: felt252 = 'only user can udpate username';
}

#[dojo::interface]
trait IGameActions {
    fn create_game(ref world: IWorldDispatcher,);
    fn get_game(ref world: IWorldDispatcher);
    fn get_cipher(ref world: IWorldDispatcher, game_id: felt252);
    fn set_player(
        ref world: IWorldDispatcher, game_id: felt252, cipher_value: u256, cipher_type: felt252
    );
}

#[dojo::contract]
mod gameActions {
    use super::Errors;
    use super::{IGameActions, Game, GamePlayer, GameMode, GameTrait, CipherTypes};
    use starknet::{ContractAddress, get_caller_address};
    use starknet::get_block_timestamp;
    use core::num::traits::Zero;

    #[abi(embed_v0)]
    impl GameActionsImpl of IGameActions<ContractState> {
        fn create_game(ref world: IWorldDispatcher) {
            let owner = get_caller_address();

            let (new_game, new_player_one, new_player_two) = GameTrait::new_single_player(owner);

            // let mut existing_account = get!(world, owner, (Account));

            // assert(existing_account.username == username, Errors::USERNAME_TAKEN);

            set!(world, (new_game, new_player_one, new_player_two));
        }

        fn get_game(ref world: IWorldDispatcher) {
            let owner = get_caller_address();

            let game = get!(world, 1, (Game));
            let player_one = get!(world, (owner, 1), (GamePlayer));
            let _player_two = get!(world, (owner, 1), (GamePlayer));

            let (type_1, value_1) = player_one.get_cipher_1;
            let (type_2, value_2) = player_one.get_cipher_2;
            let (type_3, value_3) = player_one.get_cipher_3;

            println!("GAME ID: {:?}", game.id);
            println!("GAME STATUS: {:?}", game.game_status);
            println!("GAME MODE: {:?}", game.game_mode);
            println!("PLAYER ADDRESS: {:?}", player_one.owner);
            println!("PLAYER CAR: {:?}", player_one.car);
            println!("PLAYER SCORE: {:?}", player_one.score);
            println!("PLAYER ENERGY: {:?}", player_one.energy);
            println!("PLAYER SHIELD: {:?}", player_one.shield);
            println!("PLAYER GET CIPHERS:");
            println!("  CIPHER 1: {:?} - {:?}", type_1, value_1);
            println!("  CIPHER 2: {:?} - {:?}", type_2, value_2);
            println!("  CIPHER 3: {:?} - {:?}", type_3, value_3);
        }

        fn get_cipher(
            ref world: IWorldDispatcher,
            game_id: felt252
        ) {
            // let START_ENERGY = 6;
            let REGEN_SECONDS: u256 = 3;

            let owner = get_caller_address();
            let mut player = get!(world, (owner, game_id), (GamePlayer));
            
            let current_time = get_block_timestamp();
            let time_since_action: u256 =  (current_time - player.last_action_timestamp).into();

            // TODO: Bruno fix this
            let energy_regenerated: u256 = time_since_action / REGEN_SECONDS;

            println!("Energy regenerated {:?} in {:?} seconds", energy_regenerated, time_since_action);
            println!("Current energy: {:?} + {:?} = {:?} (current + regen)", player.energy, energy_regenerated, player.energy + energy_regenerated);

            player.energy = if player.energy + energy_regenerated > 10 { 10 } else { player.energy + energy_regenerated };

            if (player.energy >= 4) {
                println!("Assigning cipher values");
                // Generate ciphers randomly
                player.get_cipher_1 = (10, 0);
                player.get_cipher_2 = (5, 0);
                player.get_cipher_3 = (5, 2);

                player.energy -= 4;
                player.last_action_timestamp = current_time;

                set!(world, (player));
            }
        }

        fn set_player(
            ref world: IWorldDispatcher, // player_address: ContractAddress,
            game_id: felt252,
            cipher_value: u256,
            cipher_type: felt252
        ) {
            let owner = get_caller_address();

            let mut player_one = get!(world, (owner, game_id), (GamePlayer));

            let cipher_enum = match cipher_type {
                0 => CipherTypes::Speed,
                1 => CipherTypes::Attack,
                2 => CipherTypes::Energy,
                3 => CipherTypes::Shield,
                _ => { CipherTypes::Speed }
            };

            match cipher_enum {
                CipherTypes::Speed => { player_one.score += cipher_value; },
                CipherTypes::Attack => {},
                CipherTypes::Shield => { player_one.shield += cipher_value; },
                CipherTypes::Energy => { player_one.energy += cipher_value; },
            }

            set!(world, (player_one));
        }
    }
}
