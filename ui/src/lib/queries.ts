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

export function get_square_id_balances(square_nodes: SquareNode[]): {
    square_ids: number[];
    square_balances: number[];
    square_escrows: number[];
} {
    let square_ids: number[] = [];
    let square_balances: number[] = [];
    let square_escrows: number[] = [];

    square_nodes.forEach((square) => {
        square_ids.push(square.pit_id);
        square_balances.push(Number(square.total_balance));
        square_escrows.push(Number(square.total_escrow));
    });

    return { square_ids, square_balances, square_escrows };
}

interface TokenNode {
    player: string;
    balance: string;
    moves_since_last_claim: number;
    has_claimed: boolean;
}
export const USER_TOKEN_QUERY = gql`
	query GetUserTokens {
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

export function get_token_balances(apollo_result: ApolloQueryResult<any>): TokenNode[] {
    let node_list: TokenNode[] = [];
    const token_nodes = apollo_result.data.dojoStarterTokenModels.edges;
    token_nodes.forEach((token: { node: TokenNode }) => {
        node_list.push(token.node);
    });
    return node_list;
}

export function match_user_contract_address(token_nodes: TokenNode[], player_contract_address: string): TokenNode {
    let matched_object = token_nodes.filter((token) => token.player === player_contract_address);
    return matched_object[0];
}