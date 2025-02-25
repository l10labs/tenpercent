<script lang="ts">
	import GameGrid from '$lib/components/GameGrid.svelte';
	import { onMount } from 'svelte';
	import { controllerStatus } from '$lib/stores/controller_state.svelte';
	import { apolloClient } from '$lib/stores/apollo';
	import { SQUARES_QUERY, get_square_balances, log_squares_data } from '$lib/queries';

	let showGrid = $state(false);
	let squareBalances = $state([0, 0, 0, 0]);

	// Derived states for individual balances
	let s1_balance = $derived(squareBalances[0]);
	let s2_balance = $derived(squareBalances[1]);
	let s3_balance = $derived(squareBalances[2]);
	let s4_balance = $derived(squareBalances[3]);

	let intervalId: number;
	let test_counter = 0;

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
	<!-- <div class="flex min-h-screen flex-col items-center justify-center p-4">
		<div class="w-full">
			<GameGrid {showGrid} />
		</div>
	</div> -->

	<div class="flex min-h-screen flex-col items-center justify-center p-4">
		<h1>S1: {s1_balance}</h1>
		<h1>S2: {s2_balance}</h1>
		<h1>S3: {s3_balance}</h1>
		<h1>S4: {s4_balance}</h1>
	</div>
{:else}
	<div class="flex h-screen items-center justify-center">
		<h1 class="text-2xl">Please connect via controller</h1>
	</div>
{/if}
