/////////////////////////////////////////////////////////////////////////////////
/// ERRORS                                                                    ///
///////////////////////////////////////////////////////////////////////////////// 
pub const ADDRESS_ZERO: felt252 = 'Cannot create from zero address';
pub const USERNAME_TAKEN: felt252 = 'username already taken';
pub const USERNAME_NOT_FOUND: felt252 = 'player with username not found';
pub const USERNAME_EXIST: felt252 = 'username already exist';
pub const ONLY_OWNER_USERNAME: felt252 = 'only user can update username';
pub const UNKNOWN_CIPHER_TYPE: felt252 = 'cipher type is not valid';

/////////////////////////////////////////////////////////////////////////////////
/// GAMEPLAY VALUES                                                           ///
///////////////////////////////////////////////////////////////////////////////// 
pub const MAX_SCORE: u8 = 100;

/////////////////////////////////////////////////////////////////////////////////
/// ENERGY VALUES                                                             ///
///////////////////////////////////////////////////////////////////////////////// 
pub const START_ENERGY: u8 = 6;
pub const REGEN_EVERY: u8 = 3;

/////////////////////////////////////////////////////////////////////////////////
/// CIPHER VALUES                                                             ///
///////////////////////////////////////////////////////////////////////////////// 
pub const DEFAULT_CIPHER_MIN: u8 = 1;
pub const DEFAULT_CIPHER_MAX: u8 = 5;
pub const ADV_CIPHER_MIN: u8 = 5;
pub const ADV_CIPHER_MAX: u8 = 10;
pub const MIXED_CIPHER_MIN: u8 = 1;
pub const MIXED_CIPHER_MAX: u8 = 5;
pub const PURE_CIPHER_MULTIPLIER: u8 = 3;