use overdrive::utils;
use overdrive::constants;
use starknet::{ContractAddress, get_block_timestamp};

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Account {
    #[key]
    pub player_address: ContractAddress,
    pub username: felt252,
    pub games_played: usize,
    pub games_won: usize,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Assets {
    #[key]
    pub player_address: ContractAddress,
    // TODO: NFT addresses
    pub cars: felt252,
    pub profile_icons: felt252,
    pub garage_environments: felt252
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Race {
    #[key]
    pub player_address: ContractAddress,
    pub game_id: usize,
    pub is_active: bool
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct RaceState {
    #[key]
    pub player_address: ContractAddress,
    pub score: u16,
    pub shield: u8,
    pub energy: u8,
    pub last_action_time: u64
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct HackedCiphers {
    #[key]
    pub player_address: ContractAddress,
    pub cipher_1: Cipher,
    pub cipher_2: Cipher,
    pub cipher_3: Cipher,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct DeckCiphers {
    #[key]
    pub player_address: ContractAddress,
    pub cipher_1: Cipher,
    pub cipher_2: Cipher,
    pub cipher_3: Cipher,
    pub cipher_4: Cipher,
    pub cipher_5: Cipher,
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
    // fn create_player(address: ContractAddress, game_id: u32) -> Player {
    //     let current_time = get_block_timestamp();

    //     Player {
    //         address: address,
    //         game_id,
    //         car: 1,
    //         score: 0,
    //         energy: constants::START_ENERGY.into(),
    //         shield: 0,
    //         cipher_1: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
    //         cipher_2: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
    //         cipher_3: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
    //         last_action_timestamp: current_time
    //     }
    // }

    fn initialize_player(player_address: ContractAddress, username: felt252) -> (
        Account, 
        Assets, 
        Race, 
        RaceState, 
        HackedCiphers, 
        DeckCiphers
    ) {
        (
            Account {
                player_address,
                username,
                games_played: 0,
                games_won: 0
            },
            Assets {
                player_address,
                cars: 0,
                profile_icons: 0,
                garage_environments: 0
            },
            Race {
                player_address,
                game_id: 0,
                is_active: false
            },
            RaceState {
                player_address,
                score: 0,
                shield: 0,
                energy: 0,
                last_action_time: 0
            },
            HackedCiphers {
                player_address,
                cipher_1: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
                cipher_2: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
                cipher_3: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 }
            },
            DeckCiphers {
                player_address,
                cipher_1: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
                cipher_2: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
                cipher_3: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
                cipher_4: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
                cipher_5: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
            }
        )
    }
    
    // TODO: use appropiate types instead of u256
    fn gen_cipher(value_hash: u256, type_hash: u256) -> Cipher {
        let type_weights = [40_u256, 25_u256, 20_u256, 15_u256].span(); // ADV, ATT, SHI, ENE
        let weights_sum: u256 = 100;

        let mut type_in_range = utils::get_range(type_hash, 0, weights_sum);
        let mut type_index: u256 = 3;
        let mut value: u256 = 0;

        let mut i: u256 = 0;
        for curr_type in type_weights {
            if (type_in_range < *curr_type) {
                type_index = i;
                break;
            }
            i += 1;
            type_in_range -= *curr_type;
        };

        if (type_index == 0) {
            value = utils::get_range(value_hash, 5, 10);
        } else {
            value = utils::get_range(value_hash, 1, 5);
        }

        Cipher {
            cipher_type: utils::parse_cipher_type(type_index.try_into().unwrap()),
            cipher_value: value.try_into().unwrap(),
        }
    }

    fn calc_energy_regen(ref raceState: RaceState) -> () {
        let current_time = get_block_timestamp();
        let time_since_action: u64 = current_time - raceState.last_action_time;
    
        let energy_regenerated: u64 = time_since_action / constants::REGEN_EVERY.into();
        let reminder_seconds: u64 = time_since_action % constants::REGEN_EVERY.into();
    
        raceState.energy = if (raceState.energy + energy_regenerated.into() > 10) {
            10
        } else {
            raceState.energy + energy_regenerated.into()
        };
    
        raceState.last_action_timestamp = current_time - reminder_seconds;
    }
    
    fn cipher_stats(
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
        ref player: Player, 
        ref opponent: Player, 
        ref cipher_total_type: CipherTypes, 
        ref cipher_total_value: u8
    ) -> () {
        match cipher_total_type {
            CipherTypes::Advance => { player.score += cipher_total_value.into(); },
            CipherTypes::Attack => {
                let mut cipher_attack = if (opponent.shield > cipher_total_value.into()) {
                    opponent.shield -= cipher_total_value.into();
                    0
                } else {
                    let shield = opponent.shield;
                    opponent.shield = 0;
                    cipher_total_value.into() - shield
                };
    
                if (opponent.score < cipher_attack) {
                    opponent.score = 0;
                } else {
                    opponent.score -= cipher_attack;
                }
            },
            CipherTypes::Shield => { player.shield += cipher_total_value.into(); },
            CipherTypes::Energy => { player.energy += cipher_total_value.into(); },
            _ => { assert(cipher_total_type == CipherTypes::Unknown, constants::UNKNOWN_CIPHER_TYPE); },
        }
    }
}
