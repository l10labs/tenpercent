<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { browser } from '$app/environment';
	import type { Player, Square, GameResult, GameResponse, SerializableSquare } from '$lib/types';
	import { tweened } from 'svelte/motion';
	import { cubicOut } from 'svelte/easing';

	// Initialize data with default values
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

<main class="container mx-auto px-4 py-8 max-w-4xl">
	<div class="mb-8">
		<h1 class="text-3xl font-bold mb-4">Ten Percent</h1>
		
		{#if !isJoined}
			<form on:submit={handleJoin} class="flex gap-2">
				<input
					type="text"
					bind:value={playerName}
					placeholder="Enter your name"
					class="px-4 py-2 border rounded"
				/>
				<button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
					Join Game
				</button>
			</form>
		{:else}
			<div class="flex flex-col items-center mb-8">
				<div class="text-lg mb-2">Playing as: <strong>{playerName}</strong></div>
				{#if data?.squares}
					<div class="text-4xl font-bold text-black {balanceChangeClass}">
						${(getPlayers(data.squares[currentSquare])
							.find(p => p.name === playerName)?.balance ?? 0).toFixed(2)}
					</div>
				{/if}
			</div>
			<div class="flex justify-end">
				<button 
					on:click={handleLeave}
					class="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
				>
					Leave Game
				</button>
			</div>
		{/if}
	</div>

	{#if errorMessage}
		<div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
			{errorMessage}
		</div>
	{/if}

	<div class="flex justify-between items-center mb-4">
		<div class="bg-yellow-100 border border-yellow-400 text-yellow-700 px-4 py-3 rounded flex-grow">
			<span class="text-lg">Bomb explodes in: <strong>{data?.bombCounter}</strong> moves</span>
		</div>
	</div>

	<div class="grid grid-cols-2 gap-4">
		{#each Array(4) as _, i}
			<button
				class="p-6 border rounded-lg text-left transition-colors duration-200
					{currentSquare === i ? 'bg-blue-50 border-blue-200' : 'hover:bg-gray-50'}
					{gameResult?.losingSquares?.includes(i) ? 'bg-red-100 border-red-200' : ''}
					{isJoined && currentSquare !== i && !isLoading ? 'cursor-pointer' : 'cursor-not-allowed'}"
				on:click={() => handleMove(i)}
				disabled={!isJoined || currentSquare === i || isLoading}
			>
				<h3 class="text-lg font-semibold mb-2">Square {i + 1}</h3>
				<div class="space-y-1">
					{#each getPlayers(data?.squares?.[i]) as player}
						<div class="flex justify-between items-center">
							<span class={player.name === playerName ? 'font-bold' : ''}>
								{player.name}
							</span>
							<span class="text-black">
								${player.balance.toFixed(2)}
							</span>
						</div>
					{/each}
				</div>
				<div class="mt-2 text-sm text-gray-500">
					Total: ${(data?.squares?.[i]?.totalBalancePoints ?? 0).toFixed(2)}
				</div>
			</button>
		{/each}
	</div>

	{#if data?.previousRoundResult}
		<div class="mt-4 p-4 bg-gray-100 rounded">
			<h3 class="font-semibold">Previous Round Result:</h3>
			<p>
				Squares {data.previousRoundResult.losingSquares.map(i => i + 1).join(', ')} lost points.
				Total penalty: ${data.previousRoundResult.penaltyAmount.toFixed(2)}
				{#if data.previousRoundResult.isDraw}
					(Draw)
				{/if}
			</p>
			<div class="mt-2">
				<div class="text-red-600">
					Penalties:
					{#each data.previousRoundResult.affectedPlayers.losing as player}
						<div>{player.name}: -${player.penalty.toFixed(2)}</div>
					{/each}
				</div>
				<div class="text-green-600 mt-1">
					Rewards:
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
