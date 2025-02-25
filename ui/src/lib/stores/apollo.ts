import { ApolloClient, InMemoryCache } from '@apollo/client/core';
import { torii_graphql_url } from '$lib/config';

// Create the Apollo Client instance
export const apolloClient = new ApolloClient({
    uri: torii_graphql_url,
    cache: new InMemoryCache(),
    defaultOptions: {
        watchQuery: {
            fetchPolicy: 'network-only',
        },
    },
});
