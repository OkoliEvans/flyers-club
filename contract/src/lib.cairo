use starknet::{ContractAddress};
#[starknet::interface]
trait IERC20<TContractState> {
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, receiver: ContractAddress, amount: u256);
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, receiver: ContractAddress, amount: u256
    );
}

#[starknet::contract]
mod Wings_club {
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};

    #[storage]
    struct Storage {
        vault: ContractAddress,
        owner: ContractAddress,
        vault_balance: u256,
        token: IERC20Dispatcher,
        user_record: LegacyMap::<ContractAddress, u256>,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let ether_on_goerli = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
            .try_into()
            .unwrap();
          let owner = 0x050050e9471eabfffd9f37482d5638ea36d03ce175559c088be74915535d17dc
            .try_into()
            .unwrap();
        let vault = get_contract_address();

        self.owner.write(owner);
        self.vault.write(vault);
        self.token.write(IERC20Dispatcher { contract_address: ether_on_goerli });
    }

    #[abi(embed_v0)]
    fn accept_deposit(ref self: ContractState, amount: u256) {
        let user = get_caller_address();
        let user_bal = self.user_record.read(user);
        let vault_bal = self.vault_balance.read();

        self.token.read().transfer_from(user, self.vault.read(), amount);
        self.vault_balance.write(vault_bal + amount);
        self.user_record.write(user, (user_bal + amount));
    }

    #[abi(embed_v0)]
    fn withdraw(ref self: ContractState, amount: u256, to: ContractAddress) {
        let caller = get_caller_address();
        let vault_bal = self.vault_balance.read();
        assert(caller == self.owner.read(), 'unauthorized caller');

        self.token.read().transfer(to, amount); 
        self.vault_balance.write(vault_bal - amount);
    }
}
