<script lang="ts">
	import { controllerStatus, moveSquare } from '$lib/stores/controller_state.svelte';
	import { apolloClient } from '$lib/stores/apollo';
	import { SQUARES_QUERY, get_square_balances, log_squares_data } from '$lib/queries';
	import { TOKEN_BASE_DECIMALS } from '$lib/config';

	let { showGrid } = $props();

	let query_data: any;
	let squareBalances = $state([0, 0, 0, 0]);
	let intervalId: number;
	let selectedSquare = $state<string | null>(null);
	let animatingSquare = $state<string | null>(null);

	let s0_balance = $derived(squareBalances[0]);
	let s1_balance = $derived(squareBalances[1]);
	let s2_balance = $derived(squareBalances[2]);
	let s3_balance = $derived(squareBalances[3]);

	$effect(() => {
		// Clear any existing interval when effect reruns
		if (intervalId) {
			clearInterval(intervalId);
		}

		// Only start polling if controller is connected
		if (controllerStatus.is_connected) {
			intervalId = setInterval(async () => {
				await queryBalances();
			}, 500);

			// Cleanup function
			return () => {
				if (intervalId) {
					clearInterval(intervalId);
				}
			};
		}
	});

	async function queryBalances() {
		try {
			const result = await apolloClient.query({
				query: SQUARES_QUERY
			});
			console.log('Fresh from graphql:', result.data);
			let balance = result.data.dojoStarterSquareModels.edges[0].node.total_balance;
			let balance2 = result.data.dojoStarterSquareModels.edges[1].node.total_balance;
			let balance3 = result.data.dojoStarterSquareModels.edges[2].node.total_balance;
			let balance4 = result.data.dojoStarterSquareModels.edges[3].node.total_balance;
			console.log(
				`balance: ${balance}, balance2: ${balance2}, balance3: ${balance3}, balance4: ${balance4}`
			);
			parse_data(result.data);
		} catch (error) {
			console.error('Query error:', error);
		}
	}

	async function parse_data(squares_query_data: any) {
		let squares_array = squares_query_data.dojoStarterSquareModels.edges;
		squares_array.forEach((square: any) => {
			console.log(`${square.node.square_id}: ${square.node.total_balance}`);
			let balance = Number(square.node.total_balance) + Number(square.node.total_escrow);
			if (balance > 0) {
				squareBalances[square.node.square_id] = balance / TOKEN_BASE_DECIMALS;
			} else {
				squareBalances[square.node.square_id] = 0;
			}
		});
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

	async function handleMoveSquare(square_id: string) {
		if (!controllerStatus.sharedController) {
			console.log('no controller');
			return;
		}
		selectedSquare = square_id;
		animatingSquare = square_id;
		setTimeout(() => {
			animatingSquare = null;
		}, 300); // Reset animation after 300ms
		await moveSquare(controllerStatus.sharedController, square_id);
	}
</script>

<div class="xs:px-3 w-full max-w-[480px] px-2 sm:px-4">
	<div class="xs:gap-3 grid grid-cols-2 gap-2 sm:gap-4 md:gap-6">
		{#each Array(4) as _, i}
			<button
				onclick={() => handleMoveSquare(`0x${i}`)}
				class="group relative flex aspect-square w-full max-w-[232px] items-center justify-center rounded border bg-white transition-all duration-300 hover:bg-blue-50
					{showGrid ? 'scale-100 opacity-100' : 'scale-0 opacity-0'}
					{selectedSquare === `0x${i}`
					? 'border-blue-500 bg-blue-50 shadow-lg ring-2 ring-blue-200'
					: 'border-gray-800'}
					{animatingSquare === `0x${i}` ? 'rotate-3 scale-110' : ''}"
				style="transition-delay: {300 + i * 150}ms"
			>
				<!-- Balance display with animation -->
				<span
					class="xs:text-xs relative text-[10px] transition-all duration-300
					group-hover:-translate-y-1 group-hover:scale-110 sm:text-sm md:text-base
					{selectedSquare === `0x${i}` ? 'font-semibold text-blue-700' : 'font-medium text-gray-800'}"
				>
					{formatDollar(squareBalances[i])}
				</span>

				<!-- Square number indicator -->
				<span
					class="xs:text-[10px] absolute bottom-1 right-1 font-mono text-[8px] text-gray-400 sm:text-xs"
				>
					{i + 1}
				</span>
			</button>
		{/each}
	</div>
</div>

<style>
	button {
		transform-origin: center;
		backface-visibility: hidden;
		-webkit-font-smoothing: subpixel-antialiased;
	}
</style>
