<script lang="ts">
	import GameGrid from '$lib/components/GameGrid.svelte';
	import { onMount } from 'svelte';
	import { controllerStatus } from '$lib/stores/controller_state.svelte';
	import { apolloClient } from '$lib/stores/apollo';
	import { SQUARES_QUERY, get_square_balances, log_squares_data } from '$lib/queries';

	let showGrid = $state(false);

	let s1_balance = $state(0);
	let s2_balance = $state(0);
	let s3_balance = $state(0);
	let s4_balance = $state(0);

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
					const square_balances = get_square_balances(result);
					log_squares_data(square_balances);

					// Update the balances when they change
					square_balances.forEach((balance, index) => {
						switch (index) {
							case 0:
								s1_balance = balance;
								break;
							case 1:
								s2_balance = balance;
								break;
							case 2:
								s3_balance = balance;
								break;
							case 3:
								s4_balance = balance;
								break;
						}
					});
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
	<div class="flex min-h-screen flex-col items-center justify-center p-4">
		<div class="w-full">
			<GameGrid {showGrid} />
		</div>
	</div>
{:else}
	<div class="flex h-screen items-center justify-center">
		<h1 class="text-2xl">Please connect via controller</h1>
	</div>
{/if}
