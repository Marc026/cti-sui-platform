\# CTI Platform Python Testing Framework



Comprehensive testing framework for the CTI Platform on Sui blockchain.



\## Features



\- Comprehensive test suite

\- Performance benchmarking

\- Security testing

\- Realistic data generation

\- Detailed reporting



\## Installation



```bash

pip install -r requirements.txt

```



\## Running Tests



```bash

\# Run all tests

pytest -v



\# Run specific test categories

pytest test\_performance.py -v

pytest test\_security.py -v



\# Run with coverage

pytest --cov=. --cov-report=html



\# Run performance benchmarks

python cti\_platform\_tester.py

```



\## Test Categories



\- \*\*Basic Tests\*\*: Fundamental functionality

\- \*\*Performance Tests\*\*: Throughput and latency

\- \*\*Security Tests\*\*: Vulnerability assessment

\- \*\*Integration Tests\*\*: End-to-end workflows



\## Configuration



Set environment variables or use `.env` file:



```bash

SUI\_NETWORK=localnet

PACKAGE\_ID=0x...

PLATFORM\_OBJECT\_ID=0x...

```



\## Reporting



Tests generate detailed reports including:

\- Performance metrics

\- Success/failure rates

\- Gas usage analysis

\- Recommendations

