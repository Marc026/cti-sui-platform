import pytest
import asyncio
from typing import Generator

@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
def cti_config():
    """Provide test configuration"""
    from cti_platform_tester import CTIPlatformConfig
    return CTIPlatformConfig(
        network="localnet",
        package_id="0x123",
        platform_object_id="0x456",
        admin_address="0x789"
    )
