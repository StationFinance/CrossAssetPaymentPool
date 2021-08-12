import { ethers } from 'hardhat';

import { BigNumberish } from './numbers';

const JOIN_DEFINET_POOL_INIT_TAG = 0;
const JOIN_DEFINET_POOL_BPT_OUT_FOR_ALL_TOKENS_IN_TAG = 1;

export type JoinStationPoolInit = {
  kind: 'Init';
  amountsIn: BigNumberish[];
};

export type JoinStationPoolBPTOutForAllTokensIn = {
  kind: 'BPTOutForAllTokensIn';
  bptAmountOut: BigNumberish;
};

export function encodeJoinStationPool(joinData: JoinStationPoolInit | JoinStationPoolBPTOutForAllTokensIn): string {
  if (joinData.kind == 'Init') {
    return ethers.utils.defaultAbiCoder.encode(
      ['uint256', 'uint256[]'],
      [JOIN_DEFINET_POOL_INIT_TAG, joinData.amountsIn]
    );
  } else {
    return ethers.utils.defaultAbiCoder.encode(
      ['uint256', 'uint256'],
      [JOIN_DEFINET_POOL_BPT_OUT_FOR_ALL_TOKENS_IN_TAG, joinData.bptAmountOut]
    );
  }
}

const EXIT_DEFINET_POOL_BPT_IN_FOR_ALL_TOKENS_OUT_TAG = 0;

export type ExitStationPoolBPTInForAllTokensOut = {
  kind: 'BPTInForAllTokensOut';
  bptAmountIn: BigNumberish;
};

export function encodeExitStationPool(exitData: ExitStationPoolBPTInForAllTokensOut): string {
  return ethers.utils.defaultAbiCoder.encode(
    ['uint256', 'uint256'],
    [EXIT_DEFINET_POOL_BPT_IN_FOR_ALL_TOKENS_OUT_TAG, exitData.bptAmountIn]
  );
}
