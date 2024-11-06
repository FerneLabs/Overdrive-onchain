use overdrive::models::{
    game_models::{GameTrait, GameState, GameStatus},
    player_models::{PlayerTrait, PlayerAccount, PlayerState, PlayerCiphers, Cipher, CipherTypes}
};
use overdrive::utils;
use overdrive::constants;
use starknet::{ContractAddress};

#[starknet::interface]
trait IPlayerActions<T> {
    fn create_player(ref self: T, username: felt252);
    fn hack_ciphers(ref self: T, is_bot: bool);
    fn run_cipher_module(ref self: T, ciphers: Array<Cipher>, is_bot: bool);
}

#[dojo::contract]
mod playerActions {
    use super::{
        GameTrait, GameState, GameStatus, IPlayerActions, PlayerTrait, PlayerAccount, PlayerState,
        PlayerCiphers, Cipher, CipherTypes, utils, constants
    };
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_block_number};
    use dojo::model::{ModelStorage, ModelValueStorage};
    use core::ArrayTrait;

    #[abi(embed_v0)]
    impl PlayerActionsImpl of IPlayerActions<ContractState> {
        fn create_player(ref self: ContractState, username: felt252) {
            // TODO: Check if account already exists for this address
            let address = get_caller_address();
            let (player_account, player_assets, player_state, player_ciphers) =
                PlayerTrait::create_player(
                address, false, username
            );

            let (_bot_account, _bot_assets, bot_state, bot_ciphers,) = PlayerTrait::create_player(
                address, true, username
            );

            let mut world = self.world(@"overdrive");
            world.write_model(@player_account);
            world.write_model(@player_assets);
            world.write_model(@player_state);
            world.write_model(@player_ciphers);
            world.write_model(@bot_state);
            world.write_model(@bot_ciphers);
        }

        fn hack_ciphers(ref self: ContractState, is_bot: bool) {
            let player_address = get_caller_address();

            let mut world = self.world(@"overdrive");
            let mut player_state: PlayerState = world.read_model((player_address, is_bot));
            let mut player_ciphers: PlayerCiphers = world.read_model((player_address, is_bot));

            if (!player_state.playing) {
                return;
            }

            println!("Running energy calc");
            PlayerTrait::calc_energy_regen(ref player_state);

            if (player_state.energy >= 4) {
                // Pseudo-random seed generation using caller address, block_number, game_id, and
                // current time
                let seed = utils::hash4(
                    player_address.into(),
                    get_block_number().into(),
                    player_state.game_id.into(),
                    get_block_timestamp().into()
                );

                // Generate 6 pseudo-random numbers using different hash inputs
                let type_1_hash: u256 = utils::hash2(seed, 1).into();
                let type_2_hash: u256 = utils::hash2(seed, 2).into();
                let type_3_hash: u256 = utils::hash2(seed, 3).into();
                let value_1_hash: u256 = utils::hash2(seed, 4).into();
                let value_2_hash: u256 = utils::hash2(seed, 5).into();
                let value_3_hash: u256 = utils::hash2(seed, 6).into();

                println!("Running cipher gen");
                let mut hacked_ciphers = ArrayTrait::<Cipher>::new();
                hacked_ciphers.append(PlayerTrait::gen_cipher(type_1_hash, value_1_hash));
                hacked_ciphers.append(PlayerTrait::gen_cipher(type_2_hash, value_2_hash));
                hacked_ciphers.append(PlayerTrait::gen_cipher(type_3_hash, value_3_hash));

                player_ciphers.hack_ciphers = hacked_ciphers;

                player_state.energy -= 4;
                world.write_model(@player_state);
                world.write_model(@player_ciphers);
            }
        }

        fn run_cipher_module(ref self: ContractState, ciphers: Array<Cipher>, is_bot: bool) {
            if (ciphers.len() < 2) {
                return;
            }

            let player_address = get_caller_address();
            let mut world = self.world(@"overdrive");

            let mut player_state: PlayerState = world.read_model((player_address, is_bot));
            let player_ciphers: PlayerCiphers = world.read_model((player_address, is_bot));

            let mut game_state: GameState = world.read_model(player_state.game_id);
            if (game_state.status == GameStatus::Ended) {
                return;
            }

            // TODO: This should work for Single Player,
            // but !is_bot should be changed when implementing MultiPlayer

            let mut opponent_state: PlayerState = if (game_state.player_1 == player_address) {
                world.read_model((game_state.player_2, !is_bot))
            } else {
                world.read_model((game_state.player_1, !is_bot))
            };

            let mut cipher_total_value: u8 = 0;
            let mut cipher_total_type = CipherTypes::Unknown;

            PlayerTrait::calc_energy_regen(ref player_state);
            PlayerTrait::calc_cipher_stats(ciphers, ref cipher_total_type, ref cipher_total_value);
            PlayerTrait::handle_cipher_action(
                ref player_state, ref opponent_state, ref cipher_total_type, ref cipher_total_value
            );

            // Check if game should be ended
            if (player_state.score >= constants::MAX_SCORE.into()
                && player_state.score > opponent_state.score) {
                let mut winner_account: PlayerAccount = world.read_model(player_state.player_address);
                let mut loser_account: PlayerAccount = world.read_model(opponent_state.player_address);
                // TODO: should change the !is_bot when implementing multiplayer
                let opponent_ciphers: PlayerCiphers = world.read_model((opponent_state.player_address, !is_bot)); 

                GameTrait::end_game(
                    ref game_state,
                    ref player_state,
                    ref opponent_state,
                    ref winner_account,
                    ref loser_account
                );

                PlayerTrait::reset_state(ref player_state);
                PlayerTrait::reset_state(ref opponent_state);
                let player_ciphers = PlayerTrait::reset_ciphers(player_ciphers, true, true);
                let opponent_ciphers = PlayerTrait::reset_ciphers(opponent_ciphers, true, true);

                world.write_model(@game_state);
                world.write_model(@player_state);
                world.write_model(@opponent_state);
                world.write_model(@loser_account);
                world.write_model(@winner_account);
                world.write_model(@player_ciphers);
                world.write_model(@opponent_ciphers);
            } else {
                if (cipher_total_type == CipherTypes::Attack) {
                    world.write_model(@opponent_state);
                }

                let player_ciphers = PlayerTrait::reset_ciphers(player_ciphers, true, false);
                world.write_model(@player_state);
                world.write_model(@player_ciphers);
            }
        }
    }
}
