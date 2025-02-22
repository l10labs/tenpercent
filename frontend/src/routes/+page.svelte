<script lang="ts">
	import { onMount, onDestroy } from 'svelte';

	let gameState: any = null;
	let playerId = crypto.randomUUID();
	let playerName = '';
	let isJoined = false;
	let selectedSquare: number | null = null;

	async function fetchGameState() {
		const response = await fetch('/api/game');
		gameState = await response.json();
	}

	async function joinGame() {
		if (!playerName) return;

		await fetch('/api/game', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				action: 'join',
				playerId,
				playerName
			})
		});

		isJoined = true;
		await fetchGameState();
	}

	async function makeMove(squareIndex: number) {
		if (!isJoined) return;

		await fetch('/api/game', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				action: 'move',
				playerId,
				squareIndex
			})
		});

		await fetchGameState();
	}

	let interval: NodeJS.Timer;

	onMount(() => {
		fetchGameState();
		interval = setInterval(fetchGameState, 1000);
	});

	onDestroy(() => {
		clearInterval(interval);
	});

	$: currentPlayer = gameState?.players?.find((p) => p.id === playerId);
</script>

<main class="container">
	{#if !isJoined}
		<div class="join-form">
			<h2>Join Game</h2>
			<input type="text" bind:value={playerName} placeholder="Enter your name" />
			<button on:click={joinGame}>Join</button>
		</div>
	{:else}
		<div class="game-container">
			<h2>Game Status: {gameState?.isActive ? 'Active' : 'Waiting for players'}</h2>

			{#if currentPlayer}
				<div class="player-info">
					<p>Your points: {currentPlayer.points}</p>
					<p>Moves left: {currentPlayer.movesLeft}</p>
					<p>Moves made: {currentPlayer.movesMade}</p>
				</div>
			{/if}

			<div class="squares-grid">
				{#each gameState?.squares || [] as square, i}
					<div
						class="square"
						class:active={currentPlayer?.currentSquare === i}
						class:winner={gameState?.isFinished && gameState?.winningSquare !== i}
						class:loser={gameState?.isFinished && gameState?.winningSquare === i}
						on:click={() => makeMove(i)}
					>
						<h3>Square {i + 1}</h3>
						<p>Total Points: {square.totalPoints}</p>
						<p>Players: {square.players.length}</p>
						<div class="players-list">
							{#each square.players as playerId (playerId)}
								<p>{gameState?.players?.find((p) => p.id === playerId)?.name || ''}</p>
							{/each}
						</div>
					</div>
				{/each}
			</div>

			{#if gameState?.isFinished}
				<div class="game-over">
					<h2>Game Over!</h2>
					<p>Square {gameState.winningSquare + 1} lost!</p>
				</div>
			{/if}
		</div>
	{/if}
</main>

<style>
	.container {
		max-width: 800px;
		margin: 0 auto;
		padding: 20px;
	}

	.join-form {
		display: flex;
		flex-direction: column;
		gap: 10px;
		max-width: 300px;
		margin: 0 auto;
	}

	.game-container {
		display: flex;
		flex-direction: column;
		gap: 20px;
	}

	.squares-grid {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 20px;
	}

	.square {
		padding: 20px;
		border: 2px solid #ccc;
		border-radius: 8px;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	.square:hover {
		background-color: #f0f0f0;
	}

	.square.active {
		border-color: #4caf50;
		background-color: #e8f5e9;
	}

	.square.winner {
		border-color: #4caf50;
		background-color: #e8f5e9;
	}

	.square.loser {
		border-color: #f44336;
		background-color: #ffebee;
	}

	.player-info {
		padding: 10px;
		background-color: #f5f5f5;
		border-radius: 4px;
	}

	.game-over {
		text-align: center;
		padding: 20px;
		background-color: #f5f5f5;
		border-radius: 4px;
	}

	button {
		padding: 10px;
		cursor: pointer;
	}

	input {
		padding: 8px;
	}
</style>
