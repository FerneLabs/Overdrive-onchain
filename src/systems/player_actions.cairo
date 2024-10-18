use overdrive::models::{
    game_models::{Game, GameTrait, GameStatus}, 
    player_models::{Player, PlayerTrait, Cipher, CipherTypes},
    account_models::{Account}
};
use overdrive::utils;
use overdrive::constants;
use starknet::{ContractAddress};

#[dojo::interface]
trait IPlayerActions {
    fn get_ciphers(ref world: IWorldDispatcher);
    fn set_player(
        ref world: IWorldDispatcher, ciphers: Array<Cipher>, player_address: ContractAddress
    );
}

#[dojo::contract]
mod playerActions {
    use super::{Game, GameTrait, GameStatus, IPlayerActions, Player, PlayerTrait, Account, Cipher, CipherTypes, utils, constants};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_block_number};

    #[abi(embed_v0)]
    impl PlayerActionsImpl of IPlayerActions<ContractState> {
        fn get_ciphers(ref world: IWorldDispatcher) {
            let caller_address = get_caller_address();
            let mut player = get!(world, caller_address, (Player));

            PlayerTrait::calc_energy_regen(ref player);

            if (player.energy >= 4) {
                // Pseudo-random seed generation using caller address, block_number, game_id, and
                // current time
                let seed = utils::hash4(
                    caller_address.into(),
                    get_block_number().into(),
                    player.game_id.into(),
                    get_block_timestamp().into()
                );

                // Generate 6 pseudo-random numbers using different hash inputs
                let type_1_hash: u256 = utils::hash2(seed, 1).into();
                let type_2_hash: u256 = utils::hash2(seed, 2).into();
                let type_3_hash: u256 = utils::hash2(seed, 3).into();
                let value_1_hash: u256 = utils::hash2(seed, 4).into();
                let value_2_hash: u256 = utils::hash2(seed, 5).into();
                let value_3_hash: u256 = utils::hash2(seed, 6).into();

                player.get_cipher_1 = PlayerTrait::gen_cipher(type_1_hash, value_1_hash);
                player.get_cipher_2 = PlayerTrait::gen_cipher(type_2_hash, value_2_hash);
                player.get_cipher_3 = PlayerTrait::gen_cipher(type_3_hash, value_3_hash);

                player.energy -= 4;
                set!(world, (player));
            }
        }

        fn set_player(
            ref world: IWorldDispatcher, ciphers: Array<Cipher>, player_address: ContractAddress
        ) {
            if (ciphers.len() < 2) { return; }

            let mut player = get!(world, player_address, (Player));
            let mut game = get!(world, player.game_id, (Game));
            if (game.game_status == GameStatus::Ended) { return; }
            
            let mut opponent = if (game.player_1 == player_address) {
                get!(world, game.player_2, (Player))
            } else {
                get!(world, game.player_1, (Player))
            };

            let mut cipher_total_value: u8 = 0;
            let mut cipher_total_type = CipherTypes::Unknown;

            PlayerTrait::calc_energy_regen(ref player);
            PlayerTrait::get_cipher_stats(ciphers, ref cipher_total_type, ref cipher_total_value);
            PlayerTrait::handle_cipher_action(ref player, ref opponent, ref cipher_total_type, ref cipher_total_value);

            // Reset player ciphers
            player.get_cipher_1 = Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 };
            player.get_cipher_2 = Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 };
            player.get_cipher_3 = Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 };

            if (
                player.score >= constants::MAX_SCORE.into() 
                && player.score > opponent.score
            ) {
                let mut winner_account = get!(world, player.address, (Account));
                let mut loser_account = get!(world, opponent.address, (Account));

                GameTrait::end_game(
                    ref game, 
                    ref player, 
                    ref opponent, 
                    ref winner_account, 
                    ref loser_account
                );

                set!(world, (game));
                set!(world, (winner_account));
                set!(world, (loser_account));
            }

            if (cipher_total_type == CipherTypes::Attack) {
                set!(world, (opponent));
            }

            set!(world, (player));
        }
    }
}
