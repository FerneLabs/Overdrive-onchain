use overdrive::models::{game_player_models::{GamePlayer, GamePlayerTrait, Cipher, CipherTypes}};
use overdrive::utils;
use starknet::{ContractAddress};

#[dojo::interface]
trait IGamePlayerActions {
    fn get_ciphers(ref world: IWorldDispatcher);
    fn set_player(
        ref world: IWorldDispatcher, ciphers: Array<Cipher>, player_address: ContractAddress
    );
}

#[dojo::contract]
mod gamePlayerActions {
    use super::{IGamePlayerActions, GamePlayer, GamePlayerTrait, Cipher, CipherTypes, utils};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_block_number};
    #[abi(embed_v0)]
    impl GamePlayerActionsImpl of IGamePlayerActions<ContractState> {
        fn get_ciphers(ref world: IWorldDispatcher) {
            // let START_ENERGY = 6;
            let REGEN_SECONDS: u64 = 3;
            let caller_address = get_caller_address();
            let mut player = get!(world, caller_address, (GamePlayer));

            let current_time = get_block_timestamp();
            let time_since_action: u64 = current_time - player.last_action_timestamp;

            let energy_regenerated: u64 = time_since_action / REGEN_SECONDS;
            let reminder_seconds: u64 = time_since_action % REGEN_SECONDS;

            println!(
                "Energy regenerated {:?} in {:?} seconds", energy_regenerated, time_since_action
            );
            println!(
                "Current energy: {:?} ({:?} + {:?})",
                player.energy + energy_regenerated.into(),
                player.energy,
                energy_regenerated
            );

            player
                .energy =
                    if (player.energy + energy_regenerated.into() > 10) {
                        10
                    } else {
                        player.energy + energy_regenerated.into()
                    };

            if (player.energy >= 4) {
                // Pseudo-random seed generation using caller address, block_number, game_id, and
                // current time
                let seed = utils::hash4(
                    caller_address.into(),
                    get_block_number().into(),
                    player.game_id.into(),
                    current_time.into()
                );
                // println!("Creating seed with: {:?} / {:?} / {:?} / {:?}", owner,
                // get_block_number(), game_id, current_time);

                // Generate 6 pseudo-random numbers using different hash inputs
                let type_1_hash: u256 = utils::hash2(seed, 1).into();
                let type_2_hash: u256 = utils::hash2(seed, 2).into();
                let type_3_hash: u256 = utils::hash2(seed, 3).into();
                let value_1_hash: u256 = utils::hash2(seed, 4).into();
                let value_2_hash: u256 = utils::hash2(seed, 5).into();
                let value_3_hash: u256 = utils::hash2(seed, 6).into();

                player.get_cipher_1 = GamePlayerTrait::gen_cipher(type_1_hash, value_1_hash);
                player.get_cipher_2 = GamePlayerTrait::gen_cipher(type_2_hash, value_2_hash);
                player.get_cipher_3 = GamePlayerTrait::gen_cipher(type_3_hash, value_3_hash);

                player.energy -= 4;
                player.last_action_timestamp = current_time - reminder_seconds;

                set!(world, (player));
            }
        }

        fn set_player(
            ref world: IWorldDispatcher, ciphers: Array<Cipher>, player_address: ContractAddress
        ) {
            if ciphers.len() < 2 {
                println!("NO SE HACE NADA");
                return;
            }

            let mut cipher_total_value = 0;
            let mut cipher_total_type = CipherTypes::Unknown(());
            // Check for max combo
            if ciphers.len() == 3
                && ciphers[0].cipher_type == ciphers[1].cipher_type
                && ciphers[0].cipher_type == ciphers[2].cipher_type {
                cipher_total_value +=
                    (*ciphers[0].cipher_value + *ciphers[1].cipher_value + *ciphers[2].cipher_value)
                    * 2;
                cipher_total_type = *ciphers[0].cipher_type;
            } else {
                // Check if at least there are two equal types
                if (ciphers.len() > 2 && ciphers[0].cipher_type == ciphers[1].cipher_type) {
                    cipher_total_value = *ciphers[0].cipher_value + *ciphers[1].cipher_value;
                    cipher_total_type = *ciphers[0].cipher_type;
                }
                if (ciphers.len() == 3 && ciphers[0].cipher_type == ciphers[2].cipher_type) {
                    cipher_total_value = *ciphers[0].cipher_value + *ciphers[2].cipher_value;
                    cipher_total_type = *ciphers[0].cipher_type;
                }
                if (ciphers.len() == 3 && ciphers[1].cipher_type == ciphers[2].cipher_type) {
                    cipher_total_value = *ciphers[1].cipher_value + *ciphers[2].cipher_value;
                    cipher_total_type = *ciphers[1].cipher_type;
                }
            };
            println!(
                "CIPHER 1 TYPE: {:?} VALUE: {:?}", ciphers[0].cipher_type, ciphers[0].cipher_value
            );
            println!(
                "CIPHER 2 TYPE: {:?} VALUE: {:?}", ciphers[1].cipher_type, ciphers[1].cipher_value
            );
            if ciphers.len() == 3 {
                println!(
                    "CIPHER 3 TYPE: {:?} VALUE: {:?}",
                    ciphers[2].cipher_type,
                    ciphers[2].cipher_value
                );
            }
            println!("CIPHER TOTAL TYPE: {:?} VALUE: {:?}", cipher_total_type, cipher_total_value);

            let mut player = get!(world, player_address, (GamePlayer));

            match cipher_total_type {
                CipherTypes::Advance => { player.score += cipher_total_value.into(); },
                CipherTypes::Attack => {
                    let mut cipher_attack = if player.shield > cipher_total_value.into() {
                        player.shield -= cipher_total_value.into();
                        0
                    } else {
                        let shield = player.shield;
                        player.shield = 0;
                        cipher_total_value.into() - shield
                    };

                    if player.score < cipher_attack {
                        player.score = 0;
                    } else {
                        player.score -= cipher_attack;
                    }
                },
                CipherTypes::Shield => { player.shield += cipher_total_value.into(); },
                //TODO JOJO CHEQUEA EL TEMA DE LA ENERGIA
                CipherTypes::Energy => {
                    if player.energy + cipher_total_value.into() < 10 {
                        player.energy = 10;
                    } else {
                        player.energy += cipher_total_value.into();
                    }
                },
                //TODO SE PODRIA PONER UN ASSERT
                CipherTypes::Unknown => {},
            }

            set!(world, (player));
        }
    }
}
