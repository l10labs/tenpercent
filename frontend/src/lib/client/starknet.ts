import { RpcProvider, Account, provider, Contract } from 'starknet';
import manifest from '../../../../contracts/manifest_dev.json'

const katana_provider = new RpcProvider({
    nodeUrl: "http://localhost:5050",
    headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
    }
});

// | Account address |  0x4184158a64a82eb982ff702e4041a49db16fa3a18229aac4ce88c832baf56e4
// | Private key     |  0x6bf3604bcb41fed6c42bcca5436eeb65083a982ff65db0dc123f65358008b51
// | Public key      |  0x4b076e402835913e3f6812ed28cef8b757d4643ebf2714471a387cb10f22be3

const katana_account = new Account(
    katana_provider,
    "0x4184158a64a82eb982ff702e4041a49db16fa3a18229aac4ce88c832baf56e4",
    "0x6bf3604bcb41fed6c42bcca5436eeb65083a982ff65db0dc123f65358008b51",
    "1" // chainId
);

let actions_contract_address = manifest.contracts[0].address;
let actions_abi = manifest.contracts[0].abi;

let actions_contract_instance = new Contract(
    actions_abi,
    actions_contract_address,
    katana_provider,
);

export { katana_provider, katana_account, actions_contract_instance };