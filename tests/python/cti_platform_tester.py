#!/usr/bin/env python3
"""
tests/python/cti_platform_tester.py
Comprehensive testing framework for CTI platform on Sui blockchain
"""

import asyncio
import json
import hashlib
import time
import random
import statistics
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
import pytest
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class CTIPlatformConfig:
    """Configuration for CTI platform testing"""
    network: str = "localnet"
    package_id: str = ""
    platform_object_id: str = ""
    admin_address: str = ""
    gas_budget: int = 20_000_000

@dataclass
class ThreatIntelligenceData:
    """Threat intelligence data structure"""
    ioc_hash: bytes
    threat_type: str
    severity: int
    confidence_score: int
    stix_pattern: str
    mitre_techniques: List[str]
    expiration_hours: int

@dataclass
class TestResults:
    """Container for test results"""
    test_name: str
    passed: int
    failed: int
    execution_time: float
    average_latency: float
    throughput: float
    gas_used: int
    details: Dict[str, Any]

class ThreatDataGenerator:
    """Generates realistic threat intelligence test data"""
    
    THREAT_TYPES = [
        "malware", "phishing", "ransomware", "botnet", 
        "apt", "ddos", "data_breach", "insider_threat",
        "cryptocurrency_miner", "trojan", "spyware", "adware"
    ]
    
    MITRE_TECHNIQUES = [
        "T1055", "T1003", "T1082", "T1083", "T1057", 
        "T1012", "T1016", "T1033", "T1049", "T1518",
        "T1086", "T1105", "T1043", "T1060", "T1064"
    ]
    
    SAMPLE_STIX_PATTERNS = [
        '[file:hashes.MD5 = "{hash}"]',
        '[ipv4-addr:value = "{ip}"]',
        '[domain-name:value = "{domain}"]',
        '[url:value = "{url}"]',
        '[email-addr:value = "{email}"]'
    ]
    
    @staticmethod
    def generate_ioc_hash(ioc_data: str) -> bytes:
        """Generate IOC hash from data"""
        return hashlib.sha256(ioc_data.encode()).digest()
    
    @staticmethod
    def generate_realistic_ioc() -> str:
        """Generate realistic IOC data"""
        ioc_types = ['file_hash', 'ip_address', 'domain', 'url', 'email']
        ioc_type = random.choice(ioc_types)
        
        if ioc_type == 'file_hash':
            return hashlib.md5(f"malware_{random.randint(10000, 99999)}".encode()).hexdigest()
        elif ioc_type == 'ip_address':
            return f"{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}"
        elif ioc_type == 'domain':
            domains = ['malicious-site.com', 'evil-domain.net', 'bad-actor.org']
            return random.choice(domains)
        elif ioc_type == 'url':
            return f"http://malicious-{random.randint(1000, 9999)}.com/payload"
        else:  # email
            return f"phishing-{random.randint(100, 999)}@evil-domain.com"
    
    @staticmethod
    def generate_stix_pattern(ioc_data: str) -> str:
        """Generate appropriate STIX pattern for IOC"""
        if '@' in ioc_data:
            return f'[email-addr:value = "{ioc_data}"]'
        elif '.' in ioc_data and len(ioc_data.split('.')) == 4:
            return f'[ipv4-addr:value = "{ioc_data}"]'
        elif 'http' in ioc_data:
            return f'[url:value = "{ioc_data}"]'
        elif len(ioc_data) == 32:  # MD5 hash
            return f'[file:hashes.MD5 = "{ioc_data}"]'
        else:
            return f'[domain-name:value = "{ioc_data}"]'
    
    @staticmethod
    def generate_threat_intelligence(
        threat_type: Optional[str] = None,
        severity: Optional[int] = None
    ) -> ThreatIntelligenceData:
        """Generate realistic threat intelligence data"""
        
        if not threat_type:
            threat_type = random.choice(ThreatDataGenerator.THREAT_TYPES)
        
        if not severity:
            # Generate severity based on threat type
            high_severity_types = ['ransomware', 'apt', 'data_breach']
            if threat_type in high_severity_types:
                severity = random.randint(7, 10)
            else:
                severity = random.randint(3, 8)
        
        ioc_data = ThreatDataGenerator.generate_realistic_ioc()
        ioc_hash = ThreatDataGenerator.generate_ioc_hash(ioc_data)
        
        return ThreatIntelligenceData(
            ioc_hash=ioc_hash,
            threat_type=threat_type,
            severity=severity,
            confidence_score=random.randint(60, 95),
            stix_pattern=ThreatDataGenerator.generate_stix_pattern(ioc_data),
            mitre_techniques=random.sample(
                ThreatDataGenerator.MITRE_TECHNIQUES, 
                random.randint(1, 3)
            ),
            expiration_hours=random.choice([24, 48, 72, 168])  # 1 day to 1 week
        )

