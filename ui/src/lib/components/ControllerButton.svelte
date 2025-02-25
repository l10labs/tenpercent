<script lang="ts">
	import { onMount } from 'svelte';
	import { RpcProvider } from 'starknet';
	import Controller, { type SessionPolicies, type ControllerOptions } from '@cartridge/controller';
	import { controllerStatus } from '$lib/stores/controller_state.svelte';
	import { apolloClient } from '$lib/stores/apollo';
	import { USER_TOKEN_QUERY, get_token_balances, match_user_contract_address } from '$lib/queries';
	import { TOKEN_BASE_DECIMALS } from '$lib/config';

	const rpcUrl = 'https://api.cartridge.gg/x/tenpercentfun/katana';
	const providerKatanaDev = new RpcProvider({
		nodeUrl: rpcUrl
	});

	const policies: SessionPolicies = {};

	let controller: Controller | undefined;

	let controllerUsername: string | undefined = $state('');
	let player_contract_address: string | undefined = $state(undefined);
	let balance: string = $state('0');

	onMount(async () => {
		let chain_id = await providerKatanaDev.getChainId();
		console.log(chain_id);
		let options = await getOptions();
		controller = new Controller(options);
		if (await controller.probe()) {
			await connect();
			controllerUsername = await controller.username();
			player_contract_address = await controller.account?.address;
			controllerStatus.sharedController = controller;
			controllerStatus.is_connected = true;
		}
	});

	let intervalId: number;

	$effect(() => {
		// Clear any existing interval when effect reruns
		if (intervalId) {
			clearInterval(intervalId);
		}

		// Only start polling if controller is connected
		if (controllerStatus.is_connected) {
			intervalId = setInterval(async () => {
				try {
					const result = await apolloClient.query({
						query: USER_TOKEN_QUERY
					});
					console.log('User token query result:', result.data);
					const user_token_data = get_token_balances(result);
					console.log(user_token_data);
					const matched_object = match_user_contract_address(
						user_token_data,
						player_contract_address ?? ''
					);
					console.log(matched_object);
					if (matched_object) {
						balance = Number(Number(matched_object.balance) / TOKEN_BASE_DECIMALS).toFixed(2);
					}
				} catch (error) {
					console.error('Query error:', error);
				}
			}, 2000);

			// Cleanup function
			return () => {
				if (intervalId) {
					clearInterval(intervalId);
				}
			};
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
				player_contract_address = await controller.account?.address;
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
