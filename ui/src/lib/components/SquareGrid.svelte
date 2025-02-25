<script lang="ts">
	import { controllerStatus } from '$lib/stores/controller_state.svelte';
	import { apolloClient } from '$lib/stores/apollo';
	import { SQUARES_QUERY, get_square_balances, log_squares_data } from '$lib/queries';
	import { TOKEN_BASE_DECIMALS } from '$lib/config';

	let { showGrid } = $props();

	let squareBalances = $state([0, 0, 0, 0]);
	let intervalId: number;

	let s1_balance = $derived(squareBalances[0]);
	let s2_balance = $derived(squareBalances[1]);
	let s3_balance = $derived(squareBalances[2]);
	let s4_balance = $derived(squareBalances[3]);

	$effect(() => {
		// Clear any existing interval when effect reruns
		if (intervalId) {
			clearInterval(intervalId);
		}

		// Only start polling if controller is connected
		if (controllerStatus.is_connected) {
			intervalId = setInterval(async () => {
				await updateBalances();
			}, 2000);

			// Cleanup function
			return () => {
				if (intervalId) {
					clearInterval(intervalId);
				}
			};
		}
	});

	async function updateBalances() {
		try {
			const result = await apolloClient.query({
				query: SQUARES_QUERY
			});
			console.log('Game state update:', result.data);
			const squareNodes = get_square_balances(result);
			log_squares_data(squareNodes);

			// Convert SquareNode array to number array using total_balance
			squareNodes.forEach((node) => {
				let graphql_balance = Number(Number(node.total_balance) / TOKEN_BASE_DECIMALS);
				let graphql_escrow = Number(Number(node.total_escrow) / TOKEN_BASE_DECIMALS);
				console.log(`graphql_balance: ${graphql_balance}, graphql_escrow: ${graphql_escrow}`);
				squareBalances[node.square_id] = graphql_balance + graphql_escrow;
				console.log(`squareBalances: ${squareBalances}`);
			});
		} catch (error) {
			console.error('Query error:', error);
		}
	}

	function formatDollar(amount: number): string {
		// Format as US dollars with commas for thousands and 2 decimal places
		return new Intl.NumberFormat('en-US', {
			style: 'currency',
			currency: 'USD',
			minimumFractionDigits: 2,
			maximumFractionDigits: 2
		}).format(amount);
	}
</script>

<div class="w-full max-w-[480px] px-4 sm:px-0">
	<div class="grid grid-cols-2 gap-3 sm:gap-6">
		<div
			class="flex aspect-square w-full max-w-[232px] scale-0 items-center justify-center rounded border border-gray-800 opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 300ms"
		>
			<span class="text-base font-medium sm:text-xl">{formatDollar(s1_balance)}</span>
		</div>
		<div
			class="flex aspect-square w-full max-w-[232px] scale-0 items-center justify-center rounded border border-gray-800 opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 450ms"
		>
			<span class="text-base font-medium sm:text-xl">{formatDollar(s2_balance)}</span>
		</div>
		<div
			class="flex aspect-square w-full max-w-[232px] scale-0 items-center justify-center rounded border border-gray-800 opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 600ms"
		>
			<span class="text-base font-medium sm:text-xl">{formatDollar(s3_balance)}</span>
		</div>
		<div
			class="flex aspect-square w-full max-w-[232px] scale-0 items-center justify-center rounded border border-gray-800 opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 750ms"
		>
			<span class="text-base font-medium sm:text-xl">{formatDollar(s4_balance)}</span>
		</div>
	</div>
</div>