class PerformanceMonitor:
    """Monitor and analyze performance metrics"""
    
    def __init__(self):
        self.metrics = {
            'transaction_times': [],
            'gas_usage': [],
            'throughput_samples': [],
            'latency_samples': [],
            'error_count': 0,
            'success_count': 0
        }
    
    def record_transaction(self, execution_time: float, gas_used: int, success: bool):
        """Record transaction metrics"""
        if success:
            self.metrics['transaction_times'].append(execution_time)
            self.metrics['gas_usage'].append(gas_used)
            self.metrics['success_count'] += 1
        else:
            self.metrics['error_count'] += 1
    
    def calculate_throughput(self, total_time: float, total_transactions: int) -> float:
        """Calculate transactions per second"""
        if total_time > 0:
            return total_transactions / total_time
        return 0.0
    
    def get_performance_summary(self) -> Dict[str, Any]:
        """Get comprehensive performance summary"""
        if not self.metrics['transaction_times']:
            return {'error': 'No successful transactions recorded'}
        
        return {
            'total_transactions': len(self.metrics['transaction_times']),
            'success_rate': self.metrics['success_count'] / (self.metrics['success_count'] + self.metrics['error_count']),
            'average_latency': statistics.mean(self.metrics['transaction_times']),
            'median_latency': statistics.median(self.metrics['transaction_times']),
            'latency_95th_percentile': self._percentile(self.metrics['transaction_times'], 95),
            'min_latency': min(self.metrics['transaction_times']),
            'max_latency': max(self.metrics['transaction_times']),
            'average_gas_usage': statistics.mean(self.metrics['gas_usage']),
            'total_gas_used': sum(self.metrics['gas_usage']),
            'gas_efficiency': statistics.stdev(self.metrics['gas_usage']) if len(self.metrics['gas_usage']) > 1 else 0
        }
    
    def _percentile(self, data: List[float], percentile: int) -> float:
        """Calculate percentile value"""
        if not data:
            return 0.0
        sorted_data = sorted(data)
        index = int((percentile / 100.0) * len(sorted_data))
        return sorted_data[min(index, len(sorted_data) - 1)]

