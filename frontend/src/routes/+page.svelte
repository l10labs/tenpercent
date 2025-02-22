<script lang="ts">
	import { enhance } from '$app/forms';
	import { onMount, onDestroy } from 'svelte';
	import type { PageData } from './$types';

	export let data: PageData;

	let playerName = '';
	let selectedSquare = 0;
	let eventSource: EventSource;

	// Setup SSE for real-time updates
	onMount(() => {
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
</script>

<div class="game-container">
	<div class="join-form">
		<form method="POST" action="?/join" use:enhance>
			<input
				type="text"
				name="playerName"
				bind:value={playerName}
				placeholder="Enter your name"
				required
			/>
			<button type="submit">Join Game</button>
		</form>
	</div>

	<div class="game-board">
		{#each Array(4) as _, i}
			<div class="square">
				<h3>Square {i}</h3>
				<div class="players">
					{#each data.squares[i].players as player}
						<div class="player">
							{player.name} (${player.balance})
							{#if player.name === playerName}
								<form method="POST" action="?/move" use:enhance>
									<input type="hidden" name="playerName" value={playerName} />
									<select name="toSquare" bind:value={selectedSquare}>
										{#each Array(4) as _, j}
											<option value={j}>Square {j}</option>
										{/each}
									</select>
									<button type="submit">Move</button>
								</form>
							{/if}
						</div>
					{/each}
				</div>
				<p>Total Balance: ${data.squares[i].totalBalancePoints}</p>
			</div>
		{/each}
	</div>

	<div class="admin-controls">
		<form method="POST" action="?/reset" use:enhance>
			<button type="submit">Reset Game</button>
		</form>
	</div>
</div>

<style>
	.game-container {
		padding: 20px;
	}

	.join-form {
		margin-bottom: 20px;
	}

	.game-board {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 20px;
	}

	.square {
		border: 2px solid #333;
		padding: 15px;
		border-radius: 8px;
	}

	.player {
		margin: 5px 0;
		padding: 5px;
		background: #f0f0f0;
		border-radius: 4px;
	}

	.admin-controls {
		margin-top: 20px;
	}

	input,
	select,
	button {
		margin: 5px;
		padding: 5px;
	}
</style>
