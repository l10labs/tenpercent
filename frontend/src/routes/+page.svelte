<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { browser } from '$app/environment';
	import type { Player, Square, GameResult, GameResponse, SerializableSquare } from '$lib/types';
	import { tweened } from 'svelte/motion';
	import { cubicOut } from 'svelte/easing';

	// Initialize data with default values
	let highestBalanceSquare = 0;
	let data: GameResponse = {
		squares: [],
		bombCounter: 5,
		roundNumber: 1,
		previousRoundResult: null,
		success: true
	};
	let playerName = '';
	let eventSource: EventSource;
	let isLoading = false;
	let errorMessage = '';
	let gameResult: GameResult | null = null;
	let previousBalance = 0;
	let balanceChangeClass = '';

	// Track balance changes
	$: currentBalance = getPlayers(data?.squares?.[currentSquare])
		?.find(p => p.name === playerName)?.balance ?? 0;

	$: if (currentBalance !== previousBalance && previousBalance !== 0) {
		balanceChangeClass = currentBalance > previousBalance ? 'balance-increase' : 'balance-decrease';
		setTimeout(() => {
			balanceChangeClass = '';
		}, 1000);
		previousBalance = currentBalance;
	} else if (previousBalance === 0) {
		previousBalance = currentBalance;
	}

	// Track which square has the highest balance
	$: {
		if (data?.squares) {
			const balances = data.squares.map(square => square.totalBalancePoints);
			const maxBalance = Math.max(...balances);
			highestBalanceSquare = balances.findIndex(balance => balance === maxBalance);
		}
	}

	function getPlayers(square: SerializableSquare | undefined): Player[] {
		if (!square) return [];
		return square.players;
	}

	function getHighestBalanceSquares(): number[] {
		if (gameResult) return gameResult.losingSquares;
		if (!data?.squares) return [];
		const balances = data.squares.map((square) => square.totalBalancePoints);
		const maxBalance = Math.max(...balances);
		return balances.reduce((acc, balance, index) => {
			if (balance === maxBalance) acc.push(index);
			return acc;
		}, [] as number[]);
	}

	$: isJoined = data?.squares?.some((square) =>
		square.players.some((player) => player.name === playerName)
	) ?? false;

	$: currentSquare = data?.squares?.findIndex((square) =>
		square.players.some((player) => player.name === playerName)
	) ?? -1;

	function showError(message: string) {
		errorMessage = message;
		setTimeout(() => {
			errorMessage = '';
		}, 5000);
	}

	onMount(async () => {
		if (browser) {
			playerName = localStorage.getItem('playerName') || '';
			
			try {
				// Initial game state
				const response = await fetch('/api/status');
				const result = await response.json();
				if (!response.ok) throw new Error(result.error || 'Failed to fetch game status');
				data = result;

				// Setup SSE
				eventSource = new EventSource('/api/game-updates');
				eventSource.onmessage = (event) => {
					try {
						const newData = JSON.parse(event.data) as GameResponse;
						data = newData;
						
						if (newData.gameResult && !gameResult) {
							gameResult = newData.gameResult;
							setTimeout(() => {
								gameResult = null;
							}, 2000);
						}
					} catch (error) {
						console.error('Error processing SSE message:', error);
					}
				};

				eventSource.onerror = () => {
					console.error('SSE connection error');
				};
			} catch (error) {
				showError(error instanceof Error ? error.message : 'Failed to initialize game');
			}
		}
	});

	onDestroy(() => {
		if (eventSource) eventSource.close();
	});

	async function handleJoin(e: SubmitEvent) {
		e.preventDefault();
		if (!playerName.trim()) return;

		try {
			const response = await fetch('/api/join', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ playerName })
			});
			const result = await response.json();
			if (!response.ok) throw new Error(result.error || 'Failed to join');
			data = result;
			localStorage.setItem('playerName', playerName);
			errorMessage = '';
		} catch (error) {
			showError(error instanceof Error ? error.message : 'Failed to join');
		}
	}

	async function handleMove(toSquare: number) {
		if (!isJoined || currentSquare === toSquare || isLoading) return;
		isLoading = true;

		try {
			const response = await fetch('/api/move', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ playerName, toSquare })
			});
			const result = await response.json();
			if (!response.ok) throw new Error(result.error || 'Failed to move');
			data = result;
		} catch (error) {
			showError(error instanceof Error ? error.message : 'Failed to move');
		} finally {
			isLoading = false;
		}
	}

	async function handleReset() {
		try {
			const response = await fetch('/api/reset', { method: 'POST' });
			const result = await response.json();
			if (!response.ok) throw new Error(result.error || 'Failed to reset');
			data = result;
			gameResult = null;
		} catch (error) {
			showError(error instanceof Error ? error.message : 'Failed to reset');
		}
	}

	function handleLeave() {
		if (eventSource) eventSource.close();
		localStorage.removeItem('playerName');
		window.location.reload();
	}
</script>

