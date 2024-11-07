use overdrive::utils;
use overdrive::constants;
use starknet::{ContractAddress, get_block_timestamp};
use dojo::model::ModelStorage;
use core::ArrayTrait;

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct PlayerAccount {
    #[key]
    pub player_address: ContractAddress,
    pub username: felt252,
    pub games_played: usize,
    pub games_won: usize,
    pub creation_time: u64
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct PlayerAssets {
    #[key]
    pub player_address: ContractAddress,
    // TODO: NFT addresses
    pub cars: felt252,
    pub profile_icons: felt252,
    pub garage_environments: felt252
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct PlayerState {
    #[key]
    pub player_address: ContractAddress,
    #[key]
    pub is_bot: bool,
    pub game_id: usize,
    pub score: u16,
    pub shield: u8,
    pub energy: u8,
    pub last_action_time: u64,
    pub playing: bool
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct PlayerCiphers {
    #[key]
    pub player_address: ContractAddress,
    #[key]
    pub is_bot: bool,
    pub hack_ciphers: Array<Cipher>,
    pub deck_ciphers: Array<Cipher>
}

#[derive(Drop, Copy, Serde, Introspect, Debug)]
pub struct Cipher {
    pub cipher_type: CipherTypes,
    pub cipher_value: u8,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum CipherTypes {
    Advance,
    Attack,
    Shield,
    Energy,
    Unknown,
}

#[generate_trait]
impl PlayerImpl of PlayerTrait {
    fn create_player(
        player_address: ContractAddress, 
        is_bot: bool, 
        username: felt252
    ) -> (
        PlayerAccount, 
        PlayerAssets, 
        PlayerState, 
        PlayerCiphers
    ) {
        let default_cipher = Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 };
        let hack_ciphers = array![default_cipher, default_cipher, default_cipher];
        let deck_ciphers = array![default_cipher, default_cipher, default_cipher, default_cipher, default_cipher];
        (
            PlayerAccount {
                player_address,
                username,
                games_played: 0,
                games_won: 0,
                creation_time: get_block_timestamp()
            },
            PlayerAssets {
                player_address,
                cars: 0,
                profile_icons: 0,
                garage_environments: 0
            },
            PlayerState {
                player_address,
                is_bot,
                game_id: 0,
                score: 0,
                shield: 0,
                energy: constants::START_ENERGY,
                last_action_time: 0,
                playing: false
            },
            PlayerCiphers {
                player_address,
                is_bot,
                hack_ciphers,
                deck_ciphers
            }
        )
    }

    fn reset_state(ref player_state: PlayerState) -> () {
        player_state.game_id = 0;
        player_state.score = 0;
        player_state.shield = 0;
        player_state.energy = constants::START_ENERGY;
        player_state.last_action_time = 0;
        player_state.playing = false;
    }

    fn reset_ciphers(mut player_ciphers: PlayerCiphers, hack: bool, deck: bool) -> PlayerCiphers {
        let default_cipher = Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 };

        if (hack) {
            player_ciphers.hack_ciphers = array![default_cipher, default_cipher, default_cipher];
        }

        if (deck) {
            player_ciphers.deck_ciphers = array![default_cipher, default_cipher, default_cipher, default_cipher, default_cipher];
        }

        player_ciphers
    }
    
    // TODO: use appropiate types instead of u256
    fn gen_cipher(value_hash: felt252, type_hash: felt252) -> Cipher {
        let type_weights = [40_u8, 25_u8, 20_u8, 15_u8].span(); // ADV, ATT, SHI, ENE
        let weights_sum: u256 = 100;

        let mut type_in_range = utils::get_range(type_hash.into(), 0, weights_sum);
        let mut type_index: u8 = 3;
        let mut value: u8 = 0;

        let mut i: u8 = 0;
        for curr_type in type_weights {
            if (type_in_range < *curr_type) {
                type_index = i;
                break;
            }
            i += 1;
            type_in_range -= *curr_type;
        };

        if (type_index == 0) {
            value = utils::get_range(value_hash.into(), 5, 10);
        } else {
            value = utils::get_range(value_hash.into(), 1, 5);
        }

        Cipher {
            cipher_type: utils::parse_cipher_type(type_index),
            cipher_value: value,
        }
    }

    fn calc_energy_regen(ref player_state: PlayerState) -> () {
        let current_time = get_block_timestamp();
        let time_since_action: u64 = current_time - player_state.last_action_time;
    
        let mut energy_regenerated: u64 = time_since_action / constants::REGEN_EVERY.into();
        let mut reminder_seconds: u64 = time_since_action % constants::REGEN_EVERY.into();
        
        // Set as 10 max to avoid unwrap error in case the time since action is too large
        if (energy_regenerated > 10) { energy_regenerated = 10; }
        
        println!("energy regenerated: {:?}", energy_regenerated);
        player_state.energy = if (player_state.energy + energy_regenerated.try_into().unwrap() > 10) {
            10
        } else {
            player_state.energy + energy_regenerated.try_into().unwrap()
        };
    
        player_state.last_action_time = current_time - reminder_seconds;
    }
    
    fn calc_cipher_stats(
        ciphers: Array<Cipher>, 
        ref cipher_total_type: CipherTypes, 
        ref cipher_total_value: u8
    ) -> () {
        // Check for max combo
        if (ciphers.len() == 3
            && ciphers[0].cipher_type == ciphers[1].cipher_type
            && ciphers[0].cipher_type == ciphers[2].cipher_type) {
            cipher_total_value = (*ciphers[0].cipher_value + *ciphers[1].cipher_value + *ciphers[2].cipher_value) * 2;
            cipher_total_type = *ciphers[0].cipher_type;
        } else {
            // Check if at least there are two equal types
            if (ciphers.len() >= 2 && ciphers[0].cipher_type == ciphers[1].cipher_type) {
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
        }
    }
    
    fn handle_cipher_action(
        ref player_state: PlayerState, 
        ref opponent_state: PlayerState, 
        ref cipher_total_type: CipherTypes, 
        ref cipher_total_value: u8
    ) -> () {
        match cipher_total_type {
            CipherTypes::Advance => { player_state.score += cipher_total_value.into(); },
            CipherTypes::Attack => {
                let mut cipher_attack = if (opponent_state.shield > cipher_total_value.into()) {
                    opponent_state.shield -= cipher_total_value.into();
                    0
                } else {
                    let shield = opponent_state.shield;
                    opponent_state.shield = 0;
                    cipher_total_value.into() - shield
                };
    
                if (opponent_state.score < cipher_attack.into()) {
                    opponent_state.score = 0;
                } else {
                    opponent_state.score -= cipher_attack.into();
                }
            },
            CipherTypes::Shield => { player_state.shield += cipher_total_value.into(); },
            CipherTypes::Energy => { player_state.energy += cipher_total_value.into(); },
            _ => { assert(cipher_total_type == CipherTypes::Unknown, constants::UNKNOWN_CIPHER_TYPE); },
        }
    }
}
