\# CTI Sharing Platform on Sui Blockchain



A next-generation cyber threat intelligence sharing platform built on Sui blockchain using Move smart contracts. This platform enables secure, decentralized, and incentivized sharing of cyber threat intelligence between organizations.



\## 🎯 Key Features



\- \*\*Decentralized CTI Sharing\*\*: Share threat intelligence without relying on centralized authorities

\- \*\*Sui Blockchain Integration\*\*: Leverages Sui's object-centric architecture and parallel processing

\- \*\*Move Smart Contracts\*\*: Enhanced security through Move's type system and formal verification

\- \*\*Reputation System\*\*: Community-driven quality assessment and reputation tracking

\- \*\*Economic Incentives\*\*: Reward system for high-quality intelligence contributions

\- \*\*SIEM Integration\*\*: Direct integration with major SIEM platforms (Splunk, QRadar, Sentinel, etc.)

\- \*\*Standards Compliance\*\*: Native STIX/TAXII support and MITRE ATT\&CK framework integration

\- \*\*GDPR Compliant\*\*: Privacy-by-design architecture meeting regulatory requirements



\## 🏗️ Architecture Overview



```

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐

│   Frontend      │    │   API Service   │    │ Smart Contracts │

│   (Next.js)     │◄───┤   (Node.js)     │◄───┤   (Move)        │

└─────────────────┘    └─────────────────┘    └─────────────────┘

&nbsp;                             │                        │

&nbsp;                             ▼                        ▼

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐

│   SIEM Systems  │    │   Database      │    │  Sui Blockchain │

│   Integration   │    │  (PostgreSQL)   │    │   Network       │

└─────────────────┘    └─────────────────┘    └─────────────────┘

```



\## 🚀 Quick Start



\### Prerequisites



\- \*\*Node.js\*\* (v18+)

\- \*\*Rust\*\* (latest stable)

\- \*\*Python\*\* (3.11+)

\- \*\*Docker\*\* (optional, for containerized deployment)

\- \*\*Sui CLI\*\* (latest version)



\### Installation



1\. \*\*Clone the repository\*\*

&nbsp;  ```bash

&nbsp;  git clone https://github.com/marclapira/cti-sui-platform.git

&nbsp;  cd cti-sui-platform

&nbsp;  ```



2\. \*\*Install Sui CLI\*\*

&nbsp;  ```bash

&nbsp;  cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui

&nbsp;  ```



3\. \*\*Setup environment\*\*

&nbsp;  ```bash

&nbsp;  cp .env.template .env

&nbsp;  # Edit .env with your configuration

&nbsp;  ```



4\. \*\*Deploy the platform\*\*

&nbsp;  ```bash

&nbsp;  chmod +x scripts/deploy.sh

&nbsp;  ./scripts/deploy.sh development localnet

&nbsp;  ```



5\. \*\*Access the platform\*\*

&nbsp;  - \*\*Frontend\*\*: http://localhost:3001

&nbsp;  - \*\*API\*\*: http://localhost:3000

&nbsp;  - \*\*Documentation\*\*: http://localhost:3000/docs



\## 📁 Project Structure



```

cti-sui-platform/

├── smart-contracts/           # Move smart contracts

│   ├── sources/

│   │   ├── threat\_intelligence.move

│   │   ├── reputation.move

│   │   ├── access\_control.move

│   │   └── incentives.move

│   ├── tests/

│   └── Move.toml

├── sdk/                      # SDKs and libraries

│   ├── typescript/           # TypeScript SDK

│   └── python/              # Python utilities

├── api/                     # REST API service

│   ├── src/

│   ├── integrations/        # SIEM integrations

│   └── package.json

├── frontend/                # Web interface

│   ├── components/

│   ├── pages/

│   └── package.json

├── tests/                   # Testing framework

│   ├── python/             # Python test suite

│   └── integration/        # Integration tests

├── deployment/             # Deployment configurations

├── docs/                   # Documentation

├── scripts/               # Utility scripts

└── docker-compose.yml    # Docker configuration

```



\## 🔧 Development



\### Smart Contract Development



```bash

cd smart-contracts/cti\_platform



\# Build contracts

sui move build



\# Run tests

sui move test



\# Run formal verification

sui move prove

```



\### API Development



```bash

cd api



\# Install dependencies

npm install



\# Start development server

npm run dev



\# Run tests

npm test

```



\### Frontend Development



```bash

cd frontend



\# Install dependencies

npm install



\# Start development server

npm run dev



\# Run tests

npm test

```



\### Python Testing



```bash

cd tests/python



\# Install dependencies

pip install -r requirements.txt



\# Run comprehensive tests

python -m pytest -v

```



\## 🔐 Security Features



\### Smart Contract Security



\- \*\*Move Language Benefits\*\*: Eliminates common vulnerabilities (reentrancy, integer overflow)

\- \*\*Formal Verification\*\*: Mathematical proofs of security properties

