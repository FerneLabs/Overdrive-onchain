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

#[derive(Drop, Clone, Serde, Introspect, Debug)]
pub struct Cipher {
    pub cipher_types: Array<CipherTypes>,
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
        let default_cipher_types = array![CipherTypes::Unknown];
        let default_cipher = Cipher { cipher_types: default_cipher_types, cipher_value: 0 };
        let hack_ciphers = array![default_cipher.clone(), default_cipher.clone(), default_cipher.clone()];
        let deck_ciphers = array![default_cipher.clone(), default_cipher.clone(), default_cipher.clone(), default_cipher.clone(), default_cipher.clone()];
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
        let default_cipher_types = array![CipherTypes::Unknown];
        let default_cipher = Cipher { cipher_types: default_cipher_types, cipher_value: 0 };

        if (hack) {
            player_ciphers.hack_ciphers = array![default_cipher.clone(), default_cipher.clone(), default_cipher.clone()];
        }

        if (deck) {
            player_ciphers.deck_ciphers = array![default_cipher.clone(), default_cipher.clone(), default_cipher.clone(), default_cipher.clone(), default_cipher.clone()];
        }

        player_ciphers
    }

    fn type_weight_func(mut weight: u8, is_extra: bool) -> u8 {
        // Make chances equal for extra type - ADV, ATT, SHI, ENE
        let type_weights = if (is_extra) { [25_u8, 25_u8, 25_u8, 25_u8].span() } else { [40_u8, 25_u8, 20_u8, 15_u8].span() }; 
        let mut type_index: u8 = 3;

        let mut i: u8 = 0;
        for type_weight in type_weights {
            if (weight < *type_weight) {
                type_index = i;
                break;
            }
            i += 1;
            weight -= *type_weight;
        };

        type_index
    }

    fn gen_cipher_type(type_hash: felt252, value_hash:felt252, type_index: u8, is_multi: bool) -> (Array<CipherTypes>, u8) {
        if (is_multi) { 
            let extra_type_hash = utils::hash2(type_hash, value_hash);
            let mut extra_type_weight = utils::get_number_between(extra_type_hash.into(), 0, 99);
            let extra_type_index = Self::type_weight_func(extra_type_weight, true);

            (array![utils::parse_cipher_type(type_index), utils::parse_cipher_type(extra_type_index)], extra_type_index)
        } else {
            (array![utils::parse_cipher_type(type_index)], 4) // 4 => CipherTypes::Unknown
        }
    }

    fn gen_cipher_value(value_hash: felt252, type_index: u8, extra_type_index: u8, is_multi: bool) -> u8 {
        let mut value: u8 = 0;
        // Default to 5 to 10 for ADV if not multi, and 1 to 5 for the rest
        if (type_index == 0) {
            value = utils::get_number_between(value_hash.into(), constants::ADV_CIPHER_MIN.into(), constants::ADV_CIPHER_MAX.into());
        } else {
            value = utils::get_number_between(value_hash.into(), constants::DEFAULT_CIPHER_MIN.into(), constants::DEFAULT_CIPHER_MAX.into());
        } 
        
        // If multi mixed, 1 to 5 no matter the types, if multi pure, apply multiplier to default values
        if (is_multi) {
            value = if (type_index == extra_type_index) {
                value * constants::PURE_CIPHER_MULTIPLIER
            } else {
                utils::get_number_between(value_hash.into(), constants::MIXED_CIPHER_MIN.into(), constants::MIXED_CIPHER_MAX.into())
            };
        }

        value
    }
    
    fn gen_cipher(value_hash: felt252, type_hash: felt252) -> Cipher {
        let mut weight = utils::get_number_between(type_hash.into(), 0, 99);
        let is_multi = if weight < 15 { true } else { false }; // 15% chance to use multiple types
        
        let type_index = Self::type_weight_func(weight, false);
        
        let (cipher_types, extra_type_index) = Self::gen_cipher_type(type_hash, value_hash, type_index, is_multi);
        let cipher_value = Self::gen_cipher_value(value_hash, type_index, extra_type_index, is_multi);

        Cipher { cipher_types, cipher_value }
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
            && ciphers[0].cipher_types[0] == ciphers[1].cipher_types[0]
            && ciphers[0].cipher_types[0] == ciphers[2].cipher_types[0]) {
            cipher_total_value = (*ciphers[0].cipher_value + *ciphers[1].cipher_value + *ciphers[2].cipher_value) * 2;
            cipher_total_type = *ciphers[0].cipher_types[0];
        } else {
            // Check if at least there are two equal types
            if (ciphers.len() >= 2 && ciphers[0].cipher_types[0] == ciphers[1].cipher_types[0]) {
                cipher_total_value = *ciphers[0].cipher_value + *ciphers[1].cipher_value;
                cipher_total_type = *ciphers[0].cipher_types[0];
            }
            if (ciphers.len() == 3 && ciphers[0].cipher_types[0] == ciphers[2].cipher_types[0]) {
                cipher_total_value = *ciphers[0].cipher_value + *ciphers[2].cipher_value;
                cipher_total_type = *ciphers[0].cipher_types[0];
            }
            if (ciphers.len() == 3 && ciphers[1].cipher_types[0] == ciphers[2].cipher_types[0]) {
                cipher_total_value = *ciphers[1].cipher_value + *ciphers[2].cipher_value;
                cipher_total_type = *ciphers[1].cipher_types[0];
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
                let mut cipher_attack = if (opponent_state.shield > cipher_total_value) {
                    opponent_state.shield -= cipher_total_value;
                    0
                } else {
                    let shield = opponent_state.shield;
                    opponent_state.shield = 0;
                    cipher_total_value - shield
                };
    
                if (opponent_state.score < cipher_attack.into()) {
                    opponent_state.score = 0;
                } else {
                    opponent_state.score -= cipher_attack.into();
                }
            },
            CipherTypes::Shield => { player_state.shield += cipher_total_value; },
            CipherTypes::Energy => { player_state.energy += cipher_total_value; },
            _ => { assert(cipher_total_type == CipherTypes::Unknown, constants::UNKNOWN_CIPHER_TYPE); },
        }
    }
}
