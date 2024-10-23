use overdrive::models::{
    game_models::{GameTrait, GameState, GameStatus}, 
    player_models::{
        PlayerTrait,
        PlayerAccount, 
        PlayerState, 
        PlayerCiphers, 
        Cipher, CipherTypes
    }
};
use overdrive::utils;
use overdrive::constants;
use starknet::{ContractAddress};

#[dojo::interface]
trait IPlayerActions {
    fn create_player(ref world: IWorldDispatcher, username: felt252);
    fn hack_ciphers(ref world: IWorldDispatcher, is_bot: bool);
    fn run_cipher_module(
        ref world: IWorldDispatcher, ciphers: Array<Cipher>, is_bot: bool
    );
}

#[dojo::contract]
mod playerActions {
    use super::{
        GameTrait,
        GameState,
        GameStatus, 
        IPlayerActions, PlayerTrait, 
        PlayerAccount, 
        PlayerState, 
        PlayerCiphers, 
        Cipher, CipherTypes, 
        utils, constants
    };
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_block_number};

    #[abi(embed_v0)]
    impl PlayerActionsImpl of IPlayerActions<ContractState> {
        fn create_player(ref world: IWorldDispatcher, username: felt252) {
            // TODO: Check if account already exists for this address
            let address = get_caller_address();
            let (
                player_account,
                player_assets,
                player_state,
                player_ciphers

            ) = PlayerTrait::create_player(address, false, username);

            let (
                _bot_account,
                _bot_assets,
                bot_state,
                bot_ciphers,
            ) = PlayerTrait::create_player(address, true, username);

            set!(
                world, 
                (
                    player_account,
                    player_assets,
                    player_state,
                    player_ciphers,
                    bot_state,
                    bot_ciphers
                )
            );
        }

        fn hack_ciphers(ref world: IWorldDispatcher, is_bot: bool) {
            let player_address = get_caller_address();
            let (mut player_state, mut player_ciphers) = get!(world, (player_address, is_bot), (PlayerState, PlayerCiphers));

            if (!player_state.playing) { return; }

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
                player_ciphers.hack_cipher_1 = PlayerTrait::gen_cipher(type_1_hash, value_1_hash);
                player_ciphers.hack_cipher_2 = PlayerTrait::gen_cipher(type_2_hash, value_2_hash);
                player_ciphers.hack_cipher_3 = PlayerTrait::gen_cipher(type_3_hash, value_3_hash);

                player_state.energy -= 4;
                set!(world, (player_state, player_ciphers));
            }
        }

        fn run_cipher_module(
            ref world: IWorldDispatcher,
            ciphers: Array<Cipher>,
            is_bot: bool
        ) {
            if (ciphers.len() < 2) { return; }
            
            let player_address = get_caller_address();
            let player_state = get!(world, (player_address, is_bot), (PlayerState));

            let mut game_state = get!(world, player_state.game_id, (GameState));
            if (game_state.status == GameStatus::Ended) { return; }

            let (mut player_state, mut player_ciphers) = get!(
                world, 
                (player_address, is_bot), 
                (PlayerState, PlayerCiphers)
            );

            // TODO: This should work for Single Player, 
            // but !is_bot should be changed when implementing MultiPlayer
            let mut opponent_state = if (game_state.player_1 == player_address) {
                get!(world, (game_state.player_2, !is_bot), (PlayerState))
            } else {
                get!(world, (game_state.player_1, !is_bot), (PlayerState))
            };

            let mut cipher_total_value: u8 = 0;
            let mut cipher_total_type = CipherTypes::Unknown;

            PlayerTrait::calc_energy_regen(ref player_state);
            PlayerTrait::calc_cipher_stats(ciphers, ref cipher_total_type, ref cipher_total_value);
            PlayerTrait::handle_cipher_action(
                ref player_state,
                ref opponent_state,
                ref cipher_total_type,
                ref cipher_total_value
            );

            // Check if game should be ended
            if (
                player_state.score >= constants::MAX_SCORE.into() 
                && player_state.score > opponent_state.score
            ) {
                let mut winner_account = get!(world, player_state.player_address, (PlayerAccount));
                let mut loser_account = get!(world, opponent_state.player_address, (PlayerAccount));
                let mut opponent_ciphers = get!(world, (opponent_state.player_address, is_bot), (PlayerCiphers));

                // TODO: games_won is not incrementing for some reason
                GameTrait::end_game(
                    ref game_state,
                    ref player_state,
                    ref opponent_state, 
                    ref winner_account, 
                    ref loser_account
                );

                PlayerTrait::reset_state(ref player_state);
                PlayerTrait::reset_state(ref opponent_state);
                PlayerTrait::reset_ciphers(ref player_ciphers, true, true);
                PlayerTrait::reset_ciphers(ref opponent_ciphers, true, true);

                set!(
                    world, 
                    (
                        game_state,
                        player_state,
                        opponent_state,
                        winner_account,
                        loser_account,
                        player_ciphers,
                        opponent_ciphers
                    )
                );
            } else {
                if (cipher_total_type == CipherTypes::Attack) {
                    set!(world, (opponent_state));
                }

                PlayerTrait::reset_ciphers(ref player_ciphers, true, false);
                set!(world, (player_state, player_ciphers));
            }
        }
    }
}