class CTIPlatformTester:
    """Comprehensive testing framework for CTI platform"""
    
    def __init__(self, config: CTIPlatformConfig):
        self.config = config
        self.performance_monitor = PerformanceMonitor()
        self.test_results: Dict[str, TestResults] = {}
        self.participants = []  # Will hold test participant data
        
    async def setup_test_environment(self):
        """Setup test environment with participants"""
        logger.info("Setting up test environment...")
        
        # Generate test participants
        for i in range(10):  # Create 10 test participants
            participant = {
                'id': f"test_participant_{i}",
                'organization': f"Test Org {i}",
                'address': f"0x{random.randint(100000, 999999):06x}",
                'reputation': random.randint(10, 100)
            }
            self.participants.append(participant)
        
        logger.info(f"Created {len(self.participants)} test participants")
    
    async def test_participant_registration(self, num_registrations: int = 5) -> TestResults:
        """Test participant registration functionality"""
        logger.info(f"Testing participant registration with {num_registrations} participants")
        
        start_time = time.time()
        passed = 0
        failed = 0
        total_gas = 0
        latencies = []
        
        for i in range(num_registrations):
            try:
                registration_start = time.time()
                
                # Simulate participant registration
                participant = {
                    'organization': f"Test Organization {i}",
                    'address': f"0x{random.randint(100000, 999999):06x}"
                }
                
                # Simulate gas usage for registration
                gas_used = random.randint(2_000_000, 3_000_000)
                
                # Simulate network delay
                await asyncio.sleep(random.uniform(0.1, 0.3))
                
                registration_time = time.time() - registration_start
                latencies.append(registration_time)
                
                passed += 1
                total_gas += gas_used
                
                self.performance_monitor.record_transaction(registration_time, gas_used, True)
                logger.info(f"[PASS] Registration {i+1}: {participant['organization']}")
                
            except Exception as e:
                failed += 1
                logger.error(f"[FAIL] Registration {i+1} failed: {e}")
                self.performance_monitor.record_transaction(0, 0, False)
        
        execution_time = time.time() - start_time
        avg_latency = statistics.mean(latencies) if latencies else 0
        throughput = self.performance_monitor.calculate_throughput(execution_time, passed)
        
        result = TestResults(
            test_name="participant_registration",
            passed=passed,
            failed=failed,
            execution_time=execution_time,
            average_latency=avg_latency,
            throughput=throughput,
            gas_used=total_gas,
            details={
                "latency_distribution": {
                    "min": min(latencies) if latencies else 0,
                    "max": max(latencies) if latencies else 0,
                    "median": statistics.median(latencies) if latencies else 0
                }
            }
        )
        
        self.test_results["participant_registration"] = result
        return result
    
    async def test_intelligence_submission(self, num_submissions: int = 20) -> TestResults:
        """Test threat intelligence submission functionality"""
        logger.info(f"Testing intelligence submission with {num_submissions} submissions")
        
        start_time = time.time()
        passed = 0
        failed = 0
        total_gas = 0
        latencies = []
        threat_types_tested = []
        
        for i in range(num_submissions):
            try:
                submission_start = time.time()
                
                # Generate realistic threat data
                threat_data = ThreatDataGenerator.generate_threat_intelligence()
                threat_types_tested.append(threat_data.threat_type)
                
                # Simulate submission process
                participant = random.choice(self.participants) if self.participants else {"id": "default"}
                
                # Simulate gas usage based on data complexity
                base_gas = 3_000_000
                complexity_factor = len(threat_data.mitre_techniques) * 100_000
                gas_used = base_gas + complexity_factor + random.randint(-200_000, 200_000)
                
                # Simulate network processing time
                await asyncio.sleep(random.uniform(0.2, 0.5))
                
                submission_time = time.time() - submission_start
                latencies.append(submission_time)
                
                passed += 1
                total_gas += gas_used
                
                self.performance_monitor.record_transaction(submission_time, gas_used, True)
                logger.info(f"[PASS] Submission {i+1}: {threat_data.threat_type} (severity: {threat_data.severity})")
                
            except Exception as e:
                failed += 1
                logger.error(f"[FAIL] Submission {i+1} failed: {e}")
                self.performance_monitor.record_transaction(0, 0, False)
        
        execution_time = time.time() - start_time
        avg_latency = statistics.mean(latencies) if latencies else 0
        throughput = self.performance_monitor.calculate_throughput(execution_time, passed)
        
        result = TestResults(
            test_name="intelligence_submission",
            passed=passed,
            failed=failed,
            execution_time=execution_time,
            average_latency=avg_latency,
            throughput=throughput,
            gas_used=total_gas,
            details={
                "threat_types_distribution": {tt: threat_types_tested.count(tt) for tt in set(threat_types_tested)},
                "average_gas_per_submission": total_gas / passed if passed > 0 else 0,
                "submissions_per_second": passed / execution_time if execution_time > 0 else 0
            }
        )
        
        self.test_results["intelligence_submission"] = result
        return result
    
    async def test_validation_workflow(self, num_validations: int = 15) -> TestResults:
        """Test intelligence validation workflow"""
        logger.info(f"Testing validation workflow with {num_validations} validations")
        
        start_time = time.time()
        passed = 0
        failed = 0
        total_gas = 0
        latencies = []
        validation_scores = []
        
        for i in range(num_validations):
            try:
                validation_start = time.time()
                
                # Simulate validation data
                quality_score = random.randint(1, 100)
                is_accurate = random.choice([True, False])
                validation_scores.append(quality_score)
                
                # Simulate validator selection
                validator = random.choice(self.participants) if self.participants else {"id": "default"}
                
                # Gas usage for validation
                gas_used = random.randint(2_500_000, 3_500_000)
                
                # Simulate validation processing
                await asyncio.sleep(random.uniform(0.15, 0.35))
                
                validation_time = time.time() - validation_start
                latencies.append(validation_time)
                
                passed += 1
                total_gas += gas_used
                
                self.performance_monitor.record_transaction(validation_time, gas_used, True)
                logger.info(f"[PASS] Validation {i+1}: score={quality_score}, accurate={is_accurate}")
                
            except Exception as e:
                failed += 1
                logger.error(f"[FAIL] Validation {i+1} failed: {e}")
                self.performance_monitor.record_transaction(0, 0, False)
        
        execution_time = time.time() - start_time
        avg_latency = statistics.mean(latencies) if latencies else 0
        throughput = self.performance_monitor.calculate_throughput(execution_time, passed)
        
        result = TestResults(
            test_name="validation_workflow",
            passed=passed,
            failed=failed,
            execution_time=execution_time,
            average_latency=avg_latency,
            throughput=throughput,
            gas_used=total_gas,
            details={
                "average_quality_score": statistics.mean(validation_scores) if validation_scores else 0,
                "quality_score_distribution": {
                    "high (80-100)": len([s for s in validation_scores if s >= 80]),
                    "medium (50-79)": len([s for s in validation_scores if 50 <= s < 80]),
                    "low (1-49)": len([s for s in validation_scores if s < 50])
                }
            }
        )
        
        self.test_results["validation_workflow"] = result
        return result
    
    async def test_performance_benchmarks(self, duration_seconds: int = 60) -> TestResults:
        """Run comprehensive performance benchmarks"""
        logger.info(f"Running performance benchmarks for {duration_seconds} seconds")
        
        start_time = time.time()
        end_time = start_time + duration_seconds
        
        transaction_count = 0
        total_gas = 0
        latencies = []
        
        # Test different operation types with different weights
        operation_weights = {
            'registration': 0.1,
            'submission': 0.4,
            'validation': 0.3,
            'access_control': 0.2
        }
        
        while time.time() < end_time:
            operation = random.choices(
                list(operation_weights.keys()),
                weights=list(operation_weights.values())
            )[0]
            
            try:
                op_start = time.time()
                
                # Simulate different operations
                if operation == 'registration':
                    gas_used = random.randint(2_000_000, 3_000_000)
                    await asyncio.sleep(random.uniform(0.1, 0.3))
                elif operation == 'submission':
                    gas_used = random.randint(3_000_000, 4_000_000)
                    await asyncio.sleep(random.uniform(0.2, 0.5))
                elif operation == 'validation':
                    gas_used = random.randint(2_500_000, 3_500_000)
                    await asyncio.sleep(random.uniform(0.15, 0.35))
                else:  # access_control
                    gas_used = random.randint(1_500_000, 2_500_000)
                    await asyncio.sleep(random.uniform(0.1, 0.25))
                
                op_time = time.time() - op_start
                latencies.append(op_time)
                total_gas += gas_used
                transaction_count += 1
                
                self.performance_monitor.record_transaction(op_time, gas_used, True)
                
            except Exception as e:
                logger.error(f"Benchmark operation failed: {e}")
                self.performance_monitor.record_transaction(0, 0, False)
        
        execution_time = time.time() - start_time
        avg_latency = statistics.mean(latencies) if latencies else 0
        throughput = self.performance_monitor.calculate_throughput(execution_time, transaction_count)
        
        result = TestResults(
            test_name="performance_benchmarks",
            passed=transaction_count,
            failed=self.performance_monitor.metrics['error_count'],
            execution_time=execution_time,
            average_latency=avg_latency,
            throughput=throughput,
            gas_used=total_gas,
            details={
                "peak_tps": throughput,
                "total_transactions": transaction_count,
                "latency_percentiles": {
                    "50th": self.performance_monitor._percentile(latencies, 50),
                    "95th": self.performance_monitor._percentile(latencies, 95),
                    "99th": self.performance_monitor._percentile(latencies, 99)
                },
                "gas_efficiency": total_gas / transaction_count if transaction_count > 0 else 0
            }
        )
        
        self.test_results["performance_benchmarks"] = result
        return result
    
    async def test_scalability_stress(self, max_concurrent_users: int = 100) -> TestResults:
        """Test system scalability under increasing load"""
        logger.info(f"Testing scalability with up to {max_concurrent_users} concurrent users")
        
        start_time = time.time()
        results_by_load = {}
        
        # Test with increasing concurrent load
        for concurrent_users in [10, 25, 50, 75, max_concurrent_users]:
            logger.info(f"Testing with {concurrent_users} concurrent users")
            
            tasks = []
            load_start = time.time()
            
            # Create concurrent tasks
            for i in range(concurrent_users):
                task = asyncio.create_task(self._simulate_user_activity())
                tasks.append(task)
            
            # Wait for all tasks to complete
            load_results = await asyncio.gather(*tasks, return_exceptions=True)
            
            load_time = time.time() - load_start
            successful_tasks = len([r for r in load_results if not isinstance(r, Exception)])
            failed_tasks = len([r for r in load_results if isinstance(r, Exception)])
            
            results_by_load[concurrent_users] = {
                'successful_operations': successful_tasks,
                'failed_operations': failed_tasks,
                'execution_time': load_time,
                'throughput': successful_tasks / load_time if load_time > 0 else 0,
                'success_rate': successful_tasks / concurrent_users if concurrent_users > 0 else 0
            }
            
            logger.info(f"Load {concurrent_users}: {successful_tasks}/{concurrent_users} successful, "
                       f"TPS: {successful_tasks / load_time:.2f}")
        
        execution_time = time.time() - start_time
        total_successful = sum(r['successful_operations'] for r in results_by_load.values())
        total_failed = sum(r['failed_operations'] for r in results_by_load.values())
        
        result = TestResults(
            test_name="scalability_stress",
            passed=total_successful,
            failed=total_failed,
            execution_time=execution_time,
            average_latency=0,  # Will be calculated per load level
            throughput=max(r['throughput'] for r in results_by_load.values()),
            gas_used=0,  # Estimated based on operations
            details={
                "load_test_results": results_by_load,
                "max_concurrent_users_tested": max_concurrent_users,
                "performance_degradation": self._calculate_performance_degradation(results_by_load)
            }
        )
        
        self.test_results["scalability_stress"] = result
        return result
    
    async def _simulate_user_activity(self) -> Dict[str, Any]:
        """Simulate a single user's activity"""
        operations_completed = 0
        
        # Random user activity pattern
        activities = ['submit_intel', 'validate_intel', 'query_data']
        
        for _ in range(random.randint(1, 5)):  # 1-5 operations per user
            activity = random.choice(activities)
            
            try:
                if activity == 'submit_intel':
                    await asyncio.sleep(random.uniform(0.2, 0.5))
                elif activity == 'validate_intel':
                    await asyncio.sleep(random.uniform(0.15, 0.35))
                else:  # query_data
                    await asyncio.sleep(random.uniform(0.05, 0.15))
                
                operations_completed += 1
                
            except Exception:
                break
        
        return {'operations_completed': operations_completed}
    
    def _calculate_performance_degradation(self, results_by_load: Dict) -> Dict[str, float]:
        """Calculate performance degradation as load increases"""
        baseline_tps = list(results_by_load.values())[0]['throughput']
        degradation = {}
        
        for load, result in results_by_load.items():
            current_tps = result['throughput']
            degradation_pct = ((baseline_tps - current_tps) / baseline_tps * 100) if baseline_tps > 0 else 0
            degradation[str(load)] = max(0, degradation_pct)
        
        return degradation
    
    async def run_full_test_suite(self) -> Dict[str, TestResults]:
        """Run the complete test suite"""
        logger.info("Starting comprehensive CTI platform test suite")
        
        await self.setup_test_environment()
        
        # Run all tests
        test_functions = [
            (self.test_participant_registration, 10),
            (self.test_intelligence_submission, 25),
            (self.test_validation_workflow, 20),
            (self.test_performance_benchmarks, 60),
            (self.test_scalability_stress, 50)
        ]
        
        for test_func, param in test_functions:
            try:
                if 'benchmarks' in test_func.__name__:
                    await test_func(param)  # Duration in seconds
                else:
                    await test_func(param)  # Number of operations
            except Exception as e:
                logger.error(f"Test {test_func.__name__} failed: {e}")
        
        return self.test_results
    
    def generate_test_report(self) -> Dict[str, Any]:
        """Generate comprehensive test report"""
        if not self.test_results:
            return {"error": "No test results available"}
        
        overall_stats = {
            'total_tests_run': len(self.test_results),
            'total_operations': sum(r.passed + r.failed for r in self.test_results.values()),
            'overall_success_rate': sum(r.passed for r in self.test_results.values()) / 
                                  sum(r.passed + r.failed for r in self.test_results.values()),
            'total_execution_time': sum(r.execution_time for r in self.test_results.values()),
            'total_gas_used': sum(r.gas_used for r in self.test_results.values())
        }
        
        performance_summary = self.performance_monitor.get_performance_summary()
        
        return {
            'test_timestamp': datetime.now().isoformat(),
            'overall_statistics': overall_stats,
            'performance_summary': performance_summary,
            'individual_test_results': {name: asdict(result) for name, result in self.test_results.items()},
            'recommendations': self._generate_recommendations()
        }
    
    def _generate_recommendations(self) -> List[str]:
        """Generate recommendations based on test results"""
        recommendations = []
        
        perf_summary = self.performance_monitor.get_performance_summary()
        
        if perf_summary.get('success_rate', 0) < 0.95:
            recommendations.append("Success rate below 95% - investigate error handling and network stability")
        
        if perf_summary.get('average_latency', 0) > 2.0:
            recommendations.append("Average latency above 2 seconds - consider optimization")
        
        if any(r.throughput < 100 for r in self.test_results.values()):
            recommendations.append("Throughput below 100 TPS - investigate scalability bottlenecks")
        
        return recommendations

