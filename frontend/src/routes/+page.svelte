<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { browser } from '$app/environment';
	import type { Player, Square, GameResult, GameState } from '$lib/types';

	export let data: GameState;

	let playerName = '';
	let eventSource: EventSource;
	let isLoading = false;
	let errorMessage = '';
	let gameResult: GameResult | null = null;

	function getPlayers(players: Set<Player>): Player[] {
		return Array.from(players);
	}

	function getHighestBalanceSquares(): number[] {
		if (gameResult) return gameResult.losingSquares;
		const balances = data.squares.map((square) => square.totalBalancePoints);
		const maxBalance = Math.max(...balances);
		return balances.reduce((acc, balance, index) => {
			if (balance === maxBalance) acc.push(index);
			return acc;
		}, [] as number[]);
	}

	$: isJoined = data.squares.some((square) =>
		getPlayers(square.players).some((player) => player.name === playerName)
	);

	$: currentSquare = data.squares.findIndex((square) =>
		getPlayers(square.players).some((player) => player.name === playerName)
	);

	function showError(message: string) {
		errorMessage = message;
		setTimeout(() => {
			errorMessage = '';
		}, 5000);
	}

	onMount(() => {
		if (browser) {
			playerName = localStorage.getItem('playerName') || '';
			eventSource = new EventSource('/api/game-updates');
			
			eventSource.onmessage = (event) => {
				const newData = JSON.parse(event.data) as GameState;
				data = newData;
				
				if (newData.gameResult && !gameResult) {
					gameResult = newData.gameResult;
					// Clear the game result (and red background) after 2 seconds
					setTimeout(() => {
						gameResult = null;
					}, 2000);
				}
			};

			eventSource.onerror = () => {};
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
			const result = await response.json() as GameState;
			if (!response.ok) throw new Error(result.error);
			data = result;
			localStorage.setItem('playerName', playerName);
			errorMessage = '';
		} catch (error) {
			showError(`Failed to join: ${error}`);
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
			if (!response.ok) throw new Error(result.error);
			data = result;
		} catch (error) {
			errorMessage = `Failed to move: ${error}`;
		} finally {
			isLoading = false;
		}
	}

	function handleLeave() {
		if (eventSource) eventSource.close();
		localStorage.removeItem('playerName');
		window.location.reload();
	}
</script>

<main>
	{#if errorMessage}
		<div class="error">{errorMessage}</div>
	{/if}

	<div>Round {data.roundNumber}</div>

	{#if data.previousRoundResult}
		<div class="previous-round">
			{#if data.previousRoundResult.losingSquares.length > 1}
				<div>Double whammy in Round {data.previousRoundResult.roundNumber}! Squares {data.previousRoundResult
					.losingSquares.join(' and ')} lost with {data.previousRoundResult.losingSquares
					.map(square => `${data.previousRoundResult.totalBalances[square]}`).join(' and ')} points</div>
			{:else}
				<div>Last Round {data.previousRoundResult.roundNumber}: Square {data.previousRoundResult
					.losingSquares[0]} lost with
				{data.previousRoundResult.totalBalances[data.previousRoundResult.losingSquares[0]]} points</div>
			{/if}
		</div>
	{/if}

	{#if !gameResult}
		<div>Moves until bomb: {data.bombCounter}</div>
	{/if}

	{#if !isJoined}
		<form on:submit={handleJoin}>
			<input bind:value={playerName} placeholder="Enter name" required />
			<button type="submit" disabled={isLoading}>Join</button>
		</form>
	{:else}
		<div>Playing as: {playerName}</div>
	{/if}

	<div class="board">
		{#each data.squares as square, i}
			{@const highestBalanceSquares = getHighestBalanceSquares()}
			<button
				class="square"
				class:current={currentSquare === i}
				class:lost={gameResult && gameResult.losingSquares.includes(i)}
				class:previous-loser={data.previousRoundResult &&
					data.previousRoundResult.losingSquares.includes(i)}
				on:click={() => handleMove(i)}
				disabled={!isJoined || currentSquare === i || isLoading}
			>
				Square {i}
				{#if highestBalanceSquares.includes(i)}
					💣 {gameResult ? gameResult.totalBalances[i] : data.bombCounter}
				{/if}
				<div>
					{#each getPlayers(square.players) as player}
						<div class:self={player.name === playerName}>
							{player.name} (${player.balance})
						</div>
					{/each}
				</div>
				<div>Total: ${square.totalBalancePoints}</div>
			</button>
		{/each}
	</div>

	{#if isJoined}
		<button on:click={handleLeave}>Leave Game</button>
	{/if}
</main>

<style>
	.board {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 10px;
		margin: 10px 0;
	}

	.square {
		padding: 10px;
		text-align: left;
		width: 100%;
	}

	.current {
		background: #e3f2fd;
	}

	.lost {
		background: #ffebee;
	}

	.previous-loser {
		border: 1px solid #ffebee;
	}

	.self {
		font-weight: bold;
	}

	.error {
		color: red;
	}

	.previous-round {
		background: #f5f5f5;
		padding: 5px;
		margin: 5px 0;
		font-size: 0.9em;
	}

	.square.lost {
		background-color: #ffebee !important;
	}
</style>
