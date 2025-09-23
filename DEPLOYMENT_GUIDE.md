\# DEPLOYMENT\_GUIDE.md

\# CTI Platform Deployment Guide



\## Prerequisites



\- \*\*Node.js\*\* (v18+)

\- \*\*Rust\*\* (latest stable) 

\- \*\*Python\*\* (3.11+)

\- \*\*Docker\*\* (optional)

\- \*\*Sui CLI\*\* (latest)



\## Quick Start



1\. \*\*Clone Repository\*\*

&nbsp;  ```bash

&nbsp;  git clone https://github.com/marclapira/cti-sui-platform.git

&nbsp;  cd cti-sui-platform

&nbsp;  ```



2\. \*\*Initial Setup\*\*

&nbsp;  ```bash

&nbsp;  chmod +x scripts/\*.sh

&nbsp;  ./scripts/setup.sh

&nbsp;  ```



3\. \*\*Configure Environment\*\*

&nbsp;  ```bash

&nbsp;  cp .env.template .env

&nbsp;  # Edit .env with your settings

&nbsp;  ```



4\. \*\*Deploy Platform\*\*

&nbsp;  ```bash

&nbsp;  ./scripts/deploy.sh development localnet

&nbsp;  ```



\## Deployment Options



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



\## Configuration



\### Environment Variables



Key variables to configure in `.env`:



```bash

\# Blockchain

SUI\_NETWORK=testnet

PACKAGE\_ID=your-package-id

PLATFORM\_OBJECT\_ID=your-platform-id



\# Database

DATABASE\_URL=postgresql://user:pass@localhost:5432/cti\_platform



\# Security

JWT\_SECRET=your-secret-key

```



\### Network Setup



\#### Local Network

```bash

sui start --with-faucet --force-regenesis

```



\#### Testnet

```bash

sui client new-env --alias testnet \\

&nbsp;   --rpc https://fullnode.testnet.sui.io:443

sui client switch --env testnet

sui client faucet

```



\### Smart Contract Deployment



```bash

cd smart-contracts/cti\_platform

sui move build

sui client publish --gas-budget 100000000

```



\## Services



\### API Service

\- \*\*URL\*\*: http://localhost:3000

\- \*\*Health\*\*: http://localhost:3000/health

\- \*\*Docs\*\*: http://localhost:3000/docs



\### Frontend

\- \*\*URL\*\*: http://localhost:3001

\- \*\*Production\*\*: Built with Next.js



\### Database

\- \*\*PostgreSQL\*\*: Port 5432

\- \*\*Redis\*\*: Port 6379



\## Monitoring



\### Health Checks

```bash

./scripts/monitor.sh

```



\### Logs

```bash

\# API logs

tail -f api/logs/combined.log



\# Frontend logs  

docker logs cti-platform-frontend



\# Database logs

docker logs cti-platform-postgres

```



\## Backup and Recovery



\### Create Backup

```bash

./scripts/backup.sh

```



\### Restore from Backup

```bash

tar -xzf backups/cti\_platform\_backup\_TIMESTAMP.tar.gz

\# Follow restore procedures in backup directory

```



\## Security



\### SSL/TLS Setup

```bash

\# Install Certbot

sudo apt install certbot python3-certbot-nginx



\# Obtain certificate

sudo certbot --nginx -d yourdomain.com



\# Auto-renewal

sudo crontab -e

\# Add: 0 12 \* \* \* /usr/bin/certbot renew --quiet

```



\### Firewall Configuration

```bash

sudo ufw enable

sudo ufw allow ssh

sudo ufw allow 80/tcp

sudo ufw allow 443/tcp

```



\## Troubleshooting



\### Common Issues



1\. \*\*Smart Contract Deployment Fails\*\*

&nbsp;  ```bash

&nbsp;  # Check gas budget

&nbsp;  sui client gas

&nbsp;  

&nbsp;  # Request more gas

&nbsp;  sui client faucet

&nbsp;  ```



2\. \*\*API Not Starting\*\*

&nbsp;  ```bash

&nbsp;  # Check environment variables

&nbsp;  cat .env

&nbsp;  

&nbsp;  # Check database connection

&nbsp;  npm run migrate

&nbsp;  ```



3\. \*\*Frontend Build Fails\*\*

&nbsp;  ```bash

&nbsp;  # Clear cache

&nbsp;  rm -rf .next

&nbsp;  

&nbsp;  # Rebuild

&nbsp;  npm run build

&nbsp;  ```



\## Production Considerations



\### Performance Tuning

\- Use Redis for caching

\- Configure connection pooling

\- Enable compression

\- Set up CDN for static assets



\### Security Hardening

\- Use strong passwords

\- Enable rate limiting

\- Configure CORS properly

\- Regular security updates



\### Monitoring Setup

\- Prometheus for metrics

\- Grafana for dashboards

\- Log aggregation

\- Alert configuration



\## Support



\- \*\*Documentation\*\*: \[docs/](docs/)

\- \*\*Issues\*\*: GitHub Issues

\- \*\*Email\*\*: support@cti-platform.example.com



---



\# PROJECT\_STRUCTURE.md

\# CTI Platform Project Structure



Complete directory structure and file organization for the CTI Sharing Platform on Sui blockchain.