<main class="container mx-auto px-4 py-8 max-w-3xl">
	<div class="mb-12 text-center">
		<h1 class="text-4xl font-bold mb-6 text-gray-800">Ten Percent</h1>
		
		{#if !isJoined}
			<form on:submit={handleJoin} class="flex gap-2 justify-center max-w-md mx-auto">
				<input
					type="text"
					bind:value={playerName}
					placeholder="Enter your name"
					class="px-4 py-2 border rounded flex-grow focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
				/>
				<button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
					Join Game
				</button>
			</form>
		{:else}
			<div class="flex flex-col items-center mb-8">
				<div class="text-xl mb-3 text-gray-600">Playing as: <strong class="text-gray-800">{playerName}</strong></div>
				{#if data?.squares}
					<div class="text-5xl font-bold text-black {balanceChangeClass} tracking-tight">
						${(getPlayers(data.squares[currentSquare])
							.find(p => p.name === playerName)?.balance ?? 0).toFixed(2)}
					</div>
				{/if}
			</div>
			<div class="absolute top-4 right-4">
				<button 
					on:click={handleLeave}
					class="bg-red-500 text-white px-3 py-1.5 rounded text-sm hover:bg-red-600 transition-colors"
				>
					Leave Game
				</button>
			</div>
		{/if}
	</div>

	{#if errorMessage}
		<div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4 text-center max-w-md mx-auto">
			{errorMessage}
		</div>
	{/if}

	<div class="flex justify-between items-center mb-8 max-w-2xl mx-auto">
		<div class="w-full">
			<div class="flex justify-between text-sm mb-2 text-gray-600 font-medium">
				<span>Bomb explodes in: <strong>{data?.bombCounter}</strong> moves</span>
				<span>{Math.round((data?.bombCounter / 5) * 100)}%</span>
			</div>
			<div class="w-full bg-gray-200 rounded-full h-5 overflow-hidden shadow-inner">
				<div
					class="h-full transition-all duration-500 ease-in-out rounded-full shadow-sm"
					style="width: {(data?.bombCounter / 5) * 100}%; 
						background-color: rgb({255 - ((data?.bombCounter / 5) * 255)}, {((data?.bombCounter / 5) * 255)}, 0)"
				/>
			</div>
		</div>
	</div>

	<div class="grid grid-cols-2 gap-6 mb-8">
		{#each Array(4) as _, i}
			<button
				class="p-6 border-2 rounded-xl text-left transition-all duration-200 shadow-sm hover:shadow-md
					{currentSquare === i ? 'bg-blue-50 border-blue-200' : 'hover:bg-gray-50'}
					{gameResult?.losingSquares?.includes(i) ? 'bg-red-100 border-red-200' : ''}
					{isJoined && currentSquare !== i && !isLoading ? 'cursor-pointer' : 'cursor-not-allowed'}
					relative"
				on:click={() => handleMove(i)}
				disabled={!isJoined || currentSquare === i || isLoading}
			>
				{#if highestBalanceSquare === i}
					<div class="absolute top-3 right-3 bomb-icon">
						<span class="text-2xl">💣</span>
					</div>
				{/if}
				<h3 class="text-lg font-semibold mb-3 text-gray-700">Square {i + 1}</h3>
				<div class="space-y-1">
					{#each getPlayers(data?.squares?.[i]) as player}
						<div class="flex justify-between items-center">
							<span class={player.name === playerName ? 'font-bold text-blue-600' : ''}>
								{player.name}
							</span>
							<span class="text-black">
								${player.balance.toFixed(2)}
							</span>
						</div>
					{/each}
				</div>
				<div class="mt-3 text-sm font-medium text-gray-500 border-t pt-2">
					Total: ${(data?.squares?.[i]?.totalBalancePoints ?? 0).toFixed(2)}
				</div>
			</button>
		{/each}
	</div>

	{#if data?.previousRoundResult}
		<div class="mt-4 p-6 bg-gray-100 rounded-xl max-w-2xl mx-auto">
			<h3 class="font-semibold text-lg mb-3 text-gray-700">Previous Round Result:</h3>
			<p>
				Squares {data.previousRoundResult.losingSquares.map(i => i + 1).join(', ')} lost points.
				Total penalty: ${data.previousRoundResult.penaltyAmount.toFixed(2)}
				{#if data.previousRoundResult.isDraw}
					<span class="text-gray-500">(Draw)</span>
				{/if}
			</p>
			<div class="mt-4 space-y-3">
				<div class="text-red-600">
					<div class="font-medium mb-1">Penalties:</div>
					{#each data.previousRoundResult.affectedPlayers.losing as player}
						<div>{player.name}: -${player.penalty.toFixed(2)}</div>
					{/each}
				</div>
				<div class="text-green-600">
					<div class="font-medium mb-1">Rewards:</div>
					{#each data.previousRoundResult.affectedPlayers.safe as player}
						<div>{player.name}: +${player.reward.toFixed(2)}</div>
					{/each}
				</div>
			</div>
		</div>
	{/if}
</main>

<style>
	:global(body) {
		background-color: #f9fafb;
	}

	.balance-increase {
		animation: flash-green 1s;
	}

	.balance-decrease {
		animation: flash-red 1s;
	}

	.bomb-icon {
		animation: bounce 1s infinite;
		transition: transform 0.3s ease-in-out;
	}

	@keyframes bounce {
		0%, 100% {
			transform: translateY(0);
		}
		50% {
			transform: translateY(-4px);
		}
	}

	@keyframes flash-green {
		0% {
			color: black;
		}
		50% {
			color: #10B981;  /* text-green-500 */
		}
		100% {
			color: black;
		}
	}

	@keyframes flash-red {
		0% {
			color: black;
		}
		50% {
			color: #EF4444;  /* text-red-500 */
		}
		100% {
			color: black;
		}
	}
</style>