\- \*\*Resource Management\*\*: Built-in protection against asset duplication/loss

\- \*\*Access Control\*\*: Capability-based permission system



\### Platform Security



\- \*\*GDPR Compliance\*\*: Hash-only storage, automated deletion, consent management

\- \*\*Authentication\*\*: JWT-based API authentication

\- \*\*Rate Limiting\*\*: Protection against abuse and DoS attacks

\- \*\*Encryption\*\*: TLS/SSL for all communications



\## 📊 Performance Benchmarks



| Metric | Sui Implementation | Ethereum Comparison |

|--------|-------------------|-------------------|

| \*\*Transaction Throughput\*\* | 528 TPS | 15 TPS |

| \*\*Transaction Finality\*\* | 1.7 seconds | 5+ minutes |

| \*\*Gas Cost\*\* | $0.0016 | $15.40 |

| \*\*Success Rate\*\* | 99.6% | 99.2% |



\## 🔌 SIEM Integration



The platform supports integration with major SIEM systems:



\- \*\*Splunk\*\* (HTTP Event Collector)

\- \*\*IBM QRadar\*\* (Custom Events API)

\- \*\*Microsoft Sentinel\*\* (Data Collector API)

\- \*\*Elastic SIEM\*\* (Elasticsearch)

\- \*\*Generic SIEM\*\* (Custom REST APIs)



\### Example Integration



```typescript

import { SIEMConnector, SIEMType } from './integrations/siem\_connector';



const siem = new SIEMConnector({

&nbsp; siem\_type: SIEMType.SPLUNK,

&nbsp; endpoint: 'https://splunk.company.com:8088',

&nbsp; api\_key: 'your-hec-token'

});



await siem.push\_intelligence(threatData);

```



\## 🧪 Testing



\### Comprehensive Test Suite



```bash

\# Run all tests

./scripts/test.sh



\# Run specific test categories

cd tests/python

python -m pytest test\_performance.py -v

python -m pytest test\_security.py -v

python -m pytest test\_integration.py -v

```



\### Performance Testing



```bash

cd tests/python

python cti\_platform\_tester.py

```



\## 🚀 Deployment



\### Development Deployment



```bash

./scripts/deploy.sh development localnet

```



\### Production Deployment



```bash

./scripts/deploy.sh production mainnet

```



\### Docker Deployment



```bash

docker-compose up -d

```



\### Kubernetes Deployment



```bash

kubectl apply -f k8s/

```



\## 📚 API Documentation



\### REST API Endpoints



\- \*\*GET\*\* `/api/v1/stats` - Platform statistics

\- \*\*POST\*\* `/api/v1/participants/register` - Register participant

\- \*\*POST\*\* `/api/v1/intelligence/submit` - Submit threat intelligence

\- \*\*GET\*\* `/api/v1/intelligence/:id` - Get intelligence details

\- \*\*POST\*\* `/api/v1/intelligence/:id/validate` - Validate intelligence

\- \*\*GET\*\* `/api/v1/analytics/trends` - Threat trends analysis



\### TypeScript SDK



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



\## 🤝 Contributing



We welcome contributions to the CTI Sharing Platform! Please see our \[Contributing Guide](CONTRIBUTING.md) for details.



\### Development Setup



1\. Fork the repository

2\. Create a feature branch

3\. Make your changes

4\. Add tests for new functionality

5\. Ensure all tests pass

6\. Submit a pull request



\### Code Style



\- \*\*Move\*\*: Follow Sui Move style guidelines

\- \*\*TypeScript\*\*: Use ESLint with provided configuration

\- \*\*Python\*\*: Follow PEP 8 with Black formatting



\## 📄 License



This project is licensed under the MIT License - see the \[LICENSE](LICENSE) file for details.



\## 🙏 Acknowledgments



\- \*\*Sui Foundation\*\* for the advanced blockchain platform

\- \*\*MITRE Corporation\*\* for the ATT\&CK framework

\- \*\*OASIS\*\* for STIX/TAXII standards

\- \*\*CTI community\*\* for best practices and standards



\## 📞 Support



\- \*\*Documentation\*\*: \[docs/](docs/)

\- \*\*Issues\*\*: \[GitHub Issues](https://github.com/marclapira/cti-sui-platform/issues)

\- \*\*Discussions\*\*: \[GitHub Discussions](https://github.com/marclapira/cti-sui-platform/discussions)

\- \*\*Email\*\*: marc.lapira@example.com



\## 🔗 Links



\- \*\*Live Demo\*\*: https://cti-platform-demo.sui.io

\- \*\*Research Paper\*\*: \[Blockchain-Based CTI Sharing on Sui](docs/research-paper.pdf)

\- \*\*API Documentation\*\*: https://api.cti-platform.sui.io/docs

\- \*\*Sui Documentation\*\*: https://docs.sui.io



---



\*\*Built with ❤️ for the cybersecurity community\*\*

