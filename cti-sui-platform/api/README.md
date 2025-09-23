\# CTI Platform API Service



REST API service for the CTI Platform on Sui blockchain.



\## Features



\- RESTful API endpoints

\- Sui blockchain integration

\- Redis caching

\- Rate limiting

\- Authentication

\- Health monitoring

\- SIEM integrations



\## Installation



```bash

npm install

```



\## Configuration



Copy `.env.template` to `.env` and configure:



```bash

cp .env.template .env

```



\## Running



```bash

\# Development

npm run dev



\# Production

npm start

```



\## API Endpoints



\- `GET /health` - Health check

\- `GET /api/v1/stats` - Platform statistics

\- `POST /api/v1/participants/register` - Register participant

\- `POST /api/v1/intelligence/submit` - Submit intelligence

\- `GET /api/v1/intelligence/:id` - Get intelligence

\- `POST /api/v1/intelligence/:id/validate` - Validate intelligence



\## Testing



```bash

npm test

```



\## Docker



```bash

docker build -t cti-platform-api .

docker run -p 3000:3000 cti-platform-api

```

