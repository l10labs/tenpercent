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

	$: isJoined = data.squares.some((square) =>
		getPlayers(square.players).some((player) => player.name === playerName)
	);

	$: currentSquare = data.squares.findIndex((square) =>
		getPlayers(square.players).some((player) => player.name === playerName)
	);

	onMount(() => {
		if (browser) {
			playerName = localStorage.getItem('playerName') || '';
			eventSource = new EventSource('/api/game-updates');
			eventSource.onmessage = (event) => {
				const newData = JSON.parse(event.data);
				if (JSON.stringify(data) !== JSON.stringify(newData)) {
					data = newData;
				}
			};
		}
	});

	onDestroy(() => {
		if (eventSource) eventSource.close();
	});

	async function handleJoin(e: Event) {
		e.preventDefault();
		if (!playerName.trim()) return;

		try {
			const response = await fetch('/api/join', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ playerName })
			});
			const result = await response.json();
			if (!response.ok) throw new Error(result.error);
			data = result;
			localStorage.setItem('playerName', playerName);
		} catch (error) {
			errorMessage = `Failed to join: ${error}`;
		}
	}

	async function handleMove(toSquare: number) {
		if (!isJoined || currentSquare === toSquare || isLoading) return;
		isLoading = true;
		gameResult = null; // Clear any previous game result

		const oldState = structuredClone(data);
		const player = getPlayers(data.squares[currentSquare].players).find(
			(p) => p.name === playerName
		)!;

		data = {
			...data,
			bombCounter: data.bombCounter - 1,
			squares: data.squares.map((square, i) => {
				if (i === currentSquare) {
					const newPlayers = getPlayers(square.players).filter((p) => p.name !== playerName);
					return {
						...square,
						players: new Set(newPlayers),
						totalBalancePoints: square.totalBalancePoints - player.balance
					};
				}
				if (i === toSquare) {
					return {
						...square,
						players: new Set([...getPlayers(square.players), player]),
						totalBalancePoints: square.totalBalancePoints + player.balance
					};
				}
				return square;
			})
		};

		try {
			const response = await fetch('/api/move', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ playerName, toSquare })
			});
			const result = await response.json();
			if (!response.ok) throw new Error(result.error);

			if (result.gameResult) {
				data = result;
				gameResult = result.gameResult;
			}
		} catch (error) {
			data = oldState;
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
		<p class="error">{errorMessage}</p>
	{/if}

	<div class="status">
		<p>Round: {data.roundNumber}</p>
		<p class:warning={data.bombCounter <= 2}>
			Bomb in: {data.bombCounter} moves
		</p>
	</div>

	{#if !isJoined}
		<form on:submit={handleJoin}>
			<input type="text" bind:value={playerName} placeholder="Enter name" minlength="2" required />
			<button type="submit" disabled={isLoading}>
				{isLoading ? 'Joining...' : 'Join'}
			</button>
		</form>
	{:else}
		<p>Playing as: <strong>{playerName}</strong></p>
	{/if}

	<div class="board">
		{#each data.squares as square, i}
			<button
				type="button"
				class="square"
				class:current={currentSquare === i}
				class:available={isJoined && currentSquare !== i && !isLoading}
				on:click={() => handleMove(i)}
				disabled={!isJoined || currentSquare === i || isLoading}
				aria-label={`Square ${i}${currentSquare === i ? ' (current position)' : ''}`}
			>
				<h3>Square {i}</h3>
				<div class="players">
					{#each getPlayers(square.players) as player}
						<div class:player-self={player.name === playerName}>
							{player.name} (${player.balance})
						</div>
					{/each}
				</div>
				<p class="total">Total: ${square.totalBalancePoints}</p>
			</button>
		{/each}
	</div>

	{#if gameResult}
		<div class="result">
			Square {gameResult.losingSquares[0]} lost with
			{gameResult.totalBalances[gameResult.losingSquares[0]]} points
		</div>
	{/if}

	{#if isJoined}
		<button type="button" class="leave-button" on:click={handleLeave} disabled={isLoading}>
			Leave Game
		</button>
	{/if}
</main>

<style>
	main {
		max-width: 800px;
		margin: 0 auto;
		padding: 20px;
	}

	.error {
		color: red;
		margin: 10px 0;
	}

	.status {
		margin: 10px 0;
	}

	.warning {
		color: orange;
		font-weight: bold;
	}

	.board {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 10px;
		margin: 20px 0;
	}

	.square {
		border: 1px solid #333;
		padding: 10px;
		width: 100%;
		text-align: left;
		background: none;
		cursor: pointer;
	}

	.square:disabled {
		cursor: not-allowed;
		opacity: 0.7;
	}

	.square.available {
		border-color: green;
	}

	.square.available:hover:not(:disabled) {
		background: #f0f0f0;
	}

	.square.current {
		background: #e3f2fd;
	}

	.player-self {
		font-weight: bold;
		color: blue;
	}

	.result {
		text-align: center;
		margin: 10px 0;
	}

	.leave-button {
		background: #ff4444;
		color: white;
		border: none;
		padding: 5px 10px;
		border-radius: 4px;
		cursor: pointer;
	}

	button,
	input {
		padding: 5px 10px;
		margin: 5px;
	}
</style>
