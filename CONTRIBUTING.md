\# Contributing to CTI Sharing Platform



Thank you for your interest in contributing to the CTI Sharing Platform! This document provides guidelines and information for contributors.



\## 🚀 Getting Started



\### Prerequisites



Before contributing, ensure you have:



\- Understanding of blockchain technology and Sui platform

\- Experience with Move programming language

\- Familiarity with cybersecurity and threat intelligence concepts

\- Knowledge of relevant technologies (TypeScript, Python, Node.js)



\### Development Environment Setup



1\. \*\*Clone and setup the repository\*\*

&nbsp;  ```bash

&nbsp;  git clone https://github.com/marclapira/cti-sui-platform.git

&nbsp;  cd cti-sui-platform

&nbsp;  cp .env.template .env

&nbsp;  ```



2\. \*\*Install dependencies\*\*

&nbsp;  ```bash

&nbsp;  # Install Sui CLI

&nbsp;  cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui

&nbsp;  

&nbsp;  # Install Node.js dependencies

&nbsp;  cd api \&\& npm install \&\& cd ..

&nbsp;  cd frontend \&\& npm install \&\& cd ..

&nbsp;  cd sdk/typescript \&\& npm install \&\& cd ../..

&nbsp;  

&nbsp;  # Install Python dependencies

&nbsp;  cd tests/python \&\& pip install -r requirements.txt \&\& cd ../..

&nbsp;  ```



3\. \*\*Run tests to verify setup\*\*

&nbsp;  ```bash

&nbsp;  ./scripts/test.sh

&nbsp;  ```



\## 📝 How to Contribute



\### Types of Contributions



We welcome various types of contributions:



\- \*\*Bug fixes\*\*: Fix existing issues

\- \*\*Feature enhancements\*\*: Add new functionality

\- \*\*Documentation\*\*: Improve docs and examples

\- \*\*Testing\*\*: Add test coverage and scenarios

\- \*\*Security\*\*: Identify and fix security issues

\- \*\*Performance\*\*: Optimize performance and efficiency



\### Contribution Process



1\. \*\*Check existing issues\*\*: Look for existing issues or create a new one

2\. \*\*Fork the repository\*\*: Create your own fork

3\. \*\*Create a feature branch\*\*: `git checkout -b feature/your-feature-name`

4\. \*\*Make your changes\*\*: Follow coding standards and best practices

5\. \*\*Add tests\*\*: Ensure new functionality is tested

6\. \*\*Update documentation\*\*: Update relevant documentation

7\. \*\*Submit a pull request\*\*: Create a PR with clear description



\## 🏗️ Development Guidelines



\### Smart Contract Development (Move)



\- Follow Sui Move style guidelines

\- Include comprehensive tests for all functions

\- Use formal verification where applicable

\- Document all public functions and modules

\- Follow error handling best practices



\*\*Example:\*\*

```move

/// Submit new threat intelligence to the platform

/// 

/// # Arguments

/// \* `platform` - Mutable reference to the CTI platform

/// \* `profile` - Mutable reference to submitter's profile

/// \* `threat\_data` - The threat intelligence data to submit

/// 

/// # Errors

/// \* `E\_NOT\_AUTHORIZED` - If sender doesn't own the profile

/// \* `E\_INVALID\_THREAT\_TYPE` - If threat data is invalid

public entry fun submit\_intelligence(

&nbsp;   platform: \&mut CTIPlatform,

&nbsp;   profile: \&mut ParticipantProfile,

&nbsp;   // ... other parameters

) {

&nbsp;   // Implementation with proper error handling

&nbsp;   assert!(profile.address == tx\_context::sender(ctx), E\_NOT\_AUTHORIZED);

&nbsp;   // ...

}

```



\### TypeScript/JavaScript Development



\- Use TypeScript for type safety

\- Follow ESLint configuration provided

\- Write unit tests using Jest

\- Use async/await for asynchronous operations

\- Include JSDoc comments for public APIs



\*\*Example:\*\*

```typescript

/\*\*

&nbsp;\* Submit threat intelligence to the platform

&nbsp;\* @param keypair - Ed25519 keypair for signing

&nbsp;\* @param profileObjectId - Participant profile object ID

&nbsp;\* @param intelligenceData - Threat intelligence data

&nbsp;\* @returns Transaction digest

&nbsp;\*/

async submitIntelligence(

&nbsp; keypair: Ed25519Keypair,

&nbsp; profileObjectId: string,

&nbsp; intelligenceData: ThreatIntelligenceData

): Promise {

&nbsp; // Implementation

}

```



\### Python Development



\- Follow PEP 8 style guidelines

\- Use Black for code formatting

\- Include type hints where appropriate

\- Write comprehensive tests using pytest

\- Use dataclasses for structured data



\*\*Example:\*\*

```python

@dataclass

class ThreatIntelligenceData:

&nbsp;   """Threat intelligence data structure"""

&nbsp;   ioc\_hash: bytes

&nbsp;   threat\_type: str

&nbsp;   severity: int

&nbsp;   confidence\_score: int

&nbsp;   stix\_pattern: str

&nbsp;   mitre\_techniques: List\[str]

&nbsp;   expiration\_hours: int



&nbsp;   def validate(self) -> bool:

&nbsp;       """Validate the threat intelligence data"""

&nbsp;       return (

&nbsp;           1 <= self.severity <= 10 and

&nbsp;           1 <= self.confidence\_score <= 100 and

&nbsp;           self.expiration\_hours > 0

&nbsp;       )

```



