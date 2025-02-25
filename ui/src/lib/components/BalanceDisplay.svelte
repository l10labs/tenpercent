<script lang="ts">
	import { controllerStatus } from '$lib/stores/controller_state.svelte';
	import { apolloClient } from '$lib/stores/apollo';
	import { PLAYER_IN_PIT_QUERY } from '$lib/queries';
	import { TOKEN_BASE_DECIMALS } from '$lib/config';

	let { showGrid = false } = $props();
	let balance = $state(0);
	let intervalId: number;
	let my_player_contract_address = controllerStatus.sharedController?.account?.address;

	$effect(() => {
		// Clear any existing interval when effect reruns
		if (intervalId) {
			clearInterval(intervalId);
		}

		// Only start polling if controller is connected
		if (controllerStatus.is_connected) {
			intervalId = setInterval(async () => {
				await queryPlayerInPit();
			}, 2000);

			// Cleanup function
			return () => {
				if (intervalId) {
					clearInterval(intervalId);
				}
			};
		}
	});

	async function queryPlayerInPit() {
		const result = await apolloClient.query({
			query: PLAYER_IN_PIT_QUERY
		});
		console.log('Player MAIN BALANCE INFO:');
		console.log(result.data);
		let all_players = result.data.dojoStarterPlayerModels.edges;
		let my_player = all_players.find((player: any) => {
			if (player.node.player_id == my_player_contract_address) {
				let full_balance = Number(player.node.balance) + Number(player.node.escrow);
				balance = full_balance / TOKEN_BASE_DECIMALS;
			}
		});
		let player_balance = my_player.node.balance;

		console.log(`player_balance: ${player_balance}`);
	}

	function formatDollar(amount: number): string {
		return new Intl.NumberFormat('en-US', {
			style: 'currency',
			currency: 'USD',
			minimumFractionDigits: 2,
			maximumFractionDigits: 2
		}).format(amount);
	}
</script>

<div class="w-full max-w-[480px] px-4 sm:px-0">
	<div
		class="scale-0 opacity-0 transition-all duration-500"
		class:scale-100={showGrid}
		class:opacity-100={showGrid}
		style="transition-delay: 150ms"
	>
		<div class="text-center">
			<span class="text-4xl font-bold sm:text-5xl md:text-6xl">
				{formatDollar(balance)}
			</span>
		</div>
	</div>
</div>
