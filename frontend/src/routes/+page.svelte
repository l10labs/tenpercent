<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { browser } from '$app/environment';
	import type { Player, Square, GameResult, GameResponse, SerializableSquare } from '$lib/types';
	import { INITIAL_BALANCE } from '$lib/types';
	import { tweened } from 'svelte/motion';
	import { cubicOut } from 'svelte/easing';

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
		const maxPoints = Math.max(...allPoints);
		const isHighest = points === maxPoints && points > 0;

		// Calculate intensity based on points relative to max
		const intensity = points / maxPoints;

		// Return red for highest, green for others
		return isHighest
			? `rgba(255, 0, 0, ${0.1 + intensity * 0.2})` // Red with opacity 0.1-0.3
			: `rgba(0, 255, 0, ${0.1 + intensity * 0.2})`; // Green with opacity 0.1-0.3
	}

	// Initialize data with default values
	let highestBalanceSquare = 0;
	let data: GameResponse = {
		squares: [],
		bombCounter: 50,
		maxBombCounter: 50,
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
	let isAutoMoving = false;
	let autoMoveInterval: ReturnType<typeof setInterval> | null = null;

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

	// Track game results and stop auto-move
	$: if (data?.gameResult && isAutoMoving) {
		stopAutoMove();
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
		stopAutoMove();
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

	async function startAutoMove() {
		if (!isJoined || isLoading || autoMoveInterval || data?.gameResult) return;
		isAutoMoving = true;

		autoMoveInterval = setInterval(async () => {
			if (!isJoined || isLoading || data?.gameResult) {
				stopAutoMove();
				return;
			}

			// Get available squares (all except current)
			const availableSquares = [0, 1, 2, 3].filter((i) => i !== currentSquare);
			if (availableSquares.length === 0) return;

			// Pick random square
			const randomSquare = availableSquares[Math.floor(Math.random() * availableSquares.length)];
			await handleMove(randomSquare);
		}, 200); // 5 times per second = 200ms
	}

	function stopAutoMove() {
		if (autoMoveInterval) {
			clearInterval(autoMoveInterval);
			autoMoveInterval = null;
		}
		isAutoMoving = false;
	}
</script>

<main class="container mx-auto flex h-screen max-w-3xl flex-col overflow-hidden px-4 py-4 sm:py-8">
	{#if isJoined}
		<div class="fixed top-0 right-0 left-0 z-50 bg-white shadow-md">
			<div
				class="container mx-auto flex max-w-3xl items-center justify-between gap-2 px-2 py-2 sm:gap-4 sm:px-4"
			>
				<div class="flex items-center gap-2">
					<div
						class="flex h-8 w-8 items-center justify-center rounded-full bg-gray-100 text-xl sm:h-10 sm:w-10 sm:text-2xl"
					>
						{playerEmoji}
					</div>
					<span class="text-sm font-medium sm:text-base">{playerName}</span>
				</div>
				<div class="text-lg font-bold text-gray-800 sm:text-xl">Ten Percent</div>
				<div class="flex gap-1 sm:gap-2">
					<button
						on:click={() => (isAutoMoving ? stopAutoMove() : startAutoMove())}
						class="flex items-center gap-1 rounded bg-blue-500 px-2 py-1 text-xs text-white transition-colors hover:bg-blue-600 disabled:cursor-not-allowed disabled:opacity-50 sm:gap-2 sm:px-3 sm:py-1.5 sm:text-sm"
						disabled={!isJoined || isLoading}
					>
						<span>{isAutoMoving ? 'Stop' : 'Auto'}</span>
						<span class="text-base sm:text-lg">🤖</span>
					</button>
					<button
						on:click={handleLeave}
						class="flex items-center gap-1 rounded bg-red-500 px-2 py-1 text-xs text-white transition-colors hover:bg-red-600 sm:gap-2 sm:px-3 sm:py-1.5 sm:text-sm"
					>
						<span>Leave</span>
						<span class="text-base sm:text-lg">👋</span>
					</button>
				</div>
			</div>
		</div>
		<div class="h-12 sm:h-14"></div>
	{/if}

	<div class="mb-4 flex-shrink-0 text-center sm:mb-8">
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
					class="w-full rounded-lg border-2 px-4 py-2 text-center text-base shadow-sm focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none"
				/>
				<button
					type="submit"
					class="flex w-full items-center justify-center gap-2 rounded-lg bg-green-500 px-4 py-2 font-medium text-white shadow-sm transition-colors hover:bg-green-600"
				>
					<span>Join Game</span>
					<span class="text-xl">💰</span>
				</button>
			</form>
		{:else}
			<div class="mb-8 flex flex-col items-center">
				{#if data?.squares}
					<div class="flex flex-col items-center">
						<div
							class="text-5xl font-bold text-black sm:text-7xl {balanceChangeClass} tracking-tight"
						>
							${(
								getPlayers(data.squares[currentSquare]).find((p) => p.name === playerName)
									?.balance ?? 0
							).toFixed(2)}
						</div>
						{#if currentSquare !== -1}
							{#if data.squares[currentSquare]?.totalBalancePoints > 0}
								{@const player = getPlayers(data.squares[currentSquare]).find(
									(p) => p.name === playerName
								)}
								{@const profitPercent =
									(((player?.balance ?? 0) - INITIAL_BALANCE) / INITIAL_BALANCE) * 100}
								<div
									class="mt-2 text-base {profitPercent >= 0 ? 'text-green-500' : 'text-red-500'}"
								>
									{profitPercent >= 0 ? '+' : ''}{profitPercent.toFixed(1)}%
								</div>
							{/if}
						{/if}
					</div>
				{/if}
			</div>
		{/if}
	</div>

	{#if errorMessage}
		<div
			class="mx-auto mb-4 max-w-md flex-shrink-0 rounded border border-red-400 bg-red-100 px-4 py-3 text-center text-red-700"
		>
			{errorMessage}
		</div>
	{/if}

	<div class="mb-4 flex-shrink-0 sm:mb-6">
		<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-6">
			<div class="col-span-1 sm:col-span-2">
				<div class="mb-2 flex justify-between text-sm font-medium text-gray-600">
					<span>Bomb explodes in: <strong>{data?.bombCounter}</strong> moves</span>
					<span>
						{#if data?.bombCounter != null && data?.maxBombCounter != null}
							{Math.round((data.bombCounter / data.maxBombCounter) * 100)}%
						{:else}
							0%
						{/if}
					</span>
				</div>
				<div class="h-5 w-full overflow-hidden rounded-full bg-gray-200 shadow-inner">
					{#if data?.bombCounter != null && data?.maxBombCounter != null}
						<div
							class="h-full rounded-full shadow-sm transition-all duration-500 ease-in-out"
							style="width: {(data.bombCounter / data.maxBombCounter) *
								100}%; background-color: {data.bombCounter >= data.maxBombCounter / 2
								? `rgba(0, 255, 0, ${0.1 + (data.bombCounter / data.maxBombCounter) * 0.2})` // Green for top half
								: `rgba(255, 0, 0, ${0.1 + (1 - data.bombCounter / data.maxBombCounter) * 0.2})`}"
						></div>
					{/if}
				</div>
			</div>
		</div>
	</div>

	<div class="flex-1 overflow-y-auto">
		<div class="mb-4 grid grid-cols-1 gap-4 sm:mb-6 sm:grid-cols-2 sm:gap-6">
			{#each Array(4) as _, i}
				<div class="relative w-full pb-[100%]">
					<button
						class="absolute inset-0 rounded-xl border-2 p-3 text-left shadow-sm transition-all duration-200 hover:shadow-md
							{currentSquare === i ? 'border-blue-500 bg-blue-100' : 'hover:bg-opacity-75'}
							{gameResult?.losingSquares?.includes(i) ? 'border-red-200 bg-red-100' : ''}
							{isJoined && currentSquare !== i && !isLoading ? 'cursor-pointer' : 'cursor-not-allowed'}
							flex flex-col items-center justify-center"
						style="background-color: {getBackgroundColor(
							data?.squares?.[i]?.totalBalancePoints ?? 0,
							data?.squares ?? []
						)}"
						on:click={() => handleMove(i)}
						disabled={!isJoined || currentSquare === i || isLoading}
					>
						<div class="flex flex-col items-center justify-center p-3">
							{#if highestBalanceSquare === i}
								<div class="bomb-icon">
									<span class="text-3xl sm:text-4xl">💣</span>
								</div>
							{/if}

							<div class="text-lg font-bold sm:text-2xl">
								${(data?.squares?.[i]?.totalBalancePoints ?? 0).toFixed(2)}
							</div>

							{#if currentSquare === i}
								<div class="text-center text-xs sm:text-sm">
									<div class="text-blue-600">You are here</div>
									{#if data?.squares?.[i]?.totalBalancePoints > 0}
										<div class="text-gray-500">
											{Math.round(
												((getPlayers(data.squares[i]).find((p) => p.name === playerName)?.balance ??
													0) /
													data.squares[i].totalBalancePoints) *
													100
											)}% of total
										</div>
									{/if}
								</div>
							{/if}
						</div>
					</button>
				</div>
			{/each}
		</div>

		<!-- Comment out round results for now
		{#if data?.previousRoundResult}
			<div class="mx-auto mb-4 max-w-2xl rounded-xl bg-gray-100 p-4 sm:p-8">
				<button
					class="flex w-full items-center justify-between"
					on:click={() => (showResults = !showResults)}
				>
					<h3 class="text-xl font-bold text-gray-800 sm:text-2xl">
						Round {data.previousRoundResult.roundNumber} Results
					</h3>
					<span
						class="text-2xl transition-transform duration-200"
						style="transform: rotate({showResults ? '180deg' : '0deg'})"
					>
						▼
					</span>
				</button>

				{#if showResults}
					<div class="mt-4 sm:mt-6">
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

						<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-8">
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
			</div>
		{/if}
		-->
	</div>
</main>

<style>
	:global(body) {
		background-color: #f9fafb;
		overflow: hidden;
		position: fixed;
		width: 100%;
		height: 100%;
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
