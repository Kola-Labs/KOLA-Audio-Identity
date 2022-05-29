const {
  PREFIX,
  waitForEvent
} = require('./utils');

const Web3 = require('web3');
const diesel = artifacts.require('./Ens2Music.sol');
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:9545'));

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

contract('ENS2Music Tests', accounts => {

  const gasAmt = 3e6;
  const address = accounts[0];

  beforeEach(async () => (
    { contract } = await diesel.deployed(),
    { methods, events } = new web3.eth.Contract(
      contract._jsonInterface,
      contract._address
    )
  ));


  it('Should send new metadata query request', async () => {
    const expErr = 'revert';
    try {
      await methods
        .update("kola102.eth")
        .send({
          from: address,
          gas: gasAmt
        })
    } catch (e) {
      assert.isTrue(
        e.message.startsWith(`${PREFIX}${expErr}`),
        `Expected ${expErr} but got ${e.message} instead!`
      )
    }
  });

  // it('Should have logged a new Provable query', async () => {
  //   const {
  //     returnValues: {
  //       description
  //     }
  //   } = await waitForEvent(events.LogNewProvableQuery)
  //   assert.strictEqual(
  //       description,
  //       'Provable query was sent, standing by for the answer...',
  //       'Provable query incorrectly logged!'
  //   )
  // });

  // it('Callback should have logged a new metadata', async () => {
  //   const {
  //     returnValues: {
  //       uri
  //     }
  //   } = await waitForEvent(events.LogNewMetadata)
  //   console.log('query return: ', uri)
  // });


  it('Should set metadata correctly in contract', async () => {
    await sleep(60 * 1000);
    const uri = await methods
        .getMetadataByDomain("kola102.eth")
        .call();
    console.log("metadata uri: ", uri)
  })
});
