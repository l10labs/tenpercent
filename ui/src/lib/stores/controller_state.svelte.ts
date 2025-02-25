import Controller from '@cartridge/controller';
import { manual_contract_address_from_sozo_inspect } from '$lib/config';

let sharedController: undefined | Controller;
export const controllerStatus = $state({ is_connected: false, sharedController: sharedController });

let contract_address = manual_contract_address_from_sozo_inspect;
console.log(contract_address);

export async function buyTokens(controller: Controller) {
    if (!controller) {
        console.log('no controller');
        return;
    };
    let executeAccount = controller?.account;
    if (!executeAccount) {
        console.log('no execute account');
        return;
    };
    try {
        const result = await executeAccount?.execute([
            {
                contractAddress: contract_address,
                entrypoint: "buy_tokens",
                calldata: ['0x0'],
            },
        ]);
        console.log(result);
    } catch (e) {
        console.log(e);
    }
}

export async function joinPit(controller: Controller) {
    if (!controller) {
        console.log('no controller');
        return;
    };
    let executeAccount = controller?.account;
    if (!executeAccount) {
        console.log('no execute account');
        return;
    };
    try {
        const result = await executeAccount?.execute([
            {
                contractAddress: contract_address,
                entrypoint: "join_pit",
                // joining with half the user's token balance
                calldata: ['0x0', '0x2d79883d2000'],
            },
        ]);
        console.log(result);
    } catch (e) {
        console.log(e);
    }
}