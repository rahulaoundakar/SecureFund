import { queryFilterInChunks } from './web3Utils';

test('queries event logs in ranges no larger than the provider limit', async () => {
  const filter = { name: 'DonationReceived' };
  const contract = {
    runner: {
      provider: {
        getBlockNumber: jest.fn().mockResolvedValue(20000),
      },
    },
    queryFilter: jest.fn(async (_filter, fromBlock, toBlock) => [{ fromBlock, toBlock }]),
  };

  const events = await queryFilterInChunks(contract, filter, 100);

  expect(contract.queryFilter.mock.calls.map(([, from, to]) => [from, to])).toEqual([
    [100, 9099],
    [9100, 18099],
    [18100, 20000],
  ]);
  expect(events).toHaveLength(3);
});