\## 🧪 Testing Guidelines



\### Test Requirements



All contributions must include appropriate tests:



\- \*\*Smart Contracts\*\*: Move unit tests and integration tests

\- \*\*API\*\*: Unit tests and integration tests with coverage > 80%

\- \*\*Frontend\*\*: Component tests and E2E tests

\- \*\*SDK\*\*: Unit tests for all public methods



\### Running Tests



```bash

\# Run all tests

./scripts/test.sh



\# Run specific test suites

cd smart-contracts \&\& sui move test

cd api \&\& npm test

cd frontend \&\& npm test

cd tests/python \&\& python -m pytest -v

```



\### Test Structure



```

tests/

├── unit/                 # Unit tests

├── integration/          # Integration tests

├── e2e/                 # End-to-end tests

├── performance/         # Performance tests

└── security/           # Security tests

```



\## 📚 Documentation Standards



\### Code Documentation



\- \*\*Move\*\*: Document all public functions with clear descriptions

\- \*\*TypeScript\*\*: Use JSDoc for all public APIs

\- \*\*Python\*\*: Use docstrings following Google style

\- \*\*README\*\*: Update README for new features



\### Documentation Structure



```

docs/

├── api/                 # API documentation

├── sdk/                # SDK documentation

├── deployment/         # Deployment guides

├── security/          # Security documentation

└── examples/          # Code examples

```



\## 🔐 Security Guidelines



\### Security Best Practices



\- \*\*Never commit sensitive data\*\*: Use environment variables

\- \*\*Validate all inputs\*\*: Implement proper input validation

\- \*\*Follow security patterns\*\*: Use established security patterns

\- \*\*Regular security reviews\*\*: Participate in security reviews



\### Reporting Security Issues



For security vulnerabilities:



1\. \*\*DO NOT\*\* create public issues

2\. Email security@cti-platform.example.com

3\. Include detailed description and reproduction steps

4\. Wait for acknowledgment before public disclosure



\## 📋 Code Review Process



\### Review Criteria



Code reviews focus on:



\- \*\*Functionality\*\*: Does the code work as intended?

\- \*\*Security\*\*: Are there any security vulnerabilities?

\- \*\*Performance\*\*: Is the code efficient?

\- \*\*Maintainability\*\*: Is the code readable and maintainable?

\- \*\*Testing\*\*: Is there adequate test coverage?

\- \*\*Documentation\*\*: Is the code properly documented?



\### Review Checklist



\- \[ ] Code follows style guidelines

\- \[ ] All tests pass

\- \[ ] Documentation is updated

\- \[ ] Security considerations addressed

\- \[ ] Performance impact evaluated

\- \[ ] Breaking changes documented



\## 🎯 Issue Guidelines



\### Bug Reports



Include:

\- Clear description of the bug

\- Steps to reproduce

\- Expected vs actual behavior

\- Environment details

\- Screenshots/logs if applicable



\### Feature Requests



Include:

\- Clear description of the feature

\- Use case and motivation

\- Proposed implementation approach

\- Impact on existing functionality



\### Issue Labels



\- `bug`: Something isn't working

\- `enhancement`: New feature or request

\- `documentation`: Improvements to documentation

\- `security`: Security-related issues

\- `performance`: Performance improvements

\- `good first issue`: Good for newcomers



\## 🚀 Release Process



\### Version Numbering



We follow Semantic Versioning (semver):

\- \*\*MAJOR\*\*: Breaking changes

\- \*\*MINOR\*\*: New features (backward compatible)

\- \*\*PATCH\*\*: Bug fixes (backward compatible)



\### Release Checklist



\- \[ ] All tests pass

\- \[ ] Documentation updated

\- \[ ] Changelog updated

\- \[ ] Version numbers updated

\- \[ ] Security review completed

\- \[ ] Performance benchmarks run



\## 🤝 Community Guidelines



\### Code of Conduct



\- Be respectful and inclusive

\- Focus on constructive feedback

\- Help newcomers learn and contribute

\- Follow project guidelines and standards



\### Communication Channels



\- \*\*GitHub Issues\*\*: Bug reports and feature requests

\- \*\*GitHub Discussions\*\*: General discussions and questions

\- \*\*Discord\*\*: Real-time community chat

\- \*\*Email\*\*: Direct contact for sensitive issues



\## 📞 Getting Help



If you need help:



1\. Check existing documentation

2\. Search existing issues

3\. Ask in GitHub Discussions

4\. Join our Discord community

5\. Contact maintainers directly



\## 🙏 Recognition



Contributors are recognized through:



\- \*\*Contributors file\*\*: Listed in CONTRIBUTORS.md

\- \*\*Release notes\*\*: Mentioned in release notes

\- \*\*Hall of fame\*\*: Featured on project website

\- \*\*Swag\*\*: Project stickers and swag for significant contributions



---



Thank you for contributing to the CTI Sharing Platform! Your efforts help make cybersecurity more collaborative and effective.



