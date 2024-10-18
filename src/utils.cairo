use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};
use overdrive::models::player_models::CipherTypes;

pub fn hash2(val_1: felt252, val_2: felt252) -> felt252 {
    let mut hash = PoseidonTrait::new();

    hash = hash.update(val_1);
    hash = hash.update(val_2);

    hash.finalize()
}

pub fn hash4(val_1: felt252, val_2: felt252, val_3: felt252, val_4: felt252) -> felt252 {
    let mut hash = PoseidonTrait::new();

    hash = hash.update(val_1);
    hash = hash.update(val_2);
    hash = hash.update(val_3);
    hash = hash.update(val_4);

    hash.finalize()
}

pub fn get_range(value: u256, min: u256, max: u256) -> u256 {
    min + (value % (max - min + 1))
}

pub fn parse_cipher_type(cipher_type: u8) -> CipherTypes {
    match cipher_type {
        0 => CipherTypes::Advance,
        1 => CipherTypes::Attack,
        2 => CipherTypes::Energy,
        3 => CipherTypes::Shield,
        _ => { CipherTypes::Unknown }
    }
}
