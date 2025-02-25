import { katana_account, actions_contract_instance as actions_contract } from '$lib/client/starknet';

export async function starknet_buy_tokens(): Promise<{ success: boolean; message: string }> {
    try {
        const calls = [{
            contractAddress: actions_contract.address,
            entrypoint: 'buy_tokens',
            calldata: [0] // pit_id
        }];

        const tx = await katana_account.execute(calls);
        console.log('Buy tokens transaction:', tx);
        return { success: true, message: 'Successfully bought tokens on Starknet!' };
    } catch (error) {
        console.error('Buy tokens error:', error);
        return {
            success: false,
            message: error instanceof Error ? error.message : 'Failed to buy tokens on Starknet'
        };
    }
}

export async function starknet_join_game(): Promise<{ success: boolean; message: string }> {
    try {
        const calls = [{
            contractAddress: actions_contract.address,
            entrypoint: 'join_pit',
            calldata: [0, 10] // pit_id, token_amount
        }];

        const tx = await katana_account.execute(calls);
        console.log('Join game transaction:', tx);
        return { success: true, message: 'Successfully joined game on Starknet!' };
    } catch (error) {
        console.error('Join game error:', error);
        return {
            success: false,
            message: error instanceof Error ? error.message : 'Failed to join game on Starknet'
        };
    }
}