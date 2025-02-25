<script lang="ts">
	import { onMount } from 'svelte';
	import { controllerStatus } from '$lib/stores/controller_state.svelte';
	import { apolloClient } from '$lib/stores/apollo';
	import { SQUARES_QUERY, get_square_balances, log_squares_data } from '$lib/queries';
	import GameControls from '$lib/components/GameControls.svelte';
	import SquareGrid from '$lib/components/SquareGrid.svelte';

	let showGrid = $state(false);
	let squareBalances = $state<number[]>([0, 0, 0, 0]);

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

	onMount(() => {
		// Small delay to ensure page transition is complete
		setTimeout(() => {
			showGrid = true;
		}, 100);
	});
</script>

{#if controllerStatus.is_connected}
	<div class="flex flex-col items-center gap-8 pt-24">
		<GameControls {showGrid} />
		<SquareGrid {showGrid} />
	</div>
{:else}
	<div class="flex h-screen items-center justify-center">
		<h1 class="text-2xl">Please connect via controller</h1>
	</div>
{/if}
