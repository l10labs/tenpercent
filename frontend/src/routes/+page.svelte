<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { browser } from '$app/environment';
	import type { PageData } from './$types';

	export let data: PageData;

	let playerName = '';
	let eventSource: EventSource;
	let isJoined = false;

	onMount(() => {
		if (browser) {
			playerName = localStorage.getItem('playerName') || '';
			isJoined = data.squares.some((square) =>
				square.players.some((player) => player.name === playerName)
			);
		}

		eventSource = new EventSource('/api/game-updates');
		eventSource.onmessage = (event) => {
			const newData = JSON.parse(event.data);
			data.squares = newData.squares;
		};
	});

	onDestroy(() => {
		if (eventSource) {
			eventSource.close();
		}
	});

	async function handleJoin(e: Event) {
		e.preventDefault();
		if (!playerName.trim()) return;

		try {
			const response = await fetch('/api/join', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				body: JSON.stringify({ playerName })
			});

			const result = await response.json();

			if (!response.ok) {
				throw new Error(result.error);
			}

			if (browser) {
				localStorage.setItem('playerName', playerName);
			}
			isJoined = true;
			data.squares = result.squares;
		} catch (error) {
			alert(`Failed to join: ${error}`);
		}
	}

	async function handleMove(toSquare: number) {
		if (!isJoined || !playerName) return;

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
				throw new Error(result.error);
			}

			data.squares = result.squares;
		} catch (error) {
			alert(`Failed to move: ${error}`);
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
		if (browser) {
			localStorage.removeItem('playerName');
		}
		window.location.reload();
	}
</script>

<div class="game-container">
	{#if !isJoined}
		<div class="join-form">
			<form on:submit={handleJoin}>
				<input type="text" bind:value={playerName} placeholder="Enter your name" required />
				<button type="submit">Join Game</button>
			</form>
		</div>
	{:else}
		<div class="player-info">
			Playing as: <strong>{playerName}</strong>
		</div>
	{/if}

	<div class="game-board">
		{#each Array(4) as _, i}
			{@const currentSquare = getCurrentSquare()}
			<div
				class="square"
				class:current={currentSquare === i}
				class:available={currentSquare !== i && isJoined}
				on:click={() => isJoined && handleMove(i)}
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
			</div>
		{/each}
	</div>

	<div class="admin-controls">
		<button on:click={handleLeaveGame}>Leave Game</button>
		{#if isJoined}
			<button
				on:click={() => {
					if (browser) {
						localStorage.removeItem('playerName');
					}
					window.location.reload();
				}}>Reset Game</button
			>
		{/if}
	</div>
</div>

<style>
	.game-container {
		padding: 20px;
		max-width: 800px;
		margin: 0 auto;
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
	}

	.square {
		border: 2px solid #333;
		padding: 15px;
		border-radius: 8px;
		transition: all 0.3s ease;
	}

	.square.available {
		cursor: pointer;
		border-color: #4caf50;
	}

	.square.available:hover {
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
	}

	.player.my-player {
		background: #e3f2fd;
		border: 1px solid #2196f3;
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
		transition: background 0.2s ease;
	}

	button:hover {
		background: #1976d2;
	}
</style>
