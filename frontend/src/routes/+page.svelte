<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { browser } from '$app/environment';
	import type { Player, Square, GameResult, GameResponse, SerializableSquare } from '$lib/types';
	import { INITIAL_BALANCE } from '$lib/types';
	import { tweened } from 'svelte/motion';
	import { cubicOut } from 'svelte/easing';
	import { starknet_join_game, starknet_buy_tokens } from './starknet_caller';

	// Array of fun emojis that could represent players
	const avatarEmojis = [
		// Animals
		'🦊',
		'🐯',
		'🦁',
		'🐮',
		'🐷',
		'🐸',
		'🐙',
		'🦄',
		'🦋',
		'🐬',
		'🦉',
		'🦒',
		'🐘',
		'🦩',
		'🐧',
		'🦆',
		'🦅',
		'🦍',
		'🦘',
		'🦦',
		'🦥',
		'🦨',
		'🦡',
		'🦌',
		'🐿️',
		'🦫',
		'🦭',
		'🐠',
		'🦈',
		'🦕',
		// Fantasy/Mythical
		'🐲',
		'🧚',
		'🧛',
		'🧜',
		'🧝',
		'🧞',
		'🧟',
		'👻',
		'🤖',
		// Food
		'🍎',
		'🍕',
		'🌮',
		'🍦',
		'🥑',
		'🍪',
		'🥐',
		'🧁',
		'🍄',
		// Nature
		'🌺',
		'🌻',
		'🌹',
		'🌈',
		'⭐',
		'🌙',
		'❄️',
		'🔥',
		'🌵',
		// Fun Objects
		'🎨',
		'🎮',
		'🎲',
		'🎸',
		'🎭',
		'💎',
		'🎪',
		'🎯',
		'🎵'
	];
	let playerEmoji = '';

	function getRandomEmoji(): string {
		const randomIndex = Math.floor(Math.random() * avatarEmojis.length);
		return avatarEmojis[randomIndex];
	}

	// Function to calculate background color based on points
	function getBackgroundColor(points: number, squares: SerializableSquare[]): string {
		if (!squares.length) return 'rgba(0, 255, 0, 0.1)'; // Light green for empty
		if (points === 0) return 'rgba(0, 255, 0, 0.1)'; // Light green for zero

		const allPoints = squares.map((s) => s.totalBalancePoints);
		const sortedPoints = [...allPoints].sort((a, b) => b - a); // Sort descending
		const pointRank = allPoints.indexOf(points);
		const isTopHalf = sortedPoints.indexOf(points) < 2; // First 2 squares are "top half"

		// Calculate intensity (0 to 1) based on position within its half
		const intensity = isTopHalf
			? points / Math.max(...allPoints) // For red (top half)
			: 1 - points / Math.max(...allPoints); // For green (bottom half)

		// Return red for top half, green for bottom half
		return isTopHalf
			? `rgba(255, 0, 0, ${0.1 + intensity * 0.2})` // Red with opacity 0.1-0.3
			: `rgba(0, 255, 0, ${0.1 + intensity * 0.2})`; // Green with opacity 0.1-0.3
	}

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
	let isJoiningStarknet = false;
	let isBuyingTokens = false;
	let starknetMessage = '';

	// Track balance changes
	$: currentBalance =
		getPlayers(data?.squares?.[currentSquare])?.find((p) => p.name === playerName)?.balance ?? 0;

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
			const balances = data.squares.map((square) => square.totalBalancePoints);
			const maxBalance = Math.max(...balances);
			highestBalanceSquare = balances.findIndex((balance) => balance === maxBalance);
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

	$: isJoined =
		data?.squares?.some((square) => square.players.some((player) => player.name === playerName)) ??
		false;

	$: currentSquare =
		data?.squares?.findIndex((square) =>
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
			playerEmoji = localStorage.getItem('playerEmoji') || getRandomEmoji();

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
			playerEmoji = getRandomEmoji();
			localStorage.setItem('playerEmoji', playerEmoji);
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
		localStorage.removeItem('playerEmoji');
		window.location.reload();
	}

	async function handleStarknetJoin() {
		if (isJoiningStarknet) return;

		isJoiningStarknet = true;
		starknetMessage = 'Joining game on Starknet...';

		try {
			const result = await starknet_join_game();
			if (result.success) {
				starknetMessage = result.message;
				setTimeout(() => {
					starknetMessage = '';
				}, 5000);
			} else {
				showError(result.message);
			}
		} catch (error) {
			showError('Failed to join game on Starknet');
		} finally {
			isJoiningStarknet = false;
		}
	}

	async function handleBuyTokens() {
		if (isBuyingTokens) return;

		isBuyingTokens = true;
		starknetMessage = 'Buying tokens on Starknet...';

		try {
			const result = await starknet_buy_tokens();
			if (result.success) {
				starknetMessage = result.message;
				setTimeout(() => {
					starknetMessage = '';
				}, 5000);
			} else {
				showError(result.message);
			}
		} catch (error) {
			showError('Failed to buy tokens on Starknet');
		} finally {
			isBuyingTokens = false;
		}
	}
