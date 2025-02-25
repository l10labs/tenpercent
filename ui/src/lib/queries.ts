import { gql, type ApolloQueryResult } from '@apollo/client/core';

interface SquareNode {
    pit_id: number;
    square_id: number;
    total_balance: string;
    total_escrow: string;
}

export const SQUARES_QUERY = gql`
	query GetSquares {
		dojoStarterSquareModels {
			edges {
				node {
					pit_id
					square_id
					total_balance
					total_escrow
				}
			}
		}
	}
`;

export function get_square_balances(apollo_result: ApolloQueryResult<any>): SquareNode[] {
    let node_list: SquareNode[] = [];
    const square_nodes = apollo_result.data.dojoStarterSquareModels.edges;
    square_nodes.forEach((square: { node: SquareNode }) => {
        node_list.push(square.node);
    });
    return node_list;
}

export function log_squares_data(square_balances: SquareNode[]) {
    square_balances.forEach((square) => {
        console.log(`Pit ${square.pit_id} Square ${square.square_id} balance: ${square.total_balance} escrow: ${square.total_escrow}`);
    });
}
