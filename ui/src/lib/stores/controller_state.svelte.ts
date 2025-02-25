import manifest from '../../../../contracts/manifest_release.json';
import { Contract } from 'starknet';
import Controller from '@cartridge/controller';

let sharedController: undefined | Controller;
export const controllerStatus = $state({ is_connected: false, sharedController: sharedController });

let contract_address = manifest.contracts[0].address;
let manual_from_sozo_inspect = '0x00ef660ffdd25c054442280efdb20505035219d8be079eff2e8baaed71f28554';
console.log(contract_address);
console.log(manual_from_sozo_inspect);
let mainContractClass: any;
let mainContract: Contract;

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
                contractAddress: manual_from_sozo_inspect,
                entrypoint: "buy_tokens",
                calldata: ['0x0'],
            },
        ]);
        console.log(result);
    } catch (e) {
        console.log(e);
    }
}