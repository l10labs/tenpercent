<script lang="ts">
	import { apolloClient } from '$lib/stores/apollo';
	import { gql } from '@apollo/client/core';

	const SAMPLE_QUERY = gql`
		query GetTokens {
			dojoStarterTokenModels {
				edges {
					node {
						player
						balance
						moves_since_last_claim
						has_claimed
					}
				}
			}
		}
	`;

	async function handleQuery1() {
		try {
			const result = await apolloClient.query({
				query: SAMPLE_QUERY
			});
			console.log('Query result:', result.data);
		} catch (error) {
			console.error('Query error:', error);
		}
	}
</script>

<div class="flex min-h-screen flex-col items-center justify-center p-4">
	<div class="grid grid-cols-2 gap-4">
		<button
			onclick={handleQuery1}
			class="rounded border border-gray-800 px-6 py-2 text-sm hover:bg-gray-50"
		>
			Get Game States
		</button>
		<button class="rounded border border-gray-800 px-6 py-2 text-sm hover:bg-gray-50">
			Query 2
		</button>
		<button class="rounded border border-gray-800 px-6 py-2 text-sm hover:bg-gray-50">
			Query 3
		</button>
		<button class="rounded border border-gray-800 px-6 py-2 text-sm hover:bg-gray-50">
			Query 4
		</button>
	</div>
</div>
