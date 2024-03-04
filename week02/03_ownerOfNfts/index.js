const { getDefaultProvider, id } = require("ethers");

async function main() {
    const provider = getDefaultProvider("mainnet");
    const latestBlock = await provider.getBlockNumber();

    const _fromBlock = latestBlock - 10000;
    const _toBlock = latestBlock;
    const _address = "0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB";
    const eventSignature = "PunkTransfer(address,address,uint256)";
    const _topics = id(eventSignature);

    const logs = await provider.getLogs({ fromBlock: _fromBlock, toBlock: _toBlock, address: _address, topics: [_topics] })

    // Data: The ABI-Encoded or “hashed” non-indexed parameters of the event.
    // Topics: Indexed parameters of the event
    //
    // Example:
    // event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    //
    // data: '0x00000000000000000000000000000000000000000000000000000000000010fb',
    // topics: [
    //     '0x05af636b70da6819000c49f85b21fa82081c632069bb626f30932034099107d8',
    //     '0x0000000000000000000000000cdb1e900885fadd99d9955f5fb8e9f6acca8bd7',
    //     '0x000000000000000000000000ef192f0679112786ecc69198cbf59e3a8a286390'
    // ]
    //
    // (0x00000000000000000000000000000000000000000000000000000000000010fb)_16 === (4347)_10
    // 
    // means that the address 0x0000000000000000000000000cdb1e900885fadd99d9955f5fb8e9f6acca8bd7 trasnferred token with the id 4347 to the address 0x000000000000000000000000ef192f0679112786ecc69198cbf59e3a8a286390

    const map = new Map();

    logs.forEach(log => {
        console.log(`Address ${log.topics[1]} transferred token with id ${BigInt(log.data).toString()} to address ${log.topics[2]}\n`)

        const from = log.topics[1];
        const to = log.topics[2];
        const tokenId = BigInt(log.data).toString();

        if (map.has(from)) {
            let currentNftsFrom = map.get(from);
            const index = currentNftsFrom.indexOf(tokenId);
            if (index != -1) {
                currentNftsFrom.splice(index, 1);
            }
            map.set(from, currentNftsFrom);
        }

        let currentNftsTo = map.get(to);
        if (currentNftsTo) {
            currentNftsTo.push(tokenId);
        } else {
            currentNftsTo = [tokenId];
        }

        map.set(to, currentNftsTo);

    });

    map.forEach((_value, owner) => {
        console.log(`${owner} poses: ${map.get(owner)}`)
    })
}

main();