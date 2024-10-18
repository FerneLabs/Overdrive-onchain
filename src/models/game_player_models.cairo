use overdrive::utils;
use starknet::{ContractAddress, get_block_timestamp};

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct GamePlayer {
    #[key]
    pub address: ContractAddress,
    pub game_id: usize,
    pub car: u256, // Should be a contractAddress NFT
    // TODO: switch to Cipher Array
    pub get_cipher_1: Cipher,
    pub get_cipher_2: Cipher,
    pub get_cipher_3: Cipher,
    pub last_action_timestamp: u64,
    pub score: u256,
    pub energy: u256,
    pub shield: u256,
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

pub trait GamePlayerTrait {
    fn new_game_player(address: ContractAddress, game_id: u32) -> GamePlayer;
    fn gen_cipher(value_hash: u256, type_hash: u256) -> Cipher;
}

impl GamePlayerImpl of GamePlayerTrait {
    fn new_game_player(address: ContractAddress, game_id: u32) -> GamePlayer {
        let current_time = get_block_timestamp();

        GamePlayer {
            address: address,
            game_id,
            car: 1,
            score: 0,
            energy: 6,
            shield: 0,
            get_cipher_1: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
            get_cipher_2: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
            get_cipher_3: Cipher { cipher_type: CipherTypes::Unknown, cipher_value: 0 },
            last_action_timestamp: current_time
        }
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
}
