import { Contract, RpcProvider } from "starknet";
import Controller, { type SessionPolicies } from "@cartridge/controller";
import manifest from '../../../contracts/manifest_dev.json';

const rpcUrl = "https://api.cartridge.gg/x/squares2/katana";
const providerKatanaDev = new RpcProvider({
    nodeUrl: rpcUrl,
});

let contract_address = manifest.contracts[0].address;
let mainContractClass: any;
let mainContract: Contract;
let chain_id = await providerKatanaDev.getChainId();

const policies: SessionPolicies = {}

// const controller = new Controller(
//     {
//         defaultChainId: 'SN_MAINNET',
//         chains: [
//             {
//                 rpcUrl: rpcUrl,
//             }
//         ]
//     }
// );

let options: ControllerOptions = {
    policies,
    defaultChainId: chain_id,
    chains: [
        {
            rpcUrl: rpcUrl,
        }
    ]
}