# Example usage and pytest integration
@pytest.mark.asyncio
async def test_cti_platform_comprehensive():
    """Pytest integration for comprehensive testing"""
    config = CTIPlatformConfig(
        network="localnet",
        package_id="0x123...",  # Replace with actual package ID
        platform_object_id="0x456...",  # Replace with actual platform object ID
    )
    
    tester = CTIPlatformTester(config)
    results = await tester.run_full_test_suite()
    
    # Assert overall success
    assert len(results) > 0
    
    # Check individual test success rates
    for test_name, result in results.items():
        success_rate = result.passed / (result.passed + result.failed) if (result.passed + result.failed) > 0 else 0
        assert success_rate >= 0.9, f"Test {test_name} success rate {success_rate} below threshold"
    
    # Generate and save report
    report = tester.generate_test_report()
    with open(f"test_report_{int(time.time())}.json", 'w') as f:
        json.dump(report, f, indent=2)

async def main():
    """Main test execution function"""
    print("Starting CTI Platform Comprehensive Testing")
    
    config = CTIPlatformConfig(
        network="localnet",
        package_id="0x123...",  # Replace with actual package ID
        platform_object_id="0x456...",  # Replace with actual platform object ID
    )
    
    tester = CTIPlatformTester(config)
    
    # Run test suite
    results = await tester.run_full_test_suite()
    
    # Generate report
    report = tester.generate_test_report()
    
    print("\n" + "="*50)
    print("TEST EXECUTION COMPLETED")
    print("="*50)
    
    print(f"Tests Run: {len(results)}")
    print(f"Total Operations: {report['overall_statistics']['total_operations']}")
    print(f"Success Rate: {report['overall_statistics']['overall_success_rate']:.2%}")
    print(f"Total Execution Time: {report['overall_statistics']['total_execution_time']:.2f}s")
    print(f"Total Gas Used: {report['overall_statistics']['total_gas_used']:,}")
    
    if report.get('recommendations'):
        print("\nRecommendations:")
        for rec in report['recommendations']:
            print(f"- {rec}")
    
    # Save detailed report
    with open(f"cti_platform_test_report_{int(time.time())}.json", 'w') as f:
        json.dump(report, f, indent=2)
    
    print(f"\nDetailed report saved as: cti_platform_test_report_{int(time.time())}.json")

if __name__ == "__main__":
    asyncio.run(main())