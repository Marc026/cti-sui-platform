import pytest
from cti_platform_tester import CTIPlatformTester

@pytest.mark.asyncio
async def test_registration_performance(cti_config):
    """Test participant registration performance"""
    tester = CTIPlatformTester(cti_config)
    await tester.setup_test_environment()
    
    result = await tester.test_participant_registration(5)
    
    assert result.passed >= 4  # Allow for some failures
    assert result.throughput > 0
    assert result.average_latency < 5.0  # Should be under 5 seconds

@pytest.mark.asyncio
async def test_intelligence_submission_performance(cti_config):
    """Test intelligence submission performance"""
    tester = CTIPlatformTester(cti_config)
    await tester.setup_test_environment()
    
    result = await tester.test_intelligence_submission(10)
    
    assert result.passed >= 8  # Allow for some failures
    assert result.throughput > 0
    assert result.average_latency < 3.0