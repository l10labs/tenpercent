<script lang="ts">
	import { controllerStatus } from '$lib/stores/controller_state.svelte';
	import { apolloClient } from '$lib/stores/apollo';
	import { PIT_QUERY } from '$lib/queries';
	import { BOMB_TIME } from '$lib/config';

	let { showGrid = false } = $props();
	let progress = $state(100); // Fixed progress value for now
	let intervalId: number;

	$effect(() => {
		// Clear any existing interval when effect reruns
		if (intervalId) {
			clearInterval(intervalId);
		}

		// Only start polling if controller is connected
		if (controllerStatus.is_connected) {
			intervalId = setInterval(async () => {
				await queryBombTime();
			}, 500);

			// Cleanup function
			return () => {
				if (intervalId) {
					clearInterval(intervalId);
				}
			};
		}
	});

	async function queryBombTime() {
		try {
			const result = await apolloClient.query({
				query: PIT_QUERY
			});
			console.log('Fresh from graphql:', result.data);
			console.log(result.data);
			let bombTime = result.data.dojoStarterPitModels.edges[0].node.bomb_counter;
			let query_progress = (bombTime / BOMB_TIME) * 100;
			console.log(`progress: ${query_progress}`);
			progress = Math.round(query_progress);
		} catch (error) {
			console.error('Query error:', error);
		}
	}
</script>

<div class="w-full max-w-[480px] px-4 sm:px-0">
	<div
		class="scale-0 opacity-0 transition-all duration-500"
		class:scale-100={showGrid}
		class:opacity-100={showGrid}
		style="transition-delay: 900ms"
	>
		<div class="h-4 w-full rounded-full bg-gray-200">
			<div
				class="h-full rounded-full bg-gray-800 transition-all duration-300 ease-in-out"
				style="width: {progress}%"
			></div>
		</div>
		<div class="mt-2 text-center text-sm text-gray-600">
			{progress}% till Ten Percent Wave
		</div>
	</div>
</div>
