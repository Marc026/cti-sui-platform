import pytest
from cti_platform_tester import CTIPlatformTester, ThreatDataGenerator

@pytest.mark.asyncio
async def test_threat_data_generation():
    """Test threat data generation"""
    threat_data = ThreatDataGenerator.generate_threat_intelligence()
    
    assert threat_data.threat_type in ThreatDataGenerator.THREAT_TYPES
    assert 1 <= threat_data.severity <= 10
    assert 1 <= threat_data.confidence_score <= 100
    assert len(threat_data.ioc_hash) == 32  # SHA256 hash length
    assert threat_data.expiration_hours > 0

@pytest.mark.asyncio
async def test_tester_initialization(cti_config):
    """Test tester initialization"""
    tester = CTIPlatformTester(cti_config)
    await tester.setup_test_environment()
    
    assert len(tester.participants) == 10
    assert tester.config.network == "localnet"