```

cti-sui-platform/

├── README.md                              # Main project documentation

├── CONTRIBUTING.md                        # Contribution guidelines

├── LICENSE                                # MIT License

├── DEPLOYMENT\_GUIDE.md                   # Deployment instructions

├── PROJECT\_STRUCTURE.md                  # This file

├── .env.template                          # Environment variables template

├── .gitignore                            # Git ignore rules

├── .dockerignore                         # Docker ignore rules

├── docker-compose.yml                    # Development Docker setup

├── docker-compose.prod.yml               # Production Docker setup

│

├── .github/                              # GitHub workflows

│   └── workflows/

│       ├── ci.yml                        # CI/CD pipeline

│       └── security.yml                  # Security checks

│

├── smart-contracts/                      # Move smart contracts

│   ├── Move.toml                         # Move package configuration

│   ├── README.md                         # Smart contracts documentation

│   ├── sources/

│   │   ├── threat\_intelligence.move      # Main CTI contract

│   │   ├── reputation.move               # Reputation system

│   │   ├── access\_control.move           # Access control

│   │   └── incentives.move               # Economic incentives

│   └── tests/

│       └── threat\_intelligence\_tests.move # Contract tests

│

├── sdk/                                  # Software Development Kits

│   └── typescript/

│       ├── package.json                  # TypeScript SDK package

│       ├── tsconfig.json                 # TypeScript configuration

│       ├── .eslintrc.json               # ESLint configuration

│       ├── jest.config.js               # Jest test configuration

│       ├── README.md                     # SDK documentation

│       └── src/

│           └── index.ts                  # Main SDK implementation

│

├── api/                                  # REST API service

│   ├── package.json                      # API service package

│   ├── Dockerfile                        # API Docker image

│   ├── .eslintrc.json                   # ESLint configuration

│   ├── jest.config.js                   # Jest test configuration

│   ├── README.md                         # API documentation

│   ├── src/

│   │   └── server.js                     # Main API server

│   └── integrations/

│       └── siem\_connector.py             # SIEM integration module

│

├── frontend/                             # Web interface

│   ├── package.json                      # Frontend package

│   ├── Dockerfile                        # Frontend Docker image

│   ├── next.config.js                    # Next.js configuration

│   ├── tailwind.config.js               # Tailwind CSS configuration

│   ├── README.md                         # Frontend documentation

│   ├── components/                       # React components

│   ├── pages/                           # Next.js pages

│   └── styles/                          # CSS styles

│

├── tests/                                # Testing framework

│   └── python/

│       ├── requirements.txt              # Python dependencies

│       ├── conftest.py                   # Pytest configuration

│       ├── pytest.ini                   # Pytest settings

│       ├── .flake8                      # Flake8 configuration

│       ├── README.md                     # Testing documentation

│       ├── cti\_platform\_tester.py        # Main test framework

│       ├── test\_basic.py                 # Basic tests

│       └── test\_performance.py           # Performance tests

│

├── scripts/                              # Utility scripts

│   ├── deploy.sh                         # Main deployment script

│   ├── test.sh                          # Testing script

│   ├── cleanup.sh                       # Cleanup script

│   ├── backup.sh                        # Backup script

│   ├── setup.sh                         # Initial setup script

│   ├── monitor.sh                       # Monitoring script

│   └── init-db.sql                      # Database initialization

│

├── nginx/                                # Nginx configuration

│   └── nginx.conf                        # Nginx configuration file

│

├── monitoring/                           # Monitoring configuration

│   └── prometheus.yml                    # Prometheus configuration

│

├── docs/                                 # Additional documentation

│   ├── api/                             # API documentation

│   ├── sdk/                             # SDK documentation

│   ├── deployment/                      # Deployment guides

│   ├── security/                        # Security documentation

│   └── examples/                        # Code examples

│

├── logs/                                 # Log files (created at runtime)

├── data/                                 # Data files (created at runtime)

└── backups/                             # Backup files (created by scripts)

```



\## File Types and Purposes



\### Configuration Files

\- \*\*package.json\*\*: Node.js project configuration

\- \*\*tsconfig.json\*\*: TypeScript compiler configuration

\- \*\*Move.toml\*\*: Move package configuration

\- \*\*docker-compose.yml\*\*: Docker service orchestration

\- \*\*.env.template\*\*: Environment variables template



\### Source Code

\- \*\*threat\_intelligence.move\*\*: Main smart contract

\- \*\*index.ts\*\*: TypeScript SDK implementation

\- \*\*server.js\*\*: Node.js API server

\- \*\*cti\_platform\_tester.py\*\*: Python testing framework



\### Documentation

\- \*\*README.md\*\*: Project overview and quick start

\- \*\*CONTRIBUTING.md\*\*: Contribution guidelines

\- \*\*DEPLOYMENT\_GUIDE.md\*\*: Detailed deployment instructions



\### Scripts

\- \*\*deploy.sh\*\*: Main deployment automation

\- \*\*test.sh\*\*: Comprehensive testing

\- \*\*setup.sh\*\*: Initial environment setup

\- \*\*monitor.sh\*\*: System monitoring



\### Docker

\- \*\*Dockerfile\*\*: Container image definitions

\- \*\*docker-compose.yml\*\*: Development environment

\- \*\*docker-compose.prod.yml\*\*: Production environment



\## Key Features by Directory



\### smart-contracts/

\- Move language implementation

\- Formal verification support

\- Comprehensive test suite

\- Gas-optimized operations



\### sdk/typescript/

\- Type-safe API interface

\- Event subscription system

\- Analytics functions

\- Comprehensive error handling



\### api/

\- RESTful API endpoints

\- Authentication and authorization

\- Rate limiting and caching

\- SIEM integration support



\### tests/python/

\- Performance benchmarking

\- Security testing

\- Realistic data generation

\- Detailed reporting



\### scripts/

\- Automated deployment

\- Environment setup

\- System monitoring

\- Backup and recovery



This structure provides a complete, production-ready platform with proper separation of concerns, comprehensive testing, and deployment automation.

