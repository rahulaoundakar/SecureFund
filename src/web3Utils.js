const MAX_LOG_BLOCK_RANGE = 9000;

export async function queryFilterInChunks(contract, filter, fromBlock) {
  if (!Number.isSafeInteger(fromBlock) || fromBlock < 0) {
    throw new Error("Contract deployment block must be a non-negative integer.");
  }

  const provider = contract.runner && contract.runner.provider;
  if (!provider) {
    throw new Error("A provider is required to query contract events.");
  }

  const latestBlock = await provider.getBlockNumber();
  const events = [];

  for (let startBlock = fromBlock; startBlock <= latestBlock; startBlock += MAX_LOG_BLOCK_RANGE) {
    const endBlock = Math.min(startBlock + MAX_LOG_BLOCK_RANGE - 1, latestBlock);
    const batch = await contract.queryFilter(filter, startBlock, endBlock);
    events.push(...batch);
  }

  return events;
}