</script>

<main class="container mx-auto max-w-3xl px-4 py-8">
	{#if isJoined}
		<div class="fixed left-0 right-0 top-0 z-50 bg-white shadow-md">
			<div class="container mx-auto flex max-w-3xl items-center justify-between gap-4 px-4 py-2">
				<div class="flex items-center gap-2">
					<div class="flex h-10 w-10 items-center justify-center rounded-full bg-gray-100 text-2xl">
						{playerEmoji}
					</div>
					<span class="font-medium">{playerName}</span>
				</div>
				<div class="text-xl font-bold text-gray-800">Ten Percent</div>
				<button
					on:click={handleLeave}
					class="flex items-center gap-2 rounded bg-red-500 px-3 py-1.5 text-sm text-white transition-colors hover:bg-red-600"
				>
					<span>Leave Game</span>
					<span class="text-lg">👋</span>
				</button>
			</div>
		</div>
		<div class="h-14"></div>
		<!-- Spacer to prevent content from going under fixed header -->
	{/if}

	<div class="mb-12 text-center">
		<h1 class="mb-6 text-4xl font-bold text-gray-800">
			{#if !isJoined}
				Ten Percent
			{/if}
		</h1>

		{#if !isJoined}
			<form on:submit={handleJoin} class="mx-auto flex max-w-sm flex-col items-center gap-3">
				<div
					class="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-gray-100 text-2xl"
				>
					{playerEmoji}
				</div>
				<input
					type="text"
					bind:value={playerName}
					placeholder="Enter your name"
					class="w-full rounded-lg border-2 px-4 py-2 text-center text-base shadow-sm focus:border-transparent focus:outline-none focus:ring-2 focus:ring-blue-500"
				/>
				<button
					type="submit"
					class="flex w-full items-center justify-center gap-2 rounded-lg bg-green-500 px-4 py-2 font-medium text-white shadow-sm transition-colors hover:bg-green-600"
				>
					<span>Join Game</span>
					<span class="text-xl">💰</span>
				</button>

				<!-- Buy Tokens button -->
				<button
					type="button"
					on:click={handleBuyTokens}
					class="flex w-full items-center justify-center gap-2 rounded-lg bg-yellow-500 px-4 py-2 font-medium text-white shadow-sm transition-colors hover:bg-yellow-600 disabled:cursor-not-allowed disabled:opacity-50"
					disabled={isBuyingTokens}
				>
					<span>{isBuyingTokens ? 'Buying Tokens...' : 'Buy Tokens'}</span>
					<span class="text-xl">🪙</span>
				</button>

				<!-- Starknet join button -->
				<button
					type="button"
					on:click={handleStarknetJoin}
					class="flex w-full items-center justify-center gap-2 rounded-lg bg-purple-500 px-4 py-2 font-medium text-white shadow-sm transition-colors hover:bg-purple-600 disabled:cursor-not-allowed disabled:opacity-50"
					disabled={isJoiningStarknet}
				>
					<span>{isJoiningStarknet ? 'Joining Starknet...' : 'Join on Starknet'}</span>
					<span class="text-xl">⚡</span>
				</button>

				{#if starknetMessage}
					<div class="mt-2 text-sm text-green-600">
						{starknetMessage}
					</div>
				{/if}
			</form>
		{:else}
			<div class="mb-8 flex flex-col items-center">
				{#if data?.squares}
					<div class="text-5xl font-bold text-black {balanceChangeClass} tracking-tight">
						${(
							getPlayers(data.squares[currentSquare]).find((p) => p.name === playerName)?.balance ??
							0
						).toFixed(2)}
					</div>
					{#if currentSquare !== -1}
						{#if data.squares[currentSquare]?.totalBalancePoints > 0}
							{@const player = getPlayers(data.squares[currentSquare]).find(
								(p) => p.name === playerName
							)}
							{@const profitPercent =
								(((player?.balance ?? 0) - INITIAL_BALANCE) / INITIAL_BALANCE) * 100}
							<div class="mt-1 text-sm {profitPercent >= 0 ? 'text-green-500' : 'text-red-500'}">
								{profitPercent >= 0 ? '+' : ''}{profitPercent.toFixed(1)}%
							</div>
						{/if}
					{/if}
				{/if}
			</div>
		{/if}
	</div>

	{#if errorMessage}
		<div
			class="mx-auto mb-4 max-w-md rounded border border-red-400 bg-red-100 px-4 py-3 text-center text-red-700"
		>
			{errorMessage}
		</div>
	{/if}

	<div class="mx-auto mb-8 flex max-w-2xl items-center justify-between">
		<div class="w-full">
			<div class="mb-2 flex justify-between text-sm font-medium text-gray-600">
				<span>Bomb explodes in: <strong>{data?.bombCounter}</strong> moves</span>
				<span>{Math.round((data?.bombCounter / 5) * 100)}%</span>
			</div>
			<div class="h-5 w-full overflow-hidden rounded-full bg-gray-200 shadow-inner">
				<div
					class="h-full rounded-full shadow-sm transition-all duration-500 ease-in-out"
					style="width: {(data?.bombCounter / 5) * 100}%; background-color: {data?.bombCounter >= 3
						? `rgba(0, 255, 0, ${0.1 + (data?.bombCounter / 5) * 0.2})` // Green for top half (3-5 moves)
						: `rgba(255, 0, 0, ${0.1 + (1 - data?.bombCounter / 5) * 0.2})`}"
				></div>
			</div>
		</div>
	</div>

	<div class="mb-8 grid grid-cols-2 gap-6">
		{#each Array(4) as _, i}
			<button
				class="rounded-xl border-2 p-6 text-left shadow-sm transition-all duration-200 hover:shadow-md
					{currentSquare === i ? 'border-blue-200 bg-blue-50' : 'hover:bg-opacity-75'}
					{gameResult?.losingSquares?.includes(i) ? 'border-red-200 bg-red-100' : ''}
					{isJoined && currentSquare !== i && !isLoading ? 'cursor-pointer' : 'cursor-not-allowed'}
					relative flex min-h-[160px] flex-col items-center justify-center"
				style="background-color: {getBackgroundColor(
					data?.squares?.[i]?.totalBalancePoints ?? 0,
					data?.squares ?? []
				)}"
				on:click={() => handleMove(i)}
				disabled={!isJoined || currentSquare === i || isLoading}
			>
				<h3 class="mb-2 text-lg font-semibold text-gray-700">
					Square {String.fromCharCode(65 + i)}
				</h3>

				{#if highestBalanceSquare === i}
					<div class="bomb-icon mb-3">
						<span class="text-4xl">💣</span>
					</div>
				{/if}

				<div class="text-2xl font-bold">
					${(data?.squares?.[i]?.totalBalancePoints ?? 0).toFixed(2)}
				</div>

				{#if currentSquare === i}
					<div class="mt-2 flex flex-col items-center text-sm">
						<div class="text-blue-600">You are here</div>
						{#if data?.squares?.[i]?.totalBalancePoints > 0}
							<div class="mt-1 text-gray-500">
								{Math.round(
									((getPlayers(data.squares[i]).find((p) => p.name === playerName)?.balance ?? 0) /
										data.squares[i].totalBalancePoints) *
										100
								)}% of total
							</div>
						{/if}
					</div>
				{/if}
			</button>
		{/each}
	</div>

	{#if data?.previousRoundResult}
		<div class="mx-auto mt-8 max-w-2xl rounded-xl bg-gray-100 p-8">
			<h3 class="mb-6 text-center text-2xl font-bold text-gray-800">
				Round {data.previousRoundResult.roundNumber} Results
			</h3>

			<div class="mb-6 text-center">
				<div class="mb-2 text-lg">
					Squares {data.previousRoundResult.losingSquares
						.map((i) => String.fromCharCode(65 + i))
						.join(', ')} lost
					{#if data.previousRoundResult.isDraw}
						<span class="text-gray-500">(Draw)</span>
					{/if}
				</div>
				<div class="text-2xl font-bold text-red-600">
					${data.previousRoundResult.penaltyAmount.toFixed(2)}
				</div>
			</div>

			<div class="grid grid-cols-2 gap-8">
				<div class="rounded-lg bg-red-50 p-4">
					<div class="mb-4 text-center">
						<div class="mb-1 text-lg font-semibold text-red-800">Penalties</div>
						<div class="text-sm text-gray-600">Lost 10% of balance</div>
					</div>
					<div class="space-y-2">
						{#each data.previousRoundResult.affectedPlayers.losing as player}
							<div class="flex items-center justify-between rounded bg-white p-2">
								<span class="font-medium">{player.name}</span>
								<span class="text-red-600">-${player.penalty.toFixed(2)}</span>
							</div>
						{/each}
					</div>
				</div>

				<div class="rounded-lg bg-green-50 p-4">
					<div class="mb-4 text-center">
						<div class="mb-1 text-lg font-semibold text-green-800">Rewards</div>
						<div class="text-sm text-gray-600">Split proportionally</div>
					</div>
					<div class="space-y-2">
						{#each data.previousRoundResult.affectedPlayers.safe as player}
							<div class="flex items-center justify-between rounded bg-white p-2">
								<span class="font-medium">{player.name}</span>
								<span class="text-green-600">+${player.reward.toFixed(2)}</span>
							</div>
						{/each}
					</div>
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
		0%,
		100% {
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
			color: #10b981; /* text-green-500 */
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
			color: #ef4444; /* text-red-500 */
		}
		100% {
			color: black;
		}
	}
</style>
