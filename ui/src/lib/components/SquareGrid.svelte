<script lang="ts">
	import { controllerStatus } from '$lib/stores/controller_state.svelte';
	import { apolloClient } from '$lib/stores/apollo';
	import { SQUARES_QUERY, get_square_balances, log_squares_data } from '$lib/queries';

	let { showGrid } = $props();

	let squareBalances = $state<number[]>([0, 0, 0, 0]);
	let intervalId: number;

	// Derived states for individual balances
	let s1_balance = $derived(squareBalances[0]);
	let s2_balance = $derived(squareBalances[1]);
	let s3_balance = $derived(squareBalances[2]);
	let s4_balance = $derived(squareBalances[3]);

	function formatDollar(amount: number): string {
		return `$${amount.toFixed(2)}`;
	}

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
						query: SQUARES_QUERY
					});
					console.log('Game state update:', result.data);
					const squareNodes = get_square_balances(result);
					log_squares_data(squareNodes);

					// Convert SquareNode array to number array using total_balance
					const newBalances = squareNodes.map((node) =>
						Number(Number(node.total_balance || 0).toFixed(2))
					);
					squareBalances = newBalances;
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
