<script lang="ts">
	import { onMount } from 'svelte';
	import { RpcProvider } from 'starknet';
	import Controller, { type SessionPolicies, type ControllerOptions } from '@cartridge/controller';
	import { controllerStatus } from '$lib/stores/controller_state.svelte';

	const rpcUrl = 'https://api.cartridge.gg/x/tenpercentfun/katana';
	const providerKatanaDev = new RpcProvider({
		nodeUrl: rpcUrl
	});

	// let chain_id = '0x57505f5351554152455332';
	// let chain_id = '0x57505f54454e50455243454e5446554e';
	const policies: SessionPolicies = {};

	let controller: Controller | undefined;

	let controllerUsername: string | undefined = $state('');
	let balance: number = $state(0);

	onMount(async () => {
		let chain_id = await providerKatanaDev.getChainId();
		console.log(chain_id);
		let options = await getOptions();
		controller = new Controller(options);
		if (await controller.probe()) {
			await connect();
			controllerUsername = await controller.username();
			controllerStatus.sharedController = controller;
			controllerStatus.is_connected = true;
		}
	});

	async function getOptions(): Promise<ControllerOptions> {
		let chain_id = await providerKatanaDev.getChainId();
		console.log(chain_id);
		let options = {
			policies,
			defaultChainId: chain_id,
			chains: [
				{
					rpcUrl: rpcUrl
				}
			]
		};
		return options;
	}

	async function connect() {
		if (!controller) {
			console.log('no controller');
			return;
		}
		try {
			const res = await controller.connect();
			if (res) {
				controllerUsername = await controller.username();
				console.log(controllerUsername);
				console.log('controller logged in i think');
				controllerStatus.sharedController = controller;
				controllerStatus.is_connected = true;
			}
		} catch (e) {
			console.log(e);
		}
	}

	async function disconnect() {
		if (!controller) {
			console.log('no controller');
			return;
		}
		await controller.disconnect();
		controllerUsername = undefined;
		controllerStatus.is_connected = false;
		controllerStatus.sharedController = undefined;
	}
</script>

{#if controllerStatus.is_connected && controllerUsername}
	<div class="flex items-center gap-4">
		<span class="text-sm">{controllerUsername}</span>
		<span class="rounded-full bg-gray-100 px-3 py-1 text-sm font-medium">{balance} tokens</span>
		<button onclick={disconnect} class="rounded border px-3 py-1 text-sm hover:bg-gray-50">
			Disconnect
		</button>
	</div>
{:else if !controllerStatus.is_connected}
	<button onclick={connect} class="rounded border px-3 py-1 text-sm hover:bg-gray-50">
		Connect
	</button>
{/if}
