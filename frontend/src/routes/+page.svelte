<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { browser } from '$app/environment';

	interface Player {
		name: string;
		balance: number;
	}

	interface Square {
		players: Player[];
		totalBalancePoints: number;
	}

	interface GameData {
		squares: Square[];
	}

	export let data: GameData;

	let playerName = '';
	let eventSource: EventSource;
	let isJoined = false;
	let isLoading = false;
	let errorMessage = '';

	$: isJoined = data.squares.some((square) =>
		square.players.some((player) => player.name === playerName)
	);

	onMount(() => {
		if (browser) {
			playerName = localStorage.getItem('playerName') || '';
			setupEventSource();
		}
	});

	onDestroy(() => {
		cleanupEventSource();
	});

	function setupEventSource() {
		eventSource = new EventSource('/api/game-updates');

		eventSource.onmessage = (event) => {
			try {
				const newData = JSON.parse(event.data);
				if (newData.squares) {
					data.squares = newData.squares;
				}
			} catch (error) {
				console.error('Failed to parse game update:', error);
			}
		};
	}

	function cleanupEventSource() {
		if (eventSource) {
			eventSource.close();
		}
	}

	async function handleJoin(e: Event) {
		e.preventDefault();
		const trimmedName = playerName.trim();

		if (!trimmedName || trimmedName.length < 2) {
			errorMessage = 'Please enter a valid name (minimum 2 characters)';
			return;
		}

		if (isLoading) return;

		isLoading = true;
		errorMessage = '';

		try {
			const response = await fetch('/api/join', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				body: JSON.stringify({ playerName: trimmedName })
			});

			const result = await response.json();

			if (!response.ok) {
				throw new Error(result.error || 'Failed to join game');
			}

			if (browser) {
				localStorage.setItem('playerName', trimmedName);
			}
			data.squares = result.squares;
		} catch (error) {
			errorMessage = `Failed to join: ${error}`;
			console.error('Join error:', error);
		} finally {
			isLoading = false;
		}
	}

	async function handleMove(toSquare: number) {
		if (!isJoined || !playerName || toSquare < 0 || toSquare > 3) return;
		if (toSquare === getCurrentSquare()) return;
		if (isLoading) return;

		isLoading = true;
		errorMessage = '';

		try {
			const response = await fetch('/api/move', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				body: JSON.stringify({
					playerName,
					toSquare
				})
			});

			const result = await response.json();

			if (!response.ok) {
				throw new Error(result.error || 'Failed to move');
			}

			if (!result.squares) {
				throw new Error('Invalid server response');
			}

			data.squares = result.squares;
		} catch (error) {
			errorMessage = `Failed to move: ${error}`;
			console.error('Move error:', error);
		} finally {
			isLoading = false;
		}
	}

	function getCurrentSquare(): number {
		for (let i = 0; i < data.squares.length; i++) {
			if (data.squares[i].players.some((p) => p.name === playerName)) {
				return i;
			}
		}
		return -1;
	}

	function handleLeaveGame() {
		cleanupEventSource();
		if (browser) {
			localStorage.removeItem('playerName');
		}
		playerName = '';
		window.location.reload();
	}
</script>

<div class="game-container">
	{#if errorMessage}
		<div class="error-message" role="alert">
			{errorMessage}
		</div>
	{/if}

	{#if !isJoined}
		<div class="join-form">
			<form on:submit={handleJoin}>
				<input
					type="text"
					bind:value={playerName}
					placeholder="Enter your name (min 2 characters)"
					minlength="2"
					required
					disabled={isLoading}
				/>
				<button type="submit" disabled={isLoading}>
					{isLoading ? 'Joining...' : 'Join Game'}
				</button>
			</form>
		</div>
	{:else}
		<div class="player-info">
			Playing as: <strong>{playerName}</strong>
		</div>
	{/if}

	<div class="game-board" class:loading={isLoading}>
		{#each Array(4) as _, i}
			{@const currentSquare = getCurrentSquare()}
			<button
				type="button"
				class="square"
				class:current={currentSquare === i}
				class:available={currentSquare !== i && isJoined}
				on:click={() => !isLoading && isJoined && handleMove(i)}
				disabled={!isJoined || currentSquare === i || isLoading}
				aria-label={`Square ${i}${currentSquare === i ? ' (current position)' : ''}`}
				aria-disabled={!isJoined || currentSquare === i || isLoading}
			>
				<h3>Square {i}</h3>
				<div class="players">
					{#each data.squares[i].players as player}
						<div class="player" class:my-player={player.name === playerName}>
							{player.name} (${player.balance})
						</div>
					{/each}
				</div>
				<p>Total Balance: ${data.squares[i].totalBalancePoints}</p>
			</button>
		{/each}
	</div>

	<div class="admin-controls">
		<button on:click={handleLeaveGame} disabled={isLoading}> Leave Game </button>
		{#if isJoined}
			<button on:click={handleLeaveGame} disabled={isLoading}> Reset Game </button>
		{/if}
	</div>
</div>

<style>
	.game-container {
		padding: 20px;
		max-width: 800px;
		margin: 0 auto;
	}

	.error-message {
		background-color: #ffebee;
		color: #c62828;
		padding: 10px;
		border-radius: 4px;
		margin-bottom: 20px;
		text-align: center;
	}

	.join-form {
		margin-bottom: 20px;
		text-align: center;
	}

	.player-info {
		padding: 10px;
		background: #e3f2fd;
		border-radius: 4px;
		text-align: center;
		margin-bottom: 20px;
	}

	.game-board {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 20px;
		margin-bottom: 20px;
		transition: opacity 0.3s ease;
	}

	.game-board.loading {
		opacity: 0.7;
		pointer-events: none;
	}

	.square {
		border: 2px solid #333;
		padding: 15px;
		border-radius: 8px;
		transition: all 0.3s ease;
		background: none;
		width: 100%;
		text-align: left;
		cursor: pointer;
		color: black;
	}

	.square:disabled {
		cursor: not-allowed;
		opacity: 0.7;
		color: black;
	}

	.square.available {
		border-color: #4caf50;
	}

	.square.available:hover:not(:disabled) {
		background-color: rgba(76, 175, 80, 0.1);
		transform: scale(1.02);
	}

	.square.current {
		border-color: #2196f3;
		background-color: rgba(33, 150, 243, 0.1);
	}

	.player {
		margin: 5px 0;
		padding: 8px;
		background: #f0f0f0;
		border-radius: 4px;
		color: black;
	}

	.player.my-player {
		background: #e3f2fd;
		border: 1px solid #2196f3;
		color: black;
	}

	.admin-controls {
		display: flex;
		gap: 10px;
		justify-content: center;
	}

	input,
	button {
		margin: 5px;
		padding: 8px 16px;
		border: 1px solid #ccc;
		border-radius: 4px;
	}

	button {
		background: #2196f3;
		color: white;
		border: none;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	button:not(:disabled):hover {
		background: #1976d2;
	}

	button:disabled {
		background: #ccc;
		cursor: not-allowed;
	}

	h3,
	p {
		color: black;
		margin: 0;
	}
</style>
