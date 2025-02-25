<script lang="ts">
	import { onMount } from 'svelte';
	import { Contract, RpcProvider } from 'starknet';
	import Controller, { type SessionPolicies, type ControllerOptions } from '@cartridge/controller';
	import manifest from '../../../../contracts/manifest_dev.json';

	const rpcUrl = 'https://api.cartridge.gg/x/squares2/katana';
	const providerKatanaDev = new RpcProvider({
		nodeUrl: rpcUrl
	});

	let contract_address = manifest.contracts[0].address;
	let mainContractClass: any;
	let mainContract: Contract;

	let chain_id = '0x57505f5351554152455332';
	const policies: SessionPolicies = {};
	let options = {
		policies,
		defaultChainId: chain_id,
		chains: [
			{
				rpcUrl: rpcUrl
			}
		]
	};
	let controller = new Controller(options);

	let isControllerConnected = $state(true);

	let controllerUsername: string | undefined = $state('');

	onMount(async () => {
		if (await controller.probe()) {
			await connect();
			controllerUsername = await controller.username();
			isControllerConnected = false;
		}
	});

	async function connect() {
		try {
			const res = await controller.connect();
			if (res) {
				controllerUsername = await controller.username();
				console.log(controllerUsername);
				console.log('controller logged in i think');
				isControllerConnected = false;
			}
		} catch (e) {
			console.log(e);
		}
	}

	async function disconnect() {
		await controller.disconnect();
		controllerUsername = undefined;
		isControllerConnected = true;
	}
</script>

{#if isControllerConnected}
	<button onclick={connect} class="rounded border px-3 py-1 text-sm hover:bg-gray-50">
		Connect
	</button>
{/if}

{#if !isControllerConnected && controllerUsername}
	<div class="flex items-center gap-2">
		<span class="font-small">{controllerUsername}</span>
		<button onclick={disconnect} class="rounded border px-3 py-1 text-sm hover:bg-gray-50">
			Disconnect
		</button>
	</div>
{/if}
