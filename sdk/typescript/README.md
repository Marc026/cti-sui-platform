\# CTI Platform TypeScript SDK



TypeScript SDK for interacting with the CTI Platform on Sui blockchain.



\## Installation



```bash

npm install @cti-platform/sui-sdk

```



\## Usage



```typescript

import CTIPlatformSDK from '@cti-platform/sui-sdk';



const sdk = new CTIPlatformSDK({

&nbsp; network: 'testnet',

&nbsp; packageId: 'your-package-id',

&nbsp; platformObjectId: 'your-platform-id'

});



// Register participant

const result = await sdk.registerParticipant(

&nbsp; keypair,

&nbsp; 'Organization Name'

);



// Submit intelligence

await sdk.submitIntelligence(

&nbsp; keypair,

&nbsp; profileId,

&nbsp; threatData,

&nbsp; submissionFee

);

```



\## Features



\- Complete API for blockchain interaction

\- Event subscription and monitoring

\- Analytics and reporting functions

\- Type-safe interfaces

\- Comprehensive error handling



\## Documentation



Full API documentation is available at \[docs link].



\## Examples



See the `examples/` directory for complete usage examples